"""Public school-code dispatch through the actual generated native Runtime.lua."""
import unittest
from simulator.engine import JX3Simulator


class SchoolCodeTests(unittest.TestCase):
    def setUp(self):
        self.sim = JX3Simulator()
        self.lua = self.sim.lua
        # Actual client omits select; run every public dispatch test that way.
        self.lua.execute('select=nil; arg=nil')

    def logs(self):
        return [str(value) for _, value in self.lua.globals()._szSysLog.items()]

    def register(self, school, profile, result):
        self.lua.execute('''
            xMacro.Schools.Register("%s", "%s", {run=function(name)
                _codeArg=name; _codeRuns=(_codeRuns or 0)+1; return "%s"
            end})
        ''' % (school, profile, result))

    def test_vh_overrides_config_without_changing_legacy_default(self):
        self.register("Other", "Default", "configured")
        self.lua.execute('xMacro.Config={school="Other",profile="Default"}')
        self.assertEqual(self.lua.eval('macro()'), "configured")
        self.lua.eval('macro("VH")')
        self.assertGreater(len(self.lua.globals()._tCastedSkills), 0)
        self.assertEqual(self.lua.eval('macro()'), "configured")
        self.assertEqual(self.lua.globals()._codeRuns, 2)
        self.assertEqual(self.lua.eval('xMacro.Config.school'), "Other")

    def test_unimplemented_codes_never_execute_vanhoa_or_change_script(self):
        script = self.lua.eval('GetActiveMacroScript()')
        for code, destination in (("7T", "ThatTu/BangTam"), ("TS", "ThienSach/DPS"),
                                  ("TK", "TangKiem/DPS"), ("DMKV", "DuongMon/KinhVu"),
                                  ("DMTL", "DuongMon/ThienLa")):
            with self.subTest(code=code):
                self.assertFalse(self.lua.eval('macro')(code))
                self.assertIn(destination, self.logs()[-1])
        self.assertEqual(len(self.lua.globals()._tCastedSkills), 0)
        self.assertEqual(self.lua.eval('GetActiveMacroScript()'), script)

    def test_codes_route_to_future_registered_profiles(self):
        for code, school, profile in (("7T", "ThatTu", "BangTam"),
                                      ("TS", "ThienSach", "DPS"),
                                      ("TK", "TangKiem", "DPS"),
                                      ("DMKV", "DuongMon", "KinhVu"),
                                      ("DMTL", "DuongMon", "ThienLa")):
            self.register(school, profile, code)
            self.assertEqual(self.lua.eval('macro')(code), code)
            self.assertIsNone(self.lua.globals()._codeArg)
        self.assertEqual(len(self.lua.globals()._tCastedSkills), 0)

    def test_codes_accept_lowercase_and_surrounding_whitespace(self):
        self.register("DuongMon", "KinhVu", "kinh-vu")
        self.assertEqual(self.lua.eval('macro("  dmkv  ")'), "kinh-vu")

    def test_missing_code_diagnostic_is_bounded(self):
        before = len(self.logs())
        for _ in range(200):
            self.assertFalse(self.lua.eval('macro("DMTL")'))
        self.assertEqual(len(self.logs()) - before, 1)

    def test_unknown_code_does_not_fall_back_to_configured_rotation(self):
        before = len(self.logs())
        for _ in range(200):
            self.assertFalse(self.lua.eval('macro("UNKNOWN")'))
        self.assertEqual(len(self.logs()) - before, 1)
        self.assertIn("Unknown macro code", self.logs()[-1])
        self.assertEqual(len(self.lua.globals()._tCastedSkills), 0)

    def test_undefined_unquoted_identifier_is_rejected(self):
        self.assertIsNone(self.lua.globals().TS)
        self.assertFalse(self.lua.eval('macro(TS)'))
        self.assertIn('macro("TS")', self.logs()[-1])
        self.assertEqual(len(self.lua.globals()._tCastedSkills), 0)

    def test_invalid_argument_types_and_extra_arguments_are_rejected(self):
        for expression in ('macro(nil)', 'macro(false)', 'macro(7)', 'macro({})',
                           'macro("VH","TS")', 'macro("VH",nil)', 'macro(nil,nil)',
                           'macro(function() error("MUST_NOT_EXECUTE_ARGUMENT") end)'):
            self.assertFalse(self.lua.eval(expression))
            self.assertIn('Invalid macro code', self.logs()[-1])
        self.assertEqual(len(self.lua.globals()._tCastedSkills), 0)

    def test_default_auto_and_inline_dispatch_without_select_or_global_arg(self):
        self.register("Other", "Default", "configured")
        self.lua.execute('xMacro.Config={school="Other",profile="Default"}; arg={n=99}')
        for expression in ('macro()', 'macro("auto")', 'macro("")'):
            self.assertEqual(self.lua.eval(expression), "configured")
        self.assertTrue(self.lua.eval('macro("/skillraw 180")'))
        self.assertEqual(self.lua.eval('arg.n'), 99)
        self.assertIsNone(self.lua.globals().select)


if __name__ == "__main__":
    unittest.main()
