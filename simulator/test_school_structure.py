"""Native manifest and school dispatch integration contracts."""
import unittest
from pathlib import Path
from simulator.engine import JX3Simulator


class SchoolStructureTests(unittest.TestCase):
    def setUp(self):
        self.sim = JX3Simulator()
        self.lua = self.sim.lua

    def test_manifest_loads_modules_in_native_order(self):
        from tools.build_xmacro_native import NATIVE_NAMES
        self.assertEqual(self.sim.loaded_lua_files, ["interface/xMacro/" + name for name in NATIVE_NAMES])
        self.assertEqual(list(self.lua.globals()._tKeyBindings), ["XMACRO_KEY_SPAM_TOGGLE"])

    def test_unknown_school_fails_closed_and_logs_selection(self):
        self.lua.execute('xMacro.Config.school="MissingSchool"')
        self.assertFalse(self.lua.eval('macro()'))
        self.assertEqual(len(self.lua.globals()._tCastedSkills), 0)
        self.assertIn("MissingSchool/HoaGian", self.lua.eval('_szSysLog[#_szSysLog]'))

    def test_reference_only_school_is_not_executable(self):
        self.lua.execute('xMacro.Config.school="ThatTu"; xMacro.Config.profile="BangTam"')
        self.assertFalse(self.lua.eval('macro()'))
        self.assertEqual(len(self.lua.globals()._tCastedSkills), 0)

    def test_unknown_profile_does_not_use_school_default(self):
        self.lua.execute('xMacro.Config.profile="Unavailable"')
        self.assertFalse(self.lua.eval('macro()'))
        self.assertEqual(len(self.lua.globals()._tCastedSkills), 0)

    def test_new_school_dispatches_its_own_rotation_without_vanhoa(self):
        self.lua.execute('''
            _otherRuns=0
            xMacro.Schools.Register("Other", "Verified", {run=function(name)
                _otherRuns=_otherRuns+1; _otherName=name; return "own-result"
            end})
            xMacro.Config.school="Other"; xMacro.Config.profile="Verified"
        ''')
        self.assertEqual(self.lua.eval('macro("auto")'), "own-result")
        self.assertEqual(self.lua.globals()._otherRuns, 1)
        self.assertEqual(self.lua.globals()._otherName, "auto")
        self.assertEqual(len(self.lua.globals()._tCastedSkills), 0)
        self.lua.execute('xMacro.Config.profile="HoaGian"')
        self.assertFalse(self.lua.eval('macro()'))
        self.assertEqual(self.lua.globals()._otherRuns, 1)

    def test_public_script_apis_and_lastcast_remain_available(self):
        original = self.lua.eval('GetActiveMacroScript()')
        self.assertIn("VanHoa_HoaGian_80", original)
        self.lua.execute('AppendCommand("contracttest", function(arg) _contractArg=arg; return true end); SetActiveMacroScript("/contracttest payload")')
        self.assertEqual(self.lua.eval('GetActiveMacroScript()'), "/contracttest payload")
        self.assertEqual(self.lua.eval('type(ExecuteMacroCommand)'), "function")
        self.assertEqual(self.lua.eval('type(lastcast)'), "function")
        self.assertTrue(self.lua.eval('ExecuteMacroCommand("auto")'))
        self.assertEqual(self.lua.globals()._contractArg, "payload")
        self.lua.execute('xMacro.Config.school="Other"; xMacro.Config.profile="Verified"; xMacro.Schools.Register("Other", "Verified", {run=function() return false end})')
        self.assertTrue(self.lua.eval('macro("/contracttest explicit")'))
        self.assertEqual(self.lua.globals()._contractArg, "explicit")

    def test_breathe_and_scene_callbacks_survive_panel_wrapping(self):
        self.lua.execute('''
            xMacro.OnFrameBreathe()
            for _, fn in ipairs(_tEvents["ON_BREATHE"]) do fn() end
            for _, fn in ipairs(_tEvents["PLAYER_ENTER_SCENE"]) do fn() end
        ''')
        self.assertEqual(self.lua.eval('type(xMacro.HoldKey.Tick)'), "function")
        self.assertEqual(len(list(self.lua.globals()._tKeyBindings)), 1)

    def test_legacy_entry_cannot_replace_runtime(self):
        self.lua.execute('_savedMacro=macro; _savedBreathe=xMacro.OnFrameBreathe')
        addon=Path(self.sim.workspace_root)/"interface"/"xMacro"
        for name in ("xMacro.lua", "HoldKey.lua", "functions.lua"):
            self.lua.execute((addon/name).read_text(encoding="utf-8-sig"))
        self.assertTrue(self.lua.eval('macro==_savedMacro and xMacro.OnFrameBreathe==_savedBreathe'))

    def test_rotation_internals_do_not_leak_into_globals(self):
        for name in ("tVanHoaCycle", "nCLRequest", "Run", "DEFAULT_VANHOA_MACRO", "tLastCast", "tSkillCastFrame"):
            self.assertIsNone(self.lua.globals()[name])

    def test_duplicate_registration_is_rejected(self):
        ok=self.lua.eval('''pcall(xMacro.Schools.Register, "VanHoa", "HoaGian", {run=function() end})''')
        self.assertFalse(ok[0])


if __name__ == "__main__":
    unittest.main()
