-- GENERATED native entry; edit canonical modules, then rebuild.
local runtimeStatus = type(xMacro)=="table" and xMacro.Runtime
if type(runtimeStatus)~="table" or runtimeStatus.nativeLayout~="ordered-v1" then
    macro=function() return false end
    error("xMacro native bootstrap missing; combo disabled")
end
if runtimeStatus.nextNative ~= 2 then
    runtimeStatus.ready=false
    macro=function() return false end
    error("xMacro native load order invalid; combo disabled")
end
runtimeStatus.nextNative = 3
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
-- BEGIN Schools/Registry.lua
do
local function InitializeModule()
-- Stable registry: verified executable profiles only; text references never execute.
xMacro = xMacro or {}
xMacro.Schools = xMacro.Schools or {}
xMacro.SchoolProfiles = xMacro.SchoolProfiles or {}
xMacro.SchoolFactories = xMacro.SchoolFactories or {}
local profiles = xMacro.SchoolProfiles
local failures = xMacro.Schools.factoryFailures or {}
xMacro.Schools.factoryFailures = failures
function xMacro.Schools.Register(school, profile, implementation)
    assert(type(school) == "string" and school ~= "", "school is required")
    assert(type(profile) == "string" and profile ~= "", "profile is required")
    assert(type(implementation) == "table" and type(implementation.run) == "function", "profile.run is required")
    profiles[school] = profiles[school] or {}
    assert(not profiles[school][profile], "duplicate school profile")
    profiles[school][profile] = implementation
end
function xMacro.Schools.Resolve(school, profile)
    local implementation = profiles[school] and profiles[school][profile]
    if implementation then return implementation end
    local factory = xMacro.SchoolFactories[school] and xMacro.SchoolFactories[school][profile]
    if not factory then return nil, "school module/factory not loaded" end
    if not (xMacro.Core and type(xMacro.Core.SchoolDependencies) == "function") then
        return nil, "Core/Macro.lua dependencies not ready"
    end
    if failures[factory] then return nil, failures[factory] end
    local okDeps, deps = pcall(xMacro.Core.SchoolDependencies)
    if not okDeps or type(deps) ~= "table" then
        return nil, "Core dependency provider failed: " .. tostring(deps)
    end
    local ok, result = pcall(factory, deps)
    if not ok or type(result) ~= "table" or type(result.run) ~= "function" then
        local reason = "school factory failed: " .. tostring(result)
        failures[factory] = reason
        return nil, reason
    end
    xMacro.Schools.Register(school, profile, result)
    return result
end
end
local ok, result = pcall(InitializeModule)
runtimeStatus.modules["Schools/Registry.lua"] = ok
if not ok then
    runtimeStatus.errors["Schools/Registry.lua"] = tostring(result)
    ReportStartup("LOAD_ERROR Schools/Registry.lua: " .. tostring(result))
end
end
-- END Schools/Registry.lua
