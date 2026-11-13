"""
JX3 Macro Simulation Engine (Patch 80 / v2.5.2)
Mo phong toan dien moi truong C++ Client Game JX3 de test macro phuc tap:
- Vu khi & Doi vu khi (Main CW Bich Lac <-> Aux Quy Lieu Dieu Mac)
- Buff/Debuff voi Stacks & Countdown frames
- Global Cooldown (GCD 53) va Cooldown tung ky nang
- Bo phan tich /wpcycle, /skillraw, /usependant, /config before:
"""

import os
import sys

venv_site = r"C:\Users\AD\.gemini\antigravity\brain\5632561d-25f4-4e1a-9bbc-a8a188a92f7c\scratch\venv\Lib\site-packages"
if venv_site not in sys.path:
    sys.path.insert(0, venv_site)

import lupa.lua51 as lua

class JX3Simulator:
    def __init__(self, workspace_root=None):
        if workspace_root is None:
            workspace_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
        self.workspace_root = workspace_root
        self.lua = lua.LuaRuntime(unpack_returned_tuples=True)
        self.events = []
        self.cast_history = []
        self.swap_history = []
        self.setup_environment()

    def setup_environment(self):
        lua_code = """
        GLOBAL = { GAME_FPS = 16 }
        MOVE_STATE = { ON_STAND = 0, ON_DEATH = 2 }
        TARGET = { NPC = 3, PLAYER = 1 }
        INVENTORY_INDEX = { EQUIP = 0, PACKAGE = 1 }
        EQUIPMENT_INVENTORY = { MELEE_WEAPON = 0, BIG_SWORD = 1, RANGE_WEAPON = 2, PENDANT = 3 }
        
        _tCommands = {}
        _tKeyBindings = {}
        _tEvents = {}
        _szSysLog = {}
        _tCastedSkills = {}
        _tUsedItems = {}
        _tPrints = {}
        _curFrame = 100
        
        function print(...)
            local t = {...}
            for i=1, #t do t[i] = tostring(t[i]) end
            table.insert(_tPrints, table.concat(t, "\t"))
        end

        function OutputMessage(channel, msg)
            table.insert(_szSysLog, msg)
        end

        function AppendCommand(cmd, fn)
            _tCommands[cmd] = fn
        end

        Hotkey = {
            AddBinding = function(keyName, title, group, fn)
                _tKeyBindings[keyName] = { title = title, fn = fn }
            end
        }

        function RegisterEvent(evt, fn)
            _tEvents[evt] = _tEvents[evt] or {}
            table.insert(_tEvents[evt], fn)
        end

        Wnd = {
            OpenWindow = function(...) return {} end
        }

        Station = {
            Lookup = function(...) return nil end
        }

        function UI_GetClientPlayerID()
            return 101
        end

        function Table_GetSkillName(id, lvl)
            local names = {
                [131] = "Bích Thủy Thao Thiên",
                [132] = "Xuân Nê Hộ Hoa",
                [136] = "Thủy Nguyệt Vô Gian",
                [179] = "Dương Minh Chỉ",
                [180] = "Thương Dương Chỉ",
                [181] = "Thiếu Dương Chỉ",
                [182] = "Ngọc Thạch Câu Phần",
                [183] = "Quyết Âm Chỉ",
                [189] = "Chung Linh Dục Tú",
                [190] = "Lan Thôi Ngọc Chiết",
                [2645] = "Loạn Tửu Thanh Hà",
            }
            return names[id] or nil
        end

        function Table_GetBuffName(id, lvl)
            local names = {
                [666] = "Thương Dương Chỉ",
                [711] = "Lan Thôi Ngọc Chiết",
                [714] = "Chung Linh Dục Tú",
                [122] = "Xuân Nê Hộ Hoa",
                [631] = "Xuân Nê Hộ Hoa",
                [113] = "Bích Thủy Thao Thiên",
                [637] = "Bích Thủy Thao Thiên",
                [412] = "Thủy Nguyệt Vô Gian",
                [645] = "Thủy Nguyệt Vô Gian",
                [1902] = "Phệ Cốt",
                [886] = "Phệ Cốt",
                [2719] = "Thanh Hà",
                [2726] = "Loạn Sái",
                [2495] = "Bích Lạc",
                [4761] = "Quỷ Liễu Diệu Mặc",
            }
            return names[id] or ("Buff_" .. tostring(id))
        end

        function GetDistanceByTarget(me, tar)
            return 10
        end

        function GetNpcIntensity(tar)
            return (tar and tar.bIsBoss) and 4 or 1
        end

        function IsPlayer(dwID)
            return dwID == 101
        end

        -- Mock Target (Boss / NPC)
        _mockTarget = {
            dwID = 999,
            szName = "Đích Nhân (Boss)",
            bIsBoss = true,
            bFightState = true,
            nCurrentLife = 1000000,
            nMaxLife = 1000000,
            nCurrentMana = 100000,
            nMaxMana = 100000,
            nMoveState = 0,
            bPreparing = false,
            tBuffs = {},
            GetBuffList = function(...)
                return _mockTarget.tBuffs
            end,
            GetBuffCount = function(...)
                return #_mockTarget.tBuffs
            end,
            GetBuff = function(a, b)
                local idx = (type(a) == "table" or type(a) == "userdata") and b or a
                return _mockTarget.tBuffs[idx+1]
            end,
            GetSkillPrepareState = function(...)
                return _mockTarget.bPreparing
            end,
            GetTarget = function(...)
                return TARGET.PLAYER, 101
            end
        }

        -- Mock Player
        _mockPlayer = {
            dwID = 101,
            dwForceID = 3, -- Vạn Hoa
            szName = "BíchĐào",
            bFightState = true,
            bOnHorse = false,
            nCurrentLife = 10000,
            nMaxLife = 10000,
            nCurrentMana = 10000,
            nMaxMana = 10000,
            nMoveState = 0,
            bPreparing = false,
            nOTState = 0,
            tBuffs = {},
            tCDs = {},
            tEquip = {
                [0] = { szName = "Quỷ Liễu Diệu Mặc", nGenre = 1, nSub = 0, dwID = 4761 }, -- Melee weapon
                [3] = { szName = "Bích Lạc Bội", nGenre = 3, nSub = 0, dwID = 9999 },      -- Pendant
            },
            tBags = {
                [1] = {
                    [0] = { szName = "Bích Lạc", nGenre = 1, nSub = 0, dwID = 2495 },      -- Main CW in Bag 1 Slot 0
                }
            },
            GetTarget = function(...)
                return TARGET.NPC, _mockTarget.dwID
            end,
            GetKungfuMount = function(...)
                return { szSkillName = "Hoa Gian Du" }
            end,
            GetAllSkillList = function(...)
                return {
                    [179] = 1, [180] = 1, [181] = 1, [182] = 1, [183] = 1,
                    [189] = 1, [190] = 1, [131] = 1, [132] = 1, [136] = 1,
                    [2645] = 1
                }
            end,
            GetSkillLevel = function(a, b)
                local id = (type(a) == "table" or type(a) == "userdata") and b or a
                return 1
            end,
            GetSkillCDProgress = function(a, b, c)
                local skID = (type(a) == "table" or type(a) == "userdata") and b or a
                local cd = _mockPlayer.tCDs[skID]
                if cd and cd > 0 then
                    return true, cd, 160
                end
                return false, 0, 160
            end,
            GetItemCDProgress = function(a, b)
                local itemID = (type(a) == "table" or type(a) == "userdata") and b or a
                local cd = _mockPlayer.tCDs[itemID]
                if cd and cd > 0 then
                    return true, cd, 160
                end
                return false, 0, 160
            end,
            GetBuffList = function(...)
                return _mockPlayer.tBuffs
            end,
            GetBuffCount = function(...)
                return #_mockPlayer.tBuffs
            end,
            GetBuff = function(a, b)
                local idx = (type(a) == "table" or type(a) == "userdata") and b or a
                return _mockPlayer.tBuffs[idx+1]
            end,
            GetSkillPrepareState = function(...)
                return _mockPlayer.bPreparing, _mockPlayer.dwPrepSkillID or 179, _mockPlayer.dwPrepSkillLevel or 1, 0.5
            end,
            GetOTActionState = function(...)
                return _mockPlayer.nOTState
            end,
            StopCurrentAction = function(...)
                _mockPlayer.bPreparing = false
                _mockPlayer.dwPrepSkillID = 0
                _mockPlayer.nOTState = 0
                _mockPlayer.bActionStopped = true
            end,
            GetItem = function(a, b, c)
                local dwBox, dwX
                if type(a) == "table" or type(a) == "userdata" then
                    dwBox, dwX = b, c
                else
                    dwBox, dwX = a, b
                end
                if dwBox == INVENTORY_INDEX.EQUIP then
                    return _mockPlayer.tEquip[dwX]
                elseif dwBox >= INVENTORY_INDEX.PACKAGE and dwBox <= 6 then
                    local bag = _mockPlayer.tBags[dwBox - INVENTORY_INDEX.PACKAGE + 1]
                    return bag and bag[dwX] or nil
                end
                return nil
            end,
            GetBoxSize = function(a, b)
                local dwBox = (type(a) == "table" or type(a) == "userdata") and b or a
                if dwBox == INVENTORY_INDEX.EQUIP then return 10 end
                return 16
            end,
            GetEquipPos = function(a, b, c)
                return 1, EQUIPMENT_INVENTORY.MELEE_WEAPON
            end
        }

        function GetClientPlayer() return _mockPlayer end
        function GetTargetHandle(tType, dwID)
            if dwID == _mockTarget.dwID then return _mockTarget end
            if dwID == _mockPlayer.dwID then return _mockPlayer end
            return _mockTarget
        end
        function GetNpc(dwID)
            if dwID == _mockTarget.dwID then return _mockTarget end
            return nil
        end
        function GetPlayer(dwID)
            if dwID == _mockPlayer.dwID then return _mockPlayer end
            return nil
        end
        function GetLogicFrameCount() return _curFrame end
        function GetTime() return _curFrame * 62.5 end

        function OnAddOnUseSkill(id, lvl)
            table.insert(_tCastedSkills, { id = id, lvl = lvl, frame = _curFrame })
            return true
        end

        function OnExchangeItem(srcBox, srcX, destBox, destX)
            local itemSrc, itemDest
            local bagSrc, bagDest
            if srcBox == INVENTORY_INDEX.EQUIP then
                itemSrc = _mockPlayer.tEquip[srcX]
            else
                bagSrc = _mockPlayer.tBags[srcBox - INVENTORY_INDEX.PACKAGE + 1]
                itemSrc = bagSrc and bagSrc[srcX]
            end

            if destBox == INVENTORY_INDEX.EQUIP then
                itemDest = _mockPlayer.tEquip[destX]
            else
                bagDest = _mockPlayer.tBags[destBox - INVENTORY_INDEX.PACKAGE + 1]
                itemDest = bagDest and bagDest[destX]
            end

            if srcBox == INVENTORY_INDEX.EQUIP then
                _mockPlayer.tEquip[srcX] = itemDest
            elseif bagSrc then
                bagSrc[srcX] = itemDest
            end

            if destBox == INVENTORY_INDEX.EQUIP then
                _mockPlayer.tEquip[destX] = itemSrc
            elseif bagDest then
                bagDest[destX] = itemSrc
            end
            return true
        end

        function OnUseItem(dwBox, dwX)
            table.insert(_tUsedItems, { box = dwBox, pos = dwX, frame = _curFrame })
            -- Xu ly logic doi vu khi tu tui vao o trang bi
            if dwBox >= INVENTORY_INDEX.PACKAGE and dwBox <= 6 then
                local bagIdx = dwBox - INVENTORY_INDEX.PACKAGE + 1
                local bag = _mockPlayer.tBags[bagIdx]
                if bag and bag[dwX] then
                    local itemFromBag = bag[dwX]
                    local currentEquip = _mockPlayer.tEquip[EQUIPMENT_INVENTORY.MELEE_WEAPON]
                    _mockPlayer.tEquip[EQUIPMENT_INVENTORY.MELEE_WEAPON] = itemFromBag
                    bag[dwX] = currentEquip
                end
            elseif dwBox == INVENTORY_INDEX.EQUIP and dwX == EQUIPMENT_INVENTORY.PENDANT then
                -- Dung Day Chuyen
                _mockPlayer.tCDs[9999] = 160 -- 10s CD
            end
            return true
        end
        """
        self.lua.execute(lua_code)

        # Load functions.lua and Macro.lua
        func_path = os.path.join(self.workspace_root, "interface", "xMacro", "functions.lua")
        with open(func_path, "r", encoding="utf-8") as f:
            self.lua.execute(f.read())

        macro_path = os.path.join(self.workspace_root, "interface", "xMacro", "Macro.lua")
        with open(macro_path, "r", encoding="utf-8") as f:
            self.lua.execute(f.read())

    # Environment Control Methods
    def get_frame(self):
        return int(self.lua.eval("_curFrame"))

    def advance_time(self, frames=1):
        # Progress frames
        cur = self.get_frame() + frames
        self.lua.execute(f"_curFrame = {cur}")

        # Tick down player buffs
        self.lua.execute(f"""
        local cur = _curFrame
        local newBuffs = {{}}
        for _, b in ipairs(_mockPlayer.tBuffs) do
            if not b.nEndFrame or b.nEndFrame > cur then
                table.insert(newBuffs, b)
            end
        end
        _mockPlayer.tBuffs = newBuffs

        -- Tick down target buffs
        local newTargetBuffs = {{}}
        for _, b in ipairs(_mockTarget.tBuffs) do
            if not b.nEndFrame or b.nEndFrame > cur then
                table.insert(newTargetBuffs, b)
            end
        end
        _mockTarget.tBuffs = newTargetBuffs

        -- Tick down CDs
        for id, cd in pairs(_mockPlayer.tCDs) do
            local left = cd - {frames}
            if left <= 0 then
                _mockPlayer.tCDs[id] = nil
            else
                _mockPlayer.tCDs[id] = left
            end
        end
        """)

    def set_current_weapon(self, name):
        self.lua.execute(f'_mockPlayer.tEquip[EQUIPMENT_INVENTORY.MELEE_WEAPON] = {{ szName = "{name}", nGenre = 1, nSub = 0 }}')

    def get_current_weapon(self):
        return self.lua.eval("_mockPlayer.tEquip[EQUIPMENT_INVENTORY.MELEE_WEAPON] and _mockPlayer.tEquip[EQUIPMENT_INVENTORY.MELEE_WEAPON].szName or ''")

    def add_bag_item(self, name, bag=1, slot=0):
        self.lua.execute(f"""
        _mockPlayer.tBags[{bag}] = _mockPlayer.tBags[{bag}] or {{}}
        _mockPlayer.tBags[{bag}][{slot}] = {{ szName = "{name}", nGenre = 1, nSub = 0 }}
        """)

    def add_player_buff(self, buff_id, name=None, stack=1, duration_sec=10):
        cur = self.get_frame()
        end_frame = cur + int(duration_sec * 16)
        name_str = f', szName = "{name}"' if name else ''
        self.lua.execute(f"""
        -- Remove existing buff with same ID if any
        local filtered = {{}}
        for _, b in ipairs(_mockPlayer.tBuffs) do
            if b.dwID ~= {buff_id} then table.insert(filtered, b) end
        end
        table.insert(filtered, {{ dwID = {buff_id}, nLevel = 1, nStackNum = {stack}, nEndFrame = {end_frame} {name_str} }})
        _mockPlayer.tBuffs = filtered
        """)

    def add_target_buff(self, buff_id, name=None, stack=1, duration_sec=18):
        cur = self.get_frame()
        end_frame = cur + int(duration_sec * 16)
        name_str = f', szName = "{name}"' if name else ''
        self.lua.execute(f"""
        local filtered = {{}}
        for _, b in ipairs(_mockTarget.tBuffs) do
            if b.dwID ~= {buff_id} then table.insert(filtered, b) end
        end
        table.insert(filtered, {{ dwID = {buff_id}, nLevel = 1, nStackNum = {stack}, nEndFrame = {end_frame}, dwSkillSrcID = 101 {name_str} }})
        _mockTarget.tBuffs = filtered
        """)

    def remove_player_buff(self, buff_id):
        self.lua.execute(f"""
        local filtered = {{}}
        for _, b in ipairs(_mockPlayer.tBuffs) do
            if b.dwID ~= {buff_id} then table.insert(filtered, b) end
        end
        _mockPlayer.tBuffs = filtered
        """)

    def remove_target_buff(self, buff_id):
        self.lua.execute(f"""
        local filtered = {{}}
        for _, b in ipairs(_mockTarget.tBuffs) do
            if b.dwID ~= {buff_id} then table.insert(filtered, b) end
        end
        _mockTarget.tBuffs = filtered
        """)

    def set_moving(self, is_moving=True):
        state = 2 if is_moving else 0
        self.lua.execute(f"_mockPlayer.nMoveState = {state}")

    def set_player_prepare(self, is_preparing=True, skill_id=179, ot_state=1):
        b_prep = "true" if is_preparing else "false"
        self.lua.execute(f"""
        _mockPlayer.bPreparing = {b_prep}
        _mockPlayer.dwPrepSkillID = {skill_id}
        _mockPlayer.nOTState = {ot_state if is_preparing else 0}
        _mockPlayer.bActionStopped = false
        """)

    def was_action_stopped(self):
        return bool(self.lua.eval("_mockPlayer.bActionStopped or false"))

    def set_skill_cd(self, skill_id, sec):
        frames = int(sec * 16)
        self.lua.execute(f"_mockPlayer.tCDs[{skill_id}] = {frames}")

    def execute_tick(self, macro_name_or_text=None):
        self.lua.execute("_tCastedSkills = {}; _tUsedItems = {}")
        if macro_name_or_text:
            self.lua.globals()._tempMacro = macro_name_or_text
            res = self.lua.execute("return ExecuteMacroCommand(_tempMacro)")
        else:
            res = self.lua.execute("return macro()")

        # Read back what was cast or used
        casted = []
        n_cast = int(self.lua.eval("#_tCastedSkills"))
        for i in range(1, n_cast + 1):
            sk_id = int(self.lua.eval(f"_tCastedSkills[{i}].id"))
            name = self.lua.eval(f"Table_GetSkillName({sk_id}, 1) or tostring({sk_id})")
            casted.append({"id": sk_id, "name": name})

        used_items = []
        n_items = int(self.lua.eval("#_tUsedItems"))
        for i in range(1, n_items + 1):
            box = int(self.lua.eval(f"_tUsedItems[{i}].box"))
            pos = int(self.lua.eval(f"_tUsedItems[{i}].pos"))
            used_items.append({"box": box, "pos": pos})

        return {
            "success": bool(res),
            "weapon": self.get_current_weapon(),
            "casted": casted,
            "used_items": used_items,
            "frame": self.get_frame(),
            "time_sec": round(self.get_frame() / 16.0, 2)
        }
