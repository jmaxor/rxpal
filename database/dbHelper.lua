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


-- makes a lookup table for searching things quickly by name
-- table maps entry names to a table of IDs matching the given name
local function makeLookup(database, keys)
    local lookupTable = {}

    for id,entry in pairs(database) do
        local entryName = string.lower(entry[keys.name])
        lookupTable[entryName] = lookupTable[entryName] or {}
        table.insert(lookupTable[entryName], id)
    end

    return lookupTable
end

return {loadFixes=loadFixes, makeLookup=makeLookup}
