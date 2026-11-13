-- Public bridge. Runtime.lua assembles all modules in the reviewed build order.
xMacro = xMacro or {}
local lastFailure, initializedProfile = nil, nil
local function SelectedProfile()
    local config = xMacro.Config or {}
    local implementation, reason
    if xMacro.Schools and type(xMacro.Schools.Resolve) == "function" then
        implementation, reason = xMacro.Schools.Resolve(config.school, config.profile)
    else
        reason = "Schools/Registry.lua not ready"
    end
    if not implementation then
        local failure = tostring(config.school) .. "/" .. tostring(config.profile) .. ": " .. tostring(reason)
        if failure ~= lastFailure and OutputMessage then
            OutputMessage("MSG_SYS", "[xMacro] Profile unavailable: " .. failure)
            lastFailure = failure
        end
        return nil
    end
    lastFailure = nil
    if implementation ~= initializedProfile and type(SetActiveMacroScript) == "function" then
        if implementation.defaultScript then SetActiveMacroScript(implementation.defaultScript) end
        initializedProfile = implementation
    end
    return implementation
end
SelectedProfile()
function macro(szName)
    local implementation = SelectedProfile()
    if not implementation then return false end
    local me = GetClientPlayer()
    if not me then return false end
    -- 1. Neu truyen truc tiep mot doan lenh Macro chua lenh '/' thi thuc thi qua Script do
    if szName and type(szName) == "string" and szName ~= "" and szName ~= "auto" and string.find(szName, "/") then
        local ok, ret = pcall(ExecuteMacroCommand, szName)
        if ok and ret then return true end
    end

    return implementation.run(szName)
end
