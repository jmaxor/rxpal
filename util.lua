local zoneNames = require("rxpal.database.classicZoneDB")

-- concatenates two arrays into a new array! returns the result
local function arrayConcat(a1, a2)
    local newArray = {}

    for _,v in ipairs(a1) do
        table.insert(newArray, v)
    end
    for _,v in ipairs(a2) do
        table.insert(newArray, v)
    end

    return newArray
end


-- merges two tables which map zones to coordinate pairs within that zone
local function mergeCoordTables(t1, t2)
    local newSpawnTable = {}

    for zone,zoneCoords in pairs(t1) do
        newSpawnTable[zone] = arrayConcat(newSpawnTable[zone] or {}, zoneCoords)
    end
    for zone,zoneCoords in pairs(t2) do
        newSpawnTable[zone] = arrayConcat(newSpawnTable[zone] or {}, zoneCoords)
    end

    return newSpawnTable
end


-- tries to find best goto given a table mapping zoneids to coords
-- uses zone with the most coords and averages the x and y coords listed for that zone
-- returns a nice .goto string
local function autogoto(stepArray, coords)
    local maxCoords = 0
    local maxZone

    -- find which zone has the most # of coords
    for k,v in pairs(coords) do
        if #v > maxCoords then
            maxCoords = #v
            maxZone = k
        end
    end

    if not maxZone then
        warn("warn: No coords could be found for this step. Consider manually adding coords.")
    end

    -- add x and y coords so we can average them
    local xtotal = 0
    local ytotal = 0
    for k,v in pairs(coords[maxZone]) do
        xtotal = xtotal + v[1]
        ytotal = ytotal + v[2]
    end

    local xavg = xtotal/maxCoords
    local yavg = ytotal/maxCoords

    -- round to 2 decimal places
    xavg = math.floor(xavg * 100 + 0.5) / 100
    yavg = math.floor(yavg * 100 + 0.5) / 100

    table.insert(stepArray, ".goto "..zoneNames[maxZone]..","..xavg..","..yavg)
end

return {
    arrayConcat = arrayConcat,
    mergeCoordTables = mergeCoordTables,
    autogoto = autogoto
}