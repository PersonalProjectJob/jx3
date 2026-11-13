"""Phe Cot observations drive stack building; sends never imply a new stack."""
import unittest
from simulator.engine import JX3Simulator


class PheCotTests(unittest.TestCase):
    def setUp(self):
        self.s = JX3Simulator()
        for skill in (136,2645): self.s.set_skill_cd(skill,120)
        self.s.set_skill_cd(182,30)
        for buff in (666,714): self.s.add_target_buff(buff,duration_sec=120)

    def tick(self):
        return [c['id'] for c in self.s.execute_tick()['casted']]

    def test_low_stack_builds_with_healthy_td(self):
        self.s.add_target_buff(1902,stack=2,duration_sec=15)
        self.assertEqual(self.tick(),[180])

    def test_five_stacks_are_refreshed_before_four_seconds(self):
        self.s.add_target_buff(1902,stack=5,duration_sec=3.5)
        self.assertEqual(self.tick(),[180])

    def test_healthy_five_stacks_use_filler(self):
        self.s.add_target_buff(1902,stack=5,duration_sec=15)
        self.assertEqual(self.tick(),[179])

    def test_stack_building_does_not_delay_first_detonation(self):
        self.s.add_target_buff(711,duration_sec=120)
        self.s.add_target_buff(1902,stack=2,duration_sec=15)
        self.s.set_skill_cd(2645,0);self.s.set_skill_cd(182,0)
        self.assertEqual(self.tick(),[182])

    def test_pending_refresh_retries_after_one_second_not_three(self):
        self.s.add_target_buff(1902,stack=5,duration_sec=3.5)
        self.assertEqual(self.tick(),[180])
        self.s.advance_time(4);self.s.add_target_buff(666,duration_sec=120)
        self.assertEqual(self.tick(),[179])
        self.s.advance_time(12)
        self.assertEqual(self.tick(),[180])

    def test_observed_stack_increase_releases_wait(self):
        self.s.add_target_buff(1902,stack=2,duration_sec=15)
        self.assertEqual(self.tick(),[180])
        self.s.advance_time(4);self.s.add_target_buff(666,duration_sec=120)
        self.s.add_target_buff(1902,stack=3,duration_sec=15)
        self.assertEqual(self.tick(),[180])
        self.assertEqual(self.s.lua.globals().xMacro['VanHoaDiagnostics']['phe_stacks'],3)

    def test_stack_fields_are_read_from_classic_tuple_list(self):
        self.s.add_target_buff(1902,stack=4,duration_sec=15)
        self.s.lua.execute('''_mockTarget.GetBuffList=function()
          local list={};for i,b in ipairs(_mockTarget.tBuffs) do
            list[i]={b.dwID,1,false,b.nEndFrame,i,b.nStackNum,b.dwSkillSrcID,true}
          end;return list end''')
        self.assertEqual(self.tick(),[180])
        self.assertEqual(self.s.lua.globals().xMacro['VanHoaDiagnostics']['phe_stacks'],4)

    def test_low_stacks_do_not_force_td_during_lt_end_window(self):
        self.s.add_target_buff(1902,stack=2,duration_sec=15)
        self.s.add_player_buff(2719,duration_sec=1.5)
        self.assertEqual(self.tick(),[179])

    def test_urgent_phe_refresh_survives_lt_end_window(self):
        self.s.add_target_buff(1902,stack=5,duration_sec=2)
        self.s.add_player_buff(2719,duration_sec=1.5)
        self.assertEqual(self.tick(),[180])

    def test_unknown_stack_count_does_not_trigger_blind_building(self):
        self.s.add_target_buff(1902,stack=1,duration_sec=15)
        self.s.lua.execute('for _,b in ipairs(_mockTarget.tBuffs) do if b.dwID==1902 then b.nStackNum=nil end end')
        self.assertEqual(self.tick(),[179])
        self.assertEqual(self.s.lua.globals().xMacro['VanHoaDiagnostics']['phe_stacks'],-1)

    def test_low_stacks_do_not_delay_two_fresh_dots_and_lt(self):
        self.s.add_target_buff(711,duration_sec=120)
        self.s.add_target_buff(1902,stack=2,duration_sec=15)
        self.s.set_skill_cd(2645,0);self.s.set_skill_cd(182,0)
        self.assertEqual(self.tick(),[182]);self.s.set_skill_cd(182,17)
        for buff in (666,714,711): self.s.remove_target_buff(buff)
        self.s.advance_time(4);self.assertEqual(self.tick(),[180])
        self.s.add_target_buff(666,duration_sec=120);self.s.advance_time(4)
        self.assertEqual(self.tick(),[189])
        self.s.add_target_buff(714,duration_sec=120);self.s.advance_time(4)
        self.assertEqual(self.tick(),[2645])

    def test_stack_build_waits_for_dmc_while_phe_above_two_seconds(self):
        for cd,gcd in ((0,0),(5,0),(0,1)):
            with self.subTest(cd=cd,gcd=gcd):
                self.setUp();self.s.add_target_buff(1902,stack=2,duration_sec=15)
                self.s.set_skill_cd(180,cd);self.s.set_skill_cd(53,gcd)
                self.s.set_player_prepare(True,179)
                self.assertEqual(self.tick(),[])
                self.assertFalse(self.s.was_action_stopped())

    def test_missing_unseen_phe_is_reprobed_in_stable_rotation(self):
        self.assertEqual(self.tick(),[180])
        self.s.advance_time(4);self.s.add_target_buff(666,duration_sec=120)
        self.assertEqual(self.tick(),[179])
        self.s.advance_time(76)
        self.assertEqual(self.tick(),[180])

    def test_localized_phe_buff_with_different_id_is_recognized(self):
        self.s.add_target_buff(99002,stack=2,duration_sec=15)
        self.s.lua.execute('local original=Table_GetBuffName; Table_GetBuffName=function(id,level) if id==99002 then return "Phe Cot" end; return original(id,level) end')
        self.assertEqual(self.tick(),[180])
        diag=self.s.lua.globals().xMacro['VanHoaDiagnostics']
        self.assertEqual(diag['phe_stacks'],2)
        self.assertEqual(diag['phe_buff_id'],99002)

    def test_real_client_886_stacks_and_time_are_read_without_name_lookup(self):
        self.s.add_target_buff(886,stack=2,duration_sec=15)
        self.s.lua.execute('Table_GetBuffName=function() return "" end')
        self.assertEqual(self.tick(),[180])
        diag=self.s.lua.globals().xMacro['VanHoaDiagnostics']
        self.assertEqual(diag['phe_buff_id'],886)
        self.assertEqual(diag['phe_stacks'],2)
        self.assertEqual(diag['phe_time'],15)

    def test_real_client_five_stacks_do_not_build_unnecessarily(self):
        self.s.add_target_buff(886,stack=5,duration_sec=15)
        self.assertEqual(self.tick(),[179])
        self.assertTrue(self.s.lua.eval('ProcessCondition("tbuff:Phe Cot")'))


if __name__ == '__main__': unittest.main()
