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
