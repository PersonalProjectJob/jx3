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
        self.assertEqual((ADDON / "Runtime.lua").read_bytes(), render_runtime(ADDON).encode("utf-8"))

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
            self.assertEqual(output.read_bytes(), render_runtime(root).encode("utf-8"))

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


if __name__ == "__main__":
    unittest.main()
