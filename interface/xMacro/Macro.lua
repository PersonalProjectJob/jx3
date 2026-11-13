
--	宏命令：
--	skill		[条件]技能			执行技能
--	cbuff		[条件]BUFF			取消自身buff
--	umwp		[条件]				卸载身上的武器
--	omwp		[条件]武器			挂载背包中的武器
--	use			[条件]物品			使用特效装备
--	item		[条件]物品			使用背包物品
--	talk		[条件]喊话			在近聊喊话
--	config							配置宏的运行

--	config	支持参数 (channel-on/channel-off)
--	保护引导或不保护引导；before:[条件]和before:null
--	/config 保护引导  说明：引导技能不会被打断，例如纯阳的[凝神聚气]，秀秀的[玳弦急曲]
--	/config before:null  说明：清空设置的预判断
--	/config before:[buff:调息]  说明：该宏下面的所有宏指令，都会附加判断这个设置的条件

--	参数判断
--	参数间的逻辑运算：“,”分隔表示且，“;”分隔表示或，支持“;”或分组判断
--	参数内的逻辑运算：|表示或 -表示且
--	参数内的关系运算：>,<,=,<=,>=
--	参数内凡是有关系对比的，就支持所有关系运算

--	===============参数列表======================
--	自身基础状态
--	mounted/horse		自身在马上
--	unmounted/nohorse	自身不在马上
--	combat/fight		战斗中
--	nocombat/nofight	不在战斗中
--	status				自身在状态						status:run|jump
--	nostatus			自身不在状态					nostatus:run
--	qidian				自身的职业点数					qidian>3
--	life				自身生命比						life>0.5
--	mana				自身内力比						mana<=0.3
--	cd					指定技能冷却中					cd:龙吟|灭 或 cd:龙吟-灭
--	nocd				指定技能不在冷却中				nocd:金刚诀|金刚怒目 或 nocd:金刚诀-金刚怒目
--	cdtime				指定技能冷却时间符合条件		cdtime:定军>5|龙吟>1 或 cdtime:定军>5-龙吟>1
--	mount				自身内功						mount:太虚剑意|傲血战意 或 mount:太虚剑意
--	nomount				自身内功不为指定内攻			nomount:太虚剑意|傲血战意
--	rage				自身剑气						rage>80
--	target				目标类型						target:npc 或 target:player 或 target:boss
--	pet					有宠物							pet 或 pet:玉蟾
--	nopet				无宠物							nopet 或 nopet:玉蟾
--	tm/energy			唐门神机值						tm>80
--	otaction/ota		自身读条						otaction 判断所有读条状态 或 ota:四象轮回>0.5|生太极 判断普通技能读条
--	nootaction			自身不读条
--	puppet				有千机变
--	nopuppet			无千机变
--	bomb				判断唐门暗藏杀机个数			bomb>1 或 bomb=3 或 bomb<1
--	moon				判断明教月能量					moon>50 或 moon>sun
--	sun					判断明教日能量					sun>50 或 sun>moon
--	fullmoon			满月
--	fullsun				满日
--	nofullmoon			没满月
--	nofullsun			没满日
--	moonhit				[幽月轮]下一次命中目标是第几段	moonhit=3
--	sunhit				[赤日轮]下一次命中目标是第几段	sunhit>=2
--	aura/qichang		判断对自己有效的气场			aura:生太极-吞日月  或  aura:破苍穹<3|生太极<3	支持“或”“ 且” 判断，数字为剩余气场时间判断
--	noaura/noqichang	判断无气场						noaura:生太极-吞日月 	支持“ 且” 判断
--	hatred				自身仇恨值						hatred>70

--	自身BUFF判断
--	buff				自身有BUFF						buff:破风 或 buff:破风>5 或 buff:破风>5|定军 或buff:破风-定军，BUFF支持ID判断，如tbuff:破风(123)>5|定军
--	nobuff				自身无BUFF						nobuff:破风-流血 或 nobuff:破风|流血，BUFF支持ID判断
--	bufftime			自身指定BUFF的时间符合条件		bufftime:破风>3|定军<5 或 bufftime:破风<3 或 bufftime:破风>3-定军<5，BUFF支持ID判断
--	btype				自身有指定类型的增益BUFF		btype:外攻 或 btype:外攻|阳性	支持类型：外攻,阳性,混元,阴性,毒性,蛊
--	detype				自身有指定类型的减益BUFF		detype:外攻 或 detype:外攻|阳性	支持类型：外攻,阳性,混元,阴性,点穴,毒性,蛊

--	目标基础状态
--	tstatus				目标在状态						tstatus:run|jump
--	tnostatus			目标不在状态					tnostatus:run
--	tlife				目标生命比						tlife>0.5
--	tname				目标名字						tname:破风|流血
--	tnoname				目标名字不为指定名字			tnoname:破风|流血
--	distance			目标和自己的距离				distance>3
--	prepare				目标读条						prepare 或 prepare:七星拱瑞 或 prepare:化三清>0.5|生太极
--	tmana				目标内力比						tmana>0.5 或 tmana<0.5 或 tmana=0.5
--	exists				目标存在
--	noexists			目标不存在
--	dead				目标死亡
--	nodead				目标未死亡

--	目标BUFF判断
--	tbuff				目标Buff						tbuff:破风>5|定军 或 tbuff:破风>5-定军，BUFF支持ID判断，如tbuff:破风(123)>5|定军
--	mbuff				目标身上所属自己的Buff			mbuff:破风>5|定军 或 mbuff:破风>5-定军，BUFF支持ID判断
--	tnobuff				目标无BUFF						tnobuff:破风-流血 或 tnobuff:破风|流血，BUFF支持ID判断
--	nombuff				目标身上无所属自己的Buff		nombuff:破风-流血 或 nombuff:破风|流血，BUFF支持ID判断
--	tbufftime			目标Buff时间					tbufftime:破风>3|定军<5 或 tbufftime:破风<3-定军<2，BUFF支持ID判断
--	mbufftime			目标身上所属自己的Buff时间		mbufftime:破风>3|定军<5 或 mbufftime:破风<3-定军<2，BUFF支持ID判断
--	tbtype				目标Buff类型					tbtype:外攻 或 tbtype:外攻|阳性	支持类型：外攻,阳性,混元,阴性,毒性,蛊
--	tdetype				目标Debuff类型					tdetype:外攻 或 tdetype:外攻|阳性	支持类型：外攻,阳性,混元,阴性,点穴,毒性,蛊

--	目标的目标判断
--	ttlife				目标的目标的生命				ttlife>0.3
--	ttforce				目标的目标的门派				ttforce:藏剑|纯阳|万花 或 ttforce:藏剑

--	扩展技能
--	中断读条/打断
--	后跳
-- 	stopota/dừng
-- 	Rút lui
-- 	Ngồi thiền/Điều tức
--	Nhảy lùi

--	唐门技能
--	攻击				千机变攻击
--	停止				千机变停止
--	连弩				千机变变形连弩
--	重弩				千机变变形重弩
--	毒刹				千机变变形毒刹

local pairs, ipairs, tonumber, tostring = pairs, ipairs, tonumber, tostring

if not SplitString then
	function SplitString(szText, szDelimiter)
		szText = tostring(szText or "")
		szDelimiter = szDelimiter or ","
		local t = {}
		if szDelimiter == "" then
			table.insert(t, szText)
			return t
		end
		local pattern = "[^%" .. szDelimiter .. "]+"
		for match in string.gmatch(szText, pattern) do
			table.insert(t, match)
		end
		return t
	end
end

if not StringFindW then
	function StringFindW(szText, szPattern)
		if not szText or not szPattern then return nil end
		return string.find(szText, szPattern, 1, true)
	end
end

function GetTargetHandle(a, b)
	if not a and not b then return nil end
	local id1 = (type(a) == "number" and a > 0) and a or nil
	local id2 = (type(b) == "number" and b > 0) and b or nil

	-- Uu tien entity ID (> 10) vi dwID cua quai/nguoi choi luon lon hon targetType (1, 2, 3)
	if id2 and id2 > 10 and GetNpc then
		local ok, npc = pcall(GetNpc, id2)
		if ok and npc and npc.dwID then return npc end
	end
	if id1 and id1 > 10 and GetNpc then
		local ok, npc = pcall(GetNpc, id1)
		if ok and npc and npc.dwID then return npc end
	end
	if id2 and id2 > 10 and GetPlayer then
		local ok, pl = pcall(GetPlayer, id2)
		if ok and pl and pl.dwID then return pl end
	end
	if id1 and id1 > 10 and GetPlayer then
		local ok, pl = pcall(GetPlayer, id1)
		if ok and pl and pl.dwID then return pl end
	end
	if id1 and GetNpc then
		local ok, npc = pcall(GetNpc, id1)
		if ok and npc and npc.dwID then return npc end
	end
	if id2 and GetNpc then
		local ok, npc = pcall(GetNpc, id2)
		if ok and npc and npc.dwID then return npc end
	end
	return nil
end

local tAllSkill = {}
local tNpcList = {}
local bProtectChannelSkill = true
local szBeforeCmd = ""
local bAttackState = false
local szLastOTA = nil
local tSkillBox = {}

local dwCurrentTargetID = 0
local dwTargetRank = 0
local dwMyHatred = 0

local dwLastSunTime = 0
local dwLastMoonTime = 0
local nNextMoonLevel = 1
local nNextSunLevel = 1
local tMoonSkill = {[4024] = 1,[4025] = 2,[4026] = 3}
local tSunSkill =  {[4028] = 1,[4029] = 2,[4030] = 3}

local tChannelSkill = {[3110] = true, [5268] = true,}

local tPet = {
	[9956] = "圣蝎",
	[9996] = "风蜈",
	[9997] = "天蛛",
	[9998] = "灵蛇",
	[9999] = "玉蟾",
}

local tPuppet = {
	[16174] = "Thiên Cơ Nỏ",
	[16175] = "Liên Nỏ",
	[16176] = "Trọng Nỏ",
	[16177] = "Độc Sát",
}

local tPuppetSkill = {
	["Liên Nỏ"] = {3368, 1},
	["Trọng Nỏ"] = {3369, 1},
	["Độc Sát"] = {3370, 1},
	["Tấn công"] = {3360, 1},
	["Dừng"] = {3382, 1}
}

local tAuraList = {
	[4982] = 8, 	--镇山河
	[3080] = 24,	--化三清
	[4976] = 24, 	--生太极
	[4981] = 24, 	--吞日月
	[4977] = 24, 	--破苍穹
	[4978] = 8, 	--冲阴阳
	[4979] = 24, 	--凌太虚
	[4980] = 24, 	--碎星辰
}

local tDetachType = {
	["btype"] = {
		[1] = "Ngoại công",
		[3] = "Dương tính",
		[5] = "Hỗn nguyên",
		[7] = "Âm tính",
		[11] = "Độc tính",
		[13] = "Nội"
	},
	["detype"] = {
		[2] = "Ngoại công",
		[4] = "Dương tính",
		[6] = "Hỗn nguyên",
		[8] = "Âm tính",
		[10] = "Điểm huyệt",
		[12] = "Độc tính",
		[14] = "Nội"
	}
}

local tStatus = {
	["stand"]	= (MOVE_STATE and MOVE_STATE.ON_STAND) or 0,
	["walk"] 	= (MOVE_STATE and MOVE_STATE.ON_WALK) or 1,
	["run"]		= (MOVE_STATE and MOVE_STATE.ON_RUN) or 2,
	["jump"]	= (MOVE_STATE and MOVE_STATE.ON_JUMP) or 3,
	["swim"]	= (MOVE_STATE and MOVE_STATE.ON_SWIM) or 4,
	["swimjump"]= (MOVE_STATE and MOVE_STATE.ON_SWIM_JUMP) or 5,
	["float"]	= (MOVE_STATE and MOVE_STATE.ON_FLOAT) or 6,
	["sit"]		= (MOVE_STATE and MOVE_STATE.ON_SIT) or 7,
	["down"]	= (MOVE_STATE and MOVE_STATE.ON_KNOCKED_DOWN) or 8,
	["bacl"]	= (MOVE_STATE and MOVE_STATE.ON_KNOCKED_BACK) or 9,
	["off"]		= (MOVE_STATE and MOVE_STATE.ON_KNOCKED_OFF) or 10,
	["halt"]	= (MOVE_STATE and MOVE_STATE.ON_HALT) or 11,
	["freeze"]	= (MOVE_STATE and MOVE_STATE.ON_FREEZE) or 12,
	["entrap"]	= (MOVE_STATE and MOVE_STATE.ON_ENTRAP) or 13,
	["autofly"]	= (MOVE_STATE and MOVE_STATE.ON_AUTO_FLY) or 14,
	["death"]	= (MOVE_STATE and MOVE_STATE.ON_DEATH) or 15,
	["dash"]	= (MOVE_STATE and MOVE_STATE.ON_DASH) or 16,
	["pull"]	= (MOVE_STATE and MOVE_STATE.ON_PULL) or 17,
	["repulsed"]= (MOVE_STATE and MOVE_STATE.ON_REPULSED) or 18,
	["rise"]	= (MOVE_STATE and MOVE_STATE.ON_RISE) or 19,
	["skid"]	= (MOVE_STATE and MOVE_STATE.ON_SKID) or 20,
}

local tEquipmentPos = {}
local function GetEquipmentPosList()
	if #tEquipmentPos == 0 and EQUIPMENT_INVENTORY then
		tEquipmentPos = {
			EQUIPMENT_INVENTORY.MELEE_WEAPON,
			EQUIPMENT_INVENTORY.BIG_SWORD,
			EQUIPMENT_INVENTORY.RANGE_WEAPON,
			EQUIPMENT_INVENTORY.CHEST,
			EQUIPMENT_INVENTORY.HELM,
			EQUIPMENT_INVENTORY.AMULET,
			EQUIPMENT_INVENTORY.LEFT_RING,
			EQUIPMENT_INVENTORY.RIGHT_RING,
			EQUIPMENT_INVENTORY.WAIST,
			EQUIPMENT_INVENTORY.PENDANT,
			EQUIPMENT_INVENTORY.PANTS,
			EQUIPMENT_INVENTORY.BOOTS,
			EQUIPMENT_INVENTORY.BANGLE,
		}
	end
	return tEquipmentPos
end

--------------------------------------------------------

--------------------------------------------------------
local RoleCache = {}
function RoleCache:New()
	local o = {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function RoleCache:Set(data)
	self.data = data
end

function RoleCache:Get()
	return self.data
end

local MeCache, TarCache = RoleCache:New(), RoleCache:New()
local tSkillCastFrame = {}
local tLastCast = {}

--------------------------------------------------------

--------------------------------------------------------
local function print(...)
	local a = {...}
	for i, v in ipairs(a) do
		a[i] = tostring(v)
	end
	OutputMessage("MSG_SYS", "[xMacro]" .. table.concat(a, "\t") .. "\n" )
end


local function Compare(szCmp, szRes, szTar)
	local nRes, nTar = tonumber(szRes), tonumber(szTar)
	local tCompare = {
		["="] = nRes == nTar,
		[">"] = nRes > nTar,
		["<"] = nRes < nTar,
		[">="] = nRes >= nTar,
		["<="] = nRes <= nTar,
	}
	if tCompare[szCmp] then
		return tCompare[szCmp]
	end
	return false
end


local function GetPlayerSkillInfo(szName)
	if not szName or szName == "" then return nil end
	local nID = tonumber(szName)
	if nID and nID > 0 then
		local me = GetClientPlayer()
		local dwLvl = (me and me.GetSkillLevel and me.GetSkillLevel(nID)) or 1
		if dwLvl <= 0 then dwLvl = 1 end
		return nID, dwLvl
	end
	if not tAllSkill or next(tAllSkill) == nil then
		local me = GetClientPlayer()
		if me and me.GetAllSkillList then
			tAllSkill = me.GetAllSkillList() or {}
		end
	end
	for k, v in pairs(tAllSkill) do
		local szSkillName = Table_GetSkillName(k, v)
		if szSkillName == szName then
			return k, v
		end
	end
	-- Static fallback cho Mon phai Van Hoa & That Tu (chuan 100% C++ Engine JX3)
	local tStatic = {
		["Dương Minh Chỉ"]=179, ["Duong Minh Chi"]=179, ["duong minh"]=179, ["阳明指"]=179,
		["Thương Dương Chỉ"]=180, ["Thuong Duong Chi"]=180, ["thuong duong"]=180, ["商阳指"]=180,
		["Thiếu Dương Chỉ"]=181, ["Thieu Duong Chi"]=181, ["少阳指"]=181,
		["Ngọc Thạch Câu Phần"]=182, ["Ngoc Thach Cau Phan"]=182, ["ngoc thach"]=182, ["玉石俱焚"]=182,
		["Quyết Âm Chỉ"]=183, ["Quyet Am Chi"]=183, ["quyet am"]=183, ["厥阴指"]=183,
		["Thiếu Minh Chỉ"]=184, ["Thieu Minh Chi"]=184, ["少明指"]=184,
		["Phù Dung Tịnh Đế"]=186, ["Phu Dung Tinh De"]=186, ["芙蓉并蒂"]=186,
		["Chung Linh Dục Tú"]=189, ["Chung Linh Duc Tu"]=189, ["chung linh"]=189, ["钟林毓秀"]=189,
		["Lan Thôi Ngọc Chiết"]=190, ["Lan Thoi Ngoc Chiet"]=190, ["lan thoi"]=190, ["Lan Tồi Thính Phong"]=190, ["兰摧玉折"]=190,
		["Bích Thủy Thao Thiên"]=131, ["Bich Thuy Thao Thien"]=131, ["bich thuy"]=131, ["碧水滔天"]=131,
		["Xuân Nê Hộ Hoa"]=132, ["Xuan Ne Ho Hoa"]=132, ["xuan ne"]=132, ["春泥护花"]=132,
		["Thủy Nguyệt Vô Gian"]=136, ["Thuy Nguyet Vo Gian"]=136, ["水月无间"]=136,
		["Kiếm Thần Vô Ngã"]=547, ["Kiem Than Vo Nga"]=547,
		["Kiếm Phá Hư Không"]=548, ["Kiem Pha Hu Khong"]=548,
		["Kiếm Khí Trường Giang"]=550, ["Kiem Khi Truong Giang"]=550,
		["Giang Hải Ngưng Quang"]=544, ["Giang Hai Ngung Quang"]=544,
		["Đại Huyền Cấp Khúc"]=545, ["Dai Huyen Cap Khuc"]=545,
		["Phồn Âm Cấp Tiết"]=551, ["Phon Am Cap Tiet"]=551,
		["Long Trì Nhạc"]=552, ["Long Tri Nhac"]=552,
		["Mãn Đường Thế"]=553, ["Man Duong The"]=553,
		["Loạn Tửu Thanh Hà"]=2645, ["Loan Tuu Thanh Ha"]=2645, ["loan tuu"]=2645, ["乱洒青荷"]=2645,
	}
	if tStatic[szName] then
		local id = tStatic[szName]
		local me = GetClientPlayer()
		local dwLvl = (me and me.GetSkillLevel and me.GetSkillLevel(id)) or 1
		if dwLvl <= 0 then dwLvl = 1 end
		return id, dwLvl
	end
	return nil
end


-- Only DO_SKILL_CAST updates this state; a submitted request is not a cast.
function lastcast(skill)
    local me = GetClientPlayer()
    if not me or tLastCast.player ~= me.dwID then return false end
    local id = tonumber(skill) or GetPlayerSkillInfo(skill)
    return id ~= nil and id == tLastCast.skill
end

local function GetSkillCD(szText)
	local me = GetClientPlayer()
	local dwSkillID, dwLevel = GetPlayerSkillInfo(szText)
	if dwSkillID then
		local bCool, nLeft, nTotal = me.GetSkillCDProgress(dwSkillID, dwLevel)
		return nLeft / GLOBAL.GAME_FPS
	end
	return 0
end


local function GetItemPos(szText)
	local me = GetClientPlayer()
	for dwBox = 1, 6 do
		local dwSize = me.GetBoxSize(dwBox)
		if dwSize > 0 then
			for dwX = 0, dwSize - 1 do
				local item = me.GetItem(dwBox, dwX)
				if item and item.szName == szText then
					return dwBox, dwX
				end
			end
		end
	end
	return nil
end


local function GetBagFreeBoxList()
	local me = GetClientPlayer()
	local tBoxTable = {}
	for nIndex = 6, 1, -1 do
		local dwBox = INVENTORY_INDEX.PACKAGE + nIndex - 1
		local dwSize = me.GetBoxSize(dwBox)
		if dwSize > 0 then
			for dwX = dwSize, 1, -1 do
				local item = me.GetItem(dwBox, dwX - 1)
				if not item then
					local i, j = dwBox, dwX - 1
					table.insert(tBoxTable, {i, j})
				end
			end
		end
	end
	return tBoxTable
end

local tStaticBuffNames = {
	["Thương Dương Chỉ"] = 666, ["Thuong Duong Chi"] = 666, ["thuong duong chi"] = 666, ["Thương Dương"] = 666, ["Thuong Duong"] = 666, ["thuong duong"] = 666, ["商阳指"] = 666,
	["Chung Linh Dục Tú"] = 714, ["Chung Linh Duc Tu"] = 714, ["chung linh duc tu"] = 714, ["Chung Linh"] = 714, ["Chung linh"] = 714, ["chung linh"] = 714, ["钟林毓秀"] = 714,
	["Lan Thôi Ngọc Chiết"] = 711, ["Lan Thoi Ngoc Chiet"] = 711, ["lan thoi ngoc chiet"] = 711, ["Lan Thôi"] = 711, ["Lan Thoi"] = 711, ["lan thoi"] = 711, ["兰摧玉折"] = 711, ["兰摧"] = 711,
	["Lan Tồi Thính Phong"] = 715, ["Lan Toi Thinh Phong"] = 715,
	["Xuân Nê Hộ Hoa"] = 122, ["Xuan Ne Ho Hoa"] = 122, ["xuan ne ho hoa"] = 122, ["Xuân Nê"] = 122, ["Xuan Ne"] = 122, ["xuan ne"] = 122, ["春泥护花"] = 122,
	["Bích Thủy Thao Thiên"] = 113, ["Bich Thuy Thao Thien"] = 113, ["bich thuy thao thien"] = 113, ["Bích Thủy"] = 113, ["Bich Thuy"] = 113, ["bich thuy"] = 113, ["碧水滔天"] = 113,
	["Thủy Nguyệt Vô Gian"] = 412, ["Thuy Nguyet Vo Gian"] = 412, ["thuy nguyet vo gian"] = 412, ["Thủy Nguyệt"] = 412, ["Thuy Nguyet"] = 412, ["thuy nguyet"] = 412, ["水月无间"] = 412,
	["Cấp Khúc"] = 2920, ["Cap Khuc"] = 2920,
	["Thủy Thông Thiết"] = 4761, ["Thuy Thong Thiet"] = 4761,
	["Phệ Cốt"] = 886, ["Phe Cot"] = 886, ["phe cot"] = 886, ["phệ cốt"] = 886, ["噬骨"] = 886,
	["Tĩnh Minh"] = 4882, ["Tinh Minh"] = 4882, ["tinh minh"] = 4882,
	["Tứ Du"] = 4883, ["Tu Du"] = 4883,
	["Bích Lạc"] = 2495, ["Bich Lac"] = 2495, ["bich lac"] = 2495,
	["Loạn Tửu Thanh Hà"] = 2719, ["Loan Tuu Thanh Ha"] = 2719, ["loan tuu thanh ha"] = 2719, ["loan tuu"] = 2719, ["Loạn Tửu"] = 2719, ["Loan Tuu"] = 2719, ["Thanh Hà"] = 2719, ["Thanh Ha"] = 2719, ["thanh ha"] = 2719, ["Loạn Sái"] = 2726, ["Loan Sai"] = 2726, ["loan sai"] = 2726, ["乱洒青荷"] = 2719,
	["Quỷ Liễu Diệu Mặc"] = 4761, ["Quy Lieu Dieu Mac"] = 4761,
	["焚玉"] = 646,
}

local function IsBuffExist(tCache, szText, bSrc)
	-- Hỗ trợ cả ID thuần (1234), tên(ID), và mapping tên sang ID tĩnh
	local szID = type(szText) == "string" and szText:match("%((%d+)%)") or nil
	local nID = tonumber(szID or szText)
	if not nID and type(szText) == "string" then
		if tStaticBuffNames[szText] then
			nID = tStaticBuffNames[szText]
		elseif tStaticBuffNames[string.lower(szText)] then
			nID = tStaticBuffNames[string.lower(szText)]
		end
	end
	local me = (MeCache and MeCache.Get and MeCache:Get()) or (GetClientPlayer and GetClientPlayer())
	local myID = (me and me.dwID) or (UI_GetClientPlayerID and UI_GetClientPlayerID()) or nil
	for k, v in pairs(tCache) do
		local szBuffName = Table_GetBuffName and Table_GetBuffName(v.dwID, v.nLevel)
		-- Client 80 cu co the khong tra dwSkillSrcID. Neu source bi thieu/0,
		-- chap nhan buff thay vi lam mbuff/nombuff luon sai.
		local bOwn = (not bSrc)
			or (v.dwSkillSrcID == nil)
			or (tonumber(v.dwSkillSrcID or 0) == 0)
			or (myID and tonumber(v.dwSkillSrcID or 0) == tonumber(myID))
		if bOwn then
			-- Ho tro ca 2 ma Buff cua Lan Thoi Ngoc Chiet (711 va 715)
			if (nID == 711 or nID == 715) and (v.dwID == 711 or v.dwID == 715) then
				return v
			-- Ho tro ca 2 ma Buff cua Loan Tuu Thanh Ha (2719 cong noi va 2726 tuc thoi)
			elseif (nID == 2719 or nID == 2726) and (v.dwID == 2719 or v.dwID == 2726) then
				return v
			-- Ho tro ca 2 ma Buff cua Thuy Nguyet Vo Gian (412 va 645)
			elseif (nID == 412 or nID == 645) and (v.dwID == 412 or v.dwID == 645) then
				return v
			-- Ho tro ca 2 ma Buff cua Bich Thuy Thao Thien (113 va 637)
			elseif (nID == 113 or nID == 637) and (v.dwID == 113 or v.dwID == 637) then
				return v
			-- Ho tro ca 2 ma Buff cua Xuan Ne Ho Hoa (122 va 631)
			elseif (nID == 122 or nID == 631) and (v.dwID == 122 or v.dwID == 631) then
				return v
			elseif nID and v.dwID == nID then
				return v
			elseif type(szText) == "string" and szBuffName and szBuffName == szText then
				return v
			end
		end
	end
	return nil
end


local function IsAuraExist(szText)
	for k, v in pairs(tNpcList) do
		local npc = GetNpc(k)
		if npc and StringFindW(npc.szName, szText) then
			if v[2] == UI_GetClientPlayerID() then
				return v
			end
		end
	end
	return nil
end


local function GetDistanceByTarget(res, tar)
	if not res or not tar then
		return false
	end
	local nDist = math.floor(((res.nX - tar.nX) ^ 2 + (res.nY - tar.nY) ^ 2 + (res.nZ/8 - tar.nZ/8) ^ 2) ^ 0.5) / 64
	return tonumber(string.format("%.1f", nDist))
end


local function MyGetBuffList(tar)
	tar = tar or GetClientPlayer()
	local aBuff = {}
	if not tar then return aBuff end

	-- Client 80 cũ có thể trả danh sách buff trực tiếp. Ưu tiên API này nếu có.
	if tar.GetBuffList then
		local ok, list = pcall(function() return tar.GetBuffList() end)
		if ok and list then
			for _, v in pairs(list) do
				if v and v.dwID then
					v.nLevel = v.nLevel or v.dwLevel or 1
					v.nStackNum = v.nStackNum or v.dwStackNum or 1
					v.nEndFrame = v.nEndFrame or v.dwEndFrame or 0
					table.insert(aBuff, v)
				end
			end
			-- Nếu API cũ tồn tại nhưng trả cấu trúc khác, đừng kết luận danh sách rỗng; thử API fallback bên dưới.
			if #aBuff > 0 then
				return aBuff
			end
		end
	end

	-- Fallback cho API GetBuffCount/GetBuff. Dùng pcall để lỗi API không làm chết toàn bộ macro.
	if tar.GetBuffCount and tar.GetBuff then
		local okCount, nCount = pcall(function() return tar.GetBuffCount() end)
		if okCount and nCount then
			for i = 0, nCount - 1 do
				local okBuff, dwID, nLevel, bCanCancel, nEndFrame, nIndex, nStackNum, dwSkillSrcID, bValid = pcall(function()
					return tar.GetBuff(i)
				end)
				if okBuff and dwID then
					table.insert(aBuff, {
						dwID = dwID, nLevel = nLevel or 1, bCanCancel = bCanCancel, nEndFrame = nEndFrame or 0,
						nIndex = nIndex, nStackNum = nStackNum or 1, dwSkillSrcID = dwSkillSrcID, bValid = bValid,
					})
				end
			end
		end
	end

	return aBuff
end

local function GetAngle(me, tar)
	if not tar then return nil end
	local nX, nY = tar.nX - me.nX, tar.nY - me.nY
	local nFace, nDeg = me.nFaceDirection / 256 * 360, 0
	if nY == 0 then
		if nX < 0 then
			nDeg = 180
		end
	elseif nX == 0 then
		if nY > 0 then
			nDeg = 90
		else
			nDeg = 270
		end
	else
		nDeg = math.deg(math.atan(nY / nX))
		if nX < 0 then
			nDeg = 180 + nDeg
		elseif nY < 0 then
			nDeg = 360 + nDeg
		end
	end
	local nAngle = nFace - nDeg
	if nAngle < -180 then
		nAngle = nAngle + 360
	elseif nAngle > 180 then
		nAngle = nAngle - 360
	end
	return math.abs(nAngle)
end

--------------------------------------------------------
-- 条件判断
--------------------------------------------------------
-- 判断目标类型
local function CheckTarget(tar, szText)
	if not tar then return false end
	local tTypes, bRet = SplitString(szText, "|"), false
	for _, szType in ipairs(tTypes) do
		if szType == "player" and IsPlayer(tar.dwID) then
			bRet = true
		elseif szType == "npc" and not IsPlayer(tar.dwID) then
			bRet = true
		elseif szType == "boss" and (GetNpcIntensity(tar) == 4) then
			bRet = true
		elseif szType == "Cọc gỗ" and StringFindW(tar.szName, szType) then
			bRet = true
		end
	end
	return bRet
end

local function CheckForce(tar, szText)
	if not tar then return false end
	local tForce = SplitString(szText, "|")
	for _, szForce in ipairs(tForce) do
		if GetForceTitle(tar.dwForceID) == szForce then
			return true
		end
	end
	return false
end

local function CheckStatus(tar, szText)
	if not tar then return false end
	local tState = SplitString(szText, "|")
	for _, szState in ipairs(tState) do
		if tar.nMoveState == tStatus[szState] then
			return true
		end
	end
	return false
end

local function CheckName(tar, szText)
	if not tar then return false end
	local tName = SplitString(szText, "|")
	for _, szName in ipairs(tName) do
		if tar.szName == szName then
			return true
		end
	end
	return false
end

local function CheckMount(tar, szText)
	if not tar then return false end
	local tMount = SplitString(szText, "|")
	for _, szMount in ipairs(tMount) do
		local szSkill = tar.GetKungfuMount().szSkillName
		if szSkill == szMount or szMount == "Trị liệu" and (szSkill == "Vân Thường Tâm Kinh" or szSkill == "Bổ Thiên Quyết" or szSkill == "Ly Kinh Dịch Đạo") then
			return true
		end
	end
	return false
end

local function CheckPet(szText)
	local frame = Station.Lookup("Normal/PetActionBar")
	if frame and frame:IsVisible() then
		if szText then
			local tName = SplitString(szText, "|")
			for _, szName in ipairs(tName) do
				if szName == tPet[frame.dwNpcTemplateID] then
					return true
				end
			end
			return false
		end
		return true
	end
	return false
end

local function CheckPuppet(szText)
	local frame = Station.Lookup("Normal/PuppetActionBar")
	if frame and frame:IsVisible() then
		if szText then
			local tName = SplitString(szText, "|")
			for _, v in ipairs(tName) do
				local szName, szCmp, szVal = v:match("(.-)([<>=]+)(.+)")
				if szName and szCmp and szVal then
					if frame.dwNpcTemplateID == 16174 then
						return true
					else
						if szName == tPuppet[frame.dwNpcTemplateID] then
							for kk, vv in pairs(tNpcList) do
								if vv[1] == frame.dwNpcTemplateID and vv[2] == UI_GetClientPlayerID() then
									local nTime = math.floor(tPuppetList[frame.dwNpcTemplateID] - (GetTime() - vv[3]) / 1000)
									Output(nTime)
									return Compare(szCmp, nTime, szVal)
								end
							end
						end
					end
				else
					if v == tPuppet[frame.dwNpcTemplateID] then
						return true
					end
				end
			end
			return false
		end
		return true
	end
	return false
end


local function CheckSkillCD(szText, bCool)
	local szOper, bAnd = "|", false
	if StringFindW(szText, "-") then
		szOper, bAnd = "-", true
	end
	local tText = SplitString(szText, szOper)
	for _, szSkillName in ipairs(tText) do
		local nLeft = GetSkillCD(szSkillName)
		if bCool then
			if nLeft > 0 and szOper == "|" then
				return true
			elseif nLeft <= 0 and szOper == "-" then
				return false
			end
		else
			if nLeft <= 0 and szOper == "|" then
				return true
			elseif nLeft > 0 and szOper == "-" then
				return false
			end
		end
	end
	return bAnd
end


local function CheckCDTime(szText)
	local szOper, bAnd = "|", false
	if StringFindW(szText, "-") then
		szOper, bAnd = "-", true
	end
	local tText = SplitString(szText, szOper)
	for _, v in ipairs(tText) do
		local szName, szCmp, szVal = v:match("(.-)([<>=]+)(.+)")
		if szName and szCmp and szVal then
			local nLeft = GetSkillCD(szName)
			if Compare(szCmp, nLeft, szVal) and szOper == "|" then
				return true
			elseif not Compare(szCmp, nLeft, szVal) and szOper == "-" then
				return false
			end
		end
	end
	return bAnd
end


local function CheckBuff(tar, szText, bTime, bSrc)
	if not tar then return false end
	local szOper, bAnd = "|", false
	if StringFindW(szText, "-") then
		szOper, bAnd = "-", true
	end
	local tText = SplitString(szText, szOper)
	local tCache = MyGetBuffList(tar) or {}
	for _, szCmd in ipairs(tText) do
		local szName, szCmp, szVal = szCmd:match("(.-)([<>=]+)(.+)")
		if szName and szCmp and szVal then
			local tBuff = IsBuffExist(tCache, szName, bSrc)
			if tBuff then
				if bTime then
					local nTime = (tBuff.nEndFrame - GetLogicFrameCount()) / GLOBAL.GAME_FPS
					if Compare(szCmp, nTime, szVal) and szOper == "|" then
						return true
					elseif not Compare(szCmp, nTime, szVal) and szOper == "-" then
						return false
					end
				else
					local nStack = tBuff.nStackNum
					if Compare(szCmp, nStack, szVal) and szOper == "|" then
						return true
					elseif not Compare(szCmp, nStack, szVal) and szOper == "-" then
						return false
					end
				end
			end
		else
			local tBuff = IsBuffExist(tCache, szCmd, bSrc)
			if tBuff and szOper == "|" then
				return true
			elseif not tBuff and szOper == "-" then
				return false
			end
		end
	end
	return bAnd
end


local function CheckNoBuff(tar, szText, bSrc)
	if not tar then
		-- Neu chua chon target hoac target handle chua khoi tao: Coi nhu CHUA CO BUFF de cho phep mo dau combo!
		return true
	end
	local szOper, bAnd = "-", true
	if StringFindW(szText, "|") then
		szOper, bAnd = "|", false
	end
	local tText = SplitString(szText, szOper)
	local tCache = MyGetBuffList(tar) or {}
	for _, szCmd in ipairs(tText) do
		local tBuff = IsBuffExist(tCache, szCmd, bSrc)
		if tBuff and szOper == "-" then
			return false
		elseif not tBuff and szOper == "|" then
			return true
		end
	end
	return bAnd
end


local function CheckAura(szText)
	local szOper, bAnd = "|", false
	if StringFindW(szText, "-") then
		szOper, bAnd = "-", true
	end
	local tText = SplitString(szText, szOper)
	for _, szCmd in ipairs(tText) do
		local szName, szCmp, szVal = szCmd:match("(.-)([<>=]+)(.+)")
		if szName and szCmp and szVal then
			local tNpc = IsAuraExist(szName)
			if tNpc then
				local nTime = math.floor(tAuraList[tNpc[1]] - (GetTime() - tNpc[3]) / 1000)
				if Compare(szCmp, nTime, szVal) and szOper == "|" then
					return true
				elseif not Compare(szCmp, nTime, szVal) and szOper == "-" then
					return false
				end
			end
		else
			local tNpc = IsAuraExist(szCmd)
			if tNpc and szOper == "|" then
				return true
			elseif not tNpc and szOper == "-" then
				return false
			end
		end
	end
	return bAnd
end


local function CheckNoAura(szText)
	local szOper, bAnd = "-", true
	if StringFindW(szText, "|") then
		szOper, bAnd = "|", false
	end
	local tText = SplitString(szText, szOper)
	for _, szCmd in ipairs(tText) do
		local tNpc = IsAuraExist(szCmd)
		if tNpc and szOper == "-" then
			return false
		elseif not tNpc and szOper == "|" then
			return true
		end
	end
	return bAnd
end


local function CheckDetach(tar, szType, szText)
	if not tar then return false end
	local tCache = MyGetBuffList(tar) or {}
	szText = StringReplaceW(szText, "-", "|")
	local tText = SplitString(szText, "|")
	for _, szBuff in ipairs(tText) do
		for _, v in pairs(tCache) do
			local szBuffName = Table_GetBuffName(v.dwID, v.nLevel)
			if Table_BuffIsVisible(v.dwID, v.nLevel) then
				local nType = GetBuffInfo(v.dwID, v.nLevel, {}).nDetachType
				if nType ~= 0 then
					local szDetype = tDetachType[szType][nType]
					if szDetype and v == szDetype then
						return true
					end
				end
			end
		end
	end
	return false
end


local function CheckPrepare(tar, szText)
	if not tar or not tar.GetSkillPrepareState then return false end
	local ok, bPre, dwID, dwLevel, fP = pcall(function() return tar.GetSkillPrepareState() end)
	if not ok or not (bPre == true or (type(bPre) == "number" and bPre ~= 0)) then return false end
	local szSkillName
	if szText and Table_GetSkillName then
		local named, name = pcall(Table_GetSkillName, dwID, dwLevel)
		if named then szSkillName = name end
	end
	if bPre then
		if szText then
			local tSkill = SplitString(szText, "|")
			for _, szSkill in ipairs(tSkill) do
				local szName, szCmp, szVal = szSkill:match("(.-)([<>=]+)(.+)")
				if szName and szCmp and szVal then
					if szSkillName == szName then
						if Compare(szCmp, fP, szVal) then
							return true
						end
					end
				else
					if szSkillName == szSkill or tostring(dwID) == szSkill or (szSkill == "Duong Minh Chi" and dwID == 179) or (szSkill == "Dương Minh Chỉ" and dwID == 179) then
						return true
					end
				end
			end
			return false
		end
		return true
	end
	return false
end
--------------------------------------------------------

--------------------------------------------------------
local tOptions = {

	["distance"] = function(szCmp, szVal, me, tar)
		if not tar then
			return false
		end
		local nDist = GetDistanceByTarget(me, tar)
		return Compare(szCmp, nDist, szVal)
	end,

	["mounted"] = function(szCmp, szVal, me, tar)
		return me.bOnHorse
	end,

	["horse"] = function(szCmp, szVal, me, tar)
		return me.bOnHorse
	end,

	["unmounted"] = function(szCmp, szVal, me, tar)
		return not me.bOnHorse
	end,

	["nomounted"] = function(szCmp, szVal, me, tar)
		return not me.bOnHorse
	end,

	["nohorse"] = function(szCmp, szVal, me, tar)
		return not me.bOnHorse
	end,

	["combat"] = function(szCmp, szVal, me, tar)
		return me.bFightState
	end,

	["fight"] = function(szCmp, szVal, me, tar)
		return me.bFightState
	end,

	["nocombat"] = function(szCmp, szVal, me, tar)
		return not me.bFightState
	end,

	["nofight"] = function(szCmp, szVal, me, tar)
		return not me.bFightState
	end,

	["otaction"] = function(szCmp, szVal, me, tar)
		if szVal == "0" or szVal == "1" or szVal == "2" then
			return me.GetOTActionState() == tonumber(szVal)
		end
		return CheckPrepare(me, szVal)
	end,

	["ota"] = function(szCmp, szVal, me, tar)
		if szVal == "0" or szVal == "1" or szVal == "2" then
			return me.GetOTActionState() == tonumber(szVal)
		end
		return CheckPrepare(me, szVal)
	end,

	["nootaction"] = function(szCmp, szVal, me, tar)
		return not CheckPrepare(me, szVal)
	end,

	["noota"] = function(szCmp, szVal, me, tar)
		return not CheckPrepare(me, szVal)
	end,

	["exists"] = function(szCmp, szVal, me, tar)
		if tar then
			return true
		end
		return false
	end,

	["noexists"] = function(szCmp, szVal, me, tar)
		if not tar then
			return true
		end
		return false
	end,

	["dead"] = function(szCmp, szVal, me, tar)
		if tar and tar.nMoveState == MOVE_STATE.ON_DEATH then
			return true
		end
		return false
	end,

	["nodead"] = function(szCmp, szVal, me, tar)
		if tar and tar.nMoveState ~= MOVE_STATE.ON_DEATH then
			return true
		end
		return false
	end,

	["rage"] = function(szCmp, szVal, me, tar)
		local nRage = me.nCurrentRage
		return Compare(szCmp, nRage, szVal)
	end,

	["qidian"] = function(szCmp, szVal, me, tar)
		local nAte = me.nAccumulateValue
		if me.dwForceID == 1 then
			if nAte > 3 then
				nAte = 3
			end
		end
		return Compare(szCmp, nAte, szVal)
	end,

	["sun"] = function(szCmp, szVal, me, tar)
		if szVal == "moon" then
			return Compare(szCmp, me.nCurrentSunEnergy, me.nCurrentMoonEnergy)
		end
		nPer = me.nCurrentSunEnergy / me.nMaxSunEnergy * 100
		return Compare(szCmp, nPer, szVal)
	end,

	["moon"] = function(szCmp, szVal, me, tar)
		if szVal == "sun" then
			return Compare(szCmp, me.nCurrentMoonEnergy, me.nCurrentSunEnergy)
		end
		nPer = me.nCurrentMoonEnergy / me.nMaxMoonEnergy * 100
		return Compare(szCmp, nPer, szVal)
	end,

	["fullsun"] = function(szCmp, szVal, me, tar)
		return me.nSunPowerValue == 1
	end,

	["fullmoon"] = function(szCmp, szVal, me, tar)
		return me.nMoonPowerValue == 1
	end,

	["nofullsun"] = function(szCmp, szVal, me, tar)
		return me.nSunPowerValue ~= 1
	end,

	["nofullmoon"] = function(szCmp, szVal, me, tar)
		return me.nMoonPowerValue ~= 1
	end,

	["sunhit"] = function(szCmp, szVal, me, tar)
		return Compare(szCmp, nNextSunLevel, szVal)
	end,

	["moonhit"] = function(szCmp, szVal, me, tar)
		return Compare(szCmp, nNextMoonLevel, szVal)
	end,

	["life"] = function(szCmp, szVal, me, tar)
		local nPer = me.nCurrentLife / me.nMaxLife
		return Compare(szCmp, nPer, szVal)
	end,

	["mana"] = function(szCmp, szVal, me, tar)
		local nPer = me.nCurrentMana / me.nMaxMana
		return Compare(szCmp, nPer, szVal)
	end,

	["tlife"] = function(szCmp, szVal, me, tar)
		if not tar then
			return false
		end
		if tonumber(szVal) > 1 then
			return Compare(szCmp, tar.nCurrentLife, szVal)
		end
		local nPer = tar.nCurrentLife / tar.nMaxLife
		return Compare(szCmp, nPer, szVal)
	end,

	["tmaxlife"] = function(szCmp, szVal, me, tar)
		if not tar then
			return false
		end
		return Compare(szCmp, tar.nMaxLife, szVal)
	end,

	["ttlife"] = function(szCmp, szVal, me, tar)
		local ttar = GetTargetHandle(tar.GetTarget())
		if not ttar then
			return false
		end
		local nPer = ttar.nCurrentLife / ttar.nMaxLife
		return Compare(szCmp, nPer, szVal)
	end,

	["tmana"] = function(szCmp, szVal, me, tar)
		if not tar then
			return false
		end
		local nPer = tar.nCurrentMana / tar.nMaxMana
		return Compare(szCmp, nPer, szVal)
	end,

	["energy"] = function(szCmp, szVal, me, tar)
		local nEgy = me.nCurrentEnergy
		return Compare(szCmp, nEgy, szVal)
	end,

	["tm"] = function(szCmp, szVal, me, tar)
		local nEgy = me.nCurrentEnergy
		return Compare(szCmp, nEgy, szVal)
	end,

	["bomb"] = function(szCmp, szVal, me, tar)
		local nBmb = 0
		for z, x in pairs(tNpcList) do
			local npc = GetNpc(z)
			if npc and npc.dwTemplateID == 16000 and npc.dwEmployer == me.dwID then
				nBmb = nBmb + 1
			end
		end
		return Compare(szCmp, nBmb, szVal)
	end,

	["psd"] = function(szCmp, szVal, me, tar)
		local frame = Station.Lookup("Normal/PuppetActionBar")
		if frame and frame:IsVisible() then
			for k, v in pairs(tNpcList) do
				if v[1] == frame.dwNpcTemplateID and v[2] == me.dwID then
					local npc = GetNpc(k)
					if npc then
						local nDist = GetDistanceByTarget(me, npc)
						return Compare(szCmp, nDist, szVal)
					end
					return false
				end
			end
		end
		return false
	end,

	["ptd"] = function(szCmp, szVal, me, tar)
		local frame = Station.Lookup("Normal/PuppetActionBar")
		if frame and frame:IsVisible() then
			for k, v in pairs(tNpcList) do
				if v[1] == frame.dwNpcTemplateID and v[2] == me.dwID then
					local npc = GetNpc(k)
					if npc then
						local nDist = GetDistanceByTarget(tar, npc)
						return Compare(szCmp, nDist, szVal)
					end
					return false
				end
			end
		end
		return false
	end,

	["puppet"] = function(szCmp, szVal, me, tar)
		return CheckPuppet(szVal)
	end,

	["nopuppet"] = function(szCmp, szVal, me, tar)
		return not CheckPuppet(szVal)
	end,

	["prepare"] = function(szCmp, szVal, me, tar)
		return CheckPrepare(tar, szVal)
	end,

	["tprepare"] = function(szCmp, szVal, me, tar)
		return CheckPrepare(tar, szVal)
	end,

	["notprepare"] = function(szCmp, szVal, me, tar)
		return not CheckPrepare(tar, szVal)
	end,

	["target"] = function(szCmp, szVal, me, tar)
		return CheckTarget(tar, szVal)
	end,

	["mount"] = function(szCmp, szVal, me, tar)
		return CheckMount(me, szVal)
	end,

	["nomount"] = function(szCmp, szVal, me, tar)
		return not CheckMount(me, szVal)
	end,

	["tname"] = function(szCmp, szVal, me, tar)
		return CheckName(tar, szVal)
	end,

	["tnoname"] = function(szCmp, szVal, me, tar)
		return not CheckName(tar, szVal)
	end,

	["tforce"] = function(szCmp, szVal, me, tar)
		return CheckForce(tar, szVal)
	end,

	["ttforce"] = function(szCmp, szVal, me, tar)
		local ttar = GetTargetHandle(tar.GetTarget())
		return CheckForce(ttar, szVal)
	end,

	["status"] = function(szCmp, szVal, me, tar)
		return CheckStatus(me, szVal)
	end,

	["nostatus"] = function(szCmp, szVal, me, tar)
		return not CheckStatus(me, szVal)
	end,

	["tstatus"] = function(szCmp, szVal, me, tar)
		return CheckStatus(tar, szVal)
	end,

	["tnostatus"] = function(szCmp, szVal, me, tar)
		return not CheckStatus(tar, szVal)
	end,

	["state"] = function(szCmp, szVal, me, tar)
		return CheckStatus(me, szVal)
	end,

	["nostate"] = function(szCmp, szVal, me, tar)
		return not CheckStatus(me, szVal)
	end,

	["tstate"] = function(szCmp, szVal, me, tar)
		return CheckStatus(tar, szVal)
	end,

	["tnostate"] = function(szCmp, szVal, me, tar)
		return not CheckStatus(tar, szVal)
	end,

	["moving"] = function(szCmp, szVal, me, tar)
		if not me then return false end
		local nStand = (MOVE_STATE and MOVE_STATE.ON_STAND) or 0
		return (me.nMoveState or 0) ~= nStand
	end,

	["nomoving"] = function(szCmp, szVal, me, tar)
		if not me then return true end
		local nStand = (MOVE_STATE and MOVE_STATE.ON_STAND) or 0
		return (me.nMoveState or 0) == nStand
	end,

	["cd"] = function(szCmp, szVal, me, tar)
		return CheckSkillCD(szVal, true)
	end,

	["nocd"] = function(szCmp, szVal, me, tar)
		return CheckSkillCD(szVal, false)
	end,

	["cdtime"] = function(szCmp, szVal, me, tar)
		return CheckCDTime(szVal)
	end,

	["pet"] = function(szCmp, szVal, me, tar)
		return CheckPet(szVal)
	end,

	["nopet"] = function(szCmp, szVal, me, tar)
		return not CheckPet(szVal)
	end,

	["buff"] = function(szCmp, szVal, me, tar)
		return CheckBuff(me, szVal, false, false)
	end,

	["tbuff"] = function(szCmp, szVal, me, tar)
		return CheckBuff(tar, szVal, false, false)
	end,

	["mbuff"] = function(szCmp, szVal, me, tar)
		return CheckBuff(tar, szVal, false, true)
	end,

	["bufftime"] = function(szCmp, szVal, me, tar)
		return CheckBuff(me, szVal, true, false)
	end,

	["bt"] = function(szCmp, szVal, me, tar)
		return CheckBuff(me, szVal, true, false)
	end,

	["tbufftime"] = function(szCmp, szVal, me, tar)
		return CheckBuff(tar, szVal, true, false)
	end,

	["tbt"] = function(szCmp, szVal, me, tar)
		return CheckBuff(tar, szVal, true, false)
	end,

	["mbufftime"] = function(szCmp, szVal, me, tar)
		return CheckBuff(tar, szVal, true, true)
	end,

	["mbt"] = function(szCmp, szVal, me, tar)
		return CheckBuff(tar, szVal, true, true)
	end,

	["nobuff"] = function(szCmp, szVal, me, tar)
		return CheckNoBuff(me, szVal, false)
	end,

	["tnobuff"] = function(szCmp, szVal, me, tar)
		return CheckNoBuff(tar, szVal, false)
	end,

	["nombuff"] = function(szCmp, szVal, me, tar)
		return CheckNoBuff(tar, szVal, true)
	end,

	["mnobuff"] = function(szCmp, szVal, me, tar)
		return CheckNoBuff(tar, szVal, true)
	end,

	["btype"] = function(szCmp, szVal, me, tar)
		return CheckDetach(me, "btype", szVal)
	end,

	["detype"] = function(szCmp, szVal, me, tar)
		return CheckDetach(me, "detype", szVal)
	end,

	["tbtype"] = function(szCmp, szVal, me, tar)
		return CheckDetach(tar, "btype", szVal)
	end,

	["tdetype"] = function(szCmp, szVal, me, tar)
		return CheckDetach(tar, "btype", szVal)
	end,

	["threat"] = function(szCmp, szVal, me, tar)
		if tar then
			ApplyCharacterThreatRankList(tar.dwID)
			if dwCurrentTargetID ~= tar.dwID then
				dwCurrentTargetID = tar.dwID
			end
			return Compare(szCmp, dwMyHatred, szVal)
		end
		return false
	end,

	["aura"] = function(szCmp, szVal, me, tar)
		return CheckAura(szVal)
	end,

	["qichang"] = function(szCmp, szVal, me, tar)
		return CheckAura(szVal)
	end,

	["noaura"] = function(szCmp, szVal, me, tar)
		return CheckNoAura(szVal)
	end,

	["noqichang"] = function(szCmp, szVal, me, tar)
		return CheckNoAura(szVal)
	end,

	["angle"] = function(szCmp, szVal, me, tar)
		if not tar then
			return false
		end
		local nAngle = GetAngle(me, tar)
		if nAngle then
			return Compare(szCmp, nAngle, szVal)
		end
		return false
	end,
	--机关或宠物攻击状态
	["pstate"] = function(szCmp, szVal, me, tar)
		if szVal == "attack" then
			return bAttackState
		elseif szVal == "stop" then
			return not bAttackState
		end
		return false
	end,

	["gcd"] = function(szCmp, szVal, me, tar)
		local bCool, nLeft, nTotal = me.GetSkillCDProgress(53, 1)
		local nTime = nLeft / GLOBAL.GAME_FPS
		return Compare(szCmp, nTime, szVal)
	end,

	["npcs"] = function(szCmp, szVal, me, tar)
		local nNum = 0
		local a, b, c = szVal:match("(%d+)([<>=]+)(%d+)")
		for k, v in pairs(tNpcList) do
			local npc = GetNpc(k)
			if npc and IsEnemy(me.dwID, k) and GetDistanceByTarget(me, npc) <= tonumber(a) then
				nNum = nNum + 1
			end
		end
		return Compare(b, nNum, c)
	end,

	["tnpcs"] = function(szCmp, szVal, me, tar)
		local nNum = 0
		local a, b, c = szVal:match("(%d+)([<>=]+)(%d+)")
		for k, v in pairs(tNpcList) do
			local npc = GetNpc(k)
			if npc and IsEnemy(tar.dwID, k) and GetDistanceByTarget(tar, npc) <= tonumber(a) then
				nNum = nNum + 1
			end
		end
		return Compare(b, nNum, c)
	end,

	["lastota"] = function(szCmp, szVal, me, tar)
		return szLastOTA == szVal
	end,

	["lastcast"] = function(szCmp, szVal, me, tar)
		return lastcast(szVal)
	end,

	["nolastcast"] = function(szCmp, szVal, me, tar)
		return not lastcast(szVal)
	end,

	["nolastota"] = function(szCmp, szVal, me, tar)
		return szLastOTA ~= szVal
	end,
}
setmetatable(tOptions, {__index = function(t, k)
	local function callback(...)
		if k == "true" then
			return true
		elseif k == "false" then
			return false
		else
			if string.sub(k, 1, 1) == "!" then
				if string.sub(k, 2, 2) == "t" then
					k = "tno" .. string.sub(k, 3, -1)
				else
					k = "no" .. string.sub(k, 2, -1)
				end
				return t[k](...)
			else
				print("Tham số [" .. k .. "] sai!")
				return false
			end
		end
	end
	return callback
end})


local function UITestCast(dwSkillID, dwLevel, index)
	local me = (MeCache and MeCache.Get and MeCache:Get()) or GetClientPlayer()
	if not me then return false end

	-- 1. Khong duoc cast neu dang thi trien chieu (prepare / channel)
	if me.GetSkillPrepareState and me.GetSkillPrepareState() then
		return false
	end
	local okOT, nOT = pcall(function() return me.GetOTActionState() end)
	if okOT and tonumber(nOT or 0) ~= 0 then
		return false
	end

	-- 2. Anti-double-cast debounce cho Chung Linh Duc Tu (189) va Lan Thoi Ngoc Chiet (190)
	if (dwSkillID == 189 or dwSkillID == 190) and tSkillCastFrame then
		local nCur = (GetLogicFrameCount and GetLogicFrameCount()) or 0
		if (nCur - (tSkillCastFrame[dwSkillID] or 0)) <= 36 then
			return false
		end
	end

	-- 3. Kiem tra Cooldown qua Engine Player truc tiep (chinh xac 100%, khong phu thuoc UI)
	if me.GetSkillCDProgress then
		local bCool, nLeft = me.GetSkillCDProgress(dwSkillID, dwLevel or 1)
		if bCool and tonumber(nLeft or 0) > 0 then
			return false
		end
	end
	-- 4. Kiem tra qua UI Box neu co (chi kiem tra IsObjectCoolDown, khong dung IsObjectEnable de tranh bi chan goc mat/cu ly tren dummy box)
	local box = tSkillBox[index]
	if box and box.SetObject then
		box:SetObject(UI_OBJECT_SKILL, dwSkillID, dwLevel or 1)
		if UpdataSkillCDProgress then
			UpdataSkillCDProgress(me, box)
		end
		if box.IsObjectCoolDown and box:IsObjectCoolDown() then
			return false
		end
	end
	return true
end


local function GetPetSkill(szSkill)
	local frame = Station.Lookup("Normal/PetActionBar")
	if frame then
		local tSkill = Table_GetPetSkill(frame.dwNpcTemplateID)
		for v, k in pairs(tSkill) do
			local szSkillName = Table_GetSkillName(k[1], k[2])
			if szSkill == szSkillName then
				return k[1], k[2]
			end
		end
	end
	return nil
end


local function GetCurrentTargetObject()
	local tar = nil
	if HM and HM.GetTarget then
		local ok, hTar = pcall(HM.GetTarget)
		if ok and hTar and hTar.dwID and hTar.dwID > 0 then
			return hTar
		end
	end
	local me = GetClientPlayer()
	if not me then return nil end
	if GetTargetHandle and me.GetTarget then
		local ok, hTar = pcall(function() return GetTargetHandle(me.GetTarget()) end)
		if ok and hTar and hTar.dwID and hTar.dwID > 0 then
			return hTar
		end
	end
	if me.GetTarget then
		local ok, t1, t2 = pcall(me.GetTarget)
		if ok and t1 then
			local tarID = (type(t2) == "number" and t2 > 0) and t2 or ((type(t1) == "number" and t1 > 0) and t1 or nil)
			if tarID and tarID > 0 then
				if GetNpc then
					local okNpc, npc = pcall(GetNpc, tarID)
					if okNpc and npc and npc.dwID and npc.dwID > 0 then
						return npc
					end
				end
				if GetPlayer then
					local okPl, pl = pcall(GetPlayer, tarID)
					if okPl and pl and pl.dwID and pl.dwID > 0 then
						return pl
					end
				end
			end
		end
	end
	return nil
end
_G.GetCurrentTargetObject = GetCurrentTargetObject

local function ProcessCondition(szText)
	if not szText then return end
	szText = string.gsub(szText, "%&", ",")
	local function fnBracket(szText)
		while string.find(szText, "%b()") do
			szText = string.sub(szText:match("%b()"), 2, -2)
		end
		return szText
	end
	local function ProcessOperation(szText)
		local function fnOpt(szText)
			local me = GetClientPlayer() or MeCache:Get()
			local tar = GetCurrentTargetObject()
			MeCache:Set(me)
			TarCache:Set(tar)
			local tText = SplitString(szText, ",")
			for _, v in ipairs(tText) do
				local nStart, nEnd, szCmp = string.find(v, "([:<>=]+)")
				local szOpt, szVal
				if nStart then
					szOpt, szVal = string.sub(v, 1, nStart - 1), string.sub(v, nEnd + 1, -1)
				else
					szOpt, szVal = v, nil
				end
				local fn = tOptions[szOpt]
				if type(fn) ~= "function" then
					print("[xMacro] Unknown condition: " .. tostring(szOpt))
					return false
				end
				local ok, ret = pcall(fn, szCmp, szVal, me, tar)
				if not ok then
					print("[xMacro] Condition ERROR " .. tostring(szOpt) .. ": " .. tostring(ret))
					return false
				end
				if not ret then return false end
			end
			return true
		end
		if StringFindW(szText, ";") then
			local tText = SplitString(szText, ";")
			for _, v in ipairs(tText) do
				if fnOpt(v) then
					return true
				end
			end
		else
			if fnOpt(szText) then
				return true
			end
		end
		return false
	end
	local szRet, bRet = nil, nil
	while string.find(szText, "%b()") do
		szRet = fnBracket(szText)
		bRet = ProcessOperation(szRet)
		szText = string.gsub(szText, "%(" .. szRet .. "%)", tostring(bRet), 1)
	end
	return ProcessOperation(szText)
end

_G.ProcessCondition = ProcessCondition
_G.GetPlayerSkillInfo = GetPlayerSkillInfo
_G.GetSkillCD = GetSkillCD
_G.CheckSkillCD = CheckSkillCD
_G.GetBeforeCmd = function() return szBeforeCmd end


local function OnCastPlayerSkill(me, dwSkillID, dwLevel)
	if not (me and me.GetOTActionState and me.GetOTActionState() == 2 and bProtectChannelSkill) then
		local nCur = (GetLogicFrameCount and GetLogicFrameCount()) or 0
		if tSkillCastFrame then
			tSkillCastFrame[dwSkillID] = nCur
		end
		OnAddOnUseSkill(dwSkillID, dwLevel)
		local szName = (Table_GetSkillName and Table_GetSkillName(dwSkillID, dwLevel)) or tostring(dwSkillID)
		if XMCore_Sys then
			XMCore_Sys("[xMacro] -> " .. tostring(szName))
		end
		local skill = (GetSkill and GetSkill(dwSkillID, dwLevel)) or nil
		if ((skill and skill.bIsChannelSkill) or tChannelSkill[dwSkillID]) and bProtectChannelSkill then
			return false
		end
		return true
	end
	return true
end


RegisterEvent("UPDATE_SELECT_TARGET", function()
	local me = GetClientPlayer() or MeCache:Get()
	local tar = nil
	if me then
		tar = GetTargetHandle(me.GetTarget())
	end
	MeCache:Set(me)
	TarCache:Set(tar)
end)

RegisterEvent("CUSTOM_DATA_LOADED", function()
	if arg0 == "Role" then
		local frame = Wnd.OpenWindow("Interface\\xMacro\\xMacro.ini", "xMacro")
		local hBox = frame:Lookup("",""):Lookup("Handle_Box")
		tSkillBox[1] = hBox:Lookup("Box")
		tSkillBox[2] = hBox:Lookup("Box_P")
	end
end)


RegisterEvent("DO_SKILL_CAST", function()
	local me = GetClientPlayer()
	if me and tonumber(arg0) == tonumber(me.dwID) then
		local id = tonumber(arg1)
		if id and id > 0 then
			tLastCast = {skill=id,player=me.dwID,frame=GetLogicFrameCount()}
		end
		if me.dwForceID == 10 then
			if GetLogicFrameCount() - dwLastMoonTime >= 32 then
				nNextMoonLevel, dwLastMoonTime = 1, 0
			end
			if GetLogicFrameCount() - dwLastSunTime >= 32 then
				nNextSunLevel, dwLastSunTime = 1, 0
			end
			if tMoonSkill[arg1] then
				nNextMoonLevel, dwLastMoonTime = tMoonSkill[arg1] + 1, GetLogicFrameCount()
				if nNextMoonLevel > 3 then
					nNextMoonLevel, dwLastMoonTime = 1, 0
				end
			elseif tSunSkill[arg1] then
				nNextSunLevel, dwLastSunTime = tSunSkill[arg1] + 1, GetLogicFrameCount()
				if nNextSunLevel > 3 then
					nNextSunLevel, dwLastSunTime = 1, 0
				end
			end
		elseif me.dwForceID == 7 then
			if arg1 == 3360 then
				bAttackState = true
			elseif arg1 == 3382 or arg1 == 3368 or arg1 == 3369 then
				bAttackState = false
			end
		end
	end
end)


do
	for k, v in ipairs({"DO_SKILL_PREPARE_PROGRESS", "DO_SKILL_CHANNEL_PROGRESS"}) do
		RegisterEvent(v, function()
			szLastOTA = Table_GetSkillName(arg1, arg2)
		end)
	end
end


RegisterEvent("OT_ACTION_PROGRESS_BREAK", function()
	if arg0 == UI_GetClientPlayerID() and szLastOTA then
		szLastOTA = nil
	end
end)


RegisterEvent("CHARACTER_THREAT_RANKLIST", function()
	if arg0 == dwCurrentTargetID then
		if arg2 and arg1[arg2] then
			dwTargetRank = arg1[arg2]
			if dwTargetRank == 0 then
				dwTargetRank = 65535
			end
			local nHatred = arg1[UI_GetClientPlayerID()] or 0
			dwMyHatred = (nHatred / dwTargetRank) * 100
		else
			dwTargetRank = 65535
		end
	end
end)


RegisterEvent("NPC_ENTER_SCENE", function()
	local npc = GetNpc(arg0)
	if npc then
		if not tNpcList[arg0] then
			tNpcList[arg0] = {}
		end
		tNpcList[arg0] = {npc.dwTemplateID, npc.dwEmployer, GetTime()}
	end
end)


RegisterEvent("NPC_LEAVE_SCENE", function()
	local t = tNpcList[arg0]
	if t then
		if (t[1] == 16175 or t[1] == 16176 or t[1] == 16177) and t[2] == UI_GetClientPlayerID() then
			bAttackState = false
		end
		t = nil
	end
end)


RegisterEvent("SKILL_UPDATE", function()
	local me = GetClientPlayer()
	MeCache:Set(me)
	tAllSkill = me.GetAllSkillList()
end)


RegisterEvent("SYNC_ROLE_DATA_END", function()
	local me = GetClientPlayer()
	if arg0 == me.dwID then
		MeCache:Set(me)
		tAllSkill = me.GetAllSkillList()
	end
end)

local function ExecuteSkillCommand(szText)
	szText = szText or ""
	local szCondition, szContent = szText:match("^[ \t]*[%[](.+)[%]][ \t]*(.-)[ \t]*$")
	szText = szContent or szText
	szText = string.gsub(szText, "^[ \t]*(.-)[ \t]*$", "%1")
	local tSkills = SplitString(szText, ",")
	if (szBeforeCmd == "" or ProcessCondition(szBeforeCmd)) and (not szCondition or ProcessCondition(szCondition)) then
		local me = GetClientPlayer() or MeCache:Get()
		if not me then return end
		MeCache:Set(me)
		TarCache:Set(GetCurrentTargetObject())
		for _, v in ipairs(tSkills) do
			if v == "Nhảy lùi" then
				local bCool, nLeft, nTotal = me.GetSkillCDProgress(9007, 1)
				if not bCool or nLeft == 0 and nTotal == 0 then
					OnAddOnUseSkill(9007, 1)
				end
			elseif v == "Rút lui" then
				if UITestCast(9004, 1, 1) then
					return OnCastPlayerSkill(me, 9004, 1)
				end
			elseif v == "Ngồi thiền" or v == "Điều tức" then
				if me.nMoveState == ((MOVE_STATE and MOVE_STATE.ON_STAND) or 0) then
					OnAddOnUseSkill(17, 1)
				end
			elseif v == "stopota" or v == "dừng" then
				if me.GetOTActionState and me.GetOTActionState() ~= 0 then
					me.StopCurrentAction()
				end
			else
				local dwSkillID, dwLevel = GetPlayerSkillInfo(v)
				if dwSkillID then
					if UITestCast(dwSkillID, dwLevel, 1) then
						return OnCastPlayerSkill(me, dwSkillID, dwLevel)
					end
				else
					local dwForceID = me.dwForceID
					if dwForceID == 7 and tPuppetSkill and tPuppetSkill[v] then
						dwSkillID, dwLevel = unpack(tPuppetSkill[v])
						if dwSkillID and UITestCast(dwSkillID, dwLevel, 2) and (not me.GetOTActionState or me.GetOTActionState() ~= 2) then
							OnAddOnUseSkill(dwSkillID, dwLevel)
						end
					elseif dwForceID == 6 and GetPetSkill then
						dwSkillID, dwLevel = GetPetSkill(v)
						if dwSkillID and UITestCast(dwSkillID, dwLevel, 2) then
							OnAddOnUseSkill(dwSkillID, dwLevel)
						end
					end
				end
			end
		end
	end
end

local _tCommands = {}
local _OrigAppendCommand = AppendCommand
AppendCommand = function(szCmd, fn)
	if szCmd and fn then
		_tCommands[string.lower(szCmd)] = fn
	end
	if _OrigAppendCommand then
		return _OrigAppendCommand(szCmd, fn)
	end
end

AppendCommand("skill", ExecuteSkillCommand)
AppendCommand("cast", ExecuteSkillCommand)

AppendCommand("config", function(szText)
	szText = szText or ""
	szText = string.gsub(szText, "^[ \t]*(.-)[ \t]*$", "%1")
	if szText == "channel-on" then
		bProtectChannelSkill = true
	elseif szText == "channel-off" then
		bProtectChannelSkill = false
	end
	local nPos = string.find(szText, ":")
	if nPos then
		local szBefore = string.sub(szText, 1, nPos - 1)
		szBefore = string.gsub(szBefore, "^[ \t]*(.-)[ \t]*$", "%1")
		local szCmd = string.sub(szText, nPos + 1, -1)
		szCmd = string.gsub(szCmd, "^[ \t]*(.-)[ \t]*$", "%1")
		if szBefore == "before" then
			if szCmd == "null" or szCmd == "none" or szCmd == "" then
				szBeforeCmd = ""
			elseif string.sub(szCmd, 1, 1) == "[" and string.sub(szCmd, -1) == "]" then
				szBeforeCmd = string.sub(szCmd, 2, -2)
			else
				szBeforeCmd = szCmd
			end
		end
	end
end)

AppendCommand("if", function(szText)

	if szText == "" then
		return
	end
	szBeforeCmd = szText:sub(2, -2)
end)

AppendCommand("elseif", function(szText)

	if szText == "" then
		return
	end
	szBeforeCmd = szText:sub(2, -2)
end)

AppendCommand("else", function()
	szBeforeCmd = ""
end)

AppendCommand("end", function(szText)

	local szCondition = szText:match("%s*[%[](.+)[%]]%s*(.+)")
	if not szCondition then
		szBeforeCmd = ""
	else
		if (szBeforeCmd == "" or ProcessCondition(szBeforeCmd)) and ProcessCondition(szCondition) then
			return false
		end
	end
end)

AppendCommand("return", function(szText)

	if szBeforeCmd == "" or ProcessCondition(szBeforeCmd) then
		local szCondition = szText:match("%s*[%[](.+)[%]]%s*(.+)")
		if szCondition and ProcessCondition(szCondition) then
			return false
		end
	end
end)

AppendCommand("umwp", function(szText)

	local szCondition = szText:match("%s*[%[](.+)[%]]%s*(.+)")
	if ProcessCondition(szCondition) then
		local me = MeCache:Get()
		local tEquip = {EQUIPMENT_INVENTORY.MELEE_WEAPON, EQUIPMENT_INVENTORY.BIG_SWORD}
		local tFreeBoxList = GetBagFreeBoxList()
		for k, v in ipairs(tEquip) do
			local item = me.GetItem(INVENTORY_INDEX.EQUIP, v)
			if item then
				local dwBox, dwX = tFreeBoxList[k][1], tFreeBoxList[k][2]
				OnExchangeItem(INVENTORY_INDEX.EQUIP, v, dwBox, dwX)
				OutputWarningMessage("MSG_WARNING_GREEN", "[" .. item.szName .. "] đã tháo gỡ!", 1)
			end
		end
	end
end)

AppendCommand("omwp", function(szText)

	local szCondition, szContent = szText:match("[[](.+)[]]%s*(.+)")
	if not szContent then print("") return end
	if ProcessCondition(szCondition) then
		local me = MeCache:Get()
		local dwBox, dwX = GetItemPos(szContent)
		local item = GetPlayerItem(me, dwBox, dwX)
		if item then
			local eRetCode, nEquipPos = me.GetEquipPos(dwBox, dwX)
			if eRetCode == 1 then
				OnExchangeItem(dwBox, dwX, INVENTORY_INDEX.EQUIP, nEquipPos)
				OutputWarningMessage("MSG_WARNING_GREEN", "[" .. item.szName .. "] đã trang bị!", 1)
			end
		end
	end
end)

AppendCommand("use", function(szText)

	local szCondition, szContent = szText:match("%s*[%[](.+)[%]]%s*(.+)")
	if not szContent then print("Tham số sai") return end
	if ProcessCondition(szCondition) then
		local me = MeCache:Get()
		for k, v in ipairs(GetEquipmentPosList()) do
			local item = me.GetItem(INVENTORY_INDEX.EQUIP, v)
			if item and item.szName == szContent then
				local bCool, nLeft, nTotal, bBroken = me.GetItemCDProgress(item.dwID)
				if nLeft == 0 then
					OnUseItem(INVENTORY_INDEX.EQUIP ,v)
				end
			end
		end
	end
end)

AppendCommand("item", function(szText)
	local szCondition, szContent = szText:match("%s*[%[](.+)[%]]%s*(.+)")
	if not szContent then print("Tham số sai") return end
	if ProcessCondition(szCondition) then
		local me = MeCache:Get()
		local dwBox, dwX = GetItemPos(szContent)
		local item = GetPlayerItem(me, dwBox, dwX)
		if item then
			local bCool, nLeft, nTotal, bBroken = me.GetItemCDProgress(item.dwID)
			if nLeft == 0 then
				OnUseItem(dwBox, dwX)
				OutputWarningMessage("MSG_WARNING_GREEN", "Sử dụng [" .. item.szName .. "]!", 1)
			end
		end
	end
end)

AppendCommand("cbuff", function(szText)
	local szCondition, szContent = szText:match("%s*[%[](.+)[%]]%s*(.+)")
	szText = szContent or szText
	if not szCondition or ProcessCondition(szCondition) then
		local me = MeCache:Get()
		local tName = SplitString(szText, ",")
		for _, szName in ipairs(tName) do
			local tCache = MyGetBuffList(me) or {}
			for _, v in pairs(tCache) do
				local szBuffName = Table_GetBuffName(v.dwID, v.nLevel)
				if szBuffName == szName then
					me.CancelBuff(v.nIndex)
				end
			end
		end
	end
end)

AppendCommand("talk", function(szText)
	local szCondition, szContent = szText:match("%s*[%[](.+)[%]]%s*(.+)")
	szText = szContent or szText
	if not szCondition or ProcessCondition(szCondition) then
		local me = MeCache:Get()
		me.Talk(PLAYER_TALK_CHANNEL.NEARBY, "", {{type = "text", text = szText}})
	end
end)

AppendCommand("print", function(szText)
	local szCondition, szContent = szText:match("%s*[%[](.+)[%]]%s*(.+)")
	szText = szContent or szText
	if not szCondition or ProcessCondition(szCondition) then
		Output(szCondition, szText)
	end
end)

-- DEBUG: kiểm tra trực tiếp một điều kiện, ví dụ /testcond [nombuff:Thương Dương Chỉ]
AppendCommand("testcond", function(szText)
	local cond = nil
	if szText then
		cond = szText:match("%s*%[(.+)%]%s*") or szText
	end
	if not cond or cond == "" then
		print("Dung: /testcond [dieu_kien]")
		return
	end
	local ok, ret = pcall(function() return ProcessCondition(cond) end)
	if ok then
		print("COND [" .. cond .. "] = " .. tostring(ret))
	else
		print("COND ERROR [" .. cond .. "] = " .. tostring(ret))
	end
end)

-- DEBUG: in danh sách buff/debuff và ID ra chat, không cần /script
AppendCommand("buffid", function(szText)
	local me = GetClientPlayer()
	local obj = me
	if szText and StringFindW(szText, "target") then
		obj = GetTargetHandle(me.GetTarget())
	end
	if not obj then
		print("Khong co muc tieu")
		return
	end
	local list = MyGetBuffList(obj) or {}
	print("===== BUFF LIST =====")
	for _, v in pairs(list) do
		local lv = v.nLevel or v.dwLevel or 1
		local name = Table_GetBuffName(v.dwID, lv) or "?"
		print("ID=" .. tostring(v.dwID) .. " LV=" .. tostring(lv) .. " NAME=" .. tostring(name) .. " STACK=" .. tostring(v.nStackNum) .. " SRC=" .. tostring(v.dwSkillSrcID))
	end
	print("=====================")
end)

-- DEBUG: in ID các kỹ năng đang học
AppendCommand("skillid", function(szText)
	local me = GetClientPlayer()
	local all = me.GetAllSkillList() or {}
	print("===== SKILL LIST =====")
	for id, lv in pairs(all) do
		local name = Table_GetSkillName(id, lv) or "?"
		if not szText or szText == "" or StringFindW(name, szText) then
			print("ID=" .. tostring(id) .. " LV=" .. tostring(lv) .. " NAME=" .. tostring(name))
		end
	end
	print("=====================")
end)



-- ================================================================
-- xMacro Generic Core 1.5 NAME TEST
-- Muc tieu: 1 Macro.lua dung chung cho moi phai.
-- Core chi cung cap primitives; rotation/logic phai viet o macro text.
--
-- Commands:
--   /xver
--   /stopcast [condition]
--   /skillraw [condition] Skill Name
--   /equipwp [condition] Weapon Name
--   /equipwpforce [condition] Weapon Name
--   /usependant [condition]
--   /usependantforce [condition]
--   /useequip [condition] pendant|amulet|weapon
--   /wpcycle Main|Aux|StackBuff|Goal|SafeTime|ProcBuff|HoldSec
--   /wpcyclestatus
--
-- Conditions:
--   wp:Weapon Name
--   nowp:Weapon Name
--   bufflv:Buff=Level
--   tbufflv:Buff=Level
--   mbufflv:Buff=Level
--
-- Buff token in /wpcycle:
--   4761
--   4761@3
--   Ten Buff
--   Ten Buff@3
-- ================================================================

local function XMCore_Sys(msg)
    if OutputMessage then
        OutputMessage("MSG_SYS", tostring(msg) .. "\n")
    else
        print(msg)
    end
end

AppendCommand("xver", function(szText)
    XMCore_Sys("[xMacro] Generic Core 1.5 NAME TEST loaded")
end)

local function XMCore_IsBusy(me)
    if not me then return false end
    local ok, state = pcall(function() return me.GetOTActionState() end)
    return ok and tonumber(state or 0) ~= 0
end

local function XMCore_CurrentWeapon(me)
    me = me or GetClientPlayer() or MeCache:Get()
    if not me then return nil end

    local item = me.GetItem(INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.MELEE_WEAPON)
    if item then return item.szName end

    item = me.GetItem(INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.BIG_SWORD)
    if item then return item.szName end

    item = me.GetItem(INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.RANGE_WEAPON)
    return item and item.szName or nil
end

local function XMCore_NormalizeName(s)
    if s == nil then return "" end
    s = tostring(s)
    s = string.gsub(s, "%s+", "")
    s = string.gsub(s, "%-", "")
    s = string.gsub(s, "·", "")
    s = string.gsub(s, "•", "")
    s = string.gsub(s, "．", "")
    return s
end

local function XMCore_SameName(a, b)
    return XMCore_NormalizeName(a) == XMCore_NormalizeName(b)
end

tOptions["wp"] = function(szCmp, szVal, me, tar)
    return XMCore_SameName(XMCore_CurrentWeapon(me), szVal)
end
tOptions["weapon"] = tOptions["wp"]

tOptions["nowp"] = function(szCmp, szVal, me, tar)
    return not XMCore_SameName(XMCore_CurrentWeapon(me), szVal)
end
tOptions["noweapon"] = tOptions["nowp"]

local function XMCore_ParseBuffToken(token)
    if token == nil then return nil, nil, nil end
    token = tostring(token):gsub("^%s+", ""):gsub("%s+$", "")
    local base, lv = token:match("^(.-)@(%d+)$")
    if base then
        token = base
        lv = tonumber(lv)
    end
    local id = tonumber(token:match("^%d+$") and token or nil)
    return token, id, lv
end

local function XMCore_FindBuff(obj, token, ownOnly)
    if not obj or token == nil or token == "" then return nil end

    local raw, id, needLv = XMCore_ParseBuffToken(token)
    local list = MyGetBuffList(obj) or {}
    local myID = UI_GetClientPlayerID and UI_GetClientPlayerID() or nil

    for _, v in pairs(list) do
        local lv = tonumber(v.nLevel or v.dwLevel or 1) or 1
        local src = tonumber(v.dwSkillSrcID or 0) or 0
        local sourceOK = (not ownOnly) or src == 0 or not myID or src == myID

        if sourceOK and (not needLv or lv == needLv) then
            if id and tonumber(v.dwID) == id then
                return v
            elseif not id then
                local name = Table_GetBuffName(v.dwID, lv)
                if XMCore_SameName(name, raw) then return v end
            end
        end
    end
    return nil
end

local function XMCore_BuffTime(v)
    if not v then return 0 end
    local ef = tonumber(v.nEndFrame or v.dwEndFrame or 0) or 0
    if ef <= 0 or type(GetLogicFrameCount) ~= "function" then return 0 end
    local fps = (GLOBAL and GLOBAL.GAME_FPS and GLOBAL.GAME_FPS > 0) and GLOBAL.GAME_FPS or 16
    local t = (ef - GetLogicFrameCount()) / fps
    return t > 0 and t or 0
end

local function XMCore_BuffStack(v)
    if not v then return 0 end
    return tonumber(v.nStackNum or v.dwStackNum or 1) or 1
end

local function XMCore_BuffLevel(v)
    if not v then return 0 end
    return tonumber(v.nLevel or v.dwLevel or 1) or 1
end

local function XMCore_CheckBuffLevel(obj, expr, ownOnly)
    if not obj or not expr then return false end

    local oper, isAnd = "|", false
    if StringFindW(expr, "-") then
        oper, isAnd = "-", true
    end

    local parts = SplitString(expr, oper)
    for _, cmd in ipairs(parts) do
        local token, cmp, val = cmd:match("(.-)([<>=]+)(.+)")
        local ok = false

        if token and cmp and val then
            local b = XMCore_FindBuff(obj, token, ownOnly)
            ok = b and Compare(cmp, XMCore_BuffLevel(b), val) or false
        else
            ok = XMCore_FindBuff(obj, cmd, ownOnly) ~= nil
        end

        if ok and oper == "|" then return true end
        if not ok and oper == "-" then return false end
    end

    return isAnd
end

tOptions["bufflv"] = function(szCmp, szVal, me, tar)
    return XMCore_CheckBuffLevel(me, szVal, false)
end

tOptions["tbufflv"] = function(szCmp, szVal, me, tar)
    return XMCore_CheckBuffLevel(tar, szVal, false)
end

tOptions["mbufflv"] = function(szCmp, szVal, me, tar)
    return XMCore_CheckBuffLevel(tar, szVal, true)
end

-- Generic cast stop. Chi dung khi macro text tu quyet dinh dieu kien can ngat.
AppendCommand("stopcast", function(szText)
    local cond = nil
    if szText and szText ~= "" then
        cond = szText:match("^%s*%[(.+)%]%s*$")
    end
    if cond and not ProcessCondition(cond) then return end

    local me = GetClientPlayer() or MeCache:Get()
    if not me then return end
    if XMCore_IsBusy(me) then me.StopCurrentAction() end
end)

-- Direct skill request, bo qua UITestCast.
-- Dung cho cac hieu ung dac biet ma server cho phep cast instant/reset CD
-- nhung client 80 cap nhat CD cham. Macro thu cong phai tu dat condition an toan.
AppendCommand("skillraw", function(szText)
    szText = szText or ""
    local cond, content = szText:match("^[ \t]*[%[](.+)[%]][ \t]*(.-)[ \t]*$")
    content = content or szText
    content = string.gsub(content, "^[ \t]*(.-)[ \t]*$", "%1")
    if not content or content == "" then return end
    if cond and not ProcessCondition(cond) then return end
    if szBeforeCmd ~= "" and not ProcessCondition(szBeforeCmd) then return end

    local id, lv = GetPlayerSkillInfo(content)
    if id then
        OnAddOnUseSkill(id, lv)
        if XMCore_Sys then
            local szName = (Table_GetSkillName and Table_GetSkillName(id, lv)) or tostring(content)
            XMCore_Sys("[xMacro Raw] -> " .. tostring(szName))
        end
        return true
    end
    return false
end)

local XMCore_LastSwapFrame = -999999

local function XMCore_FindItemPosByName(me, name)
    if not me or not name or name == "" then return nil end
    for box = 1, 6 do
        local size = me.GetBoxSize(box) or 0
        for x = 0, size - 1 do
            local item = me.GetItem(box, x)
            if item and XMCore_SameName(item.szName, name) then
                return box, x
            end
        end
    end
    return nil
end

local function XMCore_EquipWeapon(name, force)
    local me = GetClientPlayer() or MeCache:Get()
    if not me or not name or name == "" then return false end

    if not force and XMCore_IsBusy(me) then
        return false
    end

    if XMCore_SameName(XMCore_CurrentWeapon(me), name) then
        return true
    end

    local box, x = XMCore_FindItemPosByName(me, name)
    if not box then return false end

    local item = me.GetItem(box, x)
    if not item then return false end

    local code, equipPos = me.GetEquipPos(box, x)
    if code ~= 1 or not equipPos then return false end

    local now = type(GetLogicFrameCount) == "function" and GetLogicFrameCount() or 0
    if now - XMCore_LastSwapFrame < 2 then return false end

    OnExchangeItem(box, x, INVENTORY_INDEX.EQUIP, equipPos)
    XMCore_LastSwapFrame = now
    return true
end

local function XMCore_ParseCondContent(szText)
    if not szText then return nil, nil end
    local cond, content = szText:match("%s*[%[](.+)[%]]%s*(.+)")
    if content then return cond, content end
    return nil, szText:gsub("^%s+", ""):gsub("%s+$", "")
end

AppendCommand("equipwp", function(szText)
    local cond, name = XMCore_ParseCondContent(szText)
    if not name or name == "" then return end
    if cond and not ProcessCondition(cond) then return end
    if szBeforeCmd ~= "" and not ProcessCondition(szBeforeCmd) then return end
    XMCore_EquipWeapon(name, false)
end)

AppendCommand("equipwpforce", function(szText)
    local cond, name = XMCore_ParseCondContent(szText)
    if not name or name == "" then return end
    if cond and not ProcessCondition(cond) then return end
    if szBeforeCmd ~= "" and not ProcessCondition(szBeforeCmd) then return end
    XMCore_EquipWeapon(name, true)
end)

local function XMCore_UseEquipSlot(pos, force)
    local me = GetClientPlayer() or MeCache:Get()
    if not me or not pos then return false end
    if not force and XMCore_IsBusy(me) then return false end

    local item = me.GetItem(INVENTORY_INDEX.EQUIP, pos)
    if not item then return false end

    local ok, bCool, nLeft = pcall(function()
        return me.GetItemCDProgress(item.dwID)
    end)
    if not ok or tonumber(nLeft or 0) ~= 0 then return false end

    OnUseItem(INVENTORY_INDEX.EQUIP, pos)
    return true
end

AppendCommand("usependant", function(szText)
    szText = szText or ""
    local cond = szText:match("^[ \t]*%[(.+)%][ \t]*$")
    if cond and not ProcessCondition(cond) then return end
    if szBeforeCmd ~= "" and not ProcessCondition(szBeforeCmd) then return end
    XMCore_UseEquipSlot(EQUIPMENT_INVENTORY.PENDANT, false)
end)

AppendCommand("usependantforce", function(szText)
    szText = szText or ""
    local cond = szText:match("^[ \t]*%[(.+)%][ \t]*$")
    if cond and not ProcessCondition(cond) then return end
    if szBeforeCmd ~= "" and not ProcessCondition(szBeforeCmd) then return end
    XMCore_UseEquipSlot(EQUIPMENT_INVENTORY.PENDANT, true)
end)

AppendCommand("useequip", function(szText)
    local cond, slot = XMCore_ParseCondContent(szText)
    if not slot or slot == "" then return end
    if cond and not ProcessCondition(cond) then return end
    if szBeforeCmd ~= "" and not ProcessCondition(szBeforeCmd) then return end

    slot = string.lower(slot)
    local pos = nil
    if slot == "pendant" then
        pos = EQUIPMENT_INVENTORY.PENDANT
    elseif slot == "amulet" then
        pos = EQUIPMENT_INVENTORY.AMULET
    elseif slot == "weapon" or slot == "melee" then
        pos = EQUIPMENT_INVENTORY.MELEE_WEAPON
    end

    if pos then XMCore_UseEquipSlot(pos, false) end
end)

-- Generic stateful weapon cycle.
-- /wpcycle Main|Aux|StackBuff|Goal|SafeTime|ProcBuff|HoldSec
--
-- Vi du:
-- /wpcycle MAIN|AUX|4761@3|10|1.7|PROC_NAME|10
--
-- Core khong biet phai nao, skill nao, proc nao.
-- Neu stack da du nhung time < SafeTime => GIU AUX, macro text tu cuu buff.
-- Khi stack du va time >= SafeTime => swap MAIN.
-- Sau swap, stack co the mat; core van giu MAIN trong HoldSec de cho proc.
local XMCore_WPCycle = {
    key = "",
    main = "",
    aux = "",
    stackToken = "",
    goal = 0,
    safeTime = 0,
    procToken = "",
    holdSec = 10,
    primed = false,
    sawProc = false,
    holdUntil = 0,
}

AppendCommand("wpcycle", function(szText)
    local fields = SplitString(szText or "", "|")
    if #fields < 6 then
        XMCore_Sys("[xMacro] /wpcycle Main|Aux|StackBuff|Goal|SafeTime|ProcBuff|HoldSec")
        return
    end

    local main = fields[1]
    local aux = fields[2]
    local stackToken = fields[3]
    local goal = tonumber(fields[4]) or 0
    local safeTime = tonumber(fields[5]) or 0
    local procToken = fields[6]
    local holdSec = tonumber(fields[7]) or 10

    local me = GetClientPlayer() or MeCache:Get()
    if not me then return end

    local key = table.concat({main, aux, stackToken, tostring(goal), tostring(safeTime), procToken, tostring(holdSec)}, "|")
    if XMCore_WPCycle.key ~= key then
        XMCore_WPCycle = {
            key = key,
            main = main,
            aux = aux,
            stackToken = stackToken,
            goal = goal,
            safeTime = safeTime,
            procToken = procToken,
            holdSec = holdSec,
            primed = false,
            sawProc = false,
            holdUntil = 0,
        }
    end

    -- Never interrupt an existing cast/channel by swapping.
    if XMCore_IsBusy(me) then return end

    local now = type(GetLogicFrameCount) == "function" and GetLogicFrameCount() or 0
    local fps = (GLOBAL and GLOBAL.GAME_FPS and GLOBAL.GAME_FPS > 0) and GLOBAL.GAME_FPS or 16

    local stackBuff = XMCore_FindBuff(me, stackToken, false)
    local stack = XMCore_BuffStack(stackBuff)
    local left = XMCore_BuffTime(stackBuff)
    local proc = XMCore_FindBuff(me, procToken, false) ~= nil

    if proc then
        XMCore_WPCycle.primed = true
        XMCore_WPCycle.sawProc = true
        XMCore_WPCycle.holdUntil = now + math.floor(fps * holdSec)
        XMCore_EquipWeapon(main, false)
        return
    end

    -- Proc ended => reset cycle and rebuild stack on AUX.
    if XMCore_WPCycle.sawProc then
        XMCore_WPCycle.primed = false
        XMCore_WPCycle.sawProc = false
        XMCore_WPCycle.holdUntil = 0
        XMCore_EquipWeapon(aux, false)
        return
    end

    -- Enough stacks, but too little KNOWN time: do NOT swap yet.
    -- Some level-80 clients do not expose nEndFrame; in that case left=0 means
    -- "time unknown", NOT "buff expired". Full stack must still be allowed to swap.
    local timeKnown = left > 0

    if stack >= goal and safeTime > 0 and timeKnown and left < safeTime then
        XMCore_EquipWeapon(aux, false)
        return
    end

    -- Safe to enter proc weapon.
    -- If time is unknown, full stack alone is enough to swap.
    if stack >= goal and (safeTime <= 0 or not timeKnown or left >= safeTime) then
        XMCore_WPCycle.primed = true
        XMCore_WPCycle.holdUntil = now + math.floor(fps * holdSec)
        XMCore_EquipWeapon(main, false)
        return
    end

    -- After swap, the stack buff can disappear; hold MAIN while waiting for proc.
    if XMCore_WPCycle.primed and now < (XMCore_WPCycle.holdUntil or 0) then
        XMCore_EquipWeapon(main, false)
        return
    end

    XMCore_WPCycle.primed = false
    XMCore_EquipWeapon(aux, false)
end)

AppendCommand("wpcyclestatus", function(szText)
    local me = GetClientPlayer() or MeCache:Get()
    if not me then return end

    local b = XMCore_FindBuff(me, XMCore_WPCycle.stackToken, false)
    local stack = XMCore_BuffStack(b)
    local left = XMCore_BuffTime(b)
    local proc = XMCore_FindBuff(me, XMCore_WPCycle.procToken, false) ~= nil

    local found = b ~= nil
    local lv = b and XMCore_BuffLevel(b) or 0
    local timeText = (left and left > 0) and string.format("%.2f", left) or "?"
    XMCore_Sys(string.format(
        "[xMacro] WP=%s | buff=%s lv=%d | stack=%d | time=%s | primed=%s | proc=%s",
        tostring(XMCore_CurrentWeapon(me)),
        tostring(found),
        tonumber(lv or 0),
        tonumber(stack or 0),
        tostring(timeText),
        tostring(XMCore_WPCycle.primed),
        tostring(proc)
    ))
end)

XMCore_Sys("[xMacro] Generic Core 1.5 NAME TEST ready")
-- ================================================================


-- ================================================================
-- Name-only test extension 1.5
-- Text macro can use names only for buffs, skills and weapons.
-- ================================================================

local function XMCore_CompareBuffValue(obj, expr, getter)
    if not obj or not expr then return false end
    local token, cmp, val = tostring(expr):match("^(.-)([<>=]+)(.+)$")
    if not token or not cmp or not val then return false end
    local b = XMCore_FindBuff(obj, token, false)
    if not b then return false end
    return Compare(cmp, getter(b), val)
end

tOptions["xmbuff"] = function(szCmp, szVal, me, tar)
    return XMCore_FindBuff(me, szVal, false) ~= nil
end

tOptions["xmnobuff"] = function(szCmp, szVal, me, tar)
    return XMCore_FindBuff(me, szVal, false) == nil
end

tOptions["xmtbuff"] = function(szCmp, szVal, me, tar)
    return XMCore_FindBuff(tar, szVal, false) ~= nil
end

tOptions["xmtnobuff"] = function(szCmp, szVal, me, tar)
    return XMCore_FindBuff(tar, szVal, false) == nil
end

tOptions["xmbufftime"] = function(szCmp, szVal, me, tar)
    return XMCore_CompareBuffValue(me, szVal, XMCore_BuffTime)
end

tOptions["xmtbufftime"] = function(szCmp, szVal, me, tar)
    return XMCore_CompareBuffValue(tar, szVal, XMCore_BuffTime)
end

tOptions["xmbuffstack"] = function(szCmp, szVal, me, tar)
    return XMCore_CompareBuffValue(me, szVal, XMCore_BuffStack)
end

tOptions["xmtbuffstack"] = function(szCmp, szVal, me, tar)
    return XMCore_CompareBuffValue(tar, szVal, XMCore_BuffStack)
end

-- Print exact client buff names. No buff ID is required in macro input.
AppendCommand("buffnames", function(szText)
    local me = GetClientPlayer() or MeCache:Get()
    if not me then return end
    local targetMode = szText and XMCore_NormalizeName(szText) == "target"
    local obj = targetMode and GetTargetHandle(me.GetTarget()) or me
    if not obj then
        XMCore_Sys("[xMacro] buffnames: target not found")
        return
    end
    local list = MyGetBuffList(obj) or {}
    XMCore_Sys(targetMode and "[xMacro] TARGET BUFF NAMES:" or "[xMacro] SELF BUFF NAMES:")
    for _, v in pairs(list) do
        local lv = tonumber(v.nLevel or v.dwLevel or 1) or 1
        local name = Table_GetBuffName(v.dwID, lv)
        local stack = XMCore_BuffStack(v)
        local left = XMCore_BuffTime(v)
        local timeText = (left and left > 0) and string.format("%.2f", left) or "?"
        XMCore_Sys(string.format("NAME=%s | stack=%d | lv=%d | time=%s", tostring(name), tonumber(stack or 0), tonumber(lv or 0), tostring(timeText)))
    end
end)

AppendCommand("skillname", function(szText)
    local name = (szText or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then return end
    local id, lv = GetPlayerSkillInfo(name)
    if id then
        XMCore_Sys("[xMacro] SKILL OK: " .. name .. " | level=" .. tostring(lv))
    else
        XMCore_Sys("[xMacro] SKILL NOT FOUND: " .. name)
    end
end)

local XMCore_NameWPWatch = {
    enabled=false, key="", main="", aux="", stackToken="", goal=0,
    minSafe=0, procToken="", holdSec=4,
    primed=false, sawProc=false, holdUntil=0,
}

local XMCore_NameProcWatch = {
    enabled=false, key="", buffToken="", procSkill="", interruptSkill="",
    activeLast=false, interrupted=false, lastTry=0,
}

local XMCore_WatchLastSwap = 0
local XMCore_WatchLastError = {wp=0, proc=0}

local function XMCore_WatchError(kind, err)
    local now = GetTime and GetTime() or 0
    if now - (XMCore_WatchLastError[kind] or 0) >= 3000 then
        XMCore_WatchLastError[kind] = now
        XMCore_Sys("[xMacro] " .. string.upper(kind) .. "WATCH ERROR: " .. tostring(err))
    end
end

local function XMCore_WatchEquip(name)
    local me = GetClientPlayer() or MeCache:Get()
    if not me or not name or name == "" then return false end
    if XMCore_SameName(XMCore_CurrentWeapon(me), name) then return true end

    local now = GetTime and GetTime() or 0
    if now - XMCore_WatchLastSwap < 500 then return false end

    local box, x = XMCore_FindItemPosByName(me, name)
    if not box then return false end
    local item = me.GetItem(box, x)
    if not item then return false end
    local code, equipPos = me.GetEquipPos(box, x)
    if code ~= 1 or not equipPos then return false end

    -- Deliberately does NOT StopCurrentAction: weapon swap must not interrupt Đại Huyền.
    OnExchangeItem(box, x, INVENTORY_INDEX.EQUIP, equipPos)
    XMCore_WatchLastSwap = now
    return true
end

-- /wpwatch Main|Aux|StackBuffName|Goal|MinSafeTime|ProcBuffName|HoldSec
AppendCommand("wpwatch", function(szText)
    local f = SplitString(szText or "", "|")
    if #f < 6 then
        XMCore_Sys("[xMacro] /wpwatch Main|Aux|StackBuffName|Goal|MinSafeTime|ProcBuffName|HoldSec")
        return
    end
    local main, aux, stackToken = f[1], f[2], f[3]
    local goal = tonumber(f[4]) or 0
    local minSafe = tonumber(f[5]) or 0
    local procToken = f[6]
    local holdSec = tonumber(f[7]) or 4
    local key = table.concat({main,aux,stackToken,tostring(goal),tostring(minSafe),procToken,tostring(holdSec)}, "|")
    if XMCore_NameWPWatch.key ~= key then
        XMCore_NameWPWatch = {
            enabled=true, key=key, main=main, aux=aux, stackToken=stackToken,
            goal=goal, minSafe=minSafe, procToken=procToken, holdSec=holdSec,
            primed=false, sawProc=false, holdUntil=0,
        }
    else
        XMCore_NameWPWatch.enabled = true
    end
end)

AppendCommand("wpwatchstatus", function()
    local me = GetClientPlayer() or MeCache:Get()
    if not me then return end
    local b = XMCore_FindBuff(me, XMCore_NameWPWatch.stackToken, false)
    local p = XMCore_FindBuff(me, XMCore_NameWPWatch.procToken, false)
    local left = XMCore_BuffTime(b)
    local timeText = left > 0 and string.format("%.2f", left) or "?"
    XMCore_Sys(string.format(
        "[xMacro] wpwatch=%s WP=%s stackBuff=%s found=%s stack=%d time=%s primed=%s proc=%s",
        tostring(XMCore_NameWPWatch.enabled), tostring(XMCore_CurrentWeapon(me)),
        tostring(XMCore_NameWPWatch.stackToken), tostring(b ~= nil),
        tonumber(XMCore_BuffStack(b) or 0), tostring(timeText),
        tostring(XMCore_NameWPWatch.primed), tostring(p ~= nil)
    ))
end)

-- /procwatch ProcBuffName|ProcSkillName|InterruptSkillName
AppendCommand("procwatch", function(szText)
    local f = SplitString(szText or "", "|")
    if #f < 2 then
        XMCore_Sys("[xMacro] /procwatch ProcBuffName|ProcSkillName|InterruptSkillName")
        return
    end
    local buffToken = f[1]
    local procSkill = f[2]
    local interruptSkill = f[3] or ""
    local key = table.concat({buffToken,procSkill,interruptSkill}, "|")
    if XMCore_NameProcWatch.key ~= key then
        XMCore_NameProcWatch = {
            enabled=true, key=key, buffToken=buffToken,
            procSkill=procSkill, interruptSkill=interruptSkill,
            activeLast=false, interrupted=false, lastTry=0,
        }
    else
        XMCore_NameProcWatch.enabled = true
    end
end)

AppendCommand("procwatchstatus", function()
    local me = GetClientPlayer() or MeCache:Get()
    if not me then return end
    local active = XMCore_FindBuff(me, XMCore_NameProcWatch.buffToken, false) ~= nil
    local procID = GetPlayerSkillInfo(XMCore_NameProcWatch.procSkill)
    local interruptID = GetPlayerSkillInfo(XMCore_NameProcWatch.interruptSkill)
    XMCore_Sys(string.format(
        "[xMacro] procwatch=%s buff=%s active=%s procSkill=%s(%s) interrupt=%s(%s)",
        tostring(XMCore_NameProcWatch.enabled), tostring(XMCore_NameProcWatch.buffToken),
        tostring(active), tostring(XMCore_NameProcWatch.procSkill), tostring(procID ~= nil),
        tostring(XMCore_NameProcWatch.interruptSkill), tostring(interruptID ~= nil)
    ))
end)

local function XMCore_NameWPWatchTick()
    if not XMCore_NameWPWatch.enabled then return end
    local me = GetClientPlayer() or MeCache:Get()
    if not me then return end

    local nowFrame = GetLogicFrameCount and GetLogicFrameCount() or 0
    local fps = (GLOBAL and GLOBAL.GAME_FPS and GLOBAL.GAME_FPS > 0) and GLOBAL.GAME_FPS or 16
    local b = XMCore_FindBuff(me, XMCore_NameWPWatch.stackToken, false)
    local stack = XMCore_BuffStack(b)
    local left = XMCore_BuffTime(b)
    local proc = XMCore_FindBuff(me, XMCore_NameWPWatch.procToken, false) ~= nil

    if proc then
        XMCore_NameWPWatch.primed = true
        XMCore_NameWPWatch.sawProc = true
        XMCore_NameWPWatch.holdUntil = nowFrame + math.floor(fps * XMCore_NameWPWatch.holdSec)
        XMCore_WatchEquip(XMCore_NameWPWatch.main)
        return
    end

    if XMCore_NameWPWatch.sawProc then
        XMCore_NameWPWatch.primed = false
        XMCore_NameWPWatch.sawProc = false
        XMCore_NameWPWatch.holdUntil = 0
        XMCore_WatchEquip(XMCore_NameWPWatch.aux)
        return
    end

    if XMCore_NameWPWatch.primed then
        -- If the stack buff still exists and is about to expire, go back AUX to refresh.
        -- This swaps weapon only; it NEVER interrupts the current cast/channel.
        if b and XMCore_NameWPWatch.minSafe > 0 and left > 0 and left <= XMCore_NameWPWatch.minSafe then
            XMCore_NameWPWatch.primed = false
            XMCore_NameWPWatch.holdUntil = 0
            XMCore_WatchEquip(XMCore_NameWPWatch.aux)
            return
        end
        -- If the stack buff disappears because MAIN was equipped, hold MAIN and wait proc.
        if nowFrame < (XMCore_NameWPWatch.holdUntil or 0) then
            XMCore_WatchEquip(XMCore_NameWPWatch.main)
            return
        end
        XMCore_NameWPWatch.primed = false
        XMCore_WatchEquip(XMCore_NameWPWatch.aux)
        return
    end

    local timeKnown = left > 0
    local safe = XMCore_NameWPWatch.minSafe <= 0 or not timeKnown or left > XMCore_NameWPWatch.minSafe
    if b and stack >= XMCore_NameWPWatch.goal and safe then
        XMCore_NameWPWatch.primed = true
        XMCore_NameWPWatch.holdUntil = nowFrame + math.floor(fps * XMCore_NameWPWatch.holdSec)
        XMCore_WatchEquip(XMCore_NameWPWatch.main)
        return
    end

    XMCore_WatchEquip(XMCore_NameWPWatch.aux)
end

local function XMCore_NameProcWatchTick()
    if not XMCore_NameProcWatch.enabled then return end
    local me = GetClientPlayer() or MeCache:Get()
    if not me then return end

    local active = XMCore_FindBuff(me, XMCore_NameProcWatch.buffToken, false) ~= nil
    if not active then
        XMCore_NameProcWatch.activeLast = false
        XMCore_NameProcWatch.interrupted = false
        XMCore_NameProcWatch.lastTry = 0
        return
    end

    if not XMCore_NameProcWatch.activeLast then
        XMCore_NameProcWatch.activeLast = true
        XMCore_NameProcWatch.interrupted = false
        XMCore_NameProcWatch.lastTry = 0
    end

    -- The only allowed interrupt is the configured skill name (e.g. Đại Huyền Cấp Khúc).
    if XMCore_NameProcWatch.interruptSkill ~= "" and CheckPrepare(me, XMCore_NameProcWatch.interruptSkill) then
        if not XMCore_NameProcWatch.interrupted then
            me.StopCurrentAction()
            XMCore_NameProcWatch.interrupted = true
        end
        return
    end

    -- If another skill is being prepared/channelled, do NOT interrupt it. Wait until idle.
    if XMCore_IsBusy(me) then return end

    local now = GetTime and GetTime() or 0
    if now - (XMCore_NameProcWatch.lastTry or 0) < 120 then return end
    XMCore_NameProcWatch.lastTry = now

    local id, lv = GetPlayerSkillInfo(XMCore_NameProcWatch.procSkill)
    if id and lv then
        -- Raw request: old client may keep stale CD while orange-weapon proc is active.
        OnAddOnUseSkill(id, lv)
    end
end

local function XMCore_NameBackgroundTick()
    local ok, err = pcall(XMCore_NameWPWatchTick)
    if not ok then XMCore_WatchError("wp", err) end
    ok, err = pcall(XMCore_NameProcWatchTick)
    if not ok then XMCore_WatchError("proc", err) end
end

xMacro = xMacro or {}
function xMacro.OnFrameBreathe()
    XMCore_NameBackgroundTick()
end

-- Khoi tao an toan UI xMacro.ini
if Wnd and Wnd.OpenWindow then
    pcall(Wnd.OpenWindow, "Interface/xMacro/xMacro.ini", "xMacro")
end

if RegisterEvent then
    pcall(RegisterEvent, "PLAYER_ENTER_SCENE", function()
        if Wnd and Wnd.OpenWindow then
            pcall(Wnd.OpenWindow, "Interface/xMacro/xMacro.ini", "xMacro")
        end
    end)
    pcall(RegisterEvent, "ON_BREATHE", function()
        pcall(xMacro.OnFrameBreathe)
    end)
end

-- =============================================================================
-- Kich ban Macro Mau: Van Hoa Hoa Gian PVE v80 (Tam Doc Ngoc Thach Luu Chuan Nhat)
-- =============================================================================
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

local szCurrentActiveMacroScript = DEFAULT_VANHOA_MACRO

function SetActiveMacroScript(szScript)
    szCurrentActiveMacroScript = szScript
end

function GetActiveMacroScript()
    return szCurrentActiveMacroScript
end

function ExecuteMacroCommand(szMacroText)
    local szScript = szMacroText
    if not szScript or szScript == "" or szScript == "auto" then
        szScript = szCurrentActiveMacroScript
    end
    if not szScript or szScript == "" then
        return false
    end

    local me = GetClientPlayer() or MeCache:Get()
    if not me then return false end

    -- Bao ve van khi / channel: neu dang thi trien hoac dan dao thi khong ngat chieu
    if me.GetSkillPrepareState and me.GetSkillPrepareState() then
        return false
    end
    local okOT, nOT = pcall(function() return me.GetOTActionState() end)
    if okOT and tonumber(nOT or 0) ~= 0 then
        return false
    end

    local szPattern = "[^" .. string.char(10, 13) .. "]+"
    for line in string.gmatch(szScript, szPattern) do
        local clean = string.gsub(line, "^[ \t\r\n]*(.-)[ \t\r\n]*$", "%1")
        if clean ~= "" and string.sub(clean, 1, 2) ~= "--" and string.sub(clean, 1, 1) ~= ";" and string.sub(clean, 1, 1) ~= "#" then
            local cmd, arg = string.match(clean, "^/([^ \t\r\n]+)[ \t\r\n]*(.*)$")
            if not cmd then
                cmd, arg = string.match(clean, "^([^ \t\r\n]+)[ \t\r\n]*(.*)$")
            end
            if cmd then
                cmd = string.lower(cmd)
                local handler = _tCommands and _tCommands[cmd]
                if handler then
                    local ok, ret = pcall(handler, arg)
                    if ok and ret then return true end
                end
            end
        end
    end
    return false
end

-- =============================================================================
-- Global macro() bridge, Hotkey va Slash Commands
-- =============================================================================
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
function macro(szName)
    local me = GetClientPlayer()
    if not me then return false end

    -- 1. Neu truyen truc tiep mot doan lenh Macro chua lenh '/' thi thuc thi qua Script do
    if szName and type(szName) == "string" and szName ~= "" and szName ~= "auto" and string.find(szName, "/") then
        local ok, ret = pcall(ExecuteMacroCommand, szName)
        if ok and ret then return true end
    end

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


function CheckTargetBuffs()
    local me = GetClientPlayer()
    if not me then return end
    local tar = nil
    if HM and HM.GetTarget then
        local ok, hTar = pcall(HM.GetTarget)
        if ok and hTar and hTar.dwID and hTar.dwID > 0 then tar = hTar end
    end
    if not tar and me.GetTarget then
        local ok, t1, t2 = pcall(me.GetTarget)
        if ok and t1 then
            local tarID = (type(t2) == "number" and t2 > 0) and t2 or ((type(t1) == "number" and t1 > 0) and t1 or nil)
            if tarID and GetNpc then
                local okNpc, npc = pcall(GetNpc, tarID)
                if okNpc and npc and npc.dwID then tar = npc end
            end
        end
    end
    if not tar then
        XMCore_Sys("[xMacro Debug] Khong co muc tieu (Target: nil)")
        return
    end
    local szName = (tar.szName and tostring(tar.szName)) or "NPC"
    XMCore_Sys(string.format("[xMacro Debug] Target: %s (ID: %d)", szName, tar.dwID or 0))
    if tar.GetBuffList then
        local ok, list = pcall(function() return tar.GetBuffList() end)
        if ok and list and type(list) == "table" then
            local nCount = 0
            local nCurFrame = (GetLogicFrameCount and GetLogicFrameCount()) or 0
            for _, b in pairs(list) do
                if b and b.dwID then
                    nCount = nCount + 1
                    local nLeftSec = 0
                    if b.nEndFrame and b.nEndFrame > nCurFrame then
                        nLeftSec = math.floor((b.nEndFrame - nCurFrame) / 16 * 10) / 10
                    end
                    local szBName = ""
                    if Table_GetBuffName then
                        local okN, bn = pcall(Table_GetBuffName, b.dwID, b.nLevel or 1)
                        if okN and bn then szBName = " (" .. tostring(bn) .. ")" end
                    end
                    XMCore_Sys(string.format("  -> Buff ID: %d%s | Lv: %d | Stack: %d | Con: %.1fs",
                        b.dwID, szBName, b.nLevel or 1, b.nStackNum or 1, nLeftSec))
                end
            end
            if nCount == 0 then
                XMCore_Sys("  -> Target hien chua co bat ky Buff/Debuff nao")
            end
        end
    end
end


if AppendCommand then
    pcall(AppendCommand, "macro", function(szText) macro(szText) end)
    pcall(AppendCommand, "xmacro", function(szText) macro(szText) end)
    pcall(AppendCommand, "xm", function(szText) macro(szText) end)
    pcall(AppendCommand, "checkbuff", CheckTargetBuffs)
    pcall(AppendCommand, "xmcheck", CheckTargetBuffs)
end

XMCore_Sys("[xMacro] Generic Core 1.5 San sang")
-- ================================================================
