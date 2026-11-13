"""Execute real generated Lua and canonical modules under delayed load conditions."""
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory
from simulator.engine import JX3Simulator
from tools.build_xmacro_runtime import RUNTIME_MODULES, build_runtime, render_runtime, render_sources

ADDON = Path(__file__).resolve().parents[1] / "interface" / "xMacro"


class RuntimeLoadingTests(unittest.TestCase):
    def fresh(self):
        return JX3Simulator(load_addon=False)

    def load(self, sim, *names):
        for name in names:
            sim.lua.execute((ADDON / name).read_text(encoding="utf-8-sig"))

    def failure_logs(self, sim):
        return [text for _, text in sim.lua.globals()._szSysLog.items() if "Profile unavailable:" in text]

    def test_checked_in_bundle_matches_canonical_sources(self):
        self.assertEqual((ADDON / "Runtime.lua").read_bytes(), render_runtime(ADDON).encode("utf-8-sig"))

    def test_generator_is_deterministic_and_preserves_module_scope(self):
        sources = {name: (ADDON / name).read_bytes() for name in RUNTIME_MODULES}
        rendered = render_sources(sources)
        self.assertEqual(rendered, render_sources(dict(reversed(list(sources.items())))))
        self.assertEqual(rendered.count("-- BEGIN "), len(RUNTIME_MODULES))
        sim = self.fresh()
        sim.lua.execute(rendered)
        self.assertIsNotNone(sim.lua.eval('xMacro.Schools.Resolve("VanHoa","HoaGian")'))
        self.assertIn("VanHoa_HoaGian_80", sim.lua.eval('GetActiveMacroScript()'))
        self.assertIsNone(sim.lua.globals().DEFAULT_VANHOA_MACRO)
        self.assertIsNone(sim.lua.globals().profiles)
        self.assertEqual(list(sim.lua.globals()._tKeyBindings), ["XMACRO_KEY_SPAM_TOGGLE"])

    def test_build_runtime_writes_exact_generated_bytes(self):
        with TemporaryDirectory() as folder:
            root = Path(folder)
            for name in RUNTIME_MODULES:
                target = root / name
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes((ADDON / name).read_bytes())
            output = build_runtime(root)
            self.assertEqual(output, root / "Runtime.lua")
            self.assertEqual(output.read_bytes(), render_runtime(root).encode("utf-8-sig"))

    def test_clean_config_override_does_not_leak_original_config(self):
        sources = {name: (ADDON / name).read_bytes() for name in RUNTIME_MODULES}
        sources["Config.lua"] = b'xMacro=xMacro or {}; xMacro.Config={school="VanHoa",profile="HoaGian"}\n'
        clean = render_sources(sources)
        self.assertNotIn("native force IDs", clean)
        self.assertEqual(clean, render_runtime(ADDON, {"Config.lua": sources["Config.lua"]}))
        sim = self.fresh()
        sim.lua.execute(clean)
        self.assertIsNotNone(sim.lua.eval('xMacro.Schools.Resolve("VanHoa","HoaGian")'))

    def test_school_before_registry_and_core_defers_safely(self):
        sim = self.fresh()
        self.load(sim, "Schools/VanHoa/HoaGian.lua", "Config.lua", "Schools/Registry.lua", "Macro.lua")
        for _ in range(200):
            self.assertFalse(sim.lua.eval('macro()'))
        self.assertEqual(len(self.failure_logs(sim)), 1)
        self.assertIn("dependencies not ready", self.failure_logs(sim)[0])
        self.assertEqual(len(sim.lua.globals()._tCastedSkills), 0)
        self.load(sim, "Core/functions.lua", "Core/Macro.lua")
        sim.lua.eval('macro()')
        self.assertIsNotNone(sim.lua.eval('xMacro.Schools.Resolve("VanHoa","HoaGian")'))
        self.assertIn("VanHoa_HoaGian_80", sim.lua.eval('GetActiveMacroScript()'))
        self.assertEqual(len(self.failure_logs(sim)), 1)

    def test_dispatcher_before_registry_recovers_after_modules_arrive(self):
        sim = self.fresh()
        self.load(sim, "Config.lua", "Macro.lua")
        self.assertFalse(sim.lua.eval('macro()'))
        self.assertEqual(len(self.failure_logs(sim)), 1)
        self.assertIn("Registry.lua not ready", self.failure_logs(sim)[0])
        self.load(sim, "Core/functions.lua", "Core/Macro.lua", "Schools/VanHoa/HoaGian.lua", "Schools/Registry.lua")
        sim.lua.eval('macro()')
        self.assertIn("VanHoa_HoaGian_80", sim.lua.eval('GetActiveMacroScript()'))

    def test_registry_reload_preserves_instance_and_cast_event_handler(self):
        sim = JX3Simulator()
        sim.lua.execute('_previousProfile=xMacro.Schools.Resolve("VanHoa","HoaGian"); _previousCastHandlers=#_tEvents.DO_SKILL_CAST')
        self.load(sim, "Schools/Registry.lua")
        self.assertTrue(sim.lua.eval('_previousProfile==xMacro.Schools.Resolve("VanHoa","HoaGian")'))
        self.assertTrue(sim.lua.eval('_previousCastHandlers==#_tEvents.DO_SKILL_CAST'))

    def test_factory_error_is_informative_bounded_and_not_retried(self):
        sim = JX3Simulator()
        sim.lua.execute('''
            xMacro.Config={school="Broken",profile="Example"}
            _factoryRuns=0
            xMacro.SchoolFactories.Broken={Example=function()
                _factoryRuns=_factoryRuns+1; error("dependency-test-error")
            end}
        ''')
        for _ in range(200):
            self.assertFalse(sim.lua.eval('macro()'))
        self.assertEqual(sim.lua.globals()._factoryRuns, 1)
        self.assertEqual(len(self.failure_logs(sim)), 1)
        self.assertIn("dependency-test-error", self.failure_logs(sim)[0])

    def test_missing_profile_is_logged_once_per_failure_state(self):
        sim = JX3Simulator()
        sim.lua.execute('xMacro.Config={school="Missing",profile="Unavailable"}')
        for _ in range(200):
            self.assertFalse(sim.lua.eval('macro()'))
        self.assertEqual(len(self.failure_logs(sim)), 1)
        self.assertIn("school module/factory not loaded", self.failure_logs(sim)[0])
        sim.lua.execute('xMacro.Schools.Register("Missing","Unavailable",{run=function() return true end})')
        self.assertTrue(sim.lua.eval('macro()'))
        sim.lua.execute('xMacro.Config.profile="AnotherMissing"')
        self.assertFalse(sim.lua.eval('macro()'))
        self.assertEqual(len(self.failure_logs(sim)), 2)

    def test_full_bundle_reload_rebinds_profile_to_fresh_core(self):
        sim = JX3Simulator()
        sim.lua.execute('_oldProfile=xMacro.Schools.Resolve("VanHoa","HoaGian")')
        self.load(sim, "Runtime.lua")
        self.assertTrue(sim.lua.eval('_oldProfile~=xMacro.Schools.Resolve("VanHoa","HoaGian")'))
        self.assertEqual(list(sim.lua.globals()._tKeyBindings), ["XMACRO_KEY_SPAM_TOGGLE"])

    def test_core_initialization_failure_does_not_skip_key_spam_module(self):
        sources = {name: (ADDON / name).read_bytes() for name in RUNTIME_MODULES}
        sources["Core/Macro.lua"] = 'error("core-init-probe")'
        sim = self.fresh()
        sim.lua.execute(render_sources(sources))
        self.assertFalse(sim.lua.eval('xMacro.Runtime.ready'))
        self.assertTrue(sim.lua.eval('xMacro.Runtime.modules["Features/KeySpam.lua"]'))
        self.assertEqual(sim.lua.eval('type(xMacro.HoldKey.Tick)'), "function")
        self.assertIn("XMACRO_KEY_SPAM_TOGGLE", list(sim.lua.globals()._tKeyBindings))
        logs = list(sim.lua.globals()._szSysLog.values())
        self.assertTrue(any("LOAD_ERROR Core/Macro.lua" in line and "core-init-probe" in line for line in logs))
        self.assertFalse(sim.lua.eval('macro("VH")'))
        self.assertEqual(len(sim.lua.globals()._tCastedSkills), 0)

    def test_failed_reload_cannot_run_cached_old_core(self):
        sim = JX3Simulator()
        sources = {name: (ADDON / name).read_bytes() for name in RUNTIME_MODULES}
        sources["Core/Macro.lua"] = 'error("reload-init-probe")'
        sim.lua.execute(render_sources(sources))
        self.assertFalse(sim.lua.eval('macro("VH")'))
        self.assertEqual(len(sim.lua.globals()._tCastedSkills), 0)

    def test_failed_core_and_dispatch_upgrade_invalidates_unguarded_legacy_macro(self):
        sim = JX3Simulator()
        sim.lua.execute('macro=function() OnAddOnUseSkill(132,1); return true end')
        sources = {name: (ADDON / name).read_bytes() for name in RUNTIME_MODULES}
        sources["Core/Macro.lua"] = 'error("upgrade-core-probe")'
        sources["Macro.lua"] = 'error("upgrade-dispatch-probe")'
        sim.lua.execute(render_sources(sources))
        self.assertFalse(sim.lua.eval('xMacro.Runtime.ready'))
        self.assertFalse(sim.lua.eval('macro("VH")'))
        self.assertEqual(len(sim.lua.globals()._tCastedSkills), 0)
        self.assertTrue(sim.lua.eval('xMacro.Runtime.modules["Features/KeySpam.lua"]'))

    def test_entry_exception_is_visible_and_not_repeated(self):
        sim = JX3Simulator()
        sim.lua.execute('GetClientPlayer=function() error("player-api-probe") end')
        before = len(list(sim.lua.globals()._szSysLog.values()))
        for _ in range(200):
            self.assertFalse(sim.lua.eval('macro("VH")'))
        logs = list(sim.lua.globals()._szSysLog.values())[before:]
        self.assertEqual(len(logs), 1)
        self.assertIn("Macro runtime error:", logs[0])
        self.assertIn("player-api-probe", logs[0])
        self.assertTrue(logs[0].endswith("\n"))

    def test_rotation_exception_after_resolution_is_not_spammed(self):
        sim = JX3Simulator()
        sim.lua.execute('xMacro.Schools.Register("ThienSach","DPS",{run=function() error("rotation-probe") end})')
        before = len(list(sim.lua.globals()._szSysLog.values()))
        for _ in range(200):
            self.assertFalse(sim.lua.eval('macro("TS")'))
        logs = list(sim.lua.globals()._szSysLog.values())[before:]
        self.assertEqual(len(logs), 1)
        self.assertIn("rotation-probe", logs[0])

    def test_ui_exception_is_visible_without_private_core_logger(self):
        sim = self.fresh()
        sim.lua.execute('Wnd={OpenWindow=function() error("ui-open-probe") end}; XMCore_Sys=nil')
        sim.lua.execute(render_runtime(ADDON))
        self.assertIsNotNone(sim.lua.eval('xMacro.HoldKey.uiError'))
        logs = list(sim.lua.globals()._szSysLog.values())
        self.assertTrue(any("UI_ERROR:" in line and "ui-open-probe" in line for line in logs))


if __name__ == "__main__":
    unittest.main()
