"""Behavioral regressions against real Lua, using independently controlled snapshots.

Run: python -m unittest simulator.test_vanhoa_regressions -v
The simulator records sends; it does not implement the game server, cast completion,
damage, or latency. Buff changes here are explicit observations, never assumed
effects of a successful send. No production Lua internals are inspected.
"""

import unittest

from simulator.engine import JX3Simulator


class VanHoaRegressions(unittest.TestCase):
    def setUp(self):
        self.sim = JX3Simulator()
        self.sim.set_skill_cd(136, 120)  # Keep the opener out of isolated cases.
        self.sim.set_skill_cd(2645, 120)
        self.sim.lua.execute("""
            _stopCalls = 0
            local originalStop = _mockPlayer.StopCurrentAction
            _mockPlayer.StopCurrentAction = function(...)
                _stopCalls = _stopCalls + 1
                return originalStop(...)
            end
        """)

    def tick(self):
        result = self.sim.execute_tick()
        ids = [cast["id"] for cast in result["casted"]]
        self.assertLessEqual(len(ids), 1, "macro() sent multiple priority skills")
        return ids

    def stops(self):
        return int(self.sim.lua.eval("_stopCalls"))

    def healthy_dots(self, lan_thoi=True):
        for buff in (666, 714) + ((711,) if lan_thoi else ()):
            self.sim.add_target_buff(buff, duration_sec=120)
        self.sim.add_target_buff(1902, stack=5, duration_sec=120)

    def start_first_detonation(self):
        self.healthy_dots()
        self.sim.set_skill_cd(2645, 0)
        self.assertEqual(self.tick(), [182], "fixture must detonate first")
        self.sim.set_skill_cd(182, 17)

    def foreign_dot(self, buff):
        self.sim.add_target_buff(buff, duration_sec=120)
        self.sim.lua.execute(f"""
            for _, b in ipairs(_mockTarget.tBuffs) do
                if b.dwID == {buff} then b.dwSkillSrcID = 202 end
            end
        """)

    def test_first_detonation_waits_for_reapplication_and_observation(self):
        self.start_first_detonation()
        # Server still exposes the old DOT list after accepting Ngoc Thach.
        for _ in range(3):
            self.assertNotIn(2645, self.tick(), "stale pre-detonation DOTs armed LT")
            self.sim.advance_time(1)

        for buff in (666, 714, 711):
            self.sim.remove_target_buff(buff)
        self.sim.advance_time(64)
        self.assertEqual(self.tick(), [180])
        # Sending Thuong Duong alone is not proof that its DOT reached target.
        self.sim.advance_time(64)
        self.assertNotIn(2645, self.tick())
        self.sim.add_target_buff(666, duration_sec=120)
        self.sim.advance_time(64)
        self.assertEqual(self.tick(), [189])
        self.sim.advance_time(64)
        self.assertNotIn(2645, self.tick())
        self.sim.add_target_buff(714, duration_sec=120)
        self.sim.advance_time(64)
        self.assertEqual(self.tick(), [2645])

    def test_stale_pre_nt_cl_must_clear_before_required_reapplication(self):
        self.start_first_detonation()
        # Keep all old DOTs visible while NT CD confirms the detonation.
        self.sim.advance_time(4)
        self.assertEqual(self.tick(), [180])
        self.sim.advance_time(4)
        self.sim.remove_target_buff(666)
        self.sim.add_target_buff(666,duration_sec=120)
        self.assertEqual(self.tick(), [179], 'old CL must not be requested again while present')
        self.sim.remove_target_buff(714);self.sim.advance_time(4)
        self.assertEqual(self.tick(), [189])
        for _ in range(3):
            self.sim.advance_time(4)
            self.assertEqual(self.tick(), [], 'must wait for new CL, not repeat it or arm LT early')
        self.sim.remove_target_buff(714)
        self.sim.add_target_buff(714,duration_sec=120)
        self.sim.advance_time(4)
        self.assertEqual(self.tick(), [2645])
        self.sim.set_skill_cd(2645,120)
        self.sim.add_player_buff(2719,duration_sec=15)
        self.sim.advance_time(4)
        self.assertEqual(self.tick(), [179])

    def test_long_post_nt_cl_cast_keeps_application_confirmation(self):
        self.start_first_detonation();self.sim.advance_time(4)
        self.assertEqual(self.tick(),[180])
        self.sim.advance_time(4);self.sim.remove_target_buff(666)
        self.sim.add_target_buff(666,duration_sec=120)
        self.sim.remove_target_buff(714)
        self.assertEqual(self.tick(),[189])
        self.sim.set_player_prepare(True,189);self.sim.advance_time(1);self.tick()
        self.sim.advance_time(100);self.assertEqual(self.tick(),[])
        self.sim.set_player_prepare(False);self.sim.remove_target_buff(714)
        self.sim.add_target_buff(714,duration_sec=120)
        self.assertEqual(self.tick(),[2645])

    def test_old_empty_new_snapshots_do_not_erase_post_nt_dot_request(self):
        self.start_first_detonation();self.sim.advance_time(4)
        self.assertEqual(self.tick(),[180])
        # The old TD list clears before the replacement packet arrives.
        self.sim.remove_target_buff(666);self.sim.advance_time(1)
        self.assertEqual(self.tick(),[])
        self.sim.add_target_buff(666,duration_sec=120);self.sim.advance_time(4)
        self.sim.remove_target_buff(714)
        self.assertEqual(self.tick(),[189], 'confirmed TD was incorrectly requested twice')
        # Reproduce the same packet ordering while CL is actively preparing.
        self.sim.add_target_buff(1902,stack=5,duration_sec=2)
        self.sim.set_player_prepare(True,189)
        self.sim.remove_target_buff(714);self.sim.advance_time(1)
        self.assertEqual(self.tick(),[])
        self.sim.add_target_buff(714,duration_sec=120);self.sim.advance_time(4)
        self.assertEqual(self.tick(),[2645], 'fresh CL must unlock LT and cancel redundant CL cast')
        self.assertEqual(self.stops(),1)

    def test_late_cl_dot_after_half_second_timeout_still_unlocks_lt(self):
        self.start_first_detonation()
        for buff in (666,714,711): self.sim.remove_target_buff(buff)
        self.sim.advance_time(4);self.assertEqual(self.tick(),[180])
        self.sim.add_target_buff(666,duration_sec=120);self.sim.advance_time(4)
        self.assertEqual(self.tick(),[189])
        self.sim.lua.execute('arg0=_mockPlayer.dwID;arg1=189; for _,f in ipairs(_tEvents["DO_SKILL_CAST"] or {}) do f() end')
        self.sim.advance_time(8);self.assertEqual(self.tick(),[179])
        self.sim.add_target_buff(714,duration_sec=18);self.sim.advance_time(1)
        self.assertEqual(self.tick(),[2645])

    def test_late_td_after_timeout_can_advance_without_duplicate_td(self):
        self.start_first_detonation()
        for buff in (666,714,711): self.sim.remove_target_buff(buff)
        self.sim.advance_time(4);self.assertEqual(self.tick(),[180])
        self.sim.set_skill_cd(180,10)
        self.sim.advance_time(16);self.assertNotIn(2645,self.tick())
        self.sim.add_target_buff(666,duration_sec=18);self.sim.advance_time(1)
        self.assertEqual(self.tick(),[189])

    def test_late_cl_evidence_does_not_confirm_foreign_dot(self):
        self.start_first_detonation()
        for buff in (666,714,711): self.sim.remove_target_buff(buff)
        self.sim.advance_time(4);self.assertEqual(self.tick(),[180])
        self.sim.add_target_buff(666,duration_sec=120);self.sim.advance_time(4)
        self.assertEqual(self.tick(),[189])
        self.sim.lua.execute('arg0=_mockPlayer.dwID;arg1=189; for _,f in ipairs(_tEvents["DO_SKILL_CAST"] or {}) do f() end')
        self.sim.advance_time(8);self.tick()
        self.foreign_dot(714);self.sim.advance_time(1)
        self.assertNotIn(2645,self.tick())

    def test_old_cl_presence_delays_post_nt_request_until_absent(self):
        self.start_first_detonation();self.sim.advance_time(4)
        self.assertEqual(self.tick(),[180])
        self.sim.remove_target_buff(666);self.sim.add_target_buff(666,duration_sec=120)
        self.sim.advance_time(4);self.assertEqual(self.tick(),[179])
        self.sim.remove_target_buff(714);self.sim.advance_time(4)
        self.assertEqual(self.tick(),[189])
        self.sim.set_player_prepare(True,189);self.sim.advance_time(4)
        self.assertEqual(self.tick(),[])
        self.assertEqual(self.stops(),0, 'old pre-NT CL must not justify cancelling new CL')

    def test_classic_nil_empty_list_after_nt_can_reapply_and_activate_lt(self):
        self.sim.lua.execute('''
          _mockTarget.GetBuffCount=nil;_mockTarget.GetBuff=nil
          _mockTarget.GetBuffList=function()
            if next(_mockTarget.tBuffs)==nil then return nil end
            return _mockTarget.tBuffs
          end
        ''')
        self.start_first_detonation()
        for buff in (666,714,711,1902): self.sim.remove_target_buff(buff)
        self.sim.advance_time(4);self.assertEqual(self.tick(),[180])
        self.sim.add_target_buff(666,duration_sec=120)
        self.sim.advance_time(4);self.assertEqual(self.tick(),[189])
        self.sim.add_target_buff(714,duration_sec=120)
        self.sim.advance_time(4);self.assertEqual(self.tick(),[2645])

    def test_reload_with_nt_cooling_must_wait_for_first_own_detonation(self):
        self.healthy_dots();self.sim.set_skill_cd(182,12)
        self.sim.set_skill_cd(2645,0)
        self.assertEqual(self.tick(),[179])
        for _ in range(3):
            self.sim.advance_time(16)
            for buff in (666,714): self.sim.add_target_buff(buff,duration_sec=120)
            self.assertNotIn(2645,self.tick())
        self.assertFalse(self.sim.lua.globals().xMacro['VanHoaDiagnostics']['after_nt'])
        self.sim.set_skill_cd(182,0);self.sim.advance_time(4)
        self.assertEqual(self.tick(),[182])

    def test_reload_with_nt_ready_does_not_skip_first_detonation(self):
        self.healthy_dots();self.sim.set_skill_cd(2645,0)
        self.assertEqual(self.tick(),[182])

    def test_reload_with_cooling_nt_and_foreign_dots_cannot_arm_lt(self):
        self.sim.set_skill_cd(182,12);self.sim.set_skill_cd(2645,0)
        self.assertEqual(self.tick(),[180])
        for buff in (666,714): self.foreign_dot(buff)
        self.sim.advance_time(4)
        self.assertEqual(self.tick(),[])
        self.assertFalse(self.sim.lua.globals().xMacro['VanHoaDiagnostics']['after_nt'])

    def test_reload_during_active_lt_does_not_restart_post_nt_phase(self):
        self.healthy_dots();self.sim.set_skill_cd(182,12)
        self.sim.set_skill_cd(2645,0);self.sim.add_player_buff(2719,duration_sec=15)
        self.assertEqual(self.tick(),[179])
        self.assertFalse(self.sim.lua.globals().xMacro['VanHoaDiagnostics']['after_nt'])

    def test_own_nt_cast_event_confirms_even_when_cd_snapshot_is_delayed(self):
        self.healthy_dots();self.sim.set_skill_cd(2645,0)
        self.assertEqual(self.tick(),[182])
        self.sim.lua.execute('arg0=_mockPlayer.dwID;arg1=182; for _,f in ipairs(_tEvents["DO_SKILL_CAST"] or {}) do f() end')
        for buff in (666,714,711): self.sim.remove_target_buff(buff)
        self.sim.advance_time(4);self.assertEqual(self.tick(),[180])
        self.sim.add_target_buff(666,duration_sec=120);self.sim.advance_time(4)
        self.assertEqual(self.tick(),[189])
        self.sim.add_target_buff(714,duration_sec=120);self.sim.advance_time(4)
        self.assertEqual(self.tick(),[2645])

    def test_rejected_nt_request_cannot_be_confirmed_by_later_cd_or_event(self):
        self.healthy_dots();self.sim.set_skill_cd(2645,0)
        self.sim.lua.execute('local send=OnAddOnUseSkill; OnAddOnUseSkill=function(id,level) send(id,level); return false end')
        self.assertEqual(self.tick(),[182])
        self.sim.set_skill_cd(182,12)
        self.sim.lua.execute('arg0=_mockPlayer.dwID;arg1=182; for _,f in ipairs(_tEvents["DO_SKILL_CAST"] or {}) do f() end')
        self.sim.advance_time(4);self.tick()
        self.assertFalse(self.sim.lua.globals().xMacro['VanHoaDiagnostics']['after_nt'])

    def test_cooldown_appearing_later_without_our_nt_does_not_resume(self):
        self.healthy_dots(lan_thoi=False);self.sim.set_skill_cd(2645,0)
        self.sim.set_skill_cd(190,120)
        self.assertEqual(self.tick(),[179])
        self.sim.set_skill_cd(182,12);self.sim.advance_time(4)
        self.assertEqual(self.tick(),[179])
        self.assertFalse(self.sim.lua.globals().xMacro['VanHoaDiagnostics']['after_nt'])

    def test_target_switch_while_nt_cooling_requires_its_own_first_detonation(self):
        self.start_first_detonation()
        self.sim.lua.execute('_mockTarget.dwID=1000')
        self.sim.advance_time(4)
        self.assertEqual(self.tick(),[179])
        self.assertFalse(self.sim.lua.globals().xMacro['VanHoaDiagnostics']['after_nt'])

    def test_nt_event_without_macro_request_cannot_arm_lt(self):
        self.healthy_dots(lan_thoi=False);self.sim.set_skill_cd(2645,0)
        self.sim.set_skill_cd(190,120)
        self.assertEqual(self.tick(),[179])
        self.sim.lua.execute('arg0=_mockPlayer.dwID;arg1=182; for _,f in ipairs(_tEvents["DO_SKILL_CAST"] or {}) do f() end')
        self.sim.advance_time(4);self.assertEqual(self.tick(),[179])
        self.assertFalse(self.sim.lua.globals().xMacro['VanHoaDiagnostics']['after_nt'])

    def test_other_players_dots_cannot_arm_post_detonation_lt(self):
        self.start_first_detonation()
        for buff in (666, 714, 711):
            self.sim.remove_target_buff(buff)
        for buff in (666, 714):
            self.foreign_dot(buff)
        for _ in range(3):
            self.sim.advance_time(64)
            self.assertNotIn(2645, self.tick(), "foreign DOTs armed our LT")

    def test_procs_cannot_skip_missing_opener_dots(self):
        for buff in (2495,4761):
            with self.subTest(buff=buff):
                self.setUp();self.sim.set_skill_cd(2645,0)
                self.sim.add_player_buff(buff,stack=10,duration_sec=1)
                self.assertEqual(self.tick(),[180])

    def test_procs_cannot_detonate_fresh_dots_before_lt(self):
        for buff in (2495,4761):
            with self.subTest(buff=buff):
                self.setUp();self.start_first_detonation()
                self.sim.add_player_buff(buff,stack=10,duration_sec=1)
                for old in (666,714,711): self.sim.remove_target_buff(old)
                self.sim.advance_time(4);self.assertEqual(self.tick(),[180])
                self.sim.add_target_buff(666,duration_sec=120);self.sim.advance_time(4)
                self.assertEqual(self.tick(),[189])
                self.sim.add_target_buff(714,duration_sec=120);self.sim.advance_time(4)
                self.assertEqual(self.tick(),[2645])

    def test_active_lt_procs_do_not_force_early_detonation(self):
        for buff in (2495,4761):
            with self.subTest(buff=buff):
                self.setUp();self.healthy_dots();self.sim.set_skill_cd(2645,0)
                self.sim.add_player_buff(2719,duration_sec=15)
                self.sim.add_player_buff(buff,stack=10,duration_sec=1)
                self.assertEqual(self.tick(),[179])

    def test_unknown_snapshot_is_not_evidence_of_post_nt_dot_removal(self):
        self.start_first_detonation();self.sim.advance_time(4)
        self.assertEqual(self.tick(),[180])
        self.sim.lua.execute('_buffList=_mockTarget.GetBuffList; _mockTarget.GetBuffList=function() error("unreadable") end; _mockTarget.GetBuffCount=nil')
        self.sim.advance_time(1);self.assertEqual(self.tick(),[])
        self.sim.lua.execute('_mockTarget.GetBuffList=_buffList')
        self.sim.advance_time(4)
        self.assertEqual(self.tick(),[], 'old unchanged TD cannot count as new after unknown read')
        self.assertTrue(self.sim.lua.globals().xMacro['VanHoaDiagnostics']['need_td'])

    def test_pending_nt_is_not_requested_twice_before_confirmation(self):
        self.healthy_dots();self.sim.set_skill_cd(2645,0)
        self.assertEqual(self.tick(),[182])
        self.sim.advance_time(4);self.assertEqual(self.tick(),[])

    def test_after_fresh_dots_thuy_wait_cannot_restart_lan_thoi_or_nt(self):
        self.start_first_detonation()
        for old in (666,714,711): self.sim.remove_target_buff(old)
        self.sim.advance_time(4);self.assertEqual(self.tick(),[180])
        self.sim.add_target_buff(666,duration_sec=120);self.sim.advance_time(4)
        self.assertEqual(self.tick(),[189])
        self.sim.add_target_buff(714,duration_sec=120)
        self.sim.add_player_buff(412,duration_sec=10);self.sim.set_skill_cd(182,0)
        self.sim.advance_time(4);self.assertEqual(self.tick(),[179])
        self.sim.remove_player_buff(412);self.sim.advance_time(4)
        self.assertEqual(self.tick(),[2645])

    def test_waiting_for_thuy_still_maintains_phe_cot(self):
        self.start_first_detonation()
        for old in (666,714,711): self.sim.remove_target_buff(old)
        self.sim.advance_time(4);self.assertEqual(self.tick(),[180])
        self.sim.add_target_buff(666,duration_sec=120);self.sim.advance_time(4)
        self.assertEqual(self.tick(),[189])
        self.sim.add_target_buff(714,duration_sec=120)
        self.sim.add_player_buff(412,duration_sec=10)
        self.sim.add_target_buff(1902,duration_sec=2)
        self.sim.advance_time(4);self.assertEqual(self.tick(),[180])

    def test_normal_nt_when_lt_unavailable_does_not_lock_stable_rotation(self):
        self.healthy_dots();self.sim.set_skill_cd(190,0)
        self.assertEqual(self.tick(),[182]);self.sim.set_skill_cd(182,17)
        for old in (666,714,711): self.sim.remove_target_buff(old)
        self.sim.advance_time(4);self.assertEqual(self.tick(),[180])
        self.sim.add_target_buff(666,duration_sec=120);self.sim.advance_time(4)
        self.assertEqual(self.tick(),[189])
        self.sim.add_target_buff(714,duration_sec=120);self.sim.advance_time(4)
        self.assertEqual(self.tick(),[179])
        self.sim.remove_target_buff(1902);self.sim.advance_time(48)
        self.assertEqual(self.tick(),[180])

    def test_target_switch_requires_new_first_detonation(self):
        self.start_first_detonation()
        self.sim.lua.execute("_mockTarget.dwID = 1000")
        self.sim.set_skill_cd(182, 0)
        self.sim.advance_time(64)
        self.assertEqual(self.tick(), [182], "new target inherited old target sequence")

    def test_rejected_detonation_does_not_advance_to_lt(self):
        self.healthy_dots()
        self.sim.set_skill_cd(2645, 0)
        # This API can reject an attempted send. The unchanged target snapshot
        # must not become evidence that the detonation actually happened.
        self.sim.lua.execute("""
            local originalSend = OnAddOnUseSkill
            OnAddOnUseSkill = function(id, level)
                originalSend(id, level)
                return false
            end
        """)
        self.assertEqual(self.tick(), [182])
        self.sim.advance_time(64)
        self.assertEqual(self.tick(), [182])

    def test_dot_source_legacy_fallback_excludes_known_other_players(self):
        # Some supported old clients omit the source field or report zero.
        # Compatibility permits those snapshots; a known foreign owner does not.
        for source in ("nil", "0", "202"):
            with self.subTest(source=source):
                self.setUp()
                self.healthy_dots()
                self.sim.set_skill_cd(2645, 0)
                self.sim.lua.execute(f"""
                    for _, b in ipairs(_mockTarget.tBuffs) do
                        if b.dwID ~= 1902 then b.dwSkillSrcID = {source} end
                    end
                """)
                ids = self.tick()
                if source in ("nil", "0"):
                    self.assertEqual(ids, [182], "legacy source fallback was lost")
                else:
                    self.assertNotIn(182, ids, "foreign DOTs supplied our detonation")
                self.assertNotIn(2645, ids, "unowned DOTs armed LT")

    def test_dead_target_does_not_receive_action(self):
        self.healthy_dots()
        self.sim.set_skill_cd(2645, 0)
        self.sim.lua.execute("_mockTarget.nCurrentLife = 0; _mockTarget.nMoveState = 2")
        self.assertEqual(self.tick(), [])

    def test_phe_cot_missing_or_under_three_seconds_refreshes_healthy_td(self):
        for lt_buff in (None, 2719, 2726):
            for remaining in (None, 2.5):
                with self.subTest(lt_buff=lt_buff, remaining=remaining):
                    self.setUp()
                    self.healthy_dots()
                    self.sim.set_skill_cd(182, 10)
                    if lt_buff:
                        self.sim.add_player_buff(lt_buff, duration_sec=15)
                    self.sim.remove_target_buff(1902)
                    if remaining is not None:
                        self.sim.add_target_buff(1902, duration_sec=remaining)
                    self.assertEqual(self.tick(), [180])

    def test_healthy_phe_cot_does_not_spam_thuong_duong(self):
        self.healthy_dots(lan_thoi=False)
        self.sim.set_skill_cd(182, 30)
        for _ in range(3):
            self.assertEqual(self.tick(), [179])
            self.sim.advance_time(64)

    def test_active_lt_midwindow_missing_lan_thoi_uses_dmc(self):
        for buff in (2719, 2726):
            with self.subTest(buff=buff):
                self.setUp()
                self.healthy_dots(lan_thoi=False)
                self.sim.add_player_buff(buff, duration_sec=15)
                self.sim.set_skill_cd(182, 0)
                self.assertEqual(self.tick(), [179])

    def test_valid_dmc_without_lan_thoi_survives_nt_cooldown(self):
        self.healthy_dots(lan_thoi=False)
        self.sim.set_skill_cd(182, 30)
        self.sim.set_player_prepare(True, skill_id=179)
        for _ in range(3):
            self.assertEqual(self.tick(), [], "ongoing DMC sent another action")
            self.assertEqual(self.stops(), 0, "missing Lan Thoi cancelled valid DMC")
            self.sim.advance_time(1)

    def test_valid_dmc_survives_after_lt_ends(self):
        self.healthy_dots(lan_thoi=False)
        self.sim.set_skill_cd(182, 30)
        self.sim.add_player_buff(2719, duration_sec=15)
        self.assertEqual(self.tick(), [179])
        self.sim.remove_player_buff(2719)
        self.sim.advance_time(64)
        self.sim.set_player_prepare(True, skill_id=179)
        self.assertEqual(self.tick(), [])
        self.assertEqual(self.stops(), 0)

    def test_unknown_cast_skill_is_not_assumed_to_be_dmc(self):
        self.healthy_dots(lan_thoi=False)
        self.sim.set_skill_cd(182, 30)
        self.sim.set_player_prepare(True, skill_id=0)
        self.sim.lua.execute("""
            _mockPlayer.GetSkillPrepareState = function() return true, nil, nil end
        """)
        self.assertEqual(self.tick(), [])
        self.assertEqual(self.stops(), 0, "unknown cast was treated as DMC")

    def test_usable_phe_cot_refresh_interrupts_dmc(self):
        self.healthy_dots(lan_thoi=False)
        self.sim.set_skill_cd(182, 30)
        self.sim.remove_target_buff(1902)
        self.sim.set_player_prepare(True, skill_id=179)
        self.assertEqual(self.tick(), [180])
        self.assertEqual(self.stops(), 1)

    def test_phe_cot_refresh_on_cd_does_not_cancel_dmc(self):
        self.healthy_dots(lan_thoi=False)
        self.sim.set_skill_cd(182, 30)
        self.sim.set_skill_cd(180, 10)
        self.sim.remove_target_buff(1902)
        self.sim.set_player_prepare(True, skill_id=179)
        self.assertEqual(self.tick(), [])
        self.assertEqual(self.stops(), 0)

    def test_phe_cot_refresh_on_gcd_does_not_cancel_dmc(self):
        self.healthy_dots(lan_thoi=False)
        self.sim.set_skill_cd(182, 30)
        self.sim.set_skill_cd(53, 1)
        self.sim.remove_target_buff(1902)
        self.sim.set_player_prepare(True, skill_id=179)
        self.assertEqual(self.tick(), [])
        self.assertEqual(self.stops(), 0)

    def test_emergencies_interrupt_only_for_usable_skill(self):
        for emergency, skill in (("nCurrentLife", 132), ("nCurrentMana", 131)):
            for block in (None, "skill_cd", "gcd"):
                with self.subTest(emergency=emergency, block=block):
                    self.setUp()
                    self.healthy_dots(lan_thoi=False)
                    self.sim.add_target_buff(1902,stack=5,duration_sec=2)
                    self.sim.set_skill_cd(180,120)
                    self.sim.set_skill_cd(182, 30)
                    self.sim.lua.execute(f"_mockPlayer.{emergency} = 3000")
                    self.sim.set_player_prepare(True, skill_id=179)
                    if block:
                        self.sim.set_skill_cd(skill if block == "skill_cd" else 53, 10)
                    ids = self.tick()
                    if block:
                        self.assertEqual(ids, [])
                        self.assertEqual(self.stops(), 0, "unusable rescue cancelled DMC")
                    else:
                        self.assertEqual(ids, [skill])
                        self.assertEqual(self.stops(), 1)


if __name__ == "__main__":
    unittest.main()
