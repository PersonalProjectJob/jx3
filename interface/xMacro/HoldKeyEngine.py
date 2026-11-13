"""Repeat up to four configured keys in each cycle, addressed only to the game."""

from dataclasses import dataclass
from pathlib import Path
import argparse
import ctypes
from ctypes import wintypes
import hashlib
import os
import re
import sys
import time
import struct
import zlib


GAME_ROOT = Path(__file__).resolve().parents[2]
CONTROL_FILE = Path(__file__).resolve().parent / "hold_key_control.jx3dat"
SUPPORTED_KEYS = frozenset(
    [0x08, 0x09, 0x0D, 0x20, 0x2D, 0x2E, 0xE2]
    + list(range(0x21, 0x29))  # Page/Home/End/arrows
    + list(range(0x30, 0x3A)) + list(range(0x41, 0x5B))
    + list(range(0x60, 0x88))  # Numpad and F1-F24
    + list(range(0xBA, 0xC1)) + list(range(0xDB, 0xE0))
)


@dataclass(frozen=True)
class GameTarget:
    hwnd: int
    pid: int
    executable: str
    birth: int


@dataclass(frozen=True)
class HoldSettings:
    enabled: bool = False
    interval_ms: int = 50
    keys: tuple = ()
    run_id: int = 0
    native_macro: bool = False


def encode_data(fields):
    payload = ('data=\n{\n' + ''.join(
        '  ["%s"] = %s,\n' % (key, str(value).lower() if isinstance(value, bool) else value)
        for key, value in fields.items()) + '}\n').encode('ascii')
    return struct.pack('<4sIII', b'CNDK', zlib.crc32(payload), len(payload), len(payload)) + payload


def decode_data(raw):
    if len(raw) > 4096 or len(raw) < 16:
        raise ValueError('Invalid control length')
    magic, crc, size, unpacked = struct.unpack('<4sIII', raw[:16])
    payload = raw[16:]
    if magic != b'CNDK' or size != len(payload) or unpacked != size or zlib.crc32(payload) != crc:
        raise ValueError('Invalid CNDK checksum/header')
    text = payload.decode('ascii')
    pairs = re.findall(r'\["([a-z_0-9]+)"\]\s*=\s*(true|false|[0-9]+)\s*,', text)
    values = {}
    for key, value in pairs:
        if key in values:
            raise ValueError('Duplicate field: ' + key)
        values[key] = value == 'true' if value in ('true', 'false') else int(value)
    return values


def parse_control(raw):
    values = decode_data(raw)
    if values.get('version') != 2:
        return HoldSettings()  # Legacy hold-to-repeat must never arm the new flow.
    if any(key.startswith('key_') and key not in {'key_1', 'key_2', 'key_3', 'key_4'} for key in values):
        raise ValueError('At most four key slots')
    required = ['enabled', 'interval_ms', 'run_id'] + ['key_%d' % i for i in range(1, 5)]
    if any(key not in values for key in required):
        raise ValueError('Missing v2 control field')
    if type(values['enabled']) is not bool:
        raise ValueError('enabled must be boolean')
    if any(type(values[key]) is not int for key in required[1:]):
        raise ValueError('Expected integer')
    native_macro = values.get('native_macro', False)
    if type(native_macro) is not bool:
        raise ValueError('native_macro must be boolean')
    interval, run_id = values['interval_ms'], values['run_id']
    keys = tuple(values['key_%d' % i] for i in range(1, 5) if values['key_%d' % i])
    if not 20 <= interval <= 2000 or run_id < 0 or len(keys) != len(set(keys)):
        raise ValueError('Invalid interval/run/duplicate key')
    if any(key not in SUPPORTED_KEYS for key in keys):
        raise ValueError('Unsupported key')
    if values['enabled'] and (run_id == 0 or (not keys and not native_macro)):
        raise ValueError('Start requires keys and run_id')
    return HoldSettings(values['enabled'], interval, keys, run_id, native_macro)


class GameControl:
    def __init__(self, path=CONTROL_FILE, default_interval=50):
        self.path = Path(path)
        self.settings = HoldSettings(interval_ms=default_interval)
        self.error = None
        self.next_poll = 0.0

    def poll(self, now):
        if now < self.next_poll:
            return self.settings
        self.next_poll = now + 0.025
        try:
            with self.path.open('rb') as stream:
                self.settings = parse_control(stream.read(4097))
            self.error = None
        except (OSError, ValueError, UnicodeError) as error:
            self.settings = HoldSettings()
            self.error = str(error)
        return self.settings


class ConfiguredRepeater:
    """Bind one run to one game; background focus changes never retarget it."""
    def __init__(self, native):
        self.native = native
        self.output = [KeyOutput(native) for _ in range(4)]
        self.settings = HoldSettings()
        self.target = None
        self.fault = False
        self.next_repeat = 0.0

    def release(self):
        results = [output.release() for output in self.output]
        return all(results)

    def tick(self, settings, now):
        if settings != self.settings:
            self.release()
            # An explicit stop or new Start is required after a target/output fault.
            if not settings.enabled or settings.run_id != self.settings.run_id:
                self.target, self.fault = None, False
            self.settings = settings
            self.next_repeat = now
        if not settings.enabled or settings.native_macro:
            self.release()
            return 4 if settings.enabled and settings.native_macro else 0
        if self.fault:
            return 3
        if not self.target:
            games = self.native.games()
            foreground = self.native.identity(self.native.user.GetForegroundWindow())
            self.target = foreground if foreground in games else (games[0] if len(games) == 1 else None)
            if not self.target:
                return 1
        if self.native.identity(self.target.hwnd) != self.target:
            self.fault = True
        results = [output.tick(now) for output in self.output]
        if not all(results):
            self.fault = True
        if self.fault:
            self.release()
            return 3
        if now >= self.next_repeat:
            self.next_repeat = now + settings.interval_ms / 1000
            for output, key in zip(self.output, settings.keys):
                if not output.press(key, self.target, now):
                    self.fault = True
                    self.release()
                    return 3
        return 2


class Win32:
    """All keyboard output is addressed to a validated game HWND."""

    def __init__(self):
        if os.name != "nt":
            raise RuntimeError("Tool nay chi chay tren Windows.")
        self.user = ctypes.WinDLL("user32", use_last_error=True)
        self.kernel = ctypes.WinDLL("kernel32", use_last_error=True)
        self.enum_type = ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HWND,
                                           wintypes.LPARAM)
        signatures = {
            "GetForegroundWindow": ([], wintypes.HWND),
            "GetClassNameW": ([wintypes.HWND, wintypes.LPWSTR, ctypes.c_int], ctypes.c_int),
            "GetWindowThreadProcessId": ([wintypes.HWND, ctypes.POINTER(wintypes.DWORD)], wintypes.DWORD),
            "IsWindow": ([wintypes.HWND], wintypes.BOOL),
            "PostMessageW": ([wintypes.HWND, wintypes.UINT, wintypes.WPARAM, wintypes.LPARAM], wintypes.BOOL),
            "MapVirtualKeyW": ([wintypes.UINT, wintypes.UINT], wintypes.UINT),
            "EnumWindows": ([self.enum_type, wintypes.LPARAM], wintypes.BOOL),
        }
        for name, (args, result) in signatures.items():
            fn = getattr(self.user, name)
            fn.argtypes, fn.restype = args, result
        signatures = {
            "OpenProcess": ([wintypes.DWORD, wintypes.BOOL, wintypes.DWORD], wintypes.HANDLE),
            "CloseHandle": ([wintypes.HANDLE], wintypes.BOOL),
            "QueryFullProcessImageNameW": ([wintypes.HANDLE, wintypes.DWORD, wintypes.LPWSTR, ctypes.POINTER(wintypes.DWORD)], wintypes.BOOL),
            "GetProcessTimes": ([wintypes.HANDLE] + [ctypes.POINTER(wintypes.FILETIME)] * 4, wintypes.BOOL),
            "GetModuleHandleW": ([wintypes.LPCWSTR], wintypes.HMODULE),
            "CreateMutexW": ([ctypes.c_void_p, wintypes.BOOL, wintypes.LPCWSTR], wintypes.HANDLE),
        }
        for name, (args, result) in signatures.items():
            fn = getattr(self.kernel, name)
            fn.argtypes, fn.restype = args, result

    def identity(self, hwnd):
        if not hwnd or not self.user.IsWindow(hwnd):
            return None
        cls = ctypes.create_unicode_buffer(128)
        self.user.GetClassNameW(hwnd, cls, len(cls))
        if cls.value != "KGWin32App":
            return None
        pid = wintypes.DWORD()
        self.user.GetWindowThreadProcessId(hwnd, ctypes.byref(pid))
        process = self.kernel.OpenProcess(0x1000, False, pid.value)
        if not process:
            return None
        try:
            size = wintypes.DWORD(32768)
            path = ctypes.create_unicode_buffer(size.value)
            if not self.kernel.QueryFullProcessImageNameW(process, 0, path, ctypes.byref(size)):
                return None
            exe = Path(path.value).resolve()
            if exe.name.lower() not in {"jx3client.exe", "game.exe"}:
                return None
            if os.path.normcase(str(exe.parent)) != os.path.normcase(str(GAME_ROOT)):
                return None
            created, ended, kernel, user = (wintypes.FILETIME() for _ in range(4))
            if not self.kernel.GetProcessTimes(process, ctypes.byref(created),
                                               ctypes.byref(ended), ctypes.byref(kernel), ctypes.byref(user)):
                return None
            birth = (created.dwHighDateTime << 32) | created.dwLowDateTime
            return GameTarget(int(hwnd), pid.value, str(exe), birth)
        finally:
            self.kernel.CloseHandle(process)

    def post_key(self, target, vk, down):
        # Re-check process path, PID and creation time before BOTH messages.
        if self.identity(target.hwnd) != target:
            return False
        scan = self.user.MapVirtualKeyW(vk, 4)
        lp = 1 | ((scan & 0xFF) << 16)
        if (scan >> 8) in (0xE0, 0xE1):
            lp |= 1 << 24
        if not down:
            lp |= (1 << 30) | (1 << 31)
        return bool(self.user.PostMessageW(target.hwnd, 0x100 if down else 0x101, vk, lp))

    def games(self):
        result = []

        @self.enum_type
        def collect(hwnd, _):
            target = self.identity(hwnd)
            if target:
                result.append(target)
            return True

        self.user.EnumWindows(collect, 0)
        return result


class KeyOutput:
    """Short addressed down/up pairs, including cleanup when stopped."""

    def __init__(self, native):
        self.native = native
        self.pending = None

    def release(self):
        if self.pending:
            vk, target, _ = self.pending
            self.pending = None
            return self.native.post_key(target, vk, False)
        return True

    def tick(self, now):
        if self.pending and now >= self.pending[2]:
            return self.release()
        return True

    def press(self, vk, target, now):
        if not self.release() or not self.native.post_key(target, vk, True):
            return False
        self.pending = (vk, target, now + 0.015)
        return True


def run(native, interval, control=None):
    tag = hashlib.sha256(str(GAME_ROOT).lower().encode()).hexdigest()[:20]
    mutex = native.kernel.CreateMutexW(None, False, "Local\\JX3HoldKey_" + tag)
    if not mutex:
        raise ctypes.WinError(ctypes.get_last_error())
    if ctypes.get_last_error() == 183:
        native.kernel.CloseHandle(mutex)
        raise RuntimeError('Tool dang chay. Hay dong ban cu truoc.')
    state = ConfiguredRepeater(native)
    control = control or GameControl(default_interval=round(interval * 1000))
    status_path = CONTROL_FILE.with_name('hold_key_status.jx3dat')
    sequence, next_status, shown = 0, 0, None
    try:
        print('xMacro: chon toi da 4 phim va bam BAT DAU trong game. Moi chu ky 50 ms nhan tat ca phim.', flush=True)
        while True:
            now = time.monotonic()
            settings = control.poll(now)
            status = state.tick(settings, now)
            if control.error:
                status = 3
            if (settings, status, control.error) != shown:
                shown = (settings, status, control.error)
                print(shown, flush=True)
            if now >= next_status:
                sequence += 1
                next_status = now + 0.25
                fields = dict(pid=os.getpid(), seq=sequence, state=status,
                              run_id=settings.run_id, keys_count=len(settings.keys), interval_ms=settings.interval_ms)
                temporary = status_path.with_suffix('.tmp')
                try:
                    temporary.write_bytes(encode_data(fields))
                    temporary.replace(status_path)
                except OSError as error:
                    print('Status write error:', error, flush=True)
            time.sleep(0.003)
    finally:
        state.release()
        native.kernel.CloseHandle(mutex)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--interval-ms", type=int, default=50,
                        help="Chu ky nhan lap 20-2000 ms, mac dinh 50")
    parser.add_argument("--check", action="store_true",
                        help="Kiem tra Win32 va liet ke game hop le, khong bat phim/khong gui phim")
    args = parser.parse_args()
    if not 20 <= args.interval_ms <= 2000:
        parser.error("--interval-ms phai tu 20 den 2000")
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    try:
        native = Win32()
        if args.check:
            games = native.games()
            print("Win32 API: OK; game hop le: %d" % len(games))
            for game in games:
                print(game)
            control = GameControl(default_interval=args.interval_ms)
            print("xMacro control:", control.poll(time.monotonic()))
            if control.error:
                print("Control error:", control.error)
        else:
            run(native, args.interval_ms / 1000)
    except KeyboardInterrupt:
        print("\nDa thoat.")
    except (OSError, RuntimeError) as error:
        print("LOI: %s" % error, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
