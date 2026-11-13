"""Reproduce repeated DOT requests with delayed observations, using actual Lua.

Run: python -m unittest simulator.test_vanhoa_opener -v
These assert request order; they do not prove execution by the game server.
"""

import unittest
from simulator.engine import JX3Simulator


class OpenerTests(unittest.TestCase):
    def setUp(self):
        self.sim = JX3Simulator()
        self.sim.set_skill_cd(136, 120)
        self.sim.set_skill_cd(2645, 0)

    def tick(self):
        return [c['id'] for c in self.sim.execute_tick()['casted']]

    def test_screenshot_opener_does_not_repeat_td_or_cl_with_missing_unknown_phe_cot(self):
        sent = []
        self.sim.set_skill_cd(136, 0)
        sent += self.tick()
        self.sim.set_skill_cd(136, 120)
        self.sim.advance_time(8)
        sent += self.tick()
        self.sim.advance_time(8)
        self.sim.add_target_buff(666)
        self.sim.add_player_buff(412, duration_sec=30)
        sent += self.tick()
        self.sim.advance_time(48)
        self.sim.add_target_buff(711)
        action = self.tick()
        self.assertEqual(action, [189], 'unknown missing Phe Cot must not force a second TD')
        sent += action
        # Boss interrupt is allowed, but must not erase the pending CL request.
        self.sim.lua.execute('_mockTarget.bPreparing = true')
        self.sim.advance_time(4)
        sent += self.tick()
        self.sim.lua.execute('_mockTarget.bPreparing = false')
        self.sim.advance_time(4)
        self.assertEqual(self.tick(), [], 'CL DOT still unobserved: do not send another DOT')
        self.sim.add_target_buff(714)
        self.sim.advance_time(4)
        sent += self.tick()
        self.assertEqual(sent, [136, 180, 190, 189, 183, 182])

    def test_rapid_calls_wait_for_td_observation(self):
        self.assertEqual(self.tick(), [180])
        for _ in range(3):
            self.sim.advance_time(4)
            self.assertEqual(self.tick(), [], 'pending opener TD was repeated/overridden')

    def test_rapid_calls_wait_for_cl_observation(self):
        for buff in (666, 711, 1902):
            self.sim.add_target_buff(buff, duration_sec=120)
        self.assertEqual(self.tick(), [189])
        for _ in range(3):
            self.sim.advance_time(4)
            self.assertEqual(self.tick(), [], 'pending opener CL was repeated/overridden')
        self.sim.add_target_buff(714)
        self.sim.advance_time(4)
        self.assertEqual(self.tick(), [182])

    def test_long_cl_cast_is_not_retried_at_request_timeout(self):
        for buff in (666, 711, 1902):
            self.sim.add_target_buff(buff, duration_sec=120)
        self.assertEqual(self.tick(), [189])
        self.sim.set_player_prepare(True, skill_id=189)
        self.sim.advance_time(16)
        self.assertEqual(self.tick(), [])
        self.sim.advance_time(100)
        self.assertEqual(self.tick(), [])
        self.sim.set_player_prepare(False)
        self.assertEqual(self.tick(), [])
        self.sim.advance_time(7)
        self.assertEqual(self.tick(), [], 'allow snapshot grace after cast completes')
        self.sim.add_target_buff(714)
        self.sim.advance_time(4)
        self.assertEqual(self.tick(), [182])

    def test_unconfirmed_request_can_retry_after_bounded_timeout(self):
        self.assertEqual(self.tick(), [180])
        self.sim.advance_time(15)
        self.assertEqual(self.tick(), [])
        self.sim.advance_time(1)
        self.assertEqual(self.tick(), [180], 'lost DOT request must not stall forever')

    def test_changing_target_does_not_inherit_pending_dot(self):
        self.assertEqual(self.tick(), [180])
        self.sim.advance_time(4)
        self.sim.lua.execute('_mockTarget.dwID = 1000')
        self.assertEqual(self.tick(), [180])


if __name__ == '__main__':
    unittest.main()
