"""Build a reviewed xMacro distribution, never a recursive addon snapshot."""
import argparse
import configparser
import hashlib
import json
from pathlib import Path
import re
import zipfile
if __package__:
    from . import build_xmacro_runtime as runtime
    from . import build_xmacro_native as native
else:
    import build_xmacro_runtime as runtime
    import build_xmacro_native as native

# Every release member is reviewed here. Personal state and development trees are absent.
ADDON_FILES = (
    # Inert compatibility stubs keep legacy loaders safe on clean installs.
    'functions.lua', 'HoldKey.lua', 'xMacro.lua',
    'info.ini', 'Config.lua', 'Macro.lua', 'Core/Macro.lua', 'Core/functions.lua',
    'Schools/Registry.lua', 'Schools/VanHoa/HoaGian.lua', 'Features/KeySpam.lua',
    'xMacro.ini', 'HoldKey.ini', 'HoldKeyEngine.py', 'Tools/KeySpam/engine.py',
    'start_xmacro.bat', 'KeySpam.exe', 'README_INSTALL.txt', 'README.txt', 'KEY_SPAM.txt',
    'docs/EXTENDING.txt',
    'Schools/ThatTu/ThatTu_BangTam_80_v1.5.txt', 'Schools/ThatTu/ThatTu_BangTam_80.txt',
    'Schools/VanHoa/VanHoa_HoaGian_80.txt',
    'Schools/VanHoa/VanHoa_HoaGian_reference_Core1.1.txt',
    'Schools/VanHoa/VanHoa_QuyLieu_BichLac_80.txt',
)
RESOURCE_FILES = ('CAI_DAT.bat', 'Install-xMacro.ps1', 'HUONG_DAN.txt',
                  'KIEM_TRA.bat', 'Check-xMacro.ps1', 'Check-NativeLua.ps1')
NATIVE_API_VERSION = '0.8'


def validate_release_config(config):
    """Accept only the two reviewed selector forms, never execute source Lua."""
    # These selector forms contain no string with spaces/comments. Normalize only
    # insignificant whitespace, line comments and quote style, then compare whole
    # source so a later override cannot pass by containing an earlier default.
    lines = [line.split('--', 1)[0] for line in config.splitlines()]
    normalized = re.sub(r"\s+", "", "".join(lines)).replace('"', "'")
    init = "xMacro=xMacroor{}"
    table = "xMacro.Config={school='VanHoa',profile='HoaGian'}"
    fields = ("xMacro.Config=xMacro.Configor{}"
              "xMacro.Config.school=xMacro.Config.schoolor'VanHoa'"
              "xMacro.Config.profile=xMacro.Config.profileor'HoaGian'")
    if normalized not in {table, init + table, init + fields}:
        raise ValueError('Config.lua must contain only the reviewed VanHoa/HoaGian default selector')


def release_members(addon):
    addon = Path(addon).resolve()
    members = {}
    for name in ADDON_FILES:
        path = addon / name
        if not path.is_file() or path.resolve() != path.absolute():
            raise ValueError('Missing release file or redirected path: ' + name)
        members['Interface/xMacro/' + name] = path.read_bytes()
    config = members['Interface/xMacro/Config.lua'].decode('utf-8-sig')
    validate_release_config(config)
    # Never distribute a source user's extra settings or comments in the selector.
    members['Interface/xMacro/Config.lua'] = b"xMacro = xMacro or {}\nxMacro.Config = {school='VanHoa', profile='HoaGian'}\n"
    sources = {name: members['Interface/xMacro/' + name].decode('utf-8-sig')
               for name in runtime.RUNTIME_MODULES}
    members['Interface/xMacro/Runtime.lua'] = runtime.render_sources(sources).encode('utf-8-sig')
    for name, text in native.render_native(sources).items():
        members['Interface/xMacro/' + name] = text.encode('utf-8-sig')
    members['BUILD_RUNTIME.py'] = Path(runtime.__file__).read_bytes()
    members['BUILD_NATIVE.py'] = Path(native.__file__).read_bytes().replace(b'build_xmacro_runtime', b'BUILD_RUNTIME')
    info = members['Interface/xMacro/info.ini'].decode('utf-8-sig')
    native_info = configparser.ConfigParser()
    try:
        native_info.read_string(info)
    except configparser.Error as error:
        raise ValueError('Invalid native info.ini: ' + str(error)) from error
    if native_info.get('xMacro', 'version', fallback=None) != NATIVE_API_VERSION:
        raise ValueError('info.ini version is native API compatibility; keep version=0.8 and use release= for package versions')
    entries = re.findall(r'^\s*lua_\d+\s*=\s*(.*?)\s*$', info, re.M | re.I)
    entry_keys = re.findall(r'^\s*(lua_\d+)\s*=', info, re.M | re.I)
    if entries != native.native_entries() or entry_keys != ['lua_' + str(i) for i in range(len(native.NATIVE_NAMES))]:
        raise ValueError('info.ini must load ordered unique generated Native entries from lua_0')
    # Ensure the client never references an omitted Lua/UI file.
    for text in (members['Interface/xMacro/info.ini'], members['Interface/xMacro/xMacro.ini'],
                 members['Interface/xMacro/HoldKey.ini']):
        for ref in re.findall(r'Interface[\\/]xMacro[\\/]([^\s\r\n]+\.(?:lua|ini))', text.decode('utf-8-sig'), re.I):
            canonical = 'Interface/xMacro/' + ref.replace('\\', '/')
            if canonical not in members:
                raise ValueError('Client references unshipped file: ' + canonical)
    resources = Path(__file__).parent / 'xmacro_distribution'
    for name in RESOURCE_FILES:
        members[name] = (resources / name).read_bytes()
    expected = {name: hashlib.sha256(data).hexdigest() for name, data in sorted(members.items())
                if name.startswith('Interface/xMacro/')}
    members['xMacro-expected.json'] = (json.dumps(expected, indent=2) + '\n').encode('utf-8')
    manifest = {name: hashlib.sha256(data).hexdigest() for name, data in sorted(members.items())}
    members['SHA256.json'] = (json.dumps(manifest, indent=2, ensure_ascii=False) + '\n').encode('utf-8')
    return members


def build(addon, output):
    members = release_members(addon)
    output = Path(output)
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, 'w', compression=zipfile.ZIP_DEFLATED) as archive:
        for name, data in sorted(members.items()):
            info = zipfile.ZipInfo(name, (2026, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, data)
    return members


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument('--source-root', type=Path)
    source.add_argument('--addon-root', type=Path)
    parser.add_argument('--output', type=Path)
    parser.add_argument('--dry-run', '--list', action='store_true')
    args = parser.parse_args()
    addon = args.addon_root or args.source_root / 'interface' / 'xMacro'
    if args.dry_run:
        print('\n'.join(sorted(release_members(addon))))
    elif args.output:
        members = build(addon, args.output)
        print('%d files: %s' % (len(members), args.output.resolve()))
        print('SHA256: ' + hashlib.sha256(args.output.read_bytes()).hexdigest())
    else:
        parser.error('--output required unless --dry-run')

if __name__ == '__main__':
    main()
