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


local function find(idOrName, db, keys, dbName)
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


local function findQuest_internal(questIdOrName, completedQuests, questData)
    local quests = find(questIdOrName, questData, questKeys, "quest")
    local filteredQuests = {}

    for _,quest in ipairs(quests) do
        if isQuestAvailable(quest, completedQuests) then
            table.insert(filteredQuests, quest)
        end
    end

    if #filteredQuests == 0 then
        filteredQuests = quests
        warn("filtering quest "..questIdOrName.." based on requirements removed all results. It's possible you forgot to complete a prereq.")
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
local function findSkill_internal(skill, rank, skillData)
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
    local entries = {}
    for k,v in pairs(skillData) do
        local entryName = v[skillKeys["name"]]
        local entryRank = normalizeRank(v[skillKeys["rank"]])
        if string.lower(entryName) == string.lower(skill) and entryRank == rank then
            table.insert(entries, {entry = v, id = k})
        end
    end

    if #entries > 1 then
        warn("found "..#entries.." available skills from '"..skill.."', '"..rank.."'. Consider passing a specific skill ID instead of a string. Using first result ("..entries[1].id..").")
    end
    assert(#entries > 0, errorMessage)

    return entries[1].entry, entries[1].id
end


local function makeBasicFinder(database, keys, name)
    return function (identifier, userDatabase)
        local data = find(identifier, database or userDatabase, keys, name)

        if #data > 1 then
            warn("found "..#data.." "..name.."s from "..identifier..". Consider passing an ID instead of a string. Using first result ("..data[1].id..").")
        end

        return data[1].entry, data[1].id
    end
end


local function loadFinders (settings)
    local itemData = itemDB.loadDB(settings)
    local npcData = npcDB.loadDB(settings)
    local objectData = objectDB.loadDB(settings)
    local questData = questDB.loadDB(settings)
    local skillData = skillDB.skillData

    local findCurrentQuest = makeBasicFinder(nil, questKeys, "current quest")
    local findNpc = makeBasicFinder(npcData, npcKeys, "npc")
    local findObject = makeBasicFinder(objectData, objectKeys, "object")
    local findItem = makeBasicFinder(itemData, itemKeys, "item")
    local function findQuest (quest, completedQuests)
        return findQuest_internal(quest, completedQuests, questData)
    end
    local function findSkill (skill, rank)
        return findSkill_internal(skill, rank, skillData)
    end

    return findQuest, findCurrentQuest, findNpc, findObject, findItem, findSkill
end

return loadFinders