-- Public bridge. Runtime.lua assembles all modules in the reviewed build order.
xMacro = xMacro or {}
-- Command codes are independent of installed rotations. Missing profiles fail closed.
local SCHOOL_CODES = {
    VH = {school = "VanHoa", profile = "HoaGian"},
    ["7T"] = {school = "ThatTu", profile = "BangTam"},
    TS = {school = "ThienSach", profile = "DPS"},
    TK = {school = "TangKiem", profile = "DPS"},
    DMKV = {school = "DuongMon", profile = "KinhVu"},
    DMTL = {school = "DuongMon", profile = "ThienLa"},
}
local lastFailure, initializedProfile = nil, nil
local function ReportFailure(failure)
    if failure ~= lastFailure and OutputMessage then
        OutputMessage("MSG_SYS", "[xMacro] " .. failure .. "\n")
        lastFailure = failure
    end
end
local function SelectedProfile(selection)
    local config = selection or xMacro.Config or {}
    local implementation, reason
    if xMacro.Schools and type(xMacro.Schools.Resolve) == "function" then
        implementation, reason = xMacro.Schools.Resolve(config.school, config.profile)
    else
        reason = "Schools/Registry.lua not ready"
    end
    if not implementation then
        ReportFailure("Profile unavailable: " .. tostring(config.school) .. "/" .. tostring(config.profile) .. ": " .. tostring(reason))
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
local function HasExtraArgument(first, ...)
    -- type() rejects a missing argument but accepts an explicit nil.
    return pcall(type, ...)
end
local function Dispatch(...)
    local hasFirst, firstType = pcall(type, ...)
    local szName = ...
    local selection
    -- Reject undefined bare identifiers, e.g. macro(TS), rather than running VH.
    if (hasFirst and firstType ~= "string") or HasExtraArgument(...) then
        ReportFailure('Invalid macro code. Use macro("VH"), macro("7T"), macro("TS"), macro("TK"), macro("DMKV") or macro("DMTL").')
        return false
    end
    if szName then
        local code = string.upper((string.gsub(szName, "^%s*(.-)%s*$", "%1")))
        if code ~= "" and code ~= "AUTO" and not string.find(szName, "/") then
            selection = SCHOOL_CODES[code]
            if not selection then
                ReportFailure("Unknown macro code: " .. code .. ". Valid codes: VH, 7T, TS, TK, DMKV, DMTL.")
                return false
            end
            -- The code selects a profile; it is not an argument to its rotation.
            szName = nil
        elseif code == "AUTO" then
            szName = "auto"
        end
    end
    local implementation = SelectedProfile(selection)
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
local lastRuntimeError
function macro(...)
    local status = xMacro.Runtime
    if status and status.ready == false then
        ReportFailure("Runtime NOT_READY; see LOAD_ERROR at addon startup.")
        return false
    end
    local ok, result = pcall(Dispatch, ...)
    if not ok then
        local message = "Macro runtime error: " .. tostring(result)
        if status then status.lastCallError = tostring(result) end
        if message ~= lastRuntimeError then
            ReportFailure(message)
            lastRuntimeError = message
        end
        return false
    end
    lastRuntimeError = nil
    if status then status.lastCallError = nil end
    return result
end
