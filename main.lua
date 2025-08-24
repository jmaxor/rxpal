-- TODO race and class filtering for picking up quests?
-- TODO lastNpc/lastObject should probably be encoded within the steps data. Current system is very error prone.
-- TODO Maybe some optimizations
-- TODO add rockspec?

local eh = require("rxpal.errorHandling")
local warn, wrapWithErrorHandling = eh.warn, eh.wrapWithErrorHandling

local util = require("rxpal.util")

local itemKeys = require("rxpal.database.classicItemDB").itemKeys
local npcKeys = require("rxpal.database.classicNpcDB").npcKeys
local objectKeys = require("rxpal.database.classicObjectDB").objectKeys
local questKeys = require("rxpal.database.classicQuestDB").questKeys

local findQuest, findCurrentQuest, findNpc, findObject, findItem, findSkill

local _rxpal_settings = {}
local steps = {}
local guides = {}
local completedQuests = {}
local currentQuests = {}
local totalCurrentQuests = 0
local lastNpc = nil
local lastObject = nil
local startTime = nil


-- builds the part of a step for NPC dialogue (coords, target, UX text)
-- and returns an array with those parts, as well as the id of the NPC
local function autonpc_internal(npc)
    local thisStep = {}
    local npcEntry, npcId = findNpc(npc)
    local npcName = npcEntry[npcKeys["name"]]
    local npcSpawn = npcEntry[npcKeys["spawns"]]

    if lastNpc == npcId then
        thisStep = table.remove(steps)
    else
        util.autogoto(thisStep, npcSpawn)
        table.insert(thisStep, ".target "..npcName)
        table.insert(thisStep, ">>|Tinterface/worldmap/chatbubble_64grey.blp:20|tTalk to |cRXP_FRIENDLY_"..npcName.."|r")
    end

    return thisStep, npcId
end
autonpc = wrapWithErrorHandling(autonpc_internal, "autonpc")


-- builds the part of a step for clicking an object (coords, UX text)
-- and returns an array with those parts, as well as the id of the object
local function autoobject_internal(object)
    local thisStep = {}
    local objectEntry, objectId = findObject(object)
    local objectSpawn = objectEntry[objectKeys["spawns"]]
    local objectName = objectEntry[objectKeys["name"]]

    if lastObject == objectId then
        thisStep = table.remove(steps)
    else
        util.autogoto(thisStep, objectSpawn)
        table.insert(thisStep, ">>|Tinterface/cursor/interact.blp:20|tClick on the |cRXP_LOOT_"..objectName.."|r object")
    end

    return thisStep, objectId
end
autoobject = wrapWithErrorHandling(autoobject_internal, "autoobject")


-- adds a step to accept a quest
local function accept_internal(quest)
    local thisStep

    local questEntry, questId = findQuest(quest, completedQuests)
    local questName = questEntry[questKeys["name"]]

    local startedBy = questEntry[questKeys["startedBy"]]
    local npcStart = startedBy[1]
    local objectStart = startedBy[2]
    local itemStart = startedBy[3]

    if npcStart then
        thisStep, npcId = autonpc_internal(npcStart[1])
        lastNpc = npcId
        lastObject = nil
    elseif objectStart then
        thisStep, objectId = autoobject_internal(objectStart[1])
        lastNpc = nil
        lastObject = objectId
    elseif itemStart then
        thisStep = {}
        local itemEntry, itemId = findItem(itemStart[1])
        local itemName = itemEntry[itemKeys["name"]]

        table.insert(thisStep, ".collect "..itemId..",1".." --"..itemName)
        table.insert(thisStep, ".use "..itemId.." --"..itemName)

        lastNpc = nil
        lastObject = nil
    end

    table.insert(thisStep, ".accept "..questId.." --"..questName)

    if currentQuests[questId] then
        warn("attempting to accept a quest that you are already on: "..questId)
    end
    currentQuests[questId] = questEntry
    totalCurrentQuests = totalCurrentQuests+1
    if totalCurrentQuests > 20 then
        warn("Quest log exceeded 20. Current quests:")
        for k,v in pairs(currentQuests) do
            warn(v[questKeys["name"]])
        end
    end

    table.insert(steps, thisStep)
    return #steps
end
accept = wrapWithErrorHandling(accept_internal, "accept")


-- adds a step to turn in a quest
local function turnin_internal(quest, reward)
    local thisStep = {}

    local questEntry, questId = findCurrentQuest(quest, currentQuests)
    local questName = questEntry[questKeys["name"]]

    local finishedBy = questEntry[questKeys["finishedBy"]]
    local npcEnd = finishedBy[1]
    local objectEnd = finishedBy[2]

    if npcEnd then
        thisStep, npcId = autonpc_internal(npcEnd[1])
        lastNpc = npcId
        lastObject = nil
    elseif objectEnd then
        thisStep, objectId = autoobject_internal(objectEnd[1])
        lastNpc = nil
        lastObject = objectId
    else
        error("no turnin information for quest "..quest)
    end

    local turninCmd = ".turnin "..questId
    if reward then
        turninCmd = turninCmd..","..reward
    end
    table.insert(thisStep, turninCmd.." --"..questName)

    currentQuests[questId] = nil
    totalCurrentQuests = totalCurrentQuests-1
    completedQuests[questId] = true

    table.insert(steps, thisStep)
    return #steps
end
turnin = wrapWithErrorHandling(turnin_internal, "turnin")


-- adds a step that completes a quest objective
local function complete_internal(quest, objectiveId, withCoords)
    objectiveId = objectiveId or 1
    local thisStep = {}
    local coords = {}
    local questEntry, questId = findCurrentQuest(quest, currentQuests)
    local questName = questEntry[questKeys["name"]]
    local objectives = questEntry[questKeys["objectives"]]
    local triggerEnd = questEntry[questKeys["triggerEnd"]]
    assert(objectives or triggerEnd, "Attempting to complete part of a quest with no objectives.")
    objectives = objectives or {}

    table.insert(thisStep, ".complete "..questId..","..objectiveId.." --"..questName)

    -- find mobs associated with this objective
    -- if kill objective, pretty easy
    -- if item objective, find mobs it drops from 
    -- otherwise no mobs

    -- coords associated with objective (is this useful? I think so)
    -- kill objective - send spawn coords to autogoto
    -- item objective - find mobs that drop it, merge coords (?), send to autogoto
    -- object objective - find object, send spawn coords to autogoto
    -- rep objective - NO
    -- triggerEnd objective - fulfilled by some trigger (watch some RP, escort an npc, visit a location, etc)
    
    local killObjective = objectives[1]
    local objectObjective = objectives[2]
    local itemObjective = objectives[3]

    local killStart = 0
    local objectStart = killStart + (killObjective and #killObjective or 0)
    local itemStart = objectStart + (objectObjective and #objectObjective or 0)
    local repStart = itemStart + (itemObjective and #itemObjective or 0)
    local triggerEndStart = repStart + (triggerEnd and 1 or 0)

    if objectiveId <= objectStart then --kill objective
        local npcId = killObjective[objectiveId][1]
        local npcEntry = findNpc(npcId)
        table.insert(thisStep, ".mob "..npcEntry[npcKeys["name"]])
        coords = npcEntry[npcKeys["spawns"]]
    elseif objectiveId <= itemStart then --object objective
        local objectEntry = findObject(objectObjective[objectiveId-objectStart][1])
        coords = objectEntry[objectKeys["spawns"]]
    elseif objectiveId <= repStart then --item objective
        local itemId = itemObjective[objectiveId-itemStart][1]
        local itemEntry = findItem(itemId)
        local npcDrops = itemEntry[itemKeys["npcDrops"]] or {}
        local objectDrops = itemEntry[itemKeys["objectDrops"]] or {}
        for _,npcId in ipairs(npcDrops) do
            local npcEntry = findNpc(npcId)
            table.insert(thisStep, ".mob "..npcEntry[npcKeys["name"]])
            coords = util.mergeCoordTables(coords, npcEntry[npcKeys["spawns"]] or {})
        end
        for _,objectId in pairs(objectDrops) do
            local objectEntry = findObject(objectId)
            coords = util.mergeCoordTables(coords, objectEntry[objectKeys["spawns"]] or {})
        end
    elseif objectiveId <= triggerEndStart then --trigger objective
        -- second element in the triggerEnd array are coords for that trigger
        coords = triggerEnd[2] or {}
    end

    if withCoords then
        util.autogoto(thisStep, coords)
    end

    lastNpc = nil
    lastObject = nil
    table.insert(steps, thisStep)
    return #steps
end
complete = wrapWithErrorHandling(complete_internal, "complete")


-- adds a step to buy something from a vendor
local function buy_internal(num, item, from)
    local thisStep, npcId = autonpc_internal(from)
    lastNpc = npcId
    lastObject = nil

    local itemEntry, itemId = findItem(item)

    table.insert(thisStep, ".collect "..itemId..","..num)
    table.insert(thisStep, ".buy "..itemId..","..num)

    table.insert(steps, thisStep)
    return #steps
end
buy = wrapWithErrorHandling(buy_internal, "buy")


-- adds a step to collect some item
local function collect_internal(num, item)
    local thisStep = {}

    local itemEntry, itemId = findItem(item)
    table.insert(thisStep, ".collect "..itemId..","..num.." --"..itemEntry[itemKeys["name"]])

    lastNpc = nil
    lastObject = nil
    table.insert(steps, thisStep)
    return #steps
end
collect = wrapWithErrorHandling(collect_internal, "collect")


-- adds a step to train a skill at a given trainer
local function train_internal(skill, from, rank)
    local thisStep, npcId = autonpc_internal(from)
    lastNpc = npcId
    lastObject = nil

    local skillEntry, skillId = findSkill(skill, rank)
    -- TODO use skill keys here
    local skillName = skillEntry[1]
    local skillRank = skillEntry[2]

    local rankText = skillRank and " ("..skillRank..")" or ""
    table.insert(thisStep, ".train "..skillId.." >>Train ["..skillName..rankText.."]")

    table.insert(steps, thisStep)
    return #steps
end
train = wrapWithErrorHandling(train_internal, "train")


-- merges multiple steps and/or text lines into one step, which gets added
function step(...)
    local thisStep = {}
    local stepsRemoved = {}

    -- Go in reverse so all elements in `steps` keep their starting numerical position
    -- until removed. Since we're starting from the end, we must then insert to the
    -- front of the `thisStep` array to preserve order.
    -- Also note, we need to track which steps have already been removed for the case where
    -- two steps given were already auto-merged (ex. two dialogue steps for the same NPC)
    for i=#arg,1,-1 do
        local stepToMerge = arg[i]
        if type(arg[i]) == "number" and not stepsRemoved[arg[i]] then
            stepToMerge = table.remove(steps, arg[i])
            thisStep = util.arrayConcat(stepToMerge, thisStep)
            stepsRemoved[arg[i]] = true
        elseif type(arg[i]) == "string" then
            -- trim the string
            stepToMerge = string.gsub(stepToMerge, "^%s*(.-)%s*$", "%1")
            table.insert(thisStep, 1, stepToMerge)
        elseif type(arg[i]) == "table" then
            thisStep = util.arrayConcat(stepToMerge, thisStep)
        end
    end

    lastNpc = nil
    lastObject = nil
    table.insert(steps, thisStep)
    return #steps
end


-- ends previous guide section and registers a new one
function register(group, guideName, nextGuide, customHeaders, file)
    assert(group and guideName, "register function must have a group and guideName defined")

    if #guides > 0 then
        guides[#guides].steps = steps
        steps = {}
    end

    local headers = customHeaders or ""
    headers = headers.."#name "..guideName.."\n"
    if nextGuide then
        headers = headers.."#next "..nextGuide.."\n"
    end

    table.insert(guides, {group=group, headers=headers})

    if file then dofile(file) end
end


-- wraps everything up and outputs the RXP guide file
function finish()
    if #guides > 0 then
        guides[#guides].steps = steps
        steps = {}
    end

    local output = "-- This file was generated using RXPAL\n-- https://github.com/jmaxor/rxpal\n\n"

    for _,guide in ipairs(guides) do
        output = output..'RXPGuides.RegisterGuide("'..guide.group..'",[[\n'..guide.headers..'\n\n'
        for _,step in ipairs(guide.steps) do
            output = output..'step\n'
            for _,line in ipairs(step) do
                output = output..'    '..line..'\n'
            end
        end
        output = output..']])\n\n'
    end

    print(output)
    if totalCurrentQuests > 0 then
        warn("\nwarning: potential quests left over without being turned in:")
        for k,v in pairs(currentQuests) do
            warn("  "..v[questKeys["name"]])
        end
    end
    local totalRuntime = os.clock() - startTime
    warn("\nguides built successfully in "..totalRuntime.." seconds!")
end


-- initializes the databases based on provided settings
function init(settings)
    startTime = os.clock()
    _rxpal_settings = settings
    findQuest, findCurrentQuest, findNpc, findObject, findItem, findSkill = require("rxpal.finders")(settings)
end


-- dumps debug info about current quests
function _rxpal_debug()
    warn("debug - current quests held:")
    for k,v in pairs(currentQuests) do
        warn(v[questKeys["name"]]..","..k)
    end
end


--auto-reward aliases
function turnin1(quest)
    return turnin_internal(quest, 1)
end
turnin1 = wrapWithErrorHandling(turnin1, "turnin1")

function turnin2(quest)
    return turnin_internal(quest, 2)
end
turnin2 = wrapWithErrorHandling(turnin2, "turnin2")

function turnin3(quest)
    return turnin_internal(quest, 3)
end
turnin3 = wrapWithErrorHandling(turnin3, "turnin3")

function turnin4(quest)
    return turnin_internal(quest, 4)
end
turnin4 = wrapWithErrorHandling(turnin4, "turnin4")

function turnin5(quest)
    return turnin_internal(quest, 5)
end
turnin5 = wrapWithErrorHandling(turnin5, "turnin5")

--auto-objectiveId and withCoords aliases
function complete1(quest, withCoords)
    return complete_internal(quest, 1, withCoords)
end
complete1 = wrapWithErrorHandling(complete1, "complete1")

function complete2(quest, withCoords)
    return complete_internal(quest, 2, withCoords)
end
complete2 = wrapWithErrorHandling(complete2, "complete2")

function complete3(quest, withCoords)
    return complete_internal(quest, 3, withCoords)
end
complete3 = wrapWithErrorHandling(complete3, "complete3")

function complete4(quest, withCoords)
    return complete_internal(quest, 4, withCoords)
end
complete4 = wrapWithErrorHandling(complete4, "complete4")

function complete5(quest, withCoords)
    return complete_internal(quest, 5, withCoords)
end
complete5 = wrapWithErrorHandling(complete5, "complete5")

function completewc(quest, objectiveId)
    return complete_internal(quest, objectiveId, true)
end
completewc = wrapWithErrorHandling(completewc, "completewc")

function complete1wc(quest)
    return complete_internal(quest, 1, true)
end
complete1wc = wrapWithErrorHandling(complete1wc, "complete1wc")

function complete2wc(quest)
    return complete_internal(quest, 2, true)
end
complete2wc = wrapWithErrorHandling(complete2wc, "complete2wc")

function complete3wc(quest)
    return complete_internal(quest, 3, true)
end
complete3wc = wrapWithErrorHandling(complete3wc, "complete3wc")

function complete4wc(quest)
    return complete_internal(quest, 4, true)
end
complete4wc = wrapWithErrorHandling(complete4wc, "complete4wc")

function complete5wc(quest)
    return complete_internal(quest, 5, true)
end
complete5wc = wrapWithErrorHandling(complete5wc, "complete5wc")
