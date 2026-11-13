"""Finish non-channel cast while Phe Cot has more than two seconds left."""
import unittest
from simulator.engine import JX3Simulator

class FinishCastTests(unittest.TestCase):
    def setUp(self):
        self.s=JX3Simulator()
        self.s.set_skill_cd(136,120);self.s.set_skill_cd(2645,120)
        self.s.set_skill_cd(182,30)
        for buff in (666,714,711): self.s.add_target_buff(buff,duration_sec=120)
    def tick(self): return [c['id'] for c in self.s.execute_tick()['casted']]

    def test_upward_cast_with_more_than_two_seconds_is_not_cut(self):
        for skill in (179,189,190):
            for remaining in (2.0625,3,15):
                with self.subTest(skill=skill,remaining=remaining):
                    self.setUp();self.s.add_target_buff(886,stack=2,duration_sec=remaining)
                    self.s.set_player_prepare(True,skill)
                    self.assertEqual(self.tick(),[])
                    self.assertFalse(self.s.was_action_stopped())

    def test_exactly_two_seconds_keeps_existing_refresh_stop(self):
        self.s.add_target_buff(886,stack=5,duration_sec=2)
        self.s.set_player_prepare(True,179)
        self.assertEqual(self.tick(),[180])
        self.assertTrue(self.s.was_action_stopped())

    def test_cast_finish_releases_refresh_with_phe_still_above_two_seconds(self):
        self.s.add_target_buff(886,stack=2,duration_sec=15)
        self.s.set_player_prepare(True,179)
        self.assertEqual(self.tick(),[])
        self.s.set_player_prepare(False);self.s.advance_time(1)
        self.assertEqual(self.tick(),[180])

    def test_target_interrupt_does_not_cancel_protected_own_cast(self):
        self.s.add_target_buff(886,stack=2,duration_sec=15)
        self.s.set_player_prepare(True,189)
        self.s.lua.execute('_mockTarget.bPreparing=true')
        self.assertEqual(self.tick(),[183])
        self.assertFalse(self.s.was_action_stopped())

    def test_channel_is_not_classified_as_upward_cast(self):
        self.s.add_target_buff(886,stack=2,duration_sec=15)
        self.s.set_player_prepare(True,179,ot_state=2)
        self.assertEqual(self.tick(),[180])

if __name__=='__main__': unittest.main()
