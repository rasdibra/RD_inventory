
local function rdInteractionMode()
    local c = (RDConfig and (RDConfig.interaction or RDConfig.Interaction)) or (RD and RD.Interaction) or {}
    local mode = c.mode or c.system or 'ox_target'
    if mode == 'target' then
        if c.qb_target == true or (c.target and c.target.system == 'qb-target') then return 'qb-target' end
        return 'ox_target'
    end
    return mode
end
local function rdUseOxTarget() return rdInteractionMode() == 'ox_target' and GetResourceState('ox_target') == 'started' end
local function rdUseQbTarget() return rdInteractionMode() == 'qb-target' and GetResourceState('qb-target') == 'started' end
local function rdUseTextUI()
    local c = (RDConfig and (RDConfig.interaction or RDConfig.Interaction)) or (RD and RD.Interaction) or {}
    return rdInteractionMode() == 'textui' or c.textui == true or (type(c.textui) == 'table' and c.textui.enabled == true)
end

RDStashesClient = RDStashesClient or {}
RDStashesClient.peds = {}
RDStashesClient.zones = {}
RDStashesClient.list = {}

local function notify(msg, ntype)
    if RDUtils and RDUtils.notify then
        RDUtils.notify(msg, ntype or 'info')
    elseif RD and RD.Debug then
        print('[RD_inventory] ' .. tostring(msg))
    end
end

local function vec3from(v)
    if not v then return nil end
    if type(v) == 'vector3' then return v end
    if type(v) == 'vector4' then return vec3(v.x, v.y, v.z) end
    if type(v) == 'table' and v.x and v.y and v.z then return vec3(v.x + 0.0, v.y + 0.0, v.z + 0.0) end
    return nil
end

local function headingFrom(v, default)
    if type(v) == 'vector4' or (type(v) == 'table' and v.w) then return v.w + 0.0 end
    return default or 0.0
end

local function buildList()
    local raw = RDStashes or (RD and RD.Stashes) or {}
    local out = {}
    for key, stash in pairs(raw) do
        if type(stash) == 'table' then
            local coords = vec3from(stash.coords or stash.location)
            if coords then
                out[#out + 1] = {
                    id = tostring(stash.id or key),
                    label = stash.label or tostring(key),
                    type = stash.type or (stash.personal and 'personal' or stash.gangs and 'gang' or stash.jobs and 'job' or 'public'),
                    coords = coords,
                    heading = headingFrom(stash.coords or stash.location, stash.heading or 0.0),
                    radius = stash.radius or 2.0,
                    jobs = stash.jobs,
                    gangs = stash.gangs,
                    personal = stash.personal,
                    marker = stash.marker,
                    ped = stash.ped
                }
            end
        end
    end
    table.sort(out, function(a, b) return a.id < b.id end)
    RDStashesClient.list = out
    return out
end

local function getList()
    if not RDStashesClient.list or #RDStashesClient.list == 0 then return buildList() end
    return RDStashesClient.list
end

local function getPlayerData()
    local data = nil
    pcall(function()
        if GetResourceState('es_extended') == 'started' then
            local ESX = exports['es_extended']:getSharedObject()
            data = ESX and ESX.GetPlayerData and ESX.GetPlayerData() or data
        end
    end)
    pcall(function()
        if GetResourceState('qb-core') == 'started' then
            local QBCore = exports['qb-core']:GetCoreObject()
            data = QBCore and QBCore.Functions and QBCore.Functions.GetPlayerData and QBCore.Functions.GetPlayerData() or data
        end
    end)
    pcall(function()
        if GetResourceState('qbx_core') == 'started' then
            data = exports.qbx_core:GetPlayerData() or data
        end
    end)
    return data or {}
end

local function groupAllowed(groups, obj)
    if not groups then return true end
    local name = obj and obj.name
    local grade = obj and (obj.grade_level or (type(obj.grade) == 'table' and obj.grade.level) or obj.grade or 0) or 0
    local min = name and groups[name]
    if min == nil then return false end
    return tonumber(grade or 0) >= tonumber(min or 0)
end

local function canUseStash(stash)
    local data = getPlayerData()
    if stash.jobs and not groupAllowed(stash.jobs, data.job) then return false end
    if stash.gangs then
        local gangObj = data.gang or data.job
        if not groupAllowed(stash.gangs, gangObj) then return false end
    end
    return true
end

local function loadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(hash) then
        if RD and RD.Debug then print('[RD_inventory] Invalid stash ped model:', tostring(model)) end
        hash = joaat('a_m_m_business_01')
    end
    RequestModel(hash)
    local timeout = GetGameTimer() + 8000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(10) end
    if not HasModelLoaded(hash) then return nil end
    return hash
end

local function openStash(stash)
    if not canUseStash(stash) then
        notify('You do not have access to this stash', 'error')
        return
    end
    TriggerEvent('rd_inventory:client:openStash', stash.id, stash.label or 'STASH')
end

local function addOxTargetToPed(ped, stash)
    if not rdUseOxTarget() then return false end
    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'rd_inventory_stash_ped_' .. stash.id,
            icon = 'fa-solid fa-box-open',
            label = 'Open ' .. stash.label,
            distance = 2.5,
            canInteract = function() return canUseStash(stash) end,
            onSelect = function() openStash(stash) end
        }
    })
    return true
end

local function addQbTargetToPed(ped, stash)
    if not rdUseQbTarget() then return false end
    exports['qb-target']:AddTargetEntity(ped, {
        options = {
            {
                icon = 'fas fa-box-open',
                label = 'Open ' .. stash.label,
                canInteract = function() return canUseStash(stash) end,
                action = function() openStash(stash) end
            }
        },
        distance = 2.5
    })
    return true
end

local function addOxTargetZone(stash)
    if not rdUseOxTarget() then return false end
    local zoneId = exports.ox_target:addSphereZone({
        coords = stash.coords,
        radius = stash.radius or 2.0,
        debug = false,
        options = {
            {
                name = 'rd_inventory_stash_zone_' .. stash.id,
                icon = 'fa-solid fa-box-open',
                label = 'Open ' .. stash.label,
                distance = 2.5,
                canInteract = function() return canUseStash(stash) end,
                onSelect = function() openStash(stash) end
            }
        }
    })
    RDStashesClient.zones[stash.id] = zoneId
    return true
end

local function spawnPed(stash)
    if stash.ped == false or (type(stash.ped) == 'table' and stash.ped.enabled == false) then return false end
    local pedCfg = type(stash.ped) == 'table' and stash.ped or {}
    local hash = loadModel(pedCfg.model or 'a_m_m_business_01')
    if not hash then return false end
    local coords = vec3from(pedCfg.coords) or stash.coords
    local h = headingFrom(pedCfg.coords, pedCfg.heading or stash.heading or 0.0)
    local ped = CreatePed(4, hash, coords.x, coords.y, coords.z - 1.0, h, false, true)
    if not DoesEntityExist(ped) then return false end
    SetEntityAsMissionEntity(ped, true, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    if pedCfg.scenario then TaskStartScenarioInPlace(ped, pedCfg.scenario, 0, true) end
    RDStashesClient.peds[stash.id] = ped
    if not addOxTargetToPed(ped, stash) then addQbTargetToPed(ped, stash) end
    SetModelAsNoLongerNeeded(hash)
    return true
end

function RDStashesClient.init()
    for _, stash in ipairs(getList()) do
        local hasPed = spawnPed(stash)
        if not hasPed then addOxTargetZone(stash) end
    end
end

CreateThread(function()
    Wait(2500)
    RDStashesClient.init()
end)

CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        for _, stash in ipairs(getList()) do
            if rdUseTextUI() and stash.coords then
                local dist = #(coords - stash.coords)
                if dist <= 12.0 then
                    sleep = 0
                    DrawMarker(2, stash.coords.x, stash.coords.y, stash.coords.z + 0.15, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25, 0.25, 0.25, 255, 35, 35, 180, false, true, 2, false, nil, nil, false)
                    if dist <= (stash.radius or 2.0) then
                        BeginTextCommandDisplayHelp('STRING')
                        AddTextComponentSubstringPlayerName(('Press ~INPUT_CONTEXT~ to open %s'):format(stash.label or 'stash'))
                        EndTextCommandDisplayHelp(0, false, true, 1)
                        if IsControlJustReleased(0, 38) then openStash(stash) end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)
