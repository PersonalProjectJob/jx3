-- Verified Van Hoa Hoa Gian rotation; combat policy preserved from the original.
local DEFAULT_VANHOA_MACRO = [[
#name VanHoa_HoaGian_80
#tip Macro Van Hoa Hoa Gian Du v80: No Ngoc Thach dau -> Loan Tuu (2645) danh DMC -> No Ngoc Thach cuoi buff

-- 1. Tu cuu & Sinh ton
/skill [life<0.4] Xuan Ne Ho Hoa
/skill [mana<0.4] Bich Thuy Thao Thien
/skill [tprepare] Quyet Am Chi

-- 2. Ngat Duong Minh Chi khi can thiet:
/skill [ota:Duong Minh Chi,tnobuff:Phe Cot] stopota
/skill [ota:Duong Minh Chi,tbufftime:Phe Cot<3] stopota
-- Ngat DMC de bat Loan Tuu KHI NGOC THACH VUA NO va da phu lai 2 DOT
/skill [ota:Duong Minh Chi,nocd:Loan Tuu Thanh Ha,cdtime:Ngoc Thach Cau Phan>0,mbuff:Thuong Duong Chi,mbuff:Chung Linh Duc Tu] stopota
-- Co buff Thuy Nguyet ma chua phu Lan Thoi
/skill [ota:Duong Minh Chi,buff:Thuy Nguyet Vo Gian,nombuff:Lan Thoi Ngoc Chiet] stopota
-- Dang di chuyen ma bi ket van cong DMC
/skill [ota:Duong Minh Chi,moving,nobuff:Loan Tuu Thanh Ha|Thuy Nguyet Vo Gian] stopota

-- 3. Mo man: Thuy Nguyet (off-GCD)
/skill [nocd:136,nombuff:Lan Thoi Ngoc Chiet] Thuy Nguyet Vo Gian

-- 4. Giai doan 1: Mo man phu du 3 DOT va No Ngoc Thach dot dau
/skill [buff:Thuy Nguyet Vo Gian,nombuff:Lan Thoi Ngoc Chiet] Lan Thoi Ngoc Chiet
/skill [nombuff:Thuong Duong Chi] Thuong Duong Chi
/skill [nombuff:Chung Linh Duc Tu] Chung Linh Duc Tu
/skill [mbuff:Thuong Duong Chi,mbuff:Chung Linh Duc Tu,nocd:Ngoc Thach Cau Phan,nombuff:Lan Thoi Ngoc Chiet] Lan Thoi Ngoc Chiet
/skill [mbuff:Lan Thoi Ngoc Chiet,mbuff:Thuong Duong Chi,mbuff:Chung Linh Duc Tu,nocd:Loan Tuu Thanh Ha] Ngoc Thach Cau Phan

-- 5. Giai doan 2: Kich hoat Loan Tuu Thanh Ha (2645):
-- CHI BAT KHI NGOC THACH VUA NO (dang CD) VA DA PHU DU 2 DOT (Thuong Duong & Chung Linh)
/skill [mbuff:Thuong Duong Chi,mbuff:Chung Linh Duc Tu,cdtime:Ngoc Thach Cau Phan>0] Loan Tuu Thanh Ha

-- 6. Giai doan 3: TRONG BUFF LOAN TUU (2719/2726):
-- a) Buff lai Thuong Duong & Chung Linh neu bi thieu DOT
/skill [buff:Loan Tuu Thanh Ha,nombuff:Thuong Duong Chi] Thuong Duong Chi
/skill [buff:Loan Tuu Thanh Ha,nombuff:Chung Linh Duc Tu] Chung Linh Duc Tu
-- b) Chi buff Lan Thoi khi CAN NO Ngoc Thach (cuoi buff Loan Tuu <= 2s hoac DOT sap het <= 3s)
/skill [bufftime:Loan Tuu Thanh Ha<=2,nombuff:Lan Thoi Ngoc Chiet] Lan Thoi Ngoc Chiet
/skill [buff:Loan Tuu Thanh Ha,mbufftime:Thuong Duong Chi<=3,nombuff:Lan Thoi Ngoc Chiet] Lan Thoi Ngoc Chiet
-- c) No Ngoc Thach khi da du Lan Thoi o cuoi buff Loan Tuu
/skill [bufftime:Loan Tuu Thanh Ha<=2,mbuff:Lan Thoi Ngoc Chiet,mbuff:Thuong Duong Chi] Ngoc Thach Cau Phan
/skill [buff:Loan Tuu Thanh Ha,mbufftime:Thuong Duong Chi<=3,mbuff:Lan Thoi Ngoc Chiet,mbuff:Thuong Duong Chi] Ngoc Thach Cau Phan
-- d) Khi chua can no Ngoc Thach: CHI DANH DUONG MINH CHI!
/skill [buff:Loan Tuu Thanh Ha] Duong Minh Chi

-- 7. Giai doan 4: Vong lap binh on (ngoai Loan Tuu)
/skill [tnobuff:Phe Cot;tbufftime:Phe Cot<3] Thuong Duong Chi
/skill [mbuff:Lan Thoi Ngoc Chiet,mbuff:Thuong Duong Chi,mbuff:Chung Linh Duc Tu] Ngoc Thach Cau Phan
/skill [mbuff:Thuong Duong Chi,mbuff:Chung Linh Duc Tu,nocd:Ngoc Thach Cau Phan,nombuff:Lan Thoi Ngoc Chiet] Lan Thoi Ngoc Chiet

-- 8. Di chuyen (Instant Cast - zero downtime)
/skill [moving] Thuong Duong Chi

-- 9. Main DPS Filler khi dung yen
/skill Duong Minh Chi
]]

local function Create(deps)
local CheckPrepare = deps.CheckPrepare
local GetCurrentTargetObject = deps.GetCurrentTargetObject
local XMCore_Sys = deps.XMCore_Sys
local XMCore_UseEquipSlot = deps.XMCore_UseEquipSlot
local tLastCast = deps.tLastCast
local tSkillCastFrame = deps.tSkillCastFrame
local tVanHoaCycle = {}
local nCLRequest = 0
local function CLLog(p, phase, detail)
    if p and p.skill == 189 and XMCore_Sys then
        XMCore_Sys(string.format("[xMacro CL] req=%s target=%s frame=%s %s %s",
            tostring(p.request), tostring(p.target),
            tostring((GetLogicFrameCount and GetLogicFrameCount()) or 0), phase, detail or ""))
    end
end
-- Existing client contract: DO_SKILL_CAST arg0=caster, arg1=skill.
-- This confirms the cast event only; DOT_OK separately confirms target application.
if RegisterEvent then
    RegisterEvent("DO_SKILL_CAST", function()
        local me = GetClientPlayer()
        local nt = tVanHoaCycle.nt
        if me and nt and tonumber(arg0) == tonumber(me.dwID) and tonumber(arg1) == 182 then
            local target = GetCurrentTargetObject()
            local now = (GetLogicFrameCount and GetLogicFrameCount()) or 0
            if target and target.dwID == nt.target and now >= nt.frame and now - nt.frame < 48 then
                nt.castEvent = true
            end
        end
        local p = tVanHoaCycle.clRequest
        if me and p and not p.rejected and not p.expired and not p.castEvent
            and tonumber(arg0) == tonumber(me.dwID) and tonumber(arg1) == 189 then
            p.castEvent = (GetLogicFrameCount and GetLogicFrameCount()) or 0
            CLLog(p, "CAST_EVENT", p.dotOK and "game reported skill; DOT already observed" or "game reported skill; waiting for DOT")
        end
    end)
end
if XMCore_Sys then XMCore_Sys("[xMacro] VanHoa CL guard 2 / DMC allowlist ready") end
local function Run(szName)
    local me = GetClientPlayer()
    if not me then return false end

    -- 2. Uu tien tuyet doi: Chay truc tiep Engine Workflow chuan 100% cua Game
    local tar = GetCurrentTargetObject()
    if tar and tar.nCurrentLife and tar.nCurrentLife <= 0 then tar = nil end

    local nCurFrame = (GetLogicFrameCount and GetLogicFrameCount()) or 0
    local dwTargetID = tar and tar.dwID or 0
    if tVanHoaCycle.target ~= dwTargetID or tVanHoaCycle.player ~= me.dwID then
        tVanHoaCycle = {target = dwTargetID, player = me.dwID, dots = {}, lateDots = {}, pheTries = 0}
    end
    local cycle = tVanHoaCycle
    -- One normalized snapshot per tick. A failed read is unknown, not missing DOTs.
    local targetBuffs, targetBuffsKnown = {}, false
    local buffAPI = {list_api=tar and tar.GetBuffList ~= nil or false,
        count_api=tar and tar.GetBuffCount ~= nil or false,
        slot_api=tar and tar.GetBuff ~= nil or false}
    local function BuffField(b,key)
        if type(b)=="table" then return b[key] end
        local ok,value=pcall(function() return b[key] end)
        if ok then return value end
    end
    local function AddTargetBuff(b)
        if type(b) ~= "table" and type(b) ~= "userdata" then return false end
        local function field(key) return BuffField(b,key) end
        local id=tonumber(field("dwID") or field("dwBuffID") or field("nBuffID") or field(1))
        if not id or id <= 0 then return false end
        local active=field("bValid")
        if active == nil then active=field(8) end
        table.insert(targetBuffs, {dwID=id,
            nLevel=tonumber(field("nLevel") or field("dwLevel") or field(2)) or 1,
            nEndFrame=tonumber(field("nEndFrame") or field("dwEndFrame") or field(4)),
            nStartFrame=tonumber(field("nStartFrame") or field("dwStartFrame")),
            nStackNum=tonumber(field("nStackNum") or field("dwStackNum") or field("nStackCount") or field(6)),
            dwSkillSrcID=tonumber(field("dwSkillSrcID") or field(7)),bValid=active})
        return true
    end
    if tar and tar.GetBuffList then
        local ok, list = pcall(function() return tar.GetBuffList() end)
        buffAPI.list_ok,buffAPI.list_type=ok,type(list)
        if not ok then buffAPI.list_error=tostring(list) end
        if ok and type(list) == "table" then
            for _, b in pairs(list) do
                if not buffAPI.first_type then
                    buffAPI.first_type=type(b)
                    if type(b)=="table" or type(b)=="userdata" then
                        buffAPI.first_id=tostring(BuffField(b,"dwID") or BuffField(b,"dwBuffID") or BuffField(b,"nBuffID") or BuffField(b,1))
                    end
                end
                AddTargetBuff(b)
            end
            targetBuffsKnown = next(list) == nil or #targetBuffs > 0
        elseif ok and list == nil and not (tar.GetBuffCount and tar.GetBuff) then
            -- Classic clients return nil for an empty list and expose no slot API.
            -- A successful empty result is distinct from a failed API call.
            targetBuffsKnown=true
            buffAPI.empty_nil=true
        end
    end
    if not targetBuffsKnown and tar and tar.GetBuffCount and tar.GetBuff then
        local ok, count = pcall(function() return tar.GetBuffCount() end)
        buffAPI.count_ok,buffAPI.count_type,buffAPI.count_value=ok,type(count),tostring(count)
        if ok and type(count) == "number" and count >= 0 and count <= 1024 then
            local readable, found = true, 0
            -- Include count for one-based clients. Empty slots are not read errors.
            for i=0,(count > 0 and count or -1) do
                local valid, id, level, cancel, ending, index, stack, source, active = pcall(function()
                    return tar.GetBuff(i)
                end)
                if i == 0 then
                    buffAPI.slot0_ok,buffAPI.slot0_type=valid,type(id)
                    buffAPI.slot0_value=(type(id)=="number" or type(id)=="nil") and tostring(id) or type(id)
                end
                if not valid then
                    buffAPI.slot_error=tostring(id)
                    -- Legacy clients reject either edge depending on index base.
                    if i ~= 0 and i ~= count then readable=false;break end
                elseif id then
                    local added
                    if type(id)=="table" or type(id)=="userdata" then added=AddTargetBuff(id)
                    else added=AddTargetBuff({dwID=id,nLevel=level,nEndFrame=ending,nStackNum=stack,dwSkillSrcID=source,bValid=active}) end
                    if added then found=found+1 end
                end
            end
            targetBuffsKnown=readable and (count == 0 or found > 0)
        end
    end
    buffAPI.normalized_count=#targetBuffs
    if tar and not targetBuffsKnown and not cycle.buffReadFailed then
        cycle.buffReadFailed = true
        CLLog(cycle.clRequest, "BUFF_READ_UNKNOWN", "cannot conclude DOT absent; retries paused")
    elseif targetBuffsKnown then cycle.buffReadFailed = nil end
    local function TargetBuff(dwBuffID, szBuffName)
        for _, b in pairs(targetBuffs) do
            local src = b.dwSkillSrcID or 0
            local ownDOT = dwBuffID == 666 or dwBuffID == 714 or dwBuffID == 711 or dwBuffID == 715
            if b.bValid ~= false and (not ownDOT or src == 0 or src == tonumber(me.dwID))
                and (not b.nEndFrame or b.nEndFrame <= 0 or b.nEndFrame > nCurFrame) then
                local match = b.dwID == dwBuffID
                if not match and szBuffName and Table_GetBuffName then
                    local okName, name = pcall(Table_GetBuffName, b.dwID, b.nLevel)
                    match = okName and name and (name == szBuffName or string.find(name, szBuffName, 1, true))
                end
                if match then return b end
            end
        end
    end
    local function HasTargetBuff(dwBuffID, szBuffName)
        return TargetBuff(dwBuffID, szBuffName) ~= nil
    end

    local function HasTargetLanThoi()
        return HasTargetBuff(711, "Lan Thoi") or HasTargetBuff(715, "Lan Toi") or HasTargetBuff(711, "兰摧玉折")
    end

    local function AppliedDOT(skill)
        if skill == 180 then return TargetBuff(666) end
        if skill == 189 then return TargetBuff(714, "Chung Linh") end
        if skill == 190 then return TargetBuff(711) or TargetBuff(715) end
    end

    local function GetTargetBuffTime(dwBuffID, szBuffName)
        local b = TargetBuff(dwBuffID, szBuffName)
        if b and b.nEndFrame and nCurFrame > 0 then
            return math.max(0, (b.nEndFrame - nCurFrame) / 16.0)
        end
        return 0
    end

    local function GetTargetLanThoiTime()
        local t1 = GetTargetBuffTime(711, "Lan Thoi")
        local t2 = GetTargetBuffTime(715, "Lan Toi")
        return (t1 > t2) and t1 or t2
    end

    local function HasPlayerBuff(dwBuffID, szBuffName)
        if not me then return false end
        if me.GetBuffList then
            local ok, list = pcall(function() return me.GetBuffList() end)
            if ok and list and type(list) == "table" then
                local nCurFrame = (GetLogicFrameCount and GetLogicFrameCount()) or 0
                for _, b in pairs(list) do
                    if b and b.dwID then
                        local bActive = true
                        if b.nEndFrame and nCurFrame > 0 and b.nEndFrame > 0 then
                            if b.nEndFrame <= nCurFrame then
                                bActive = false
                            end
                        end
                        if bActive then
                            if b.dwID == dwBuffID then return true end
                            if szBuffName and Table_GetBuffName then
                                local okName, name = pcall(Table_GetBuffName, b.dwID, b.nLevel or 1)
                                if okName and name and (name == szBuffName or string.find(name, szBuffName)) then
                                    return true
                                end
                            end
                        end
                    end
                end
            end
        end
        return false
    end

    local function GetPlayerBuffTime(dwBuffID, szBuffName)
        if not me then return 0 end
        if me.GetBuffList then
            local ok, list = pcall(function() return me.GetBuffList() end)
            if ok and list and type(list) == "table" then
                local nCurFrame = (GetLogicFrameCount and GetLogicFrameCount()) or 0
                for _, b in pairs(list) do
                    if b and b.dwID then
                        local bMatch = (b.dwID == dwBuffID)
                        if not bMatch and szBuffName and Table_GetBuffName then
                            local okName, name = pcall(Table_GetBuffName, b.dwID, b.nLevel or 1)
                            if okName and name and (name == szBuffName or string.find(name, szBuffName)) then
                                bMatch = true
                            end
                        end
                        if bMatch and b.nEndFrame and nCurFrame > 0 then
                            local nLeft = (b.nEndFrame - nCurFrame) / 16.0
                            return (nLeft > 0) and nLeft or 0
                        end
                    end
                end
            end
        end
        return 0
    end

    -- Loan Tuu Thanh Ha (乱洒青荷): ID that lay tu bang skill trong client v2.5.2
    --   Skill 2645 | Buff 2719 = +40% cong noi hon nguyen (15s) | Buff 2726 = 3 luot thi trien tuc thoi
    local LT_SKILL_ID = 2645
    local function HasThuyNguyetBuff()
        return HasPlayerBuff(412) or HasPlayerBuff(645)
    end
    local function HasLoanTuuBuff()
        return HasPlayerBuff(2719) or HasPlayerBuff(2726)
    end
    local function GetLoanTuuBuffTime()
        if HasPlayerBuff(2719) then return GetPlayerBuffTime(2719) end
        return GetPlayerBuffTime(2726)
    end

    local function IsSkillReady(dwSkillID)
        if not dwSkillID or dwSkillID <= 0 then return false end
        -- Chua hoc skill (level 0) -> khong bao gio coi la san sang (tranh spam lenh vo hieu)
        if me.GetSkillLevel then
            local okL, nLvl = pcall(function() return me.GetSkillLevel(dwSkillID) end)
            if okL and tonumber(nLvl or 0) <= 0 then return false end
        end
        local last = tSkillCastFrame[dwSkillID]
        if last and nCurFrame >= last and nCurFrame - last < 4 then return false end
        -- Chong spam: skill off-GCD vua gui lenh < 1.5s ma chua vao CD -> server da tu choi, nhuong cho rotation
        if dwSkillID == LT_SKILL_ID or dwSkillID == 136 then
            local nLast = tSkillCastFrame[dwSkillID]
            local nNow = (GetLogicFrameCount and GetLogicFrameCount()) or 0
            if nLast and nNow > 0 and (nNow - nLast) >= 0 and (nNow - nLast) < 24 then return false end
        end
        if me.GetSkillCDProgress then
            local ok, bCool, nLeft = pcall(function() return me.GetSkillCDProgress(dwSkillID, 1) end)
            if ok and bCool and tonumber(nLeft or 0) > 0 then
                return false
            end
        end
        return true
    end

    local function IsGCD()
        if me.GetSkillCDProgress then
            local ok, bCool, nLeft = pcall(function() return me.GetSkillCDProgress(53, 1) end)
            if ok and bCool and tonumber(nLeft or 0) > 0 then
                return true
            end
        end
        return false
    end

    -- Planning returns one candidate. Only the execution gate below issues requests.
    local function Cast(dwSkillID, szSkillName, bPendant)
        return dwSkillID, szSkillName, bPendant
    end
    local function SkillCD(id)
        if me.GetSkillCDProgress then
            local ok, cool, left = pcall(function() return me.GetSkillCDProgress(id, 1) end)
            if ok then return cool and (tonumber(left) or 0) or 0 end
        end
        return 0
    end
    local nNTCD = SkillCD(182)
    -- An existing cooldown never proves the opener on this target. Confirm only
    -- our pending request by its cast event or a subsequent cooldown rise.
    if cycle.nt then
        local p = cycle.nt
        if (p.fullDOTs or p.ltDetonation) and (p.castEvent or nNTCD > p.cd) then
            if cycle.clRequest then cycle.clRequest.expired = true end
            cycle.clGuard = nil
            cycle.afterNT, cycle.dots, cycle.nt, cycle.pendingDOT = true, {}, nil, nil
            cycle.lateDots = {}
            if p.fullDOTs then cycle.firstNTFrame = cycle.firstNTFrame or nCurFrame end
            cycle.ltDone = HasLoanTuuBuff() or not IsSkillReady(LT_SKILL_ID)
            cycle.ltPhase = nil
            if XMCore_Sys then XMCore_Sys("[xMacro LT] NT_CONFIRMED target="..tostring(dwTargetID)
                .." evidence="..(p.castEvent and "CAST_EVENT" or "CD_RISE")) end
        elseif nCurFrame - p.frame >= 48 then
            cycle.nt = nil
        end
    end
    for _, id in ipairs({666, 714}) do
        local late = cycle.lateDots[id]
        local d = cycle.dots[id] or late
        if d and not d.confirmed then
            local b = TargetBuff(id)
            if targetBuffsKnown and not b then
                d.absent = true
                -- Keep this request through old -> empty -> new packet ordering.
                -- The pending timeout owns retries; absence alone is not failure.
            end
            if b and (d.absent or (b.nEndFrame and d.ending and b.nEndFrame > d.ending)
                or (b.nStartFrame and b.nStartFrame >= d.frame and b.nStartFrame ~= d.starting)) then
                d.confirmed = true
                cycle.dots[id], cycle.lateDots[id] = d, nil
                if XMCore_Sys then XMCore_Sys("[xMacro LT] NEW_DOT_OK buff="..tostring(id)
                    .." target="..tostring(dwTargetID).." end="..tostring(b.nEndFrame)
                    .." late="..tostring(d == late)) end
            elseif d ~= late and nCurFrame - d.frame >= 80 and not (cycle.pendingDOT
                and cycle.pendingDOT.frame == d.frame
                and cycle.pendingDOT.skill == (id == 666 and 180 or 189)) then
                cycle.dots[id] = nil
            end
        end
    end
    local function NeedReapply(id)
        return cycle.afterNT and not (cycle.dots[id] and cycle.dots[id].confirmed)
    end
    -- Live client v2.5.2 reports 886 as Phe Cot; 1902 is legacy compatibility.
    local phe = TargetBuff(886) or TargetBuff(1902, "Phệ Cốt")
        or TargetBuff(1902, "Phe Cot") or TargetBuff(1902, "噬骨")
    if phe then
        cycle.pheSeen, cycle.pheTries = true, 0
    end
    local nPheTime = phe and phe.nEndFrame and math.max(0,(phe.nEndFrame-nCurFrame)/16) or 0
    local nPheStacks = phe and phe.nStackNum or nil
    local phePending = cycle.phePending
    if phePending then
        local updated = phe and ((nPheStacks and nPheStacks > (phePending.stacks or 0))
            or (phe.nEndFrame and phePending.ending and phe.nEndFrame > phePending.ending)
            or not phePending.hadBuff)
        if updated or nCurFrame - phePending.frame >= 16 then cycle.phePending = nil end
    end
    -- Do not duplicate opener TD for an unseen optional talent. If the initial
    -- probe never produced a visible Phe Cot, retry only in stable filler time.
    local stablePheProbe = HasTargetBuff(666) and HasTargetBuff(714)
        and (not IsSkillReady(LT_SKILL_ID) or HasLoanTuuBuff() or cycle.ltDone)
        and not (cycle.afterNT and (NeedReapply(666) or NeedReapply(714)))
    local retryUnseenPhe = stablePheProbe and cycle.pheLast and nCurFrame-cycle.pheLast >= 80
    local bPheUrgent = (phe and nPheTime > 0 and nPheTime <= 4)
        or (not phe and (cycle.pheTries == 0
            or cycle.pheSeen or retryUnseenPhe))
    -- Build five stacks only in stable/burst filler time, never delay the
    -- first NT, its two fresh DOTs, or the end-of-LT detonation window.
    local ltTime = GetLoanTuuBuffTime()
    local bPheBuild = nPheStacks and nPheStacks > 0 and nPheStacks < 5
        and HasTargetBuff(666) and HasTargetBuff(714)
        and (not IsSkillReady(LT_SKILL_ID) or HasLoanTuuBuff() or cycle.ltDone)
        and not (cycle.afterNT and (NeedReapply(666) or NeedReapply(714)))
        and (not HasLoanTuuBuff() or (ltTime > 2
            and GetTargetBuffTime(666) > 3 and GetTargetBuffTime(714) > 3))
    local bNeedPhe = bPheUrgent or bPheBuild
    local bPheGrace = cycle.phePending ~= nil
    local bNeedTD = NeedReapply(666) or not HasTargetBuff(666)
        or (GetTargetBuffTime(666) > 0 and GetTargetBuffTime(666) < 3)
        or (bNeedPhe and not bPheGrace)

    -- 0. Kiem tra trang thai di chuyen (Moving)
    local bMoving = false
    if me and me.nMoveState then
        local nStand = (MOVE_STATE and MOVE_STATE.ON_STAND) or 0
        bMoving = (me.nMoveState ~= nStand)
    end

    local bIsPreparing, dwPrepSkillID = false, 0
    if me.GetSkillPrepareState then
        local ok, preparing, id = pcall(function() return me.GetSkillPrepareState() end)
        if ok and preparing then bIsPreparing, dwPrepSkillID = true, tonumber(id) or 0 end
    end
    local okOT, nOT = pcall(function() return me.GetOTActionState() end)
    local bIsOT = okOT and tonumber(nOT or 0) ~= 0
    -- Upward prepare casts deliver damage on completion. Preserve them while
    -- the observed Phe Cot has >2s; channels (OT=2) retain existing behavior.
    local bFinishPrepare = bIsPreparing and tonumber(nOT or 0) ~= 2 and nPheTime > 2

    -- Track every DOT request, including the first opener. A request returning
    -- true is not a DOT observation. Preserve the cast, then allow packet grace;
    -- TD and CL wait at most 1s for a cast start, or 0.5s after finish.
    -- An active cast is protected. Lan Thoi retains its existing timing.
    if not bIsPreparing and not bIsOT then cycle.stopAttempt = nil end
    local pending = cycle.pendingDOT
    if pending then
        local b = AppliedDOT(pending.skill)
        if targetBuffsKnown and not b then pending.absent = true end
        local observed = b and (not pending.hadBuff or pending.absent
            or (b.nEndFrame and pending.ending and b.nEndFrame > pending.ending)
            or (b.nStartFrame and b.nStartFrame >= pending.frame and b.nStartFrame ~= pending.starting))
        if observed then
            CLLog(pending, "DOT_OK", "buff="..tostring(b.dwID).." source="..tostring(b.dwSkillSrcID)
                .." end="..tostring(b.nEndFrame))
            if pending.skill == 189 then
                pending.dotOK = true
                cycle.clGuard = {ending=b.nEndFrame}
            end
            cycle.pendingDOT = nil
        elseif (bIsPreparing or bIsOT) and dwPrepSkillID == pending.skill then
            if not pending.wasPreparing then CLLog(pending, "PREPARE_START") end
            pending.wasPreparing, pending.finished = true, nil
        elseif (bIsPreparing or bIsOT) and dwPrepSkillID == 0 then
            -- Unknown cast ID is not proof of Chung Linh; preserve it until idle.
        else
            if pending.wasPreparing and not pending.finished then
                pending.finished = nCurFrame
                CLLog(pending, "PREPARE_END", "not proof of success; waiting for DOT")
            end
            local shortWait = pending.skill == 180 or pending.skill == 189
            local finish = pending.finished or pending.castEvent
            local deadline = finish and (finish + (shortWait and 8 or 16))
                or (pending.frame + (shortWait and 16 or 64))
            if targetBuffsKnown and nCurFrame >= deadline then
                pending.expired = true
                CLLog(pending, "DOT_WAIT_TIMEOUT", "no confirmed DOT; allowing RETRY")
                cycle.pendingDOT = nil
                if pending.skill == 180 or pending.skill == 189 then
                    local buffID = pending.skill == 180 and 666 or 714
                    local d = cycle.dots[buffID]
                    if d and not d.confirmed and d.frame == pending.frame then
                        -- Retry timing is unchanged. Keep nonblocking evidence so
                        -- a delayed own DOT can still finish this NT cycle.
                        if not pending.rejected then cycle.lateDots[buffID] = d end
                        cycle.dots[buffID] = nil
                    end
                end
                if pending.skill == 189 then cycle.clRetry = pending.request end
            end
        end
    end
    -- A short missing snapshot after DOT_OK is not a new application opportunity.
    local cl = AppliedDOT(189)
    if cl then
        cycle.clGuard = {ending=cl.nEndFrame}
    elseif cycle.clGuard and targetBuffsKnown then
        local guard = cycle.clGuard
        guard.missingSince = guard.missingSince or nCurFrame
        if (guard.ending and guard.ending > 0 and guard.ending <= nCurFrame)
            or nCurFrame - guard.missingSince >= 16 then cycle.clGuard = nil end
    end
    local function CanRequestCL()
        -- Wait for the old post-NT list to clear. Never request CL when its DOT
        -- is present or CL was the most recent confirmed cast.
        local requiredAfterNT = NeedReapply(714) and not cycle.dots[714]
        return targetBuffsKnown and not HasTargetBuff(714) and not lastcast(189)
            and (not cycle.clGuard or requiredAfterNT) and not cycle.pendingDOT
            and (not bMoving or HasPlayerBuff(2726) or HasThuyNguyetBuff())
    end
    local function CanStopAppliedDOT(skill)
        if bFinishPrepare then return false end
        local buffID = skill == 180 and 666 or skill == 189 and 714
            or skill == 190 and 711
        if not buffID or not targetBuffsKnown or not AppliedDOT(skill) then return false end
        -- Pre-NT DOTs cannot cancel a mandatory fresh application after NT.
        if (skill == 180 or skill == 189) and NeedReapply(buffID) then return false end
        -- A refresh requested against an existing DOT still needs new evidence.
        if cycle.pendingDOT and cycle.pendingDOT.skill == skill then return false end
        return true
    end
    if HasLoanTuuBuff() then cycle.ltDone = true end
    local function CanActivateLT()
        return cycle.firstNTFrame ~= nil and cycle.afterNT and not cycle.nt and not cycle.ltDone
            and not cycle.pendingDOT and targetBuffsKnown
            and not NeedReapply(666) and not NeedReapply(714)
            and HasTargetBuff(666) and HasTargetBuff(714)
            and not HasThuyNguyetBuff() and not HasLoanTuuBuff()
    end
    local function CanDetonateLT()
        local remaining = GetLoanTuuBuffTime()
        return HasLoanTuuBuff() and remaining > 0 and remaining <= 2
            and targetBuffsKnown and not cycle.pendingDOT and not cycle.nt
            and HasTargetBuff(666) and HasTargetBuff(714)
            and GetTargetBuffTime(666) >= 5 and GetTargetBuffTime(714) >= 5
    end
    if cycle.afterNT then
        local phase
        if HasLoanTuuBuff() then phase="LT_BUFF_OK"
        elseif not targetBuffsKnown then phase="WAIT_BUFF_READ"
        elseif cycle.pendingDOT then phase="WAIT_DOT_"..tostring(cycle.pendingDOT.skill)
        elseif NeedReapply(666) then phase="NEED_NEW_TD"
        elseif NeedReapply(714) then phase="NEED_NEW_CL"
        elseif not HasTargetBuff(666) or not HasTargetBuff(714) then phase="WAIT_BOTH_DOTS"
        elseif HasThuyNguyetBuff() then phase="WAIT_THUY_NGUYET_END"
        elseif not IsSkillReady(LT_SKILL_ID) then phase="WAIT_LT_READY"
        else phase="READY_FOR_LT" end
        if phase ~= cycle.ltPhase then
            cycle.ltPhase = phase
            if XMCore_Sys then XMCore_Sys("[xMacro LT] "..phase.." target="..tostring(dwTargetID)) end
        end
    end

    local okLTLevel, ltLevel = pcall(function() return me.GetSkillLevel(LT_SKILL_ID) end)
    local diag = {
        version=11,frame=nCurFrame,target=dwTargetID,buffs_known=targetBuffsKnown,
        finish_cast_phe=bFinishPrepare == true,
        late_td=cycle.lateDots[666] ~= nil,late_cl=cycle.lateDots[714] ~= nil,
        lt_nt_gate=CanDetonateLT() == true,phe_buff_id=phe and phe.dwID or 0,
        last_cast=tLastCast.player == me.dwID and tLastCast.skill or 0,
        last_cast_frame=tLastCast.player == me.dwID and tLastCast.frame or 0,
        phe_stacks=phe and (nPheStacks or -1) or 0,phe_time=nPheTime,
        phe_urgent=bPheUrgent == true,phe_build=bPheBuild == true,phe_wait=bPheGrace,
        first_nt_frame=cycle.firstNTFrame or 0,lt_gate=CanActivateLT() == true,
        after_nt=cycle.afterNT == true,nt_pending=cycle.nt ~= nil,nt_cd=nNTCD,
        pending_dot=cycle.pendingDOT and cycle.pendingDOT.skill or 0,
        need_td=NeedReapply(666) == true,need_cl=NeedReapply(714) == true,
        has_td=HasTargetBuff(666),has_cl=HasTargetBuff(714),cl_guard=cycle.clGuard ~= nil,
        lt_ready=IsSkillReady(LT_SKILL_ID),lt_cd=SkillCD(LT_SKILL_ID),
        lt_level=okLTLevel and (tonumber(ltLevel) or -1) or -1,
        lt_buff=HasLoanTuuBuff(),thuy_buff=HasThuyNguyetBuff(),
        preparing=bIsPreparing,ot=bIsOT,prepare_skill=dwPrepSkillID,moving=bMoving,
        dot_cast_applied=CanStopAppliedDOT(dwPrepSkillID),
        phase=cycle.ltPhase or "BEFORE_NT",decision="SELECT",selected=0,
        last_send=cycle.lastSend or 0,last_send_result=cycle.lastSendResult or "none",
        last_send_frame=cycle.lastSendFrame or 0,
    }
    local okTDLevel,tdLevel=pcall(function() return me.GetSkillLevel(180) end)
    diag.td_level=okTDLevel and (tonumber(tdLevel) or -1) or -1
    diag.td_cd=SkillCD(180)
    diag.self_life=tonumber(me.nCurrentLife) or -1
    diag.target_life=tar and (tonumber(tar.nCurrentLife) or -1) or -1
    if tar and tonumber(me.nX) and tonumber(me.nY) and tonumber(tar.nX) and tonumber(tar.nY) then
        diag.distance=math.floor(math.sqrt((me.nX-tar.nX)^2+(me.nY-tar.nY)^2)/64*10)/10
    end
    for key,value in pairs(buffAPI) do diag["buff_"..key]=value end
    local buffSummary={}
    for i,b in ipairs(targetBuffs) do
        if i>8 then break end
        local ok,name=pcall(function() return Table_GetBuffName(b.dwID,b.nLevel) end)
        buffSummary[#buffSummary+1]=tostring(b.dwID)..":"..tostring(b.nStackNum)
            ..":"..(ok and string.sub(tostring(name),1,40) or "?")
    end
    diag.buff_summary=table.concat(buffSummary,"|")
    xMacro.VanHoaDiagnostics = diag

    -- Stop a redundant DOT at the first positive snapshot, independently of
    -- the next skill's GCD/readiness. Never wait for cast finish or a timer here.
    if (bIsPreparing or bIsOT) and CanStopAppliedDOT(dwPrepSkillID) then
        if cycle.stopAttempt then diag.decision="WAIT_DOT_STOP_ACK";return false end
        cycle.stopAttempt={frame=nCurFrame,reason="DOT_ALREADY_APPLIED"}
        if XMCore_Sys then XMCore_Sys("[xMacro DOT] STOP reason=DOT_ALREADY_APPLIED current="..tostring(dwPrepSkillID)) end
        local stopped,result=pcall(function() return me.StopCurrentAction() end)
        if not stopped or result == false then
            diag.decision="DOT_STOP_REJECTED"
            if XMCore_Sys then XMCore_Sys("[xMacro DOT] STOP_REJECTED; wait for current cast") end
            return false
        end
        local ok,preparing=pcall(function() return me.GetSkillPrepareState() end)
        local okOT2,ot=pcall(function() return me.GetOTActionState() end)
        if not ok or not okOT2 or preparing or tonumber(ot or 0) ~= 0 then
            diag.decision="WAIT_DOT_STOP_ACK";return false
        end
        cycle.stopAttempt=nil
        bIsPreparing,bIsOT,dwPrepSkillID=false,false,0
        diag.preparing,diag.ot,diag.prepare_skill=false,false,0
    end

    local function AutoInterruptTarget()
        if tar and CheckPrepare(tar) and IsSkillReady(183) then
            return Cast(183, "Quyet Am Chi")
        end
    end

    local function SelectSkill()
    -- A. Tu cuu khi mau < 40% (Skill ID: 132 - Xuan Ne Ho Hoa)
    if me.nCurrentLife and me.nMaxLife and (me.nCurrentLife / math.max(1, me.nMaxLife) < 0.40) and IsSkillReady(132) then
        return Cast(132, "Xuan Ne Ho Hoa")
    end

    -- B. Hoi noi luc khi Mana < 40% (Skill ID: 131 - Bich Thuy Thao Thien)
    if me.nCurrentMana and me.nMaxMana and (me.nCurrentMana / math.max(1, me.nMaxMana) < 0.40) and IsSkillReady(131) then
        return Cast(131, "Bich Thuy Thao Thien")
    end

    -- C. Khong the ra don tan cong neu khong co muc tieu
    if not tar then
        return false
    end

    -- D. Ngat van cong quai / Boss (Skill ID: 183 - Quyet Am Chi, off-GCD)
    local interruptID, interruptName = AutoInterruptTarget()
    if interruptID then return interruptID, interruptName end

    -- Procs cannot override the opener, fresh-DOT phase or LT end-window.
    if cycle.nt or cycle.pendingDOT or not targetBuffsKnown then return false end

    -- LT requires two confirmed applications after an observed NT detonation.
    if IsSkillReady(LT_SKILL_ID) and CanActivateLT() then
        return Cast(LT_SKILL_ID, "Loan Tuu Thanh Ha")
    end

    if cycle.afterNT and not IsGCD() then
        if NeedReapply(666) and not cycle.dots[666] and IsSkillReady(180) then
            return Cast(180, "Thuong Duong Chi")
        end
        if not NeedReapply(666) and NeedReapply(714) and not cycle.dots[714] and IsSkillReady(189) then
            if CanRequestCL() then return Cast(189, "Chung Linh Duc Tu") end
        end
    end
    -- Once the first detonation is confirmed, finish its two-DOT/LT phase.
    -- Waiting for Thuy Nguyet or LT cooldown must not restart Lan Thoi/NT.
    if cycle.afterNT and not cycle.ltDone then
        if not IsGCD() then
            if bNeedTD and not (cycle.dots[666] and not cycle.dots[666].confirmed)
                and IsSkillReady(180) then return Cast(180, "Thuong Duong Chi") end
            if not NeedReapply(666) and not HasTargetBuff(714) and CanRequestCL() and IsSkillReady(189) then
                return Cast(189, "Chung Linh Duc Tu")
            end
        end
        if not IsGCD() and (not bMoving or HasPlayerBuff(2726) or HasThuyNguyetBuff())
            and IsSkillReady(179) then return Cast(179, "Duong Minh Chi") end
        return false
    end
    -- G. Thuy Nguyet Vo Gian (Skill ID: 136): Off-GCD buff ban than khi khong trong Loan Tuu
    if IsSkillReady(136) and not HasLoanTuuBuff() and not HasThuyNguyetBuff() then
        if not HasTargetLanThoi() or not HasTargetBuff(714, "Chung Linh") then
            return Cast(136, "Thuy Nguyet Vo Gian")
        end
    end

    -- H. Chan Global Cooldown (GCD) cho cac skill danh tiep theo
    if IsGCD() then
        return false
    end

    -- Stable Lan Thoi -> NT handoff takes priority over another filler cast.
    if not HasLoanTuuBuff() and lastcast(190) and HasTargetBuff(666)
        and HasTargetBuff(714) and HasTargetLanThoi() and IsSkillReady(182) then
        return Cast(182, "Ngoc Thach Cau Phan")
    end

    -- I. PHỦ 3-DOT TỨC THỜI (HỖ TRỢ CẢ LOẠN TỬU VÀ THỦY NGUYỆT 0s VẬN KHÍ):
    -- I. ROTATION KHI CO BUFF LOAN TUU THANH HA (2645/2719):
    -- During LT, detonate two DOTs directly near buff end; never add Lan Thoi.
    -- A main DOT with less than 5s remaining vetoes this detonation.
    if HasLoanTuuBuff() then
        local nLTBuffTime = GetLoanTuuBuffTime()
        local bNeedDetonateLT = (nLTBuffTime > 0 and nLTBuffTime <= 2.0)
        -- 1. Buff lai Thuong Duong Chi neu bi no DOT / thieu DOT
        if bNeedTD and (not bNeedDetonateLT or not HasTargetBuff(666) or NeedReapply(666) or bPheUrgent)
            and not (cycle.dots[666] and not cycle.dots[666].confirmed) and IsSkillReady(180) then
            return Cast(180, "Thuong Duong Chi")
        end

        -- 2. Buff lai Chung Linh Duc Tu neu bi no DOT / thieu DOT (tuc thoi 0s duoi Loan Tuu)
        if not NeedReapply(666) and not HasTargetBuff(714, "Chung Linh") and not (cycle.dots[714] and not cycle.dots[714].confirmed) and IsSkillReady(189) then
            if CanRequestCL() then return Cast(189, "Chung Linh Duc Tu") end
        end

        -- 3. Kiem tra xem DA DEN LUC CAN NO NGOC THACH CHUA:

        if CanDetonateLT() and IsSkillReady(182) then
            return Cast(182, "Ngoc Thach Cau Phan")
        end

        -- 4. Khi chua can no Ngoc Thach: CHI CAN DANH DUONG MINH CHI (179)!
        if (not bMoving or HasPlayerBuff(2726) or HasThuyNguyetBuff()) and IsSkillReady(179) then
            return Cast(179, "Duong Minh Chi")
        end
        if bMoving and IsSkillReady(180) then return Cast(180, "Thuong Duong Chi") end
        return false
    end

    -- I2. VONG LAP BINH ON (NGOAI LOAN TUU):
    -- 1. Lan Thoi tuc thoi khi co Thuy Nguyet (645)
    if HasThuyNguyetBuff() and not HasTargetLanThoi() and IsSkillReady(190) then
        return Cast(190, "Lan Thoi Ngoc Chiet")
    end

    -- 3. DOT Thuong Duong Chi (ID 180, Buff 666): Tuc thoi goc, lam moi khi thieu hoac con < 3s (duy tri Phe Cot)
    if bNeedTD and not (cycle.dots[666] and not cycle.dots[666].confirmed) and IsSkillReady(180) then
        return Cast(180, "Thuong Duong Chi")
    end

    -- 4. Chung Linh Duc Tu (ID 189) trong giai doan thuong (Debounce 16 frames) - Chi cast khi DUNG YEN (not bMoving)
    local nLast189 = tSkillCastFrame[189] or 0
    if not NeedReapply(666) and not HasLoanTuuBuff() and not HasTargetBuff(714, "Chung Linh") and not (cycle.dots[714] and not cycle.dots[714].confirmed) and IsSkillReady(189) and (nCurFrame - nLast189 >= 16 or cycle.clRetry) then
        if CanRequestCL() then return Cast(189, "Chung Linh Duc Tu") end
    end

    -- 5. Smart Hard-Cast Lan Thoi Ngoc Chiet (ID 190):
    -- Trong giai doan binh on: Chi doc tay khi DUNG YEN (not bMoving), DA CO DU 2 DOT kia va Ngoc Thach sap no (CD <= 2.5s)
    local bHas666 = HasTargetBuff(666, "Thuong Duong")
    local bHas714 = HasTargetBuff(714, "Chung Linh")
    local bHasLanThoi = HasTargetLanThoi()
    local nLast190 = tSkillCastFrame[190] or 0
    local bNgocThachReadySoon = false
    if me.GetSkillCDProgress then
        local ok, bCool, nLeft = pcall(function() return me.GetSkillCDProgress(182, 1) end)
        if ok then
            if not bCool or tonumber(nLeft or 0) <= 40 then
                bNgocThachReadySoon = true
            end
        else
            bNgocThachReadySoon = true
        end
    else
        bNgocThachReadySoon = true
    end

    if not HasLoanTuuBuff() and not bHasLanThoi and IsSkillReady(190) and (nCurFrame - nLast190 > 36) then
        if bHas666 and bHas714 and bNgocThachReadySoon then
            return Cast(190, "Lan Thoi Ngoc Chiet")
        end
    end

    -- J. KÍCH NỔ NGỌC THẠCH CÂU PHẦN (ID 182):
    if not HasLoanTuuBuff() and bHas666 and bHasLanThoi and bHas714 and IsSkillReady(182) then
        -- Outside LT, the opener/stable rotation still requires three DOTs.
        return Cast(182, "Ngoc Thach Cau Phan")
    end

    -- K. Toi uu hoa khi DI CHUYEN (Moving - zero downtime):
    if bMoving then
        -- 1. Neu co buff tuc thoi tu Loan Tuu hoac Thuy Nguyet thi van ban duoc Duong Minh Chi
        if (HasPlayerBuff(2726) or HasThuyNguyetBuff()) and IsSkillReady(179) then
            return Cast(179, "Duong Minh Chi")
        end
        -- 2. Neu khong co buff tuc thoi: tuyet doi khong doc thanh Duong Minh Chi.
        -- Thay vao do, spam Thuong Duong Chi (180, tuc thoi 0s) de lien tuc gay sat thuong va lam moi Phe Cot
        if IsSkillReady(180) then
            return Cast(180, "Thuong Duong Chi")
        end
        return false
    end

    -- L. Chieu danh chinh khi DUNG YEN (Filler & Proc Tran phai Han Bich): Duong Minh Chi (ID 179)
    if IsSkillReady(179) then
        return Cast(179, "Duong Minh Chi")
    end

    return false
    end

    local id, name, pendant = SelectSkill()
    diag.selected=id or 0
    diag.target_preparing=tar and CheckPrepare(tar) or false
    if id == 183 and not diag.target_preparing then
        diag.decision="TARGET_CAST_ENDED";return false
    end
    -- Final execution invariants apply to every planner branch.
    if id == LT_SKILL_ID and not CanActivateLT() then
        diag.decision="LT_GATE_BLOCKED";return false
    end
    if id == 189 and (lastcast(189) or HasTargetBuff(714)) then
        diag.decision="CL_LASTCAST_OR_DOT_BLOCKED";return false
    end
    if id == 182 then
        if HasLoanTuuBuff() then
            if not CanDetonateLT() then diag.decision="LT_NT_REQUIRES_FIVE_SECONDS";return false end
        elseif cycle.nt or cycle.pendingDOT or not targetBuffsKnown
            or not HasTargetBuff(666) or not HasTargetBuff(714) or not HasTargetLanThoi() then
            diag.decision="NT_REQUIRES_THREE_DOTS";return false
        end
    end
    -- Bich Lac may use the pendant only when the normal combo chooses NT.
    if id == 182 and HasPlayerBuff(2495, "Bích Lạc") then pendant=true end
    if not id then
        diag.decision="NO_CANDIDATE"
        -- Preserve custom idle fallback without allowing its stopota lines to
        -- re-enter while any cast is protected or a selected skill is blocked.
        if tar and not cycle.nt and not cycle.pendingDOT and not bIsPreparing and not bIsOT and szCurrentActiveMacroScript
            and szCurrentActiveMacroScript ~= DEFAULT_VANHOA_MACRO
            and szCurrentActiveMacroScript ~= "" and szCurrentActiveMacroScript ~= "auto" then
            local ok, ret = pcall(ExecuteMacroCommand, szCurrentActiveMacroScript)
            if ok and ret then return true end
        end
        return false
    end
    -- Off-GCD buffs/defensives keep their original priority; other skills must wait.
    local offGCD = id == 136 or id == 183 or id == LT_SKILL_ID
    if not IsSkillReady(id) or (not offGCD and IsGCD()) then
        diag.decision="WAIT_CD_OR_GCD";return false
    end
    if bFinishPrepare and id ~= 183 then
        diag.decision="FINISH_CAST_PHE_GT_2";return false
    end
    -- Quyet Am Chi interrupts the target off-GCD; do not stop our own cast.
    if (bIsPreparing or bIsOT) and id ~= 183 then
        -- Applied DOTs were handled above; DMC retains its explicit allowlist.
        if dwPrepSkillID ~= 179 or id == 179 or not me.StopCurrentAction then
            diag.decision="PROTECTED_CAST";return false
        end
        local reason
        if id == 132 and me.nCurrentLife / math.max(1, me.nMaxLife or 1) < 0.4 then reason="LOW_LIFE"
        elseif id == 131 and me.nCurrentMana / math.max(1, me.nMaxMana or 1) < 0.4 then reason="LOW_MANA"
        elseif id == 180 and bNeedPhe and not bPheGrace then reason="PHE_COT"
        elseif id == 180 and bMoving and not HasLoanTuuBuff() and not HasThuyNguyetBuff() then reason="MOVING"
        elseif id == LT_SKILL_ID and cycle.afterNT and not cycle.nt
            and not NeedReapply(666) and not NeedReapply(714)
            and HasTargetBuff(666) and HasTargetBuff(714)
            and not HasLoanTuuBuff() and not HasThuyNguyetBuff() then reason="LOAN_TUU_AFTER_DOTS"
        elseif id == 190 and HasThuyNguyetBuff() and not HasTargetLanThoi() then reason="INSTANT_LAN_THOI"
        end
        if not reason or cycle.stopAttempt then
            diag.decision=cycle.stopAttempt and "WAIT_STOP_ACK" or "DMC_NO_INTERRUPT_REASON"
            return false
        end
        cycle.stopAttempt = {frame=nCurFrame, reason=reason}
        local stopTag="[xMacro DMC]"
        if XMCore_Sys then XMCore_Sys(stopTag.." STOP reason="..reason.." current="..tostring(dwPrepSkillID).." next="..tostring(id)) end
        local stopped, result = pcall(function() return me.StopCurrentAction() end)
        if not stopped or result == false then
            if XMCore_Sys then XMCore_Sys(stopTag.." STOP_REJECTED; wait for current cast") end
            return false
        end
        -- Some clients acknowledge StopCurrentAction asynchronously. Never send
        -- a follow-up into the old cast, and never repeat Stop for that cast.
        local ok, preparing = pcall(function() return me.GetSkillPrepareState() end)
        local okOT2, ot = pcall(function() return me.GetOTActionState() end)
        if not ok or not okOT2 or preparing or tonumber(ot or 0) ~= 0 then return false end
        cycle.stopAttempt = nil
        if not IsSkillReady(id) or (not offGCD and IsGCD()) then return false end
    end
    if id == 182 and not cycle.nt then
        cycle.nt = {frame = nCurFrame, cd = nNTCD, target = dwTargetID,
            fullDOTs = not HasLoanTuuBuff(),ltDetonation = HasLoanTuuBuff()}
    elseif (id == 180 or id == 189) and cycle.afterNT then
        local buffID = id == 180 and 666 or 714
        if NeedReapply(buffID) and not cycle.dots[buffID] then
            local b = TargetBuff(buffID)
            cycle.dots[buffID] = {frame = nCurFrame, absent = not b,
                ending = b and b.nEndFrame, starting = b and b.nStartFrame}
        end
    end
    if id == 180 and bNeedPhe and not bPheGrace then
        if not phe then cycle.pheTries = cycle.pheTries + 1 end
        cycle.pheLast = nCurFrame
        cycle.phePending = {frame=nCurFrame,stacks=nPheStacks,ending=phe and phe.nEndFrame,hadBuff=phe ~= nil}
        if XMCore_Sys then XMCore_Sys("[xMacro PHE] "..(bPheUrgent and "REFRESH" or "BUILD")
            .." stacks="..tostring(nPheStacks or 0).." time="..tostring(nPheTime)) end
    end
    if id == 180 or id == 189 or id == 190 then
        local b = AppliedDOT(id)
        cycle.pendingDOT = {skill = id, frame = nCurFrame, hadBuff = b ~= nil,
            ending = b and b.nEndFrame, starting = b and b.nStartFrame, target=dwTargetID}
        if id == 189 then
            nCLRequest = nCLRequest + 1
            cycle.pendingDOT.request = nCLRequest
            cycle.clRequest = cycle.pendingDOT
            if cycle.clRetry then
                CLLog(cycle.pendingDOT, "RETRY", "previous_req="..tostring(cycle.clRetry))
                cycle.clRetry = nil
            end
            CLLog(cycle.pendingDOT, "REQUEST", "skill=189; awaiting game evidence")
        end
    end
    tSkillCastFrame[id] = nCurFrame
    if pendant and XMCore_UseEquipSlot then
        pcall(XMCore_UseEquipSlot, EQUIPMENT_INVENTORY.PENDANT, false)
    end
    local level = (me.GetSkillLevel and me.GetSkillLevel(id)) or 1
    local okSend, result = pcall(OnAddOnUseSkill, id, math.max(1, level))
    cycle.lastSend,cycle.lastSendResult,cycle.lastSendFrame=id,tostring(result),nCurFrame
    diag.last_send,diag.last_send_result,diag.last_send_frame=id,tostring(result),nCurFrame
    diag.decision=(not okSend or result == false) and "API_REJECTED" or "REQUEST_SENT"
    if id == 189 then
        local p = cycle.clRequest
        p.rejected = not okSend or result == false
        CLLog(p, p.rejected and "API_REJECTED" or (result == true and "API_ACCEPTED" or "API_UNKNOWN"),
            "return="..tostring(result).."; application not confirmed by API return")
    end
    if not okSend or result == false then
        if id == 182 then cycle.nt = nil end
        if id == 180 then cycle.phePending = nil end
        return false
    end
    if id ~= 189 and XMCore_Sys then XMCore_Sys("[xMacro] -> " .. tostring(name)) end
    return true
end


return {run = Run, defaultScript = DEFAULT_VANHOA_MACRO}
end
-- Publish a deferred factory; module loading does not require Core or Registry yet.
xMacro = xMacro or {}
xMacro.SchoolFactories = xMacro.SchoolFactories or {}
xMacro.SchoolFactories.VanHoa = xMacro.SchoolFactories.VanHoa or {}
-- A fresh module must bind to the current Core after a full addon reload.
-- Registry-only reloads retain the already initialized implementation.
if xMacro.SchoolProfiles and xMacro.SchoolProfiles.VanHoa then
    xMacro.SchoolProfiles.VanHoa.HoaGian = nil
end
xMacro.SchoolFactories.VanHoa.HoaGian = Create
