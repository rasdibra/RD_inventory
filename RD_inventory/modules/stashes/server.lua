RDStash = RDStash or {}

local function getStashList()
    local raw = RDStashes or (RD and RD.Stashes) or {}
    local out = {}
    for id, stash in pairs(raw) do
        if type(stash) == 'table' then
            stash.id = stash.id or tostring(id)
            out[#out + 1] = stash
        end
    end
    return out
end

function RDStash.find(stashId)
    stashId = tostring(stashId or '')
    for _, stash in ipairs(getStashList()) do
        if tostring(stash.id) == stashId then return stash end
    end
    return nil
end

local function getESXPlayer(src)
    if GetResourceState('es_extended') ~= 'started' then return nil end
    local ok, ESX = pcall(function() return exports.es_extended:getSharedObject() end)
    if ok and ESX then return ESX.GetPlayerFromId(src) end
end

local function getQBPlayer(src)
    if GetResourceState('qbx_core') == 'started' then
        local ok, p = pcall(function() return exports.qbx_core:GetPlayer(src) end)
        if ok and p then return p end
    end
    if GetResourceState('qb-core') == 'started' then
        local ok, QBCore = pcall(function() return exports['qb-core']:GetCoreObject() end)
        if ok and QBCore and QBCore.Functions then return QBCore.Functions.GetPlayer(src) end
    end
end

local function playerJob(src)
    local xPlayer = getESXPlayer(src)
    if xPlayer and xPlayer.job then
        return xPlayer.job.name, tonumber(xPlayer.job.grade or xPlayer.job.grade_level or 0) or 0
    end
    local p = getQBPlayer(src)
    local data = p and (p.PlayerData or p)
    local job = data and data.job
    if job then
        return job.name, tonumber(job.grade and (job.grade.level or job.grade) or job.grade_level or 0) or 0
    end
end

local function playerGang(src)
    local p = getQBPlayer(src)
    local data = p and (p.PlayerData or p)
    local gang = data and data.gang
    if gang then
        return gang.name, tonumber(gang.grade and (gang.grade.level or gang.grade) or gang.grade_level or 0) or 0
    end
    -- ESX gang resources often store gang as a job. This fallback allows gangs to work when configured that way.
    return playerJob(src)
end

local function hasGroupAccess(groups, name, grade)
    if not groups then return true end
    if not name then return false end
    local minGrade = groups[name]
    if minGrade == nil then return false end
    return tonumber(grade or 0) >= tonumber(minGrade or 0)
end

function RDStash.canOpen(src, stashId)
    local stash = RDStash.find(stashId)
    if not stash then return false, nil, 'Stash not found' end

    if stash.jobs then
        local job, grade = playerJob(src)
        if not hasGroupAccess(stash.jobs, job, grade) then return false, stash, 'No job access' end
    end

    if stash.gangs then
        local gang, grade = playerGang(src)
        if not hasGroupAccess(stash.gangs, gang, grade) then return false, stash, 'No gang access' end
    end

    return true, stash
end

function RDStash.resolveId(src, stashId)
    local stash = RDStash.find(stashId)
    if not stash then return tostring(stashId or 'default'), nil end
    local isPersonal = stash.personal == true or stash.type == 'personal' or stash.owner == true
    if isPersonal then
        local identifier = RDUtils.identifier(src):gsub('[^%w_:%-%.]', '_')
        return ('%s:%s'):format(stash.id, identifier), stash
    end
    return stash.id, stash
end

function RDStash.save(stashId)
    if not stashId or not RDInv or not RDInv.stashes or not RDInv.stashes[stashId] then return end
    if RDMySQL and RDMySQL.save then
        RDMySQL.save('stash:' .. tostring(stashId), RDInv.stashes[stashId])
    end
end
