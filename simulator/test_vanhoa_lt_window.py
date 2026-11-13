"""LT detonation uses two main DOTs, with no Lan Thoi and a five-second floor."""
import unittest
from simulator.engine import JX3Simulator

class LTWindowTests(unittest.TestCase):
    def setUp(self):
        self.s=JX3Simulator()
        self.s.set_skill_cd(136,120);self.s.set_skill_cd(2645,120)
        self.s.add_player_buff(2719,duration_sec=1.5)
        self.s.add_target_buff(1902,stack=5,duration_sec=120)
        for buff in (666,714): self.s.add_target_buff(buff,duration_sec=10)
    def tick(self): return [c['id'] for c in self.s.execute_tick()['casted']]

    def test_lt_end_detonates_without_lan_thoi(self):
        self.assertEqual(self.tick(),[182])

    def test_less_than_five_seconds_on_either_dot_skips_nt(self):
        for buff in (666,714):
            with self.subTest(buff=buff):
                self.setUp();self.s.add_target_buff(buff,duration_sec=4.9375)
                self.assertEqual(self.tick(),[179])

    def test_exactly_five_seconds_is_eligible(self):
        for buff in (666,714): self.s.add_target_buff(buff,duration_sec=5)
        self.assertEqual(self.tick(),[182])

    def test_mid_lt_never_detonates_because_dot_is_short(self):
        self.s.add_player_buff(2719,duration_sec=10)
        self.s.add_target_buff(714,duration_sec=4)
        self.assertEqual(self.tick(),[179])

    def test_even_with_lan_thoi_short_dot_blocks_lt_detonation(self):
        self.s.add_target_buff(711,duration_sec=20)
        self.s.add_target_buff(714,duration_sec=4)
        self.assertEqual(self.tick(),[179])

    def test_lt_nt_confirmation_does_not_fabricate_first_opener(self):
        self.assertEqual(self.tick(),[182]);self.s.set_skill_cd(182,17)
        for buff in (666,714): self.s.remove_target_buff(buff)
        self.s.advance_time(4);self.assertEqual(self.tick(),[180])
        diag=self.s.lua.globals().xMacro['VanHoaDiagnostics']
        self.assertTrue(diag['after_nt'])
        self.assertEqual(diag['first_nt_frame'],0)

    def test_outside_lt_opener_still_requires_lan_thoi(self):
        self.s.remove_player_buff(2719)
        self.assertEqual(self.tick(),[190])

    def test_nt_cooldown_does_not_request_lan_thoi(self):
        self.s.set_skill_cd(182,10)
        self.assertEqual(self.tick(),[179])

if __name__=='__main__': unittest.main()
