local function loadFixes(database, fixes, hordeFixes, allianceFixes, settings)
    for id,fixTable in pairs(fixes) do
        if not database[id] then database[id] = {} end
        for key,fix in pairs(fixTable) do
            database[id][key] = fix
        end
    end

    local factionFixes
    if settings.faction == "horde" then
        factionFixes = hordeFixes
    elseif settings.faction == "alliance" then
        factionFixes = allianceFixes
    else
        error("please add a faction (horde or alliance) to the settings when initializing")
    end

    for id,fixTable in pairs(factionFixes) do
        if not database[id] then database[id] = {} end
        for key,fix in pairs(fixTable) do
            database[id][key] = fix
        end
    end

    return database
end

return {loadFixes=loadFixes}