local callingFileInfo = nil
local commandInfo = nil
local warnStateCreated = false

local function warn(message)
    if callingFileInfo and commandInfo and not warnStateCreated then
        io.stderr:write("\nwarning(s) while attempting to "..commandInfo.." "..callingFileInfo..":\n")
        warnStateCreated = true
    end

    io.stderr:write((warnStateCreated and "  - " or "")..message.."\n")
end

local function wrapWithErrorHandling(func, stepName)
    return function (...)
        local debugInfo = debug.getinfo(2, "Sl")
        callingFileInfo = debugInfo.source.."(line "..debugInfo.currentline..")"
        commandInfo = stepName.." ("..table.concat({...}, ", ")..")"

        local status, result = pcall(func, ...)

        if not status then
            error("error when attempting to "..commandInfo.." "..callingFileInfo..":\n"..result)
        end

        callingFileInfo = nil
        commandInfo = nil
        warnStateCreated = false

        return result
    end
end

return {
    warn = warn,
    wrapWithErrorHandling = wrapWithErrorHandling
}