"""Native API fixtures and file bridge; not live game visual evidence."""
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import Mock
from hold_key_repeater import (GameControl, GameTarget, ConfiguredRepeater,
    HoldSettings, parse_control, encode_data, decode_data)
ROOT=Path(__file__).resolve().parent.parent
sys.path.insert(0,str(ROOT))
from simulator.engine import lua
ADDON=ROOT/'interface/xMacro'
CONTROL='interface\\xMacro\\hold_key_control.jx3dat'
UI='interface\\xMacro\\hold_key_ui.jx3dat'
STATUS='interface\\xMacro\\hold_key_status.jx3dat'
FIXTURE=r'''
_saved={["interface\\xMacro\\hold_key_control.jx3dat"]={native_macro=false}};_events={};_now=100;_mx=270;_my=190;_down=true;_saveOK=true;_frame=nil
function GetTime() return _now end
function GetClientPlayer() return {} end
function SaveLUAData(path,data)
 if not _saveOK then return false end
 _saved[path]=data
 if _diskSave then _diskSave(path,data) end
 return true
end
function LoadLUAData(path) return _saved[path] end
function RegisterEvent(name,fn) _events[name]=fn end
_bindings={}
Hotkey={AddBinding=function(id,title,group,callback,onUp)
 _bindings[id]={title=title,group=group,callback=callback,release=onUp}
end}
Cursor={GetPos=function() return _mx,_my end}
Station={Lookup=function() return _frame end,IsLButtonPressed=function() return _down end}
local function Widget()
 local w={text='',visible=true,enabled=true,x=0,y=0}
 function w:SetText(text) self.text=text end
 function w:GetText() return self.text end
 function w:Show() self.visible=true end
 function w:Hide() self.visible=false end
 function w:Enable(v) assert(type(v)=='number');self.enabled=v==1 end
 function w:SetSize(a,b) self.width,self.height=a,b end
 function w:SetRelPos(x,y) self.x,self.y=x,y end
 function w:GetRelPos() return self.x,self.y end
 function w:GetAbsPos() return self.x,self.y end
 function w:CorrectPos() end
 function w:EnableDrag(v) assert(type(v)=='boolean') end
 function w:SetDragArea(...) end
 return w
end
Wnd={OpenWindow=function()
 local f=Widget();f.items={};f.children={}
 for _,name in ipairs({'Text_Title','Text_Status','Text_Helper','Text_Notice','Text_Help',
 'Text_Background','Text_Key1','Text_Key2','Text_Key3','Text_Key4','Image_Background'}) do
  f.items[name]=Widget()
 end
 for _,name in ipairs({'Btn_On','Btn_Off','Btn_Mini','Edit_1','Edit_2','Edit_3','Edit_4','Drag_Title'}) do
  local child=Widget();child.label=Widget()
  local handle={Lookup=function(_,key) if key=='Text_'..name then return child.label end end}
  function child:Lookup(a,b) if a=='' and b=='' then return handle end end
  f.children[name]=child
 end
 function f:Lookup(a,b) if b then return self.items[b] end return self.children[a] end
 _frame=f;return f
end}
'''

class PanelTests(unittest.TestCase):
 def setUp(self):
  self.lua=lua.LuaRuntime(unpack_returned_tuples=True)
  self.lua.execute(FIXTURE)
  self.source=(ADDON/'HoldKey.lua').read_text('ascii')
  self.lua.execute(self.source)
 def runlua(self,s): self.lua.execute(s)
 def value(self,s): return self.lua.eval(s)
 def online(self):
  self.lua.globals()._saved[STATUS]=self.lua.table_from(dict(pid=7,seq=1,state=0))
  self.runlua('_now=400;xMacro.HoldKey.Tick()')
  self.lua.globals()._saved[STATUS]['seq']=2
  self.runlua('_now=700;xMacro.HoldKey.Tick()')
 def test_default_stopped_requires_helper(self):
  self.runlua('_frame.children.Btn_On.OnLButtonClick()')
  self.assertFalse(self.lua.globals()._saved[CONTROL]['enabled'])
  self.assertIn('OFFLINE',self.value('_frame.items.Text_Notice.text'))
 def test_four_keys_start_ack_and_stop(self):
  self.online()
  self.runlua('for i=1,4 do _frame.children["Edit_"..i]:SetText(tostring(i)) end;_frame.children.Btn_On.OnLButtonClick()')
  data=self.lua.globals()._saved[CONTROL]
  self.assertTrue(data['enabled']);self.assertEqual(data['interval_ms'],50)
  self.assertEqual([data['key_'+str(i)] for i in range(1,5)],[49,50,51,52])
  self.assertFalse(self.value('_frame.children.Edit_1.enabled'))
  self.assertIn('CHO HELPER',self.value('_frame.items.Text_Status.text'))
  self.lua.globals()._saved[STATUS]=self.lua.table_from(dict(pid=7,seq=3,state=2,run_id=1))
  self.runlua('_now=1000;xMacro.HoldKey.Tick()')
  self.assertIn('DANG SPAM',self.value('_frame.items.Text_Status.text'))
  self.runlua('_frame.children.Btn_Off.OnLButtonClick()')
  self.assertFalse(self.lua.globals()._saved[CONTROL]['enabled'])
  self.assertTrue(self.value('_frame.children.Edit_1.enabled'))
 def test_empty_duplicate_unknown_rejected(self):
  self.online()
  for setup in ['for i=1,4 do _frame.children["Edit_"..i]:SetText("") end',
                '_frame.children.Edit_1:SetText("1");_frame.children.Edit_2:SetText("1")',
                '_frame.children.Edit_2:SetText("CTRL+A")']:
   self.runlua(setup+';_frame.children.Btn_On.OnLButtonClick()')
   self.assertFalse(self.lua.globals()._saved[CONTROL]['enabled'])
 def test_drag_mouse_delta_and_save_on_release(self):
  self.runlua('_frame.children.Drag_Title.OnLButtonDown();_mx=370;_my=240;xMacro.OnFrameBreathe()')
  self.assertEqual((self.value('_frame.x'),self.value('_frame.y')),(360,230))
  self.runlua('_down=false;xMacro.OnFrameBreathe()')
  self.assertEqual(self.lua.globals()._saved[UI]['x'],360)
  self.runlua('_mx=470;xMacro.OnFrameBreathe()')
  self.assertEqual(self.value('_frame.x'),360)
 def test_drag_rejects_body_and_minimize_button(self):
  for x,y in [(270,290),(555,190)]:
   self.runlua(f'_mx={x};_my={y};xMacro.HoldKey.BeginDrag();_mx=700;xMacro.HoldKey.DragTick()')
   self.assertEqual(self.value('_frame.x'),260)
 def test_minimize_restore_stop_while_running(self):
  self.online();self.runlua('_frame.children.Btn_On.OnLButtonClick();_frame.children.Btn_Mini.OnLButtonClick()')
  self.assertEqual(self.value('_frame.height'),76)
  self.assertFalse(self.value('_frame.children.Edit_1.visible'))
  self.assertTrue(self.value('_frame.children.Btn_Off.visible'))
  self.assertTrue(self.lua.globals()._saved[UI]['mini'])
  self.runlua('_frame.children.Btn_Off.OnLButtonClick();_frame.children.Btn_Mini.OnLButtonClick()')
  self.assertEqual(self.value('_frame.height'),300)
  self.assertTrue(self.value('_frame.children.Edit_1.visible'))
  self.assertFalse(self.lua.globals()._saved[CONTROL]['enabled'])
 def test_stale_heartbeat_never_claims_running(self):
  self.online();self.runlua('_frame.children.Btn_On.OnLButtonClick();_now=3000;xMacro.HoldKey.Tick()')
  self.assertIn('OFFLINE',self.value('_frame.items.Text_Helper.text'))
  self.assertNotIn('DANG SPAM',self.value('_frame.items.Text_Status.text'))
 def test_save_failure_keeps_stop_available(self):
  self.online();self.runlua('_frame.children.Btn_On.OnLButtonClick();_saveOK=false;_frame.children.Btn_Off.OnLButtonClick()')
  self.assertTrue(self.lua.globals()._saved[CONTROL]['enabled'])
  self.assertIn('Loi luu',self.value('_frame.items.Text_Notice.text'))
  self.assertTrue(self.value('_frame.children.Btn_Off.enabled'))
 def test_reload_stops_retains_bindings_position(self):
  self.online();self.runlua('_frame.children.Edit_1:SetText("F2");_frame.children.Btn_On.OnLButtonClick();_frame:SetRelPos(420,310);xMacro.HoldKey.SavePosition();_frame=nil')
  self.lua.execute(self.source)
  self.assertFalse(self.lua.globals()._saved[CONTROL]['enabled'])
  self.assertEqual(self.value('_frame.children.Edit_1.text'),'F2')
  self.assertEqual(self.value('_frame.x'),420)
  self.runlua('xMacro.OnFrameBreathe()')
 def test_ascii_and_mouse_windows_not_dummy(self):
  for _,item in self.lua.globals()._frame['items'].items(): self.assertTrue(item['text'].isascii())
  import configparser
  cfg=configparser.ConfigParser();cfg.read(ADDON/'HoldKey.ini')
  self.assertEqual(cfg['Drag_Title']['DummyWnd'],'0')
  self.assertEqual(cfg['XMacroHoldKeyHUD']['DummyWnd'],'0')
 def test_real_file_from_lua_to_four_key_output(self):
  with tempfile.TemporaryDirectory() as directory:
   path=Path(directory)/'control.jx3dat'
   def disk(pathname,data):
    if pathname==CONTROL: path.write_bytes(encode_data(dict(data.items())))
   self.lua.globals()._diskSave=disk
   self.online()
   self.runlua('for i=1,4 do _frame.children["Edit_"..i]:SetText(tostring(i)) end;_frame.children.Btn_On.OnLButtonClick()')
   settings=GameControl(path).poll(0)
   self.assertEqual(settings.keys,(49,50,51,52))
   native=Mock();game=GameTarget(1,2,'game',3)
   native.games.return_value=[game];native.identity.return_value=game;native.post_key.return_value=True
   state=ConfiguredRepeater(native);self.assertEqual(state.tick(settings,0),2)
   self.assertEqual([call.args[1] for call in native.post_key.call_args_list],[49,50,51,52])

 def test_loaded_addon_registers_only_key_spam_toggle(self):
  from simulator.engine import JX3Simulator
  sim=JX3Simulator()
  sim.lua.execute(self.source)
  self.assertEqual(list(sim.lua.globals()._tKeyBindings.keys()),['XMACRO_KEY_SPAM_TOGGLE'])
  # The optional legacy entry must not resurrect removed menu actions either.
  legacy=(ADDON/'xMacro.lua').read_text('utf-8-sig')
  self.assertNotIn('Hotkey.AddBinding(',legacy)

 def test_one_toggle_registration_and_distinct_label(self):
  self.assertIsNone(self.lua.globals()._bindings['XMACRO_KEY_SPAM_START'])
  self.assertIsNone(self.lua.globals()._bindings['XMACRO_KEY_SPAM_STOP'])
  self.assertEqual(self.value('_bindings.XMACRO_KEY_SPAM_TOGGLE.group'),'xMacro - Key Spam BAT/TAT')
 def test_toggle_press_starts_next_press_stops_without_repeat_flipping(self):
  self.online()
  self.runlua('for i=1,4 do _frame.children["Edit_"..i]:SetText(tostring(i)) end; _bindings.XMACRO_KEY_SPAM_TOGGLE.callback()')
  data=self.lua.globals()._saved[CONTROL]
  self.assertTrue(data['enabled'])
  self.assertEqual([data['key_'+str(i)] for i in range(1,5)],[49,50,51,52])
  run_id=data['run_id']
  self.runlua('for i=1,10 do _bindings.XMACRO_KEY_SPAM_TOGGLE.callback() end')
  self.assertTrue(self.lua.globals()._saved[CONTROL]['enabled'])
  self.assertEqual(self.lua.globals()._saved[CONTROL]['run_id'],run_id)
  self.runlua('_bindings.XMACRO_KEY_SPAM_TOGGLE.release();_bindings.XMACRO_KEY_SPAM_TOGGLE.callback()')
  self.assertFalse(self.lua.globals()._saved[CONTROL]['enabled'])
  self.runlua('_bindings.XMACRO_KEY_SPAM_TOGGLE.release();_bindings.XMACRO_KEY_SPAM_TOGGLE.callback()')
  self.assertTrue(self.lua.globals()._saved[CONTROL]['enabled'])
 def test_toggle_stops_minimized_even_offline(self):
  self.online()
  self.runlua('_bindings.XMACRO_KEY_SPAM_TOGGLE.callback();_bindings.XMACRO_KEY_SPAM_TOGGLE.release();xMacro.HoldKey.ToggleMini();_now=4000;xMacro.HoldKey.Tick();_bindings.XMACRO_KEY_SPAM_TOGGLE.callback()')
  self.assertFalse(self.lua.globals()._saved[CONTROL]['enabled'])
  self.assertEqual(self.value('_frame.height'),76)
 def test_toggle_start_requires_helper_and_can_retry_next_press(self):
  self.runlua('_bindings.XMACRO_KEY_SPAM_TOGGLE.callback();_bindings.XMACRO_KEY_SPAM_TOGGLE.release()')
  self.assertFalse(self.lua.globals()._saved[CONTROL]['enabled'])
  self.assertIn('OFFLINE',self.value('_frame.items.Text_Notice.text'))
  self.online()
  self.runlua('_bindings.XMACRO_KEY_SPAM_TOGGLE.callback()')
  self.assertTrue(self.lua.globals()._saved[CONTROL]['enabled'])

class FileTests(unittest.TestCase):
 def fields(self,**changes):
  data=dict(version=2,enabled=True,interval_ms=50,run_id=1,key_1=49,key_2=0,key_3=65,key_4=0)
  data.update(changes);return data
 def test_native_config_allows_no_keys_and_disables_external_key_output(self):
  settings=parse_control(encode_data(self.fields(native_macro=True,key_1=0,key_3=0)))
  self.assertTrue(settings.native_macro)
  native=Mock();native.post_key.return_value=True
  state=ConfiguredRepeater(native)
  self.assertEqual(state.tick(settings,0),4)
  native.post_key.assert_not_called()
 def test_crc_and_empty_slots(self):
  data=self.fields();raw=encode_data(data)
  self.assertEqual(decode_data(raw),data)
  self.assertEqual(parse_control(raw),HoldSettings(True,50,(49,65),1))
 def test_legacy_migrates_stopped(self):
  self.assertFalse(parse_control(encode_data(dict(enabled=True,interval_ms=50))).enabled)
 def test_invalid_configuration_rejected(self):
  for change in [dict(key_2=49),dict(key_1=16),dict(interval_ms=1),dict(key_1=0,key_3=0),dict(run_id=0),dict(key_5=66)]:
   with self.subTest(change=change),self.assertRaises(ValueError): parse_control(encode_data(self.fields(**change)))
 def test_missing_corrupt_deleted_file_stops(self):
  with tempfile.TemporaryDirectory() as directory:
   path=Path(directory)/'control';control=GameControl(path)
   self.assertFalse(control.poll(0).enabled)
   path.write_bytes(encode_data(self.fields()));self.assertTrue(control.poll(.1).enabled)
   raw=bytearray(path.read_bytes());raw[-2]^=1;path.write_bytes(raw)
   self.assertFalse(control.poll(.2).enabled)
   path.unlink();self.assertFalse(control.poll(.3).enabled)

if __name__=='__main__': unittest.main()
