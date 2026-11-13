"""Stable rotation and confirmed lastcast, with explicit game events."""
import unittest
from simulator.engine import JX3Simulator


class StableTests(unittest.TestCase):
    def setUp(self):
        self.s=JX3Simulator()
        self.s.set_skill_cd(136,120);self.s.set_skill_cd(2645,120)
        for buff in (666,714): self.s.add_target_buff(buff,duration_sec=120)
        self.s.add_target_buff(1902,stack=5,duration_sec=120)

    def tick(self): return [c['id'] for c in self.s.execute_tick()['casted']]
    def event(self,skill,caster=101):
        self.s.lua.execute(f'arg0={caster};arg1={skill}; for _,f in ipairs(_tEvents["DO_SKILL_CAST"] or {{}}) do f() end')

    def test_lan_thoi_observed_then_nt_even_with_long_lan_thoi_cd(self):
        self.assertEqual(self.tick(),[190])
        self.event(190);self.s.set_skill_cd(190,30)
        self.s.advance_time(40);self.s.add_target_buff(711,duration_sec=18)
        self.assertEqual(self.tick(),[182])

    def test_full_three_dots_do_not_fall_back_to_dmc(self):
        self.s.add_target_buff(711,duration_sec=18);self.s.set_skill_cd(190,30)
        self.assertEqual(self.tick(),[182])

    def test_ready_nt_waits_for_our_dmc_to_finish(self):
        for cd in (0,5):
            with self.subTest(cd=cd):
                self.setUp();self.s.add_target_buff(711,duration_sec=18)
                self.event(190);self.s.set_skill_cd(190,30)
                self.s.set_skill_cd(182,cd);self.s.set_player_prepare(True,179)
                self.assertEqual(self.tick(),[])
                self.assertFalse(self.s.was_action_stopped())
                self.s.set_player_prepare(False)
                self.assertEqual(self.tick(),[182] if cd==0 else [179])

    def test_lastcast_matches_id_name_and_macro_conditions(self):
        self.event(189)
        self.assertTrue(self.s.lua.eval('lastcast(189)'))
        self.assertTrue(self.s.lua.eval('lastcast("Chung Linh Duc Tu")'))
        self.assertTrue(self.s.lua.eval('ProcessCondition("lastcast:Chung Linh Duc Tu")'))
        self.assertFalse(self.s.lua.eval('ProcessCondition("nolastcast:189")'))
        self.event(179)
        self.assertFalse(self.s.lua.eval('lastcast(189)'))

    def test_request_is_not_lastcast_and_foreign_event_is_ignored(self):
        self.s.remove_target_buff(714)
        self.assertEqual(self.tick(),[189])
        self.assertFalse(self.s.lua.eval('lastcast(189)'))
        self.event(189,caster=202)
        self.assertFalse(self.s.lua.eval('lastcast(189)'))

    def test_confirmed_cl_missing_dot_cannot_cast_cl_again_until_another_skill(self):
        self.s.remove_target_buff(714);self.s.set_skill_cd(182,30)
        self.assertEqual(self.tick(),[189]);self.event(189)
        self.s.advance_time(8)
        self.assertEqual(self.tick(),[179])
        self.s.advance_time(4);self.assertNotIn(189,self.tick())
        self.event(179);self.s.advance_time(4)
        self.assertEqual(self.tick(),[189])

    def test_existing_cl_dot_blocks_cl_even_after_dmc(self):
        self.event(179);self.s.set_skill_cd(182,30)
        self.assertEqual(self.tick(),[179])

    def test_tprepare_casts_quyet_am_without_stopping_our_dot(self):
        self.s.set_player_prepare(True,189)
        self.s.remove_target_buff(714)
        self.s.lua.execute('_mockTarget.bPreparing=true')
        self.assertTrue(self.s.lua.eval('ProcessCondition("tprepare")'))
        self.assertEqual(self.tick(),[183])
        self.assertFalse(self.s.was_action_stopped())

    def test_no_target_cast_or_quyet_am_cd_does_not_interrupt(self):
        self.s.set_skill_cd(182,30)
        self.assertEqual(self.tick(),[179])
        self.s.lua.execute('_mockTarget.bPreparing=true')
        self.s.set_skill_cd(183,10);self.s.advance_time(4)
        self.assertEqual(self.tick(),[179])

    def test_self_prepare_without_target_prepare_does_not_use_quyet_am(self):
        self.s.set_player_prepare(True,179);self.s.set_skill_cd(182,30)
        self.assertFalse(self.s.lua.eval('ProcessCondition("tprepare")'))
        self.assertEqual(self.tick(),[])
        self.assertFalse(self.s.was_action_stopped())

    def test_tprepare_quyet_am_works_on_gcd_during_dmc(self):
        self.s.lua.execute('_mockTarget.bPreparing=true')
        self.s.set_player_prepare(True,179);self.s.set_skill_cd(53,1)
        self.assertEqual(self.tick(),[183])
        self.assertFalse(self.s.was_action_stopped())

    def test_failed_or_zero_target_prepare_is_not_tprepare(self):
        for body in ('return 0','error("unavailable")'):
            with self.subTest(body=body):
                self.setUp();self.s.set_skill_cd(182,30)
                self.s.lua.execute('_mockTarget.GetSkillPrepareState=function() '+body+' end')
                self.assertFalse(self.s.lua.eval('ProcessCondition("tprepare")'))
                self.assertEqual(self.tick(),[179])


if __name__=='__main__': unittest.main()
