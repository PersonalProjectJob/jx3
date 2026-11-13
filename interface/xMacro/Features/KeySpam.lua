-- Native game panel and typed file bridge. Combat rotation stays in Macro.lua.
xMacro = xMacro or {}
xMacro.HoldKey = xMacro.HoldKey or {}
local hold = xMacro.HoldKey
local controlFile = "interface\\xMacro\\hold_key_control.jx3dat"
local statusFile = "interface\\xMacro\\hold_key_status.jx3dat"
local uiFile = "interface\\xMacro\\hold_key_ui.jx3dat"
local frame, enabled, runId = nil, false, 0
local uiX, uiY, mini = 260, 180, false
local keys = {"1", "", "", ""}
local notice = "Mo start_xmacro.bat mot lan."
local status, lastSeq, lastPid, seenAt = {}, nil, nil, -10000
local nextPoll, dragging = 0, nil
local nextDiagnostic=0
local function Now() return (GetTime and GetTime()) or 0 end
local function Read(path)
    if not LoadLUAData then return nil end
    local ok, data = pcall(LoadLUAData, path)
    if ok and type(data) == "table" then return data end
end
local names = {SPACE=32, TAB=9, ENTER=13, BACKSPACE=8, INSERT=45, DELETE=46,
    HOME=36, END=35, LEFT=37, UP=38, RIGHT=39, DOWN=40, PGUP=33, PGDN=34,
    ["~"]=192, ["`"]=192}
for i=48,57 do names[string.char(i)]=i end
for i=65,90 do names[string.char(i)]=i end
for i=1,24 do names["F"..i]=111+i end
local old = Read(controlFile)
if old and old.version == 2 then
    runId = tonumber(old.run_id) or 0
    for i=1,4 do
        local vk=old["key_"..i]
        keys[i]=""
        for name, code in pairs(names) do
            if code==vk then keys[i]=name; break end
        end
    end
end
local pos=Read(uiFile)
if pos and type(pos.x)=="number" and type(pos.y)=="number"
    and math.abs(pos.x)<10000 and math.abs(pos.y)<10000 then
    uiX,uiY,mini=pos.x,pos.y,pos.mini==true
end
local function Item(name) return frame and frame:Lookup("",name) end
local function Child(name) return frame and frame:Lookup(name) end
local function Text(name,text)
    local item=Item(name)
    if item then item:SetText(text) end
end
local function ButtonText(name,text)
    local button=Child(name)
    local handle=button and button:Lookup("","")
    local label=handle and handle:Lookup("Text_"..name)
    if label then label:SetText(text) end
end
local function Online() return Now()-seenAt<2000 end
local function Write(want, values)
    if not SaveLUAData then notice="Client thieu SaveLUAData."; return false end
    local data={version=2,enabled=want,interval_ms=50,run_id=runId+(want and 1 or 0)}
    for i=1,4 do data["key_"..i]=values[i] or 0 end
    local ok,result=pcall(SaveLUAData,controlFile,data)
    if not ok or result==false then notice="Loi luu lenh. Kiem tra quyen ghi."; return false end
    enabled,runId=want,data.run_id
    return true
end
local function CurrentValues()
    local values, used, count={},{},0
    for i=1,4 do
        local edit=Child("Edit_"..i)
        local text=(edit and edit:GetText()) or keys[i]
        text=string.upper(string.match(tostring(text),"^%s*(.-)%s*$"))
        local vk=text=="" and 0 or names[text]
        if not vk then return nil,"Phim "..i.." khong hop le." end
        if vk~=0 and used[vk] then return nil,"Khong gan trung phim." end
        if vk~=0 then used[vk]=true;count=count+1 end
        values[i]=vk;keys[i]=text
    end
    if count==0 then return nil,"Hay gan it nhat 1 phim." end
    return values
end
function hold.SetEnabled(want)
    local values,err=CurrentValues()
    if want and not values then notice=err
    elseif want and not Online() then notice="Helper OFFLINE: mo start_xmacro.bat."
    else
        if not values then
            values={}
            for i=1,4 do values[i]=names[keys[i]] or 0 end
        end
        if Write(want,values) then notice=want and "Da gui lenh. Dang cho helper..." or "Da gui lenh DUNG." end
    end
    hold.UpdateHUD()
    return enabled==want
end
function hold.Start()
    -- Holding the Start hotkey must not restart the run on keyboard repeat.
    if enabled then return true end
    return hold.SetEnabled(true)
end
function hold.Stop() return hold.SetEnabled(false) end
function hold.Toggle() return hold.SetEnabled(not enabled) end
-- One toggle per physical press; OS key repeat must not flip the state again.
local toggleKeyDown = false
if Hotkey and Hotkey.AddBinding then
    pcall(Hotkey.AddBinding, "XMACRO_KEY_SPAM_TOGGLE", "xMacro: Key Spam - Bat/Tat", "xMacro - Key Spam BAT/TAT",
        function()
            if toggleKeyDown then return end
            toggleKeyDown = true
            return hold.Toggle()
        end,
        function() toggleKeyDown = false end)
end
function hold.SavePosition()
    if not frame then return false end
    uiX,uiY=frame:GetRelPos()
    if SaveLUAData then
        local ok,result=pcall(SaveLUAData,uiFile,{x=uiX,y=uiY,mini=mini})
        return ok and result~=false
    end
    return false
end
function hold.UpdateHUD()
    if not frame then return end
    local live=Online()
    local label="DUNG"
    if enabled then
        label="CHO HELPER"
        if live and status.run_id==runId then
            if status.state==2 then label="DANG SPAM"
            elseif status.state==1 then label="CHO GAME"
            elseif status.state==3 then label="LOI - DUNG/BAT LAI" end
        end
    end
    Text("Text_Title","xMacro - Key Spam | Keo")
    Text("Text_Status",label.." | 50 ms")
    Text("Text_Helper",live and "Helper: ONLINE" or "Helper: OFFLINE - mo launcher")
    Text("Text_Notice",notice)
    Text("Text_Help","1-9, A-Z, F1-F24, SPACE, ~")
    Text("Text_Background","Alt+Tab van spam vao game.")
    ButtonText("Btn_On","BAT DAU")
    ButtonText("Btn_Off","DUNG")
    ButtonText("Btn_Mini",mini and "+" or "-")
    for i=1,4 do
        Text("Text_Key"..i,"Phim "..i)
        local edit=Child("Edit_"..i)
        if edit then edit:Enable(enabled and 0 or 1) end
    end
    local on,off=Child("Btn_On"),Child("Btn_Off")
    if on then on:Enable(enabled and 0 or 1) end
    -- Stop remains usable even when the helper disconnects.
    if off then off:Enable(1) end
    local h=mini and 76 or 300
    frame:SetSize(320,h)
    local bg=Item("Image_Background")
    if bg and bg.SetSize then bg:SetSize(320,h) end
    for _,name in ipairs({"Text_Helper","Text_Notice","Text_Help","Text_Background",
        "Text_Key1","Text_Key2","Text_Key3","Text_Key4",
        "Image_Edit1","Image_Edit2","Image_Edit3","Image_Edit4"}) do
        local item=Item(name)
        if item then if mini then item:Hide() else item:Show() end end
    end
    for i=1,4 do
        local edit=Child("Edit_"..i)
        if edit then if mini then edit:Hide() else edit:Show() end end
    end
    if mini then on:Hide(); off:SetRelPos(222,39);off:SetSize(86,28)
    else on:Show();off:SetRelPos(166,204);off:SetSize(142,32) end
end
function hold.ToggleMini()
    mini=not mini
    hold.UpdateHUD()
    hold.SavePosition()
end
local function Mouse()
    if Cursor and Cursor.GetPos then
        local ok,x,y=pcall(Cursor.GetPos)
        if ok and type(x)=="number" and type(y)=="number" then return x,y end
        ok,x,y=pcall(Cursor.GetPos,Cursor)
        if ok and type(x)=="number" and type(y)=="number" then return x,y end
    end
    for _,name in ipairs({"GetMessagePos","GetMousePos"}) do
        if Station and Station[name] then
            local ok,x,y=pcall(Station[name],Station)
            if ok and type(x)=="number" and type(y)=="number" then return x,y end
        end
    end
end
function hold.EndDrag()
    if dragging then dragging=nil;hold.SavePosition() end
end
function hold.BeginDrag()
    local x,y=Mouse()
    if not frame or not x then return end
    local ax,ay=frame:GetAbsPos()
    if x<ax or x>ax+276 or y<ay or y>ay+34 then return end
    local fx,fy=frame:GetRelPos()
    dragging={x=x,y=y,fx=fx,fy=fy}
end
function hold.DragTick()
    if not dragging or not frame then return end
    local fn=Station and (Station.IsLButtonPressed or Station.IsLButtonDown)
    if fn then
        local ok,down=pcall(fn,Station)
        if ok and down==false then hold.EndDrag();return end
    end
    local x,y=Mouse()
    if x then
        frame:SetRelPos(dragging.fx+x-dragging.x,dragging.fy+y-dragging.y)
        if frame.CorrectPos then frame:CorrectPos() end
    end
end
function hold.EnsureHUD()
    if not (Wnd and Wnd.OpenWindow) then return false end
    if GetClientPlayer and not GetClientPlayer() then return false end
    local current=Station and Station.Lookup and Station.Lookup("Normal/XMacroHoldKeyHUD")
    if frame and current==frame then return true end
    if current and not current:Lookup("Btn_Mini") and Wnd.CloseWindow then
        pcall(Wnd.CloseWindow,current)
        current=nil
    end
    frame=current or Wnd.OpenWindow("interface/xMacro/HoldKey.ini","XMacroHoldKeyHUD")
    if not frame then return false end
    frame:SetRelPos(uiX,uiY)
    if frame.SetDummyWnd then frame:SetDummyWnd(false) end
    if frame.EnableDrag then frame:EnableDrag(true) end
    if frame.SetDragArea then
        pcall(frame.SetDragArea,frame,0,0,276,34)
        pcall(frame.SetDragArea,frame,276,34)
    end
    local on,off,small=Child("Btn_On"),Child("Btn_Off"),Child("Btn_Mini")
    if not on or not off or not small then frame=nil;return false end
    on.OnLButtonClick=function() hold.Start() end
    off.OnLButtonClick=function() hold.Stop() end
    small.OnLButtonClick=hold.ToggleMini
    for i=1,4 do
        local edit=Child("Edit_"..i)
        if not edit then frame=nil;return false end
        edit:SetText(keys[i])
    end
    for _,wnd in ipairs({frame,Child("Drag_Title")}) do
        wnd.OnLButtonDown=hold.BeginDrag
        wnd.OnLButtonUp=hold.EndDrag
        wnd.OnMouseMove=hold.DragTick
        wnd.OnFrameDrag=hold.DragTick
        wnd.OnFrameDragEnd=function() dragging=nil;hold.SavePosition() end
    end
    frame:Show()
    hold.UpdateHUD()
    return true
end
function hold.Tick()
    hold.DragTick()
    local now=Now()
    if now<nextPoll then return end
    nextPoll=now+250
    if now>=nextDiagnostic and SaveLUAData and xMacro.VanHoaDiagnostics then
        nextDiagnostic=now+1000
        pcall(SaveLUAData,"interface\\xMacro\\vanhoa_status.jx3dat",xMacro.VanHoaDiagnostics)
    end
    local data=Read(statusFile)
    if data and type(data.seq)=="number" and type(data.pid)=="number" then
        if lastPid==data.pid and lastSeq~=nil and lastSeq~=data.seq then seenAt=now end
        if lastPid~=data.pid then seenAt=-10000 end
        lastSeq,lastPid,status=data.seq,data.pid,data
    end
    local ok, result=pcall(hold.EnsureHUD)
    if not ok and not hold.uiError then
        hold.uiError=tostring(result)
        if OutputMessage then
            pcall(OutputMessage,"MSG_SYS","[xMacro Key Spam] UI_ERROR: "..hold.uiError.."\n")
        end
    elseif ok and result then
        hold.uiError=nil
        hold.UpdateHUD()
    end
end
-- Breathe already runs on the addon's existing frame; render callbacks vary by client.
if not xMacro._HoldBreatheInstalled then
    xMacro._HoldOriginalBreathe=xMacro.OnFrameBreathe
    xMacro._HoldBreatheInstalled=true
end
function xMacro.OnFrameBreathe(...)
    if xMacro._HoldOriginalBreathe then xMacro._HoldOriginalBreathe(...) end
    hold.Tick()
end
if RegisterEvent then
    for _,event in ipairs({"PLAYER_ENTER_GAME","PLAYER_ENTER_SCENE","LOADING_END","RENDER_FRAME_UPDATE"}) do
        pcall(RegisterEvent,event,hold.Tick)
    end
end
-- Reload always stops the old run; saved bindings are preserved.
local initial={}
for i=1,4 do initial[i]=names[keys[i]] or 0 end
Write(false,initial)
hold.Tick()
