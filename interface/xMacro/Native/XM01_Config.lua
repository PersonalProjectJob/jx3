-- GENERATED native entry; edit canonical modules, then rebuild.
local runtimeStatus = type(xMacro)=="table" and xMacro.Runtime
if type(runtimeStatus)~="table" or runtimeStatus.nativeLayout~="ordered-v1" then
    macro=function() return false end
    error("xMacro native bootstrap missing; combo disabled")
end
if runtimeStatus.nextNative ~= 1 then
    runtimeStatus.ready=false
    macro=function() return false end
    error("xMacro native load order invalid; combo disabled")
end
runtimeStatus.nextNative = 2
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
-- BEGIN Config.lua
do
local function InitializeModule()
-- Explicit selection: native force IDs are intentionally not guessed.
xMacro = xMacro or {}
xMacro.Config = xMacro.Config or {}
xMacro.Config.school = xMacro.Config.school or "VanHoa"
xMacro.Config.profile = xMacro.Config.profile or "HoaGian"
end
local ok, result = pcall(InitializeModule)
runtimeStatus.modules["Config.lua"] = ok
if not ok then
    runtimeStatus.errors["Config.lua"] = tostring(result)
    ReportStartup("LOAD_ERROR Config.lua: " .. tostring(result))
end
end
-- END Config.lua
