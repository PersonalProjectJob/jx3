-- =============================================================================
-- xMacro.lua (v1.0)
-- He thong Macro Doc Lap Backup cho JX3 / Kiem Vong 3 (Patch 80 / v2.5.2)
-- Ho tro cu phap chuan /cast, /skill, /use kem dieu kien [buff/debuff/life/mana/cd]
-- Goi truc tiep OnAddOnUseSkill khong qua engine C++ goc hay cac bo dem bytecode
-- =============================================================================

xMacro = xMacro or {
	bEnable        = true,
	bAutoLoop      = false,
	nInterval      = 100,        -- Chu ky lap lai khi bat Auto (ms)
	nLastTick      = 0,
	szCurrentMacro = "vanhoa_pve",
	tMacros        = {},
	tSkillCache    = {},         -- [szName] = dwID, [dwID] = szName
	tBuffCache     = {},
	nCastCount     = 0,
	szLastCasted   = "",
}

local _XM = {
	bInitialized = false,
	hFrame       = nil,
	uiTxtStatus  = nil,
}

-- =============================================================================
-- Bang ky nang & Buff mac dinh cua Mon phai Van Hoa (v80)
-- =============================================================================
local VANHOA_SKILLS = {
	["Dương Minh Chỉ"]    = 179, ["Duong Minh Chi"]    = 179, ["duong minh"]  = 179,
	["Thương Dương Chỉ"]  = 180, ["Thuong Duong Chi"]  = 180, ["thuong duong"]= 180,
	["Thiếu Dương Chỉ"]   = 181, ["Thieu Duong Chi"]   = 181, ["thieu duong"] = 181,
	["Ngọc Thạch Câu Phần"]= 182,["Ngoc Thach Cau Phan"]= 182,["ngoc thach"]   = 182,
	["Quyết Âm Chỉ"]      = 183, ["Quyet Am Chi"]      = 183, ["quyet am"]    = 183,
	["Thiếu Minh Chỉ"]    = 184, ["Thieu Minh Chi"]    = 184,
	["Phù Dung Tịnh Đế"]  = 186, ["Phu Dung Tinh De"]  = 186, ["Phù Dung Châm"] = 186,
	["Chung Linh Dục Tú"] = 189, ["Chung Linh Duc Tu"] = 189, ["chung linh"]  = 189,
	["Lan Thôi Ngọc Chiết"]= 190,["Lan Thoi Ngoc Chiet"]= 190,["lan thoi"]    = 190, ["Lan Tồi Thính Phong"] = 190,
	["Bích Thủy Thao Thiên"]= 131,["Bich Thuy Thao Thien"]= 131,
	["Xuân Nê Hộ Hoa"]    = 132, ["Xuan Ne Ho Hoa"]    = 132, ["xuan ne"]     = 132,
	["Thủy Nguyệt Vô Gian"]= 136,["Thuy Nguyet Vo Gian"]= 136,
}

local VANHOA_BUFFS = {
	["Thương Dương Chỉ"]  = 666, ["Thuong Duong Chi"]  = 666, [180] = 666,
	["Chung Linh Dục Tú"] = 714, ["Chung Linh Duc Tu"] = 714, [189] = 714,
	["Lan Thôi Ngọc Chiết"]= 711,["Lan Thoi Ngoc Chiet"]= 711, [190] = 711,
	["Xuân Nê Hộ Hoa"]    = 631, ["Xuan Ne Ho Hoa"]    = 631, [132] = 631,
}

-- =============================================================================
-- Macro mac dinh: PVE Van Hoa cap 28 - 80
-- =============================================================================
local DEFAULT_VANHOA_MACRO = [[
/cast [life<0.60] Xuân Nê Hộ Hoa
/cast [tnobuff:Thương Dương Chỉ] Thương Dương Chỉ
/cast [tnobuff:Chung Linh Dục Tú] Chung Linh Dục Tú
/cast [tbuff:Thương Dương Chỉ&tbuff:Chung Linh Dục Tú] Ngọc Thạch Câu Phần
/cast Dương Minh Chỉ
]]

-- =============================================================================
-- Ham in thong bao ra he thong chat
-- =============================================================================
function xMacro.Print(szMsg)
	if OutputMessage then
		pcall(OutputMessage, "MSG_SYS", "[xMacro] " .. tostring(szMsg) .. "\n")
	end
end

-- =============================================================================
-- Khoi tao Cache Ky Nang tu Client
-- =============================================================================
function xMacro.InitSkillCache()
	-- 1. Nap bang tay cac skill pho bien
	for szName, dwID in pairs(VANHOA_SKILLS) do
		xMacro.tSkillCache[szName] = dwID
		xMacro.tSkillCache[string.lower(szName)] = dwID
		xMacro.tSkillCache[dwID] = szName
	end

	for szName, dwID in pairs(VANHOA_BUFFS) do
		xMacro.tBuffCache[szName] = dwID
		xMacro.tBuffCache[string.lower(tostring(szName))] = dwID
	end

	-- 2. Quet he thong game bang Table_GetSkillName neu co
	if Table_GetSkillName then
		for id = 1, 3500 do
			local ok, name = pcall(Table_GetSkillName, id, 1)
			if ok and name and type(name) == "string" and name ~= "" then
				xMacro.tSkillCache[name] = id
				xMacro.tSkillCache[string.lower(name)] = id
				if not xMacro.tSkillCache[id] then
					xMacro.tSkillCache[id] = name
				end
			end
		end
	end
end

-- =============================================================================
-- Phan giai ten Skill sang dwSkillID
-- =============================================================================
function xMacro.ResolveSkillID(szSkill)
	if not szSkill then return nil end
	local nID = tonumber(szSkill)
	if nID and nID > 0 then return nID end

	local clean = string.gsub(szSkill, "^%s*(.-)%s*$", "%1")
	if xMacro.tSkillCache[clean] then
		return xMacro.tSkillCache[clean]
	end
	local lower = string.lower(clean)
	if xMacro.tSkillCache[lower] then
		return xMacro.tSkillCache[lower]
	end

	-- Tim kiem gan dung trong cache
	for k, v in pairs(xMacro.tSkillCache) do
		if type(k) == "string" and (string.find(k, clean) or string.find(clean, k)) then
			return v
		end
	end
	return nil
end

-- =============================================================================
-- Phan giai ten Buff sang dwBuffID
-- =============================================================================
function xMacro.ResolveBuffID(szBuff)
	if not szBuff then return nil end
	local nID = tonumber(szBuff)
	if nID and nID > 0 then return nID end

	local clean = string.gsub(szBuff, "^%s*(.-)%s*$", "%1")
	if xMacro.tBuffCache[clean] then
		return xMacro.tBuffCache[clean]
	end
	local lower = string.lower(clean)
	if xMacro.tBuffCache[lower] then
		return xMacro.tBuffCache[lower]
	end

	-- Thu tra qua SkillCache
	local skID = xMacro.ResolveSkillID(szBuff)
	if skID and VANHOA_BUFFS[skID] then
		return VANHOA_BUFFS[skID]
	end
	return nil
end

-- =============================================================================
-- Lay doi tuong Muc tieu (Target) hien tai
-- =============================================================================
function xMacro.GetTargetObject(me)
	if not me or not me.GetTarget then return nil end
	local ok, tarType, tarID = pcall(me.GetTarget)
	if not ok or not tarID or tarID == 0 then return nil end

	if (tarType == 3 or tarType == TARGET.NPC) and GetNpc then
		local okNpc, npc = pcall(GetNpc, tarID)
		if okNpc and npc then return npc end
	elseif (tarType == 1 or tarType == 2 or tarType == TARGET.PLAYER) and GetPlayer then
		local okPl, pl = pcall(GetPlayer, tarID)
		if okPl and pl then return pl end
	end
	if GetNpc then
		local okNpc, npc = pcall(GetNpc, tarID)
		if okNpc and npc then return npc end
	end
	if GetPlayer then
		local okPl, pl = pcall(GetPlayer, tarID)
		if okPl and pl then return pl end
	end
	return nil
end

-- =============================================================================
-- Kiem tra Buff tren nguoi Nhan vat hoac Muc tieu
-- =============================================================================
function xMacro.HasBuff(obj, buffIdentifier)
	if not obj or not buffIdentifier then return false end
	local dwTargetBuffID = xMacro.ResolveBuffID(buffIdentifier)

	local ok, tBuffList = pcall(function() return obj.GetBuffList() end)
	if not ok or type(tBuffList) ~= "table" then return false end

	for _, buff in ipairs(tBuffList) do
		if dwTargetBuffID and buff.dwID == dwTargetBuffID then
			return true
		end
		-- Kiem tra theo ten neu co Table_GetBuffName
		if Table_GetBuffName and type(buffIdentifier) == "string" then
			local okName, bName = pcall(Table_GetBuffName, buff.dwID, buff.nLevel or 1)
			if okName and bName and string.find(bName, buffIdentifier) then
				return true
			end
		end
	end
	return false
end

-- =============================================================================
-- Kiem tra Ky Nang co the thi trien (Level > 0 & Cooldown = 0)
-- =============================================================================
function xMacro.CanCastSkill(me, dwSkillID)
	if not me or not dwSkillID then return false end

	-- 1. Kiem tra cap do skill
	local okLvl, dwLevel = pcall(me.GetSkillLevel, dwSkillID)
	if not okLvl or not dwLevel or dwLevel <= 0 then
		return false
	end

	-- 2. Kiem tra Cooldown qua GetSkillCDProgress
	if me.GetSkillCDProgress then
		local okCd, bCool, nLeft = pcall(me.GetSkillCDProgress, dwSkillID, dwLevel)
		if okCd and bCool and nLeft and nLeft > 0 then
			return false
		end
	end

	-- 3. Fallback kiem tra qua HM neu co
	if HM and HM.CanUseSkill then
		local okHM, bCan = pcall(HM.CanUseSkill, dwSkillID)
		if okHM and bCan == false then
			return false
		end
	end

	return true
end

-- =============================================================================
-- Bo phan tich & Kiem tra Dieu kien Macro ([cond1&cond2,cond3])
-- =============================================================================
function xMacro.EvalCondition(szCond, me, tar)
	if not szCond or szCond == "" then return true end

	-- Phan tach cac dieu kien boi dau & hoac dau phay
	for cond in string.gmatch(szCond, "[^&,]+") do
		cond = string.gsub(cond, "^%s*(.-)%s*$", "%1")
		if cond ~= "" then
			-- 1. life < X hoac life > X
			local opLife, valLife = string.match(cond, "^life%s*([<>]=?)%s*([%d%.]+)$")
			if opLife and valLife then
				local nThreshold = tonumber(valLife)
				if nThreshold > 1 then nThreshold = nThreshold / 100 end
				local curLife = me.nCurrentLife or 1
				local maxLife = me.nMaxLife or 1
				local pctLife = maxLife > 0 and (curLife / maxLife) or 1
				if opLife == "<" and not (pctLife < nThreshold) then return false end
				if opLife == "<=" and not (pctLife <= nThreshold) then return false end
				if opLife == ">" and not (pctLife > nThreshold) then return false end
				if opLife == ">=" and not (pctLife >= nThreshold) then return false end

			-- 2. mana < X hoac mana > X
			elseif string.find(cond, "^mana") then
				local opMana, valMana = string.match(cond, "^mana%s*([<>]=?)%s*([%d%.]+)$")
				if opMana and valMana then
					local nThreshold = tonumber(valMana)
					if nThreshold > 1 then nThreshold = nThreshold / 100 end
					local curMana = me.nCurrentMana or 1
					local maxMana = me.nMaxMana or 1
					local pctMana = maxMana > 0 and (curMana / maxMana) or 1
					if opMana == "<" and not (pctMana < nThreshold) then return false end
					if opMana == "<=" and not (pctMana <= nThreshold) then return false end
					if opMana == ">" and not (pctMana > nThreshold) then return false end
					if opMana == ">=" and not (pctMana >= nThreshold) then return false end
				end

			-- 3. tnobuff:DebuffName (Muc tieu CHUA co debuff)
			elseif string.find(cond, "^tnobuff:") then
				local szBuff = string.match(cond, "^tnobuff:(.+)$")
				if not tar then return false end
				if xMacro.HasBuff(tar, szBuff) then return false end

			-- 4. tbuff:DebuffName (Muc tieu DA co debuff)
			elseif string.find(cond, "^tbuff:") then
				local szBuff = string.match(cond, "^tbuff:(.+)$")
				if not tar then return false end
				if not xMacro.HasBuff(tar, szBuff) then return false end

			-- 5. nobuff:BuffName (Ban than CHUA co buff)
			elseif string.find(cond, "^nobuff:") then
				local szBuff = string.match(cond, "^nobuff:(.+)$")
				if xMacro.HasBuff(me, szBuff) then return false end

			-- 6. buff:BuffName (Ban than DA co buff)
			elseif string.find(cond, "^buff:") then
				local szBuff = string.match(cond, "^buff:(.+)$")
				if not xMacro.HasBuff(me, szBuff) then return false end

			-- 7. cd:SkillName / nocd:SkillName
			elseif string.find(cond, "^cd:") then
				local szSk = string.match(cond, "^cd:(.+)$")
				local skID = xMacro.ResolveSkillID(szSk)
				if skID and xMacro.CanCastSkill(me, skID) then return false end
			elseif string.find(cond, "^nocd:") then
				local szSk = string.match(cond, "^nocd:(.+)$")
				local skID = xMacro.ResolveSkillID(szSk)
				if skID and not xMacro.CanCastSkill(me, skID) then return false end

			-- 8. fight / nofight
			elseif cond == "fight" then
				if not me.bFightState then return false end
			elseif cond == "nofight" then
				if me.bFightState then return false end

			-- 9. tprepare (muc tieu dang doc chieu / van khi)
			elseif cond == "tprepare" then
				if not tar or not tar.bPrepareSkill then return false end
			end
		end
	end
	return true
end

-- =============================================================================
-- Thuc thi 1 dong lenh Macro
-- =============================================================================
function xMacro.ExecuteLine(szLine, me, tar)
	if not szLine or szLine == "" then return false end
	local clean = string.gsub(szLine, "^%s*(.-)%s*$", "%1")
	if clean == "" or string.sub(clean, 1, 1) == "#" or string.sub(clean, 1, 2) == "--" then
		return false
	end

	-- Trich xuat phan lenh (/cast, /skill, /use) va phan dieu kien [cond]
	local szCmd, szRest = string.match(clean, "^/(%a+)%s*(.*)$")
	if not szCmd then return false end
	szCmd = string.lower(szCmd)

	local szCond = nil
	local szArg = szRest

	if string.sub(szRest, 1, 1) == "[" then
		local c, a = string.match(szRest, "^%[([^%]]+)%]%s*(.*)$")
		if c then
			szCond = c
			szArg = a
		end
	end
	szArg = string.gsub(szArg, "^%s*(.-)%s*$", "%1")

	-- Kiem tra dieu kien logic
	if szCond and not xMacro.EvalCondition(szCond, me, tar) then
		return false
	end

	-- Xu ly cac loai lenh
	if szCmd == "cast" or szCmd == "skill" then
		local dwSkillID = xMacro.ResolveSkillID(szArg)
		if not dwSkillID then
			-- Thu tonumber truc tiep
			dwSkillID = tonumber(szArg)
		end

		if not dwSkillID then
			return false
		end

		-- Kiem tra hoi chieu & cap do
		if not xMacro.CanCastSkill(me, dwSkillID) then
			return false
		end

		-- Thi trien ky nang qua OnAddOnUseSkill
		local dwLevel = (me.GetSkillLevel and me.GetSkillLevel(dwSkillID)) or 1
		if dwLevel <= 0 then dwLevel = 1 end

		local bCasted = false
		if OnAddOnUseSkill then
			local ok = pcall(OnAddOnUseSkill, dwSkillID, dwLevel)
			if ok then bCasted = true end
		end
		if not bCasted and OnUseSkill then
			local ok = pcall(OnUseSkill, dwSkillID, dwLevel)
			if ok then bCasted = true end
		end
		if not bCasted and CastSkill then
			local ok = pcall(CastSkill, dwSkillID, dwLevel)
			if ok then bCasted = true end
		end

		if bCasted then
			xMacro.nCastCount = xMacro.nCastCount + 1
			xMacro.szLastCasted = szArg .. " (#" .. tostring(dwSkillID) .. ")"
			return true
		end

	elseif szCmd == "use" then
		if OnUseItem then
			pcall(OnUseItem, szArg)
			return true
		end
	end

	return false
end

-- =============================================================================
-- Thuc thi Macro hien tai (Mot lan bam)
-- =============================================================================
function xMacro.Execute()
	local me = GetClientPlayer and GetClientPlayer()
	if not me then return false end
	if me.nMoveState == MOVE_STATE.ON_DEATH then return false end

	local tar = xMacro.GetTargetObject(me)
	local szMacro = xMacro.tMacros[xMacro.szCurrentMacro] or DEFAULT_VANHOA_MACRO

	for line in string.gmatch(szMacro, "[^\r\n]+") do
		local bExecuted = xMacro.ExecuteLine(line, me, tar)
		if bExecuted then
			return true
		end
	end
	return false
end

-- =============================================================================
-- Bat / Tat Che do Auto Loop (Lap lai lien tuc trong combat)
-- =============================================================================
function xMacro.ToggleAuto()
	xMacro.bAutoLoop = not xMacro.bAutoLoop
	local szState = xMacro.bAutoLoop and "BAT (Dang tu dong danh)" or "TAT (Dung tu dong)"
	xMacro.Print("Che do Auto Macro: " .. szState)
	if _XM.uiTxtStatus then
		_XM.uiTxtStatus:SetText("xMacro: " .. szState)
	end
end

-- =============================================================================
-- Vong lap Heartbeat / Breathe
-- =============================================================================
function xMacro.OnBreathe()
	if not xMacro.bAutoLoop then return end

	local nNow = GetTime()
	if nNow - xMacro.nInterval < xMacro.nLastTick then
		return
	end
	xMacro.nLastTick = nNow

	xMacro.Execute()
end

-- =============================================================================
-- Xu ly lenh Chat Slash Command (/xmacro, /xm)
-- =============================================================================
function xMacro.OnCommand(szParam)
	szParam = szParam or ""
	local clean = string.gsub(szParam, "^%s*(.-)%s*$", "%1")
	local cmd, arg = string.match(clean, "^(%S+)%s*(.*)$")
	cmd = cmd and string.lower(cmd) or ""

	if cmd == "auto" or cmd == "loop" then
		xMacro.ToggleAuto()
	elseif cmd == "help" or cmd == "?" then
		xMacro.Print("=== HUONG DAN SU DUNG xMacro ===")
		xMacro.Print("/xmacro : Thuc thi macro 1 lan")
		xMacro.Print("/xmacro auto : Bat/Tat che do Auto Macro lien tuc")
		xMacro.Print("/xmacro reset : Dat lai macro mac dinh (Van Hoa PVE)")
		xMacro.Print("Phim tat: ESC -> Cai dat phim tat -> [xMacro] -> Gan phim ~ hoac 1")
	elseif cmd == "reset" then
		xMacro.tMacros[xMacro.szCurrentMacro] = DEFAULT_VANHOA_MACRO
		xMacro.Print("Da dat lai Macro ve Van Hoa PVE chuan.")
	else
		-- Mac dinh khong co tham so thi thuc thi macro 1 lan
		local ok = xMacro.Execute()
		if not ok and clean ~= "" then
			xMacro.Print("Khong co ky nang nao san sang hoac khong du dieu kien.")
		end
	end
end

-- =============================================================================
-- Tao Floating HUD nho thong bao trang thai
-- =============================================================================
function xMacro.CreateHUD()
	if _XM.hFrame then return end
	if not (HM and HM.UI and HM.UI.CreateFrame) then return end

	local frm = HM.UI.CreateFrame("xMacro_HUD", {
		w = 200, h = 55,
		x = 10, y = 140,
		title = "xMacro (Backup)",
		drag = true,
		close = false
	})
	_XM.hFrame = frm

	_XM.uiTxtStatus = frm:Append("Text", "Txt_Status", {
		txt = "xMacro: SAN SANG (Phim ~)",
		x = 10, y = 5, w = 180, h = 20, font = 27
	})

	frm:Append("WndButton", "Btn_Exec", {
		txt = "Danh 1 Lan",
		x = 10, y = 26, w = 85, h = 22
	}):Click(function()
		xMacro.Execute()
	end)

	frm:Append("WndButton", "Btn_Auto", {
		txt = "Auto On/Off",
		x = 100, y = 26, w = 90, h = 22
	}):Click(function()
		xMacro.ToggleAuto()
	end)
end

-- =============================================================================
-- Dang ky Su kien & Khoi dong Addon
-- =============================================================================
function xMacro.Init()
	if _XM.bInitialized then return end
	_XM.bInitialized = true

	-- 1. Khoi tao Cache Ky Nang & Buff
	xMacro.InitSkillCache()

	-- 2. Dang ky Macro mac dinh
	xMacro.tMacros["vanhoa_pve"] = DEFAULT_VANHOA_MACRO

	-- 3. Dang ky Slash Commands
	if AppendCommand then
		pcall(AppendCommand, "xmacro", xMacro.OnCommand)
		pcall(AppendCommand, "xm", xMacro.OnCommand)
	end

	-- 5. Dang ky Breathe Loop
	if RegisterEvent then
		pcall(RegisterEvent, "ON_BREATHE", xMacro.OnBreathe)
		pcall(RegisterEvent, "PLAYER_ENTER_SCENE", function()
			xMacro.InitSkillCache()
			xMacro.CreateHUD()
		end)
	end

	-- 6. Tao HUD neu HM da san sang
	if HM and HM.UI then
		xMacro.CreateHUD()
	end

	xMacro.Print("Khoi dong thanh cong! Go /xmacro help hoac bam phim de su dung.")
end

-- =============================================================================
-- Entry Point
-- =============================================================================
if RegisterEvent then
	RegisterEvent("LOGIN_GAME", xMacro.Init)
	RegisterEvent("LOADING_END", xMacro.Init)
end

-- Tu dong khoi chay neu load giua chung qua /reloadui
xMacro.Init()
