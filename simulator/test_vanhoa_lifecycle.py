"""Regressions for observed Chung Linh lifecycle and restricted DMC stops."""
import unittest
from simulator.engine import JX3Simulator

class LifecycleTests(unittest.TestCase):
    def setUp(self):
        self.s=JX3Simulator()
        self.s.set_skill_cd(136,120)
        self.s.set_skill_cd(2645,120)
        self.s.set_skill_cd(182,30)
        for buff in (666,1902): self.s.add_target_buff(buff, stack=5 if buff==1902 else 1, duration_sec=120)
        self.s.lua.execute('''_stops=0; local stop=_mockPlayer.StopCurrentAction
            _mockPlayer.StopCurrentAction=function() _stops=_stops+1; return stop() end''')
    def tick(self): return [c['id'] for c in self.s.execute_tick()['casted']]
    def allow_stop_at_phe_threshold(self):
        self.s.add_target_buff(1902,stack=5,duration_sec=2)
        self.s.set_skill_cd(180,120)
    def logs(self): return '\n'.join(str(v) for _,v in self.s.lua.globals()._szSysLog.items())
    def event(self,name,skill=189,player=1):
        self.s.lua.execute(f'arg0=_mockPlayer.dwID;arg1={skill}; for _,f in ipairs(_tEvents["{name}"] or {{}}) do f() end')
    def test_dot_within_half_second_after_finish_does_not_repeat_cl(self):
        self.assertEqual(self.tick(),[189])
        self.s.set_player_prepare(True,189);self.s.advance_time(1);self.tick()
        self.s.advance_time(40);self.s.set_player_prepare(False);self.tick()
        self.s.advance_time(7)
        self.assertEqual(self.tick(),[])
        self.s.add_target_buff(714);self.s.advance_time(1);self.tick()
        self.assertIn('DOT_OK',self.logs())
    def test_cast_event_instant_waits_for_delayed_dot(self):
        self.assertEqual(self.tick(),[189]);self.event('DO_SKILL_CAST')
        self.s.advance_time(7)
        self.assertEqual(self.tick(),[])
        self.assertIn('CAST_EVENT',self.logs())
        self.s.add_target_buff(714);self.s.advance_time(1);self.tick()
        self.assertIn('DOT_OK',self.logs())
    def test_transient_missing_confirmed_dot_does_not_recast(self):
        self.tick();self.s.add_target_buff(714);self.s.advance_time(40);self.tick()
        self.s.remove_target_buff(714);self.s.advance_time(1)
        self.assertNotIn(189,self.tick())
        self.s.add_target_buff(714);self.s.advance_time(4)
        self.assertNotIn(189,self.tick())
    def test_api_rejection_and_timeout_are_visible(self):
        self.s.lua.execute('OnAddOnUseSkill=function() return false end')
        self.tick()
        self.assertIn('API_REJECTED',self.logs())
        self.s.advance_time(16);self.tick()
        self.assertIn('RETRY',self.logs())
    def test_named_buff_and_string_id_are_recognized(self):
        self.s.add_target_buff(714)
        self.s.lua.execute('for _,b in ipairs(_mockTarget.tBuffs) do b.dwID=tostring(b.dwID) end')
        self.assertNotIn(189,self.tick())
    def test_pending_cl_does_not_starve_filler_after_dot(self):
        self.tick();self.s.add_target_buff(714);self.s.advance_time(4)
        self.assertEqual(self.tick(),[179])

    def test_confirmed_cl_cuts_redundant_active_cast_for_next_combo(self):
        self.assertEqual(self.tick(),[189])
        self.allow_stop_at_phe_threshold()
        self.s.set_player_prepare(True,189)
        self.s.advance_time(4);self.s.add_target_buff(714)
        self.assertEqual(self.tick(),[179])
        self.assertEqual(self.s.lua.eval('_stops'),1)
        self.assertIn('DOT_ALREADY_APPLIED',self.logs())
        self.s.advance_time(4)
        self.assertNotIn(189,self.tick())

    def test_existing_own_dot_can_cancel_untracked_duplicate_cl(self):
        self.allow_stop_at_phe_threshold()
        self.s.add_target_buff(714);self.s.set_player_prepare(True,189)
        self.assertEqual(self.tick(),[179])
        self.assertEqual(self.s.lua.eval('_stops'),1)

    def test_missing_or_foreign_dot_never_cuts_cl(self):
        for foreign in (False,True):
            with self.subTest(foreign=foreign):
                self.setUp();self.s.set_player_prepare(True,189)
                if foreign:
                    self.s.add_target_buff(714)
                    self.s.lua.execute('for _,b in ipairs(_mockTarget.tBuffs) do if b.dwID==714 then b.dwSkillSrcID=202 end end')
                self.assertEqual(self.tick(),[])
                self.assertEqual(self.s.lua.eval('_stops'),0)

    def test_confirmed_dot_stop_waits_for_ack_without_repeating(self):
        self.allow_stop_at_phe_threshold()
        self.s.add_target_buff(714);self.s.set_player_prepare(True,189)
        self.s.lua.execute('_mockPlayer.StopCurrentAction=function() _stops=_stops+1 end')
        for _ in range(5):
            self.assertEqual(self.tick(),[]);self.s.advance_time(1)
        self.assertEqual(self.s.lua.eval('_stops'),1)
        self.s.set_player_prepare(False)
        self.assertEqual(self.tick(),[179])

    def test_confirmed_dot_cuts_immediately_even_when_next_skill_is_on_gcd(self):
        self.allow_stop_at_phe_threshold()
        self.s.add_target_buff(714);self.s.set_player_prepare(True,189)
        self.s.set_skill_cd(53,20)
        self.assertEqual(self.tick(),[])
        self.assertEqual(self.s.lua.eval('_stops'),1)

    def test_fresh_dot_after_empty_snapshot_cuts_on_first_observed_frame(self):
        self.s.add_target_buff(714);self.s.add_target_buff(711)
        self.s.set_skill_cd(182,0);self.s.set_skill_cd(2645,0)
        self.assertEqual(self.tick(),[182]);self.s.set_skill_cd(182,17)
        self.s.advance_time(4);self.assertEqual(self.tick(),[180])
        self.s.remove_target_buff(666);self.s.add_target_buff(666,duration_sec=120)
        self.s.remove_target_buff(714)
        self.s.advance_time(4);self.assertEqual(self.tick(),[189])
        self.allow_stop_at_phe_threshold()
        self.s.set_player_prepare(True,189);self.s.remove_target_buff(714)
        self.s.advance_time(1);self.assertEqual(self.tick(),[])
        self.s.add_target_buff(714,duration_sec=120);self.s.advance_time(1)
        self.assertEqual(self.tick(),[2645])
        self.assertEqual(self.s.lua.eval('_stops'),1)

    def test_applied_td_and_lan_thoi_can_cut_redundant_cast(self):
        for skill in (180,190):
            with self.subTest(skill=skill):
                self.setUp();self.allow_stop_at_phe_threshold();self.s.add_target_buff(714)
                self.s.add_target_buff(711);self.s.set_player_prepare(True,skill)
                self.assertEqual(self.tick(),[179])
                self.assertEqual(self.s.lua.eval('_stops'),1)

    def test_rejected_applied_dot_stop_does_not_send_or_repeat(self):
        self.allow_stop_at_phe_threshold()
        self.s.add_target_buff(714);self.s.set_player_prepare(True,189)
        self.s.lua.execute('_mockPlayer.StopCurrentAction=function() _stops=_stops+1; return false end')
        self.assertEqual(self.tick(),[])
        self.s.advance_time(4);self.assertEqual(self.tick(),[])
        self.assertEqual(self.s.lua.eval('_stops'),1)
        self.assertIn('STOP_REJECTED',self.logs())
    def test_normal_missing_cl_never_cuts_dmc(self):
        self.s.set_player_prepare(True,179)
        self.assertEqual(self.tick(),[])
        self.assertEqual(self.s.lua.eval('_stops'),0)
    def test_hardcast_lan_thoi_and_thuy_nguyet_never_cut_dmc(self):
        self.s.add_target_buff(714);self.s.set_skill_cd(182,0)
        self.s.set_player_prepare(True,179)
        self.assertEqual(self.tick(),[])
        self.s.set_skill_cd(136,0);self.s.advance_time(4)
        self.assertEqual(self.tick(),[])
        self.assertEqual(self.s.lua.eval('_stops'),0)
    def test_instant_lan_thoi_has_explicit_stop_reason(self):
        self.allow_stop_at_phe_threshold()
        self.s.add_target_buff(714);self.s.add_player_buff(412)
        self.s.set_player_prepare(True,179)
        self.assertEqual(self.tick(),[190])
        self.assertIn('INSTANT_LAN_THOI',self.logs())
    def test_async_stop_waits_and_is_not_repeated(self):
        self.s.remove_target_buff(1902)
        self.s.set_player_prepare(True,179)
        self.s.lua.execute('_mockPlayer.StopCurrentAction=function() _stops=_stops+1 end')
        for _ in range(6):
            self.assertEqual(self.tick(),[]);self.s.advance_time(1)
        self.assertEqual(self.s.lua.eval('_stops'),1)
        self.s.set_player_prepare(False);self.s.advance_time(1)
        self.assertEqual(self.tick(),[180])
    def test_lifecycle_logs_have_request_target_and_frame(self):
        self.tick();self.s.set_player_prepare(True,189);self.s.advance_time(1);self.tick()
        self.s.set_player_prepare(False);self.s.advance_time(40);self.tick()
        self.s.add_target_buff(714);self.s.advance_time(1);self.tick()
        for phase in ('REQUEST','API_ACCEPTED','PREPARE_START','PREPARE_END','DOT_OK'):
            self.assertIn(phase,self.logs())
        self.assertIn('target=',self.logs());self.assertIn('req=',self.logs())

    def test_unreadable_buff_api_cannot_trigger_retry(self):
        self.tick()
        self.s.lua.execute('_mockTarget.GetBuffList=function() error("unavailable") end; _mockTarget.GetBuffCount=nil')
        self.s.advance_time(200)
        self.assertEqual(self.tick(),[])
        self.assertIn('BUFF_READ_UNKNOWN',self.logs())
        self.assertNotIn('RETRY',self.logs())
    def test_fallback_tuple_buff_api_and_legacy_fields(self):
        self.s.add_target_buff(714)
        self.s.lua.execute("""
            _mockTarget.GetBuffList=nil
            _mockTarget.GetBuff=function(i)
                local b=_mockTarget.tBuffs[i+1]
                return tostring(b.dwID),1,false,b.nEndFrame,i,1,b.dwSkillSrcID,true
            end
        """)
        self.assertNotIn(189,self.tick())
    def test_confirmed_dot_stably_absent_can_reapply(self):
        self.tick();self.s.add_target_buff(714);self.s.advance_time(40);self.tick()
        self.s.remove_target_buff(714);self.s.advance_time(1)
        self.assertNotIn(189,self.tick())
        self.s.advance_time(16)
        self.assertEqual(self.tick(),[189])
    def test_another_players_dot_does_not_confirm_our_request(self):
        self.tick();self.s.add_target_buff(714)
        self.s.lua.execute('for _,b in ipairs(_mockTarget.tBuffs) do if b.dwID==714 then b.dwSkillSrcID=202 end end')
        self.s.advance_time(4);self.tick()
        self.assertNotIn('DOT_OK',self.logs())
    def test_rejected_stop_never_sends_replacement_or_retries_stop(self):
        self.s.remove_target_buff(1902);self.s.set_player_prepare(True,179)
        self.s.lua.execute('_mockPlayer.StopCurrentAction=function() _stops=_stops+1;return false end')
        self.assertEqual(self.tick(),[])
        self.s.advance_time(10);self.assertEqual(self.tick(),[])
        self.assertEqual(self.s.lua.eval('_stops'),1)
        self.assertIn('STOP_REJECTED',self.logs())

    def test_non_buff_list_falls_back_instead_of_assuming_empty(self):
        self.s.add_target_buff(714)
        self.s.lua.execute('_mockTarget.GetBuffList=function() return {666,714} end')
        self.assertNotIn(189,self.tick())
    def test_moving_without_instant_buff_does_not_request_cl(self):
        self.s.lua.execute('_mockPlayer.nMoveState=1')
        self.assertNotIn(189,self.tick())
    def test_cl_retries_once_at_timeout_with_same_target_trace(self):
        self.tick();self.s.advance_time(16)
        self.assertEqual(self.tick(),[189])
        self.assertIn('req=2',self.logs())
        self.assertIn('previous_req=1',self.logs())
        self.assertIn('DOT_WAIT_TIMEOUT',self.logs())
        self.s.advance_time(1);self.assertEqual(self.tick(),[])

    def test_cl_without_start_retries_at_one_second_not_before(self):
        self.assertEqual(self.tick(),[189])
        self.s.advance_time(15);self.assertEqual(self.tick(),[])
        self.s.advance_time(1);self.assertEqual(self.tick(),[189])
    def test_cl_after_finish_retries_at_half_second(self):
        self.tick();self.s.set_player_prepare(True,189);self.s.advance_time(1);self.tick()
        self.s.advance_time(40);self.s.set_player_prepare(False);self.tick()
        self.s.advance_time(7);self.assertEqual(self.tick(),[])
        self.s.advance_time(1);self.assertEqual(self.tick(),[189])
    def test_cast_event_does_not_extend_post_finish_half_second_wait(self):
        self.tick();self.s.set_player_prepare(True,189);self.s.advance_time(1);self.tick()
        self.s.advance_time(40);self.event('DO_SKILL_CAST');self.s.set_player_prepare(False);self.tick()
        self.s.advance_time(7);self.assertEqual(self.tick(),[])
        self.s.advance_time(1);self.assertEqual(self.tick(),[179])
        self.event('DO_SKILL_CAST',skill=179);self.s.advance_time(4)
        self.assertEqual(self.tick(),[189])
    def test_instant_cast_event_waits_only_half_second(self):
        self.tick();self.event('DO_SKILL_CAST')
        self.s.advance_time(7);self.assertEqual(self.tick(),[])
        self.s.advance_time(1)
        self.assertEqual(self.tick(),[179])
        self.event('DO_SKILL_CAST',skill=179);self.s.advance_time(4)
        self.assertEqual(self.tick(),[189])
        self.assertIn('DOT_WAIT_TIMEOUT',self.logs())
    def test_post_nt_td_request_does_not_keep_old_five_second_guard(self):
        self.s.add_target_buff(714);self.s.add_target_buff(711)
        self.s.set_skill_cd(182,0);self.s.set_skill_cd(2645,0)
        self.assertEqual(self.tick(),[182]);self.s.set_skill_cd(182,17)
        for buff in (666,714,711): self.s.remove_target_buff(buff)
        self.s.advance_time(4);self.assertEqual(self.tick(),[180])
        self.s.advance_time(15);self.assertEqual(self.tick(),[])
        self.s.advance_time(1);self.assertEqual(self.tick(),[180])

    def test_td_after_finish_retries_at_half_second(self):
        self.s.remove_target_buff(666)
        self.assertEqual(self.tick(),[180])
        self.s.set_player_prepare(True,180);self.s.advance_time(1);self.tick()
        self.s.advance_time(40);self.s.set_player_prepare(False);self.tick()
        self.s.advance_time(7);self.assertEqual(self.tick(),[])
        self.s.advance_time(1);self.assertEqual(self.tick(),[180])

    def test_live_diagnostics_report_protected_dmc_and_selected_skill(self):
        self.s.add_target_buff(714)
        self.s.set_player_prepare(True,179)
        self.assertEqual(self.tick(),[])
        diag=self.s.lua.globals().xMacro['VanHoaDiagnostics']
        self.assertEqual(diag['decision'],'FINISH_CAST_PHE_GT_2')
        self.assertEqual(diag['selected'],179)
        self.assertEqual(diag['prepare_skill'],179)
        self.assertFalse(diag['after_nt'])

    def test_one_based_legacy_buff_slots_with_empty_zero_are_readable(self):
        self.s.add_target_buff(714)
        self.s.lua.execute('''
          _mockTarget.GetBuffList=nil
          _mockTarget.GetBuff=function(i) return _mockTarget.tBuffs[i] end
        ''')
        self.assertNotIn(189,self.tick())
        self.assertTrue(self.s.lua.globals().xMacro['VanHoaDiagnostics']['buffs_known'])
    def test_tuple_array_buff_list_is_normalized(self):
        self.s.add_target_buff(714)
        self.s.lua.execute('''
          _mockTarget.GetBuffList=function()
            local list={}
            for i,b in ipairs(_mockTarget.tBuffs) do list[i]={b.dwID,1,false,b.nEndFrame,i,1,b.dwSkillSrcID,true} end
            return list
          end
        ''')
        self.assertNotIn(189,self.tick())
        self.assertTrue(self.s.lua.globals().xMacro['VanHoaDiagnostics']['has_cl'])

    def test_zero_count_does_not_probe_invalid_buff_slot(self):
        self.s.lua.execute('''
          _mockTarget.GetBuffList=nil;_mockTarget.GetBuffCount=function() return 0 end
          _mockTarget.GetBuff=function() error("no slot") end
        ''')
        self.assertEqual(self.tick(),[180])
        self.assertTrue(self.s.lua.globals().xMacro['VanHoaDiagnostics']['buffs_known'])
    def test_zero_based_native_buff_api_can_reject_endpoint(self):
        self.s.add_target_buff(714)
        self.s.lua.execute('''
          _mockTarget.GetBuffList=nil
          _mockTarget.GetBuff=function(i)
            local b=_mockTarget.tBuffs[i+1]
            if not b then error("out of range") end
            return b
          end
        ''')
        self.assertNotIn(189,self.tick())
        self.assertTrue(self.s.lua.globals().xMacro['VanHoaDiagnostics']['buffs_known'])

    def test_nil_empty_list_on_classic_client_allows_dot_application(self):
        self.s.lua.execute('''
          _mockTarget.tBuffs={};_mockTarget.GetBuffCount=nil;_mockTarget.GetBuff=nil
          _mockTarget.GetBuffList=function() return nil end
        ''')
        self.assertEqual(self.tick(),[180])
        self.assertTrue(self.s.lua.globals().xMacro['VanHoaDiagnostics']['buffs_known'])
    def test_tuple_array_excludes_other_players_dot(self):
        self.s.lua.execute('''
          _mockTarget.GetBuffList=function()
            return {{666,1,false,_curFrame+1000,0,1,101,true},
                    {1902,1,false,_curFrame+1000,1,1,101,true},
                    {714,1,false,_curFrame+1000,2,1,202,true}}
          end
        ''')
        self.assertEqual(self.tick(),[189])
        self.assertFalse(self.s.lua.globals().xMacro['VanHoaDiagnostics']['has_cl'])

if __name__=='__main__': unittest.main()
