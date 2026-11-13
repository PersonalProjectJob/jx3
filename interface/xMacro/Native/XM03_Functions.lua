-- GENERATED native entry; edit canonical modules, then rebuild.
local runtimeStatus = type(xMacro)=="table" and xMacro.Runtime
if type(runtimeStatus)~="table" or runtimeStatus.nativeLayout~="ordered-v1" then
    macro=function() return false end
    error("xMacro native bootstrap missing; combo disabled")
end
if runtimeStatus.nextNative ~= 3 then
    runtimeStatus.ready=false
    macro=function() return false end
    error("xMacro native load order invalid; combo disabled")
end
runtimeStatus.nextNative = 4
local function ReportStartup(message)
    if OutputMessage then pcall(OutputMessage, "MSG_SYS", "[xMacro 0.9.7] " .. message .. "\n") end
end
local unavailableReported = false
local function UnavailableMacro()
    if not unavailableReported then
        ReportStartup("Runtime NOT_READY; see LOAD_ERROR at addon startup")
        unavailableReported = true
    end
    return false
end
-- BEGIN Core/functions.lua
do
local function InitializeModule()
function checkcd(target, skillID)
bOnCD, currentCDTime, totalCDTime = target.GetSkillCDProgress(skillID, target.GetSkillLevel(skillID))
if currentCDTime/16 == 0 then
	return true
else
	return false
end
end

function CastSkillIDs(p,skillIDs)
	for z,x in pairs(skillIDs) do
		if CheckCD(p,x)==0 then
			OnAddOnUseSkill(x)
			return true
		end
	end
end

function TerminateSkill(p,t,NPCskills,MySkill)
	a,b,c,d=t.GetSkillPrepareState()
	if a then
		for z,x in pairs(NPCskills) do
			if b == x then
				p.StopCurrentAction()
				OnAddOnUseSkill(MySkill)
			end
		end
	end
end

function BuffLastingTime(target,buffID)
for z,x in pairs(target.GetBuffList()) do
if x.dwID==buffID then return (x.nEndFrame-GetLogicFrameCount())/GLOBAL.GAME_FPS end
end
return 0
end

function CheckBuff(target, buffID)
buffed = false
for z,x in pairs(target.GetBuffList() or {}) do
	if x.dwID == buffID then
		buffed = true
	end
end
return buffed
end

function BuffStack(target, buffID)
stack=0
	for z,x in pairs(target.GetBuffList()) do
		if x.dwID == buffID then
			stack = x.nStackNum
		end
	end
	return stack
end
end
local ok, result = pcall(InitializeModule)
runtimeStatus.modules["Core/functions.lua"] = ok
if not ok then
    runtimeStatus.errors["Core/functions.lua"] = tostring(result)
    ReportStartup("LOAD_ERROR Core/functions.lua: " .. tostring(result))
end
end
-- END Core/functions.lua
