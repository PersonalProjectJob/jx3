"""Run from tools: python -m unittest test_hold_key_repeater -v."""

import unittest
from unittest.mock import Mock

from hold_key_repeater import GAME_ROOT, GameTarget, ConfiguredRepeater, HoldSettings, KeyOutput, Win32


GAME = GameTarget(100, 200, "C:/game/jx3client.exe", 300)
OTHER_GAME = GameTarget(101, 201, "C:/game/jx3client.exe", 301)


class ConfiguredRepeaterTests(unittest.TestCase):
    def setUp(self):
        self.native=Mock()
        self.native.identity.side_effect=lambda hwnd: GAME if hwnd==100 else None
        self.native.games.return_value=[GAME]
        self.native.user.GetForegroundWindow.return_value=100
        self.native.post_key.return_value=True
        self.state=ConfiguredRepeater(self.native)
        self.settings=HoldSettings(True,50,(49,50,51,52),1)

    def test_all_four_keys_each_fifty_ms_with_short_release(self):
        self.assertEqual(self.state.tick(self.settings,0),2)
        self.assertEqual([c.args for c in self.native.post_key.call_args_list],
                         [(GAME,k,True) for k in self.settings.keys])
        self.state.tick(self.settings,.016)
        self.assertEqual([c.args for c in self.native.post_key.call_args_list][4:],
                         [(GAME,k,False) for k in self.settings.keys])
        self.state.tick(self.settings,.049)
        self.assertEqual(self.native.post_key.call_count,8)
        self.state.tick(self.settings,.05)
        self.assertEqual(self.native.post_key.call_count,12)

    def test_stop_releases_all_four_immediately(self):
        self.state.tick(self.settings,0)
        self.assertEqual(self.state.tick(HoldSettings(),.001),0)
        self.assertEqual(self.native.post_key.call_count,8)
        self.assertTrue(all(out.pending is None for out in self.state.output))

    def test_alt_tab_keeps_same_recipient(self):
        self.state.tick(self.settings,0)
        self.native.user.GetForegroundWindow.return_value=999
        self.native.games.return_value=[OTHER_GAME]
        self.state.tick(self.settings,.05)
        self.assertTrue(all(c.args[0]==GAME for c in self.native.post_key.call_args_list))

    def test_ambiguous_games_wait_for_foreground(self):
        self.native.user.GetForegroundWindow.return_value=999
        self.native.games.return_value=[GAME,OTHER_GAME]
        self.assertEqual(self.state.tick(self.settings,0),1)
        self.native.post_key.assert_not_called()
        self.native.user.GetForegroundWindow.return_value=100
        self.assertEqual(self.state.tick(self.settings,.1),2)

    def test_target_loss_latches_until_new_start(self):
        self.state.tick(self.settings,0)
        self.native.identity.side_effect=lambda hwnd: None
        self.assertEqual(self.state.tick(self.settings,.02),3)
        self.native.identity.side_effect=lambda hwnd: GAME
        self.assertEqual(self.state.tick(self.settings,.1),3)
        self.assertEqual(self.state.tick(HoldSettings(True,50,(49,),2),.2),2)

    def test_partial_batch_failure_releases_keys_and_latches(self):
        self.native.post_key.side_effect=lambda target,key,down: key!=51 or not down
        self.assertEqual(self.state.tick(self.settings,0),3)
        self.assertTrue(all(out.pending is None for out in self.state.output))
        self.assertIn((GAME,49,False),[c.args for c in self.native.post_key.call_args_list])
        self.assertNotIn((GAME,52,True),[c.args for c in self.native.post_key.call_args_list])

    def test_late_tick_does_not_catch_up_in_burst(self):
        self.state.tick(self.settings,0)
        self.state.tick(self.settings,5)
        count=self.native.post_key.call_count
        self.state.tick(self.settings,5)
        self.assertEqual(count,self.native.post_key.call_count)

    def test_default_configuration_emits_nothing(self):
        self.assertEqual(self.state.tick(HoldSettings(),0),0)
        self.native.post_key.assert_not_called()

    def test_background_start_and_many_cycles_never_follow_foreground(self):
        self.native.user.GetForegroundWindow.return_value=999
        self.assertEqual(self.state.tick(self.settings,0),2)
        self.native.user.GetForegroundWindow.side_effect=AssertionError('must not read focus once bound')
        for i in range(1,11):
            self.assertEqual(self.state.tick(self.settings,i*.051),2)
        downs=[c.args for c in self.native.post_key.call_args_list if c.args[2]]
        self.assertEqual(len(downs),44)
        self.assertTrue(all(c[0]==GAME for c in downs))
        self.assertEqual([c[1] for c in downs],list(self.settings.keys)*11)

    def test_switch_to_native_combo_releases_external_keys_and_never_sends_more(self):
        self.state.tick(self.settings,0)
        settings=HoldSettings(True,50,self.settings.keys,2,True)
        self.assertEqual(self.state.tick(settings,.001),4)
        calls=self.native.post_key.call_count
        self.assertEqual(calls,8)
        self.state.tick(settings,.1)
        self.assertEqual(self.native.post_key.call_count,calls)


class OutputTests(unittest.TestCase):
    def test_down_and_up_use_same_explicit_game_target(self):
        native = Mock()
        native.post_key.return_value = True
        out = KeyOutput(native)
        self.assertTrue(out.press(0x31, GAME, 0))
        self.assertTrue(out.tick(0.01))
        self.assertEqual(native.post_key.call_count, 1)
        self.assertTrue(out.tick(0.02))
        self.assertEqual(native.post_key.call_args_list,
                         [((GAME, 0x31, True),), ((GAME, 0x31, False),)])

    def test_stop_releases_pending_key(self):
        native = Mock()
        native.post_key.return_value = True
        out = KeyOutput(native)
        out.press(0x31, GAME, 0)
        out.release()
        self.assertIsNone(out.pending)
        native.post_key.assert_called_with(GAME, 0x31, False)

    def test_failed_down_leaves_no_pending_key(self):
        native = Mock()
        native.post_key.return_value = False
        out = KeyOutput(native)
        self.assertFalse(out.press(0x31, GAME, 0))
        self.assertIsNone(out.pending)

    def test_recycled_window_identity_cannot_receive_down_or_up(self):
        native = Win32.__new__(Win32)
        native.user = Mock()
        native.identity = Mock(return_value=GameTarget(GAME.hwnd, GAME.pid,
                                                       GAME.executable, GAME.birth + 1))
        self.assertFalse(native.post_key(GAME, 0x31, True))
        self.assertFalse(native.post_key(GAME, 0x31, False))
        native.user.PostMessageW.assert_not_called()

    def test_native_messages_are_addressed_not_desktop_injection(self):
        native = Win32.__new__(Win32)
        native.identity = Mock(return_value=GAME)
        native.user = Mock()
        native.user.MapVirtualKeyW.return_value = 2
        native.user.PostMessageW.return_value = 1
        self.assertTrue(native.post_key(GAME, 0x31, True))
        self.assertTrue(native.post_key(GAME, 0x31, False))
        calls = native.user.PostMessageW.call_args_list
        self.assertEqual([call.args[:3] for call in calls],
                         [(GAME.hwnd, 0x100, 0x31), (GAME.hwnd, 0x101, 0x31)])
        self.assertFalse(calls[0].args[3] & (1 << 31))
        self.assertTrue(calls[1].args[3] & (1 << 31))


class GameIdentityTests(unittest.TestCase):
    def native(self, path=None, window_class="KGWin32App"):
        native = Win32.__new__(Win32)
        native.user = Mock()
        native.kernel = Mock()
        native.user.IsWindow.return_value = True
        native.user.GetClassNameW.side_effect = lambda hwnd, buf, size: setattr(buf, "value", window_class)
        native.user.GetWindowThreadProcessId.side_effect = lambda hwnd, pid: setattr(pid._obj, "value", 200)
        native.kernel.OpenProcess.return_value = 999

        def image(process, flags, buf, size):
            buf.value = str(path or GAME_ROOT / "jx3client.exe")
            return True

        def times(process, created, ended, kernel, user):
            created._obj.dwLowDateTime = 300
            return True

        native.kernel.QueryFullProcessImageNameW.side_effect = image
        native.kernel.GetProcessTimes.side_effect = times
        return native

    def test_accepts_exact_install_executable_and_process_birth(self):
        native = self.native()
        target = native.identity(100)
        self.assertEqual((target.hwnd, target.pid, target.birth), (100, 200, 300))
        native.kernel.CloseHandle.assert_called_once_with(999)

    def test_same_class_and_executable_in_another_folder_is_rejected(self):
        native = self.native(GAME_ROOT.parent / "other-install" / "jx3client.exe")
        self.assertIsNone(native.identity(100))
        native.kernel.CloseHandle.assert_called_once_with(999)

    def test_other_program_in_game_folder_is_rejected(self):
        native = self.native(GAME_ROOT / "notepad.exe")
        self.assertIsNone(native.identity(100))

    def test_other_window_class_is_rejected_without_process_access(self):
        native = self.native(window_class="Notepad")
        self.assertIsNone(native.identity(100))
        native.kernel.OpenProcess.assert_not_called()

    def test_unreadable_process_identity_fails_closed(self):
        native = self.native()
        native.kernel.QueryFullProcessImageNameW.side_effect = None
        native.kernel.QueryFullProcessImageNameW.return_value = False
        self.assertIsNone(native.identity(100))
        native.kernel.CloseHandle.assert_called_once_with(999)


if __name__ == "__main__":
    unittest.main()
