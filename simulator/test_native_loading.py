"""Exercise native lua_n entries, including silently skipped files."""
from pathlib import Path
import unittest
from simulator.engine import JX3Simulator
from tools.build_xmacro_native import render_native, NATIVE_NAMES
from tools.build_xmacro_runtime import RUNTIME_MODULES

ADDON = Path(__file__).resolve().parents[1] / 'interface/xMacro'


class NativeLoadingTests(unittest.TestCase):
    def chunks(self):
        return render_native({name: (ADDON/name).read_bytes() for name in RUNTIME_MODULES})

    def test_generated_files_match_sources_and_unique_basenames(self):
        chunks = self.chunks()
        self.assertEqual(len(set(Path(n).name.lower() for n in chunks)), len(chunks))
        for name,text in chunks.items():
            self.assertEqual((ADDON/name).read_bytes(), text.encode("utf-8-sig"))

    def test_native_load_reaches_ready_and_exposes_vh_without_casting(self):
        sim = JX3Simulator()
        self.assertTrue(sim.lua.eval('xMacro.Runtime.ready'))
        self.assertIsNotNone(sim.lua.eval('xMacro.Schools.Resolve("VanHoa","HoaGian")'))
        self.assertEqual(sim.loaded_lua_files, ['interface/xMacro/'+n for n in NATIVE_NAMES])
        self.assertEqual(len(sim.lua.globals()._tCastedSkills), 0)

    def test_every_skipped_canonical_file_keeps_combo_disabled(self):
        chunks = self.chunks()
        for skipped in NATIVE_NAMES[1:]:
            with self.subTest(skipped=skipped):
                sim = JX3Simulator(load_addon=False)
                for name,text in chunks.items():
                    if name!=skipped:
                        try: sim.lua.execute(text)
                        except Exception as error:
                            self.assertIn('native load order invalid', str(error))
                self.assertFalse(sim.lua.eval('xMacro.Runtime.ready'))
                self.assertFalse(sim.lua.eval('macro("VH")'))
                self.assertEqual(len(sim.lua.globals()._tCastedSkills), 0)

    def test_warm_reload_without_bootstrap_rejects_old_ready_context(self):
        sim = JX3Simulator()
        self.assertTrue(sim.lua.eval('xMacro.Runtime.ready'))
        for name,text in list(self.chunks().items())[1:]:
            if name.endswith('XM04_Core.lua'): continue
            with self.assertRaisesRegex(Exception,'native load order invalid'): sim.lua.execute(text)
        self.assertFalse(sim.lua.eval('xMacro.Runtime.ready'))
        self.assertFalse(sim.lua.eval('macro("VH")'))
        self.assertEqual(len(sim.lua.globals()._tCastedSkills), 0)

    def test_missing_bootstrap_rejects_each_later_file_even_with_old_macro(self):
        for name,text in list(self.chunks().items())[1:]:
            with self.subTest(name=name):
                sim=JX3Simulator(load_addon=False)
                sim.lua.execute('macro=function() error("OLD_MACRO_CALLED") end')
                with self.assertRaisesRegex(Exception,'bootstrap missing'): sim.lua.execute(text)
                self.assertFalse(sim.lua.eval('macro()'))
                self.assertEqual(len(sim.lua.globals()._tCastedSkills), 0)


if __name__=='__main__': unittest.main()
