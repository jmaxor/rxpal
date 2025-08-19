local itemDB = require("rxpal.database.classicItemDB")
local itemKeys = itemDB.itemKeys
local npcDB = require("rxpal.database.classicNpcDB")
local npcKeys = npcDB.npcKeys
local objectDB = require("rxpal.database.classicObjectDB")
local objectKeys = objectDB.objectKeys
local questDB = require("rxpal.database.classicQuestDB")
local questKeys = questDB.questKeys
local skillDB = require("rxpal.database.classicSkillDB")
local skillKeys = skillDB.skillKeys

local warn = unpack(require("rxpal.errorHandling"))


local function find(idOrName, db, lookup, keys, dbName)
    assert(
        type(idOrName) == "string" or type(idOrName) == "number",
        "please provide a string or number when searching for "..dbName
    )

    if type(idOrName) == "number" and db[idOrName] then
        return {{entry = db[idOrName], id = idOrName}}
    end

    local errorMessage = "could not find "..dbName.." from '"..idOrName.."'"
    assert(type(idOrName) == "string", errorMessage)

    local entries = {}

    -- find in the lookup table if one exists
    if lookup then
        local entryIds = lookup[string.lower(idOrName)]
        assert(entryIds, errorMessage)

        for _,v in ipairs(entryIds) do
            table.insert(entries, {id=v, entry=db[v]})
        end

        assert(#entries > 0, errorMessage)

        return entries
    end

    -- otherwise try finding with BF search
    for k,v in pairs(db) do
        local entryName = v[keys["name"]]

        if entryName and string.lower(entryName) == string.lower(idOrName) then
            table.insert(entries, {entry = v, id = k})
        end
    end

    assert(#entries > 0, errorMessage)

    return entries
end


local function isQuestAvailable(quest, completedQuests)
    -- only one quest in preQuestSingle must be completed
    local preQuestSingle = quest.entry[questKeys["preQuestSingle"]] or {}

    local singleFulfilled = #preQuestSingle == 0
    for _,preQuest in ipairs(preQuestSingle) do
        if completedQuests[preQuest] then
            singleFulfilled = true
            break
        end
    end

    -- all quests in preQuestGroup must be completed
    local preQuestGroup = quest.entry[questKeys["preQuestGroup"]] or {}

    local groupFulfilled = true
    for _,preQuest in ipairs(preQuestGroup) do
        if not completedQuests[preQuest] then
            groupFulfilled = false
            break
        end
    end

    return singleFulfilled and groupFulfilled and not completedQuests[quest.id]
end


local function findQuest_internal(questIdOrName, completedQuests, questData, questLookup)
    local quests = find(questIdOrName, questData, questLookup, questKeys, "quest")
    local filteredQuests = {}

    for _,quest in ipairs(quests) do
        if isQuestAvailable(quest, completedQuests) then
            table.insert(filteredQuests, quest)
        end
    end

    if #filteredQuests == 0 then
        filteredQuests = quests
        warn("filtering quest '"..questIdOrName.."' based on requirements removed all results. It's possible you forgot to complete a prereq.")
    end
    if #filteredQuests > 1 then
        warn("found "..#filteredQuests.." available quests from '"..questIdOrName.."'. Consider passing a specific quest ID instead of a string. Using first result ("..filteredQuests[1].id..").")
    end

    return filteredQuests[1].entry, filteredQuests[1].id
end


local function normalizeRank(rank)
    rank = rank or 1
    if type(rank) == "number" then
        return "rank "..rank
    end
    return string.lower(rank)
end


-- TODO dedupe skills in the skill db
local function findSkill_internal(skill, rank, skillData, skillLookup)
    assert(
        type(skill) == "string" or type(skill) == "number",
        "please provide a string or number when searching for a skill"
    )
    assert(
        type(rank) == "string" or type(rank) == "number" or type(rank) == "nil",
        "please provide a string or number when searching for a skill rank"
    )

    if type(skill) == "number" and skillData[skill] then
        return skillData[skill], skill
    end

    local errorMessage = "could not find skill from "..skill..", "..(rank or "nil")
    assert(type(skill) == "string", errorMessage)

    rank = normalizeRank(rank)
    local lookupKey = string.lower(skill).."_"..rank

    local entries = {}
    local skillIds = skillLookup[lookupKey] or {}
    for _,id in ipairs(skillIds) do
        table.insert(entries, {id=id, entry=skillData[id]})
    end

    --for k,v in pairs(skillData) do
    --    local entryName = v[skillKeys["name"]]
    --    local entryRank = normalizeRank(v[skillKeys["rank"]])
    --    if string.lower(entryName) == string.lower(skill) and entryRank == rank then
    --        table.insert(entries, {entry = v, id = k})
    --    end
    --end

    if #entries > 1 then
        warn("found "..#entries.." available skills from '"..skill.."', '"..rank.."'. Consider passing a specific skill ID instead of a string. Using first result ("..entries[1].id..").")
    end
    assert(#entries > 0, errorMessage)

    return entries[1].entry, entries[1].id
end


local function makeBasicFinder(database, lookup, keys, name)
    return function (identifier, userDatabase)
        local data = find(identifier, database or userDatabase, lookup, keys, name)

        if #data > 1 then
            warn("found "..#data.." "..name.."s from "..identifier..". Consider passing an ID instead of a string. Using first result ("..data[1].id..").")
        end

        return data[1].entry, data[1].id
    end
end


local function loadFinders (settings)
    local itemData, itemLookup = itemDB.loadDB(settings)
    local npcData, npcLookup = npcDB.loadDB(settings)
    local objectData, objectLookup = objectDB.loadDB(settings)
    local questData, questLookup = questDB.loadDB(settings)
    local skillData = skillDB.skillData
    local skillLookup = skillDB.skillLookup

    local findCurrentQuest = makeBasicFinder(nil, nil, questKeys, "current quest")
    local findNpc = makeBasicFinder(npcData, npcLookup, npcKeys, "npc")
    local findObject = makeBasicFinder(objectData, objectLookup, objectKeys, "object")
    local findItem = makeBasicFinder(itemData, itemLookup, itemKeys, "item")
    local function findQuest (quest, completedQuests)
        return findQuest_internal(quest, completedQuests, questData, questLookup)
    end
    local function findSkill (skill, rank)
        return findSkill_internal(skill, rank, skillData, skillLookup)
    end

    return findQuest, findCurrentQuest, findNpc, findObject, findItem, findSkill
end

return loadFinders