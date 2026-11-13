from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
import zipfile
if __package__:
    from . import build_xmacro_package as package
else:
    import build_xmacro_package as package

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'interface/xMacro'))
from Tools.KeySpam import engine


class DistributionTests(unittest.TestCase):
    def populate(self, root):
        for name in package.ADDON_FILES:
            path = root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            content = "xMacro.Config={school='VanHoa',profile='HoaGian'}" if name == 'Config.lua' else '-- fixture'
            if name == 'info.ini':
                content = r'lua_0=Interface\xMacro\Runtime.lua'
            path.write_text(content, encoding='utf-8')

    def test_actual_core_default_selector_and_reject_overrides(self):
        core_config = '''-- Explicit selection: native force IDs are intentionally not guessed.
xMacro = xMacro or {}
xMacro.Config = xMacro.Config or {}
xMacro.Config.school = xMacro.Config.school or "VanHoa"
xMacro.Config.profile = xMacro.Config.profile or "HoaGian"
'''
        with tempfile.TemporaryDirectory() as temporary:
            addon = Path(temporary); self.populate(addon)
            (addon / 'Config.lua').write_text(core_config, encoding='utf-8')
            members = package.release_members(addon)
            self.assertEqual(members['Interface/xMacro/Config.lua'],
                b"xMacro = xMacro or {}\nxMacro.Config = {school='VanHoa', profile='HoaGian'}\n")
            for invalid in (
                core_config.replace('"VanHoa"', '"ThatTu"'),
                core_config.replace('"HoaGian"', '"Other"'),
                core_config + 'xMacro.Config.school = "ThatTu"',
                "xMacro.Config={school='VanHoa',profile='HoaGian'}; evil()",
                core_config + 'xMacro.Config.profile = "Other"',
            ):
                with self.subTest(config=invalid), self.assertRaises(ValueError):
                    package.validate_release_config(invalid)

    def test_runtime_generated_from_sanitized_sources_and_native_entry_only(self):
        with tempfile.TemporaryDirectory() as temporary:
            addon = Path(temporary); self.populate(addon)
            (addon / 'Runtime.lua').write_text('STALE PRIVATE RUNTIME')
            (addon / 'Config.lua').write_text("xMacro.Config={school='VanHoa',profile='HoaGian'} -- PRIVATE")
            members = package.release_members(addon)
            bundle = members['Interface/xMacro/Runtime.lua'].decode('utf-8')
            self.assertNotIn('STALE', bundle)
            self.assertNotIn('PRIVATE', bundle)
            offsets = [bundle.index('-- BEGIN ' + name) for name in package.runtime.RUNTIME_MODULES]
            self.assertEqual(offsets, sorted(offsets))
            self.assertEqual(members['BUILD_RUNTIME.py'], Path(package.runtime.__file__).read_bytes())
            for invalid in (r'lua_0=Interface\xMacro\Macro.lua',
                            'lua_0=Interface\\xMacro\\Runtime.lua\nlua_1=Interface\\xMacro\\Macro.lua',
                            r'lua_1=Interface\xMacro\Runtime.lua'):
                (addon / 'info.ini').write_text(invalid)
                with self.subTest(info=invalid), self.assertRaises(ValueError):
                    package.release_members(addon)

    def test_source_and_frozen_paths(self):
        self.assertEqual(engine.ADDON_ROOT, ROOT / 'interface/xMacro')
        with patch.object(sys, 'frozen', True, create=True), patch.object(sys, 'executable', str(ROOT / 'interface/xMacro/KeySpam.exe')):
            self.assertEqual(engine.addon_root(), ROOT / 'interface/xMacro')

    def test_explicit_members_exclude_personal_state_and_reproducible_zip(self):
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary); addon = base / 'addon'; self.populate(addon)
            (addon / 'hold_key_control.jx3dat').write_text('private')
            (addon / 'secret.log').write_text('private')
            (addon / 'Config.lua').write_text("xMacro.Config={school='VanHoa',profile='HoaGian'} -- private")
            members = package.build(addon, base / 'one.zip')
            package.build(addon, base / 'two.zip')
            self.assertEqual((base / 'one.zip').read_bytes(), (base / 'two.zip').read_bytes())
            self.assertFalse(any(name.endswith(('.jx3dat', '.log')) for name in members))
            self.assertNotIn(b'private', members['Interface/xMacro/Config.lua'])
            self.assertIn('SHA256.json', members)

    def test_frozen_check_uses_deployment_directory_and_writes_nothing(self):
        executable = ROOT / 'interface/xMacro/KeySpam.exe'
        if not executable.is_file():
            self.skipTest('Build KeySpam.exe for frozen deployment check')
        with tempfile.TemporaryDirectory() as temporary:
            import shutil
            addon = Path(temporary) / 'Interface/xMacro'
            addon.mkdir(parents=True)
            shutil.copy2(executable, addon / 'KeySpam.exe')
            state = engine.encode_data(dict(version=2, enabled=False, interval_ms=50,
                                            run_id=7, key_1=49, key_2=0, key_3=0, key_4=0))
            (addon / 'hold_key_control.jx3dat').write_bytes(state)
            before = {p.name: p.read_bytes() for p in addon.iterdir()}
            result = subprocess.run([str(addon / 'KeySpam.exe'), '--check'],
                                    capture_output=True, text=True, encoding='utf-8')
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('run_id=7', result.stdout)
            self.assertIn('game hop le: 0', result.stdout)
            self.assertEqual(before, {p.name: p.read_bytes() for p in addon.iterdir()})

    def test_missing_module_and_unshipped_reference_fail(self):
        with tempfile.TemporaryDirectory() as temporary:
            addon = Path(temporary); self.populate(addon)
            (addon / 'HoldKey.ini').write_text('Path=Interface\\xMacro\\Private.lua')
            with self.assertRaisesRegex(ValueError, 'unshipped'):
                package.release_members(addon)
            (addon / 'HoldKey.ini').write_text('ok')
            (addon / 'Features/KeySpam.lua').unlink()
            with self.assertRaisesRegex(ValueError, 'Missing'):
                package.release_members(addon)

    def test_installer_temp_target_preserves_state_and_backs_up(self):
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary); addon = base / 'addon'; self.populate(addon)
            package.build(addon, base / 'release.zip')
            source = base / 'unpacked'
            with zipfile.ZipFile(base / 'release.zip') as archive:
                archive.extractall(source)
            game = base / 'fake-game'; game.mkdir()
            command = ['powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', str(source / 'Install-xMacro.ps1'), '-GameRoot', str(game)]
            bad = subprocess.run(command + ['-ValidateOnly'], capture_output=True, text=True)
            self.assertNotEqual(bad.returncode, 0)
            (game / 'jx3client.exe').touch()
            old = game / 'Interface/xMacro'; old.mkdir(parents=True)
            (old / 'hold_key_ui.jx3dat').write_bytes(b'user state')
            (old / 'info.ini').write_text('old version')
            result = subprocess.run(command, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual((old / 'hold_key_ui.jx3dat').read_bytes(), b'user state')
            backups = list((game / 'xMacro-backups').glob('*/xMacro/info.ini'))
            self.assertEqual(len(backups), 1)
            self.assertEqual(backups[0].read_text(), 'old version')
            self.assertEqual((old / 'info.ini').read_text(), r'lua_0=Interface\xMacro\Runtime.lua')

if __name__ == '__main__':
    unittest.main()
