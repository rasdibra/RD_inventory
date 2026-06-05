
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

RDRobbery = RDRobbery or {}
RDRobbery.npcCooldowns = RDRobbery.npcCooldowns or {}
RDRobbery.hostagePed = nil
RDRobbery.followPed = nil
RDRobbery.surrenderPed = nil

local function cfg()
    return (RDConfig and RDConfig.robbery) or {}
end

local function notify(msg, typ)
    if RDUtils and RDUtils.notify then RDUtils.notify(msg, typ or 'info') end
end


local lastDispatch = {}
local function dispatchCfg()
    return (cfg().dispatch) or {}
end

local function sendDispatch(kind, ped)
    local d = dispatchCfg()
    if d.enabled == false or d.system == 'none' then return end
    if d.events and d.events[kind] == false then return end
    local now = GetGameTimer()
    if lastDispatch[kind] and now - lastDispatch[kind] < (d.cooldown or 60000) then return end
    lastDispatch[kind] = now

    local coords = GetEntityCoords(ped or PlayerPedId())
    local alert = (d.alerts and d.alerts[kind]) or {}
    local payload = {
        type = kind,
        title = alert.title or 'Robbery Alert',
        message = alert.message or 'Suspicious robbery activity reported',
        code = alert.code or '10-31',
        coords = { x = coords.x, y = coords.y, z = coords.z },
        sprite = alert.sprite or 156,
        colour = alert.colour or 1,
        scale = alert.scale or 1.0,
        time = alert.time or 60,
        jobs = d.policeJobs or { 'police' }
    }

    local system = tostring(d.system or 'rd_mdt'):lower()

    -- Custom dispatch: put your own event/export in config only.
    if system == 'custom_event' then
        if d.custom and d.custom.clientEvent and d.custom.clientEvent ~= '' then TriggerEvent(d.custom.clientEvent, payload) end
        if d.custom and d.custom.serverEvent and d.custom.serverEvent ~= '' then TriggerServerEvent(d.custom.serverEvent, payload) end
        if d.custom and d.custom.exportResource ~= '' and d.custom.exportName ~= '' and GetResourceState(d.custom.exportResource) == 'started' then
            pcall(function() exports[d.custom.exportResource][d.custom.exportName](payload) end)
        end
        return
    end

    if system == 'ps-dispatch' and GetResourceState('ps-dispatch') == 'started' then
        pcall(function() exports['ps-dispatch']:CustomAlert({ coords = coords, message = payload.message, dispatchCode = payload.code, description = payload.title, radius = 0, sprite = payload.sprite, color = payload.colour, scale = payload.scale, length = payload.time, recipientList = payload.jobs }) end)
        return
    end

    if system == 'cd_dispatch' and GetResourceState('cd_dispatch') == 'started' then
        TriggerServerEvent('cd_dispatch:AddNotification', { job_table = payload.jobs, coords = coords, title = payload.code .. ' - ' .. payload.title, message = payload.message, flash = 0, unique_id = tostring(math.random(0000000,9999999)), sound = 1, blip = { sprite = payload.sprite, scale = payload.scale, colour = payload.colour, flashes = false, text = payload.title, time = payload.time, radius = 0 } })
        return
    end

    if system == 'qs-dispatch' and GetResourceState('qs-dispatch') == 'started' then
        TriggerServerEvent('qs-dispatch:server:CreateDispatchCall', { job = payload.jobs, callLocation = coords, callCode = { code = payload.code, snippet = payload.title }, message = payload.message, flashes = false, image = nil, blip = { sprite = payload.sprite, scale = payload.scale, colour = payload.colour, flashes = false, text = payload.title, time = payload.time } })
        return
    end

    if system == 'core_dispatch' and GetResourceState('core_dispatch') == 'started' then
        TriggerServerEvent('core_dispatch:addCall', payload.code, payload.title, { { icon = 'fa-solid fa-mask', info = payload.message } }, coords, payload.jobs, payload.time, payload.sprite, payload.colour)
        return
    end

    -- RD MDT / RD NDT fallback. Works if your MDT listens to any of these events.
    TriggerServerEvent('rd_inventory:robbery:dispatchAlert', payload)
end

local function isArmed(ped)
    local c = cfg()
    if not c.npc or c.npc.requireWeapon == false then return true end
    return IsPedArmed(ped, 4) or IsPedArmed(ped, 2)
end

local function getClosestPlayer(maxDist)
    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    local closest, closestDist = nil, maxDist or 2.5
    for _, player in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(player)
        if ped ~= myPed and DoesEntityExist(ped) then
            local dist = #(myCoords - GetEntityCoords(ped))
            if dist <= closestDist then
                closest, closestDist = GetPlayerServerId(player), dist
            end
        end
    end
    return closest, closestDist
end

local function getAimedPed()
    local aiming, entity = GetEntityPlayerIsFreeAimingAt(PlayerId())
    if aiming and entity and entity ~= 0 and DoesEntityExist(entity) and IsEntityAPed(entity) then return entity end
end

local function getPlayerServerIdFromPed(ped)
    if not ped or ped == 0 or not IsPedAPlayer(ped) then return nil end
    local idx = NetworkGetPlayerIndexFromPed(ped)
    if idx and idx ~= -1 then return GetPlayerServerId(idx) end
end

local function ignoredNPC(ped)
    local ignore = cfg().npc and cfg().npc.ignoreModels or {}
    return ignore[GetEntityModel(ped)] == true
end


local function animCfg()
    return (cfg().animations) or {}
end

local function requestAnimDict(dict, timeout)
    if not dict or dict == '' then return false end
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local endAt = GetGameTimer() + (timeout or 1500)
    while not HasAnimDictLoaded(dict) and GetGameTimer() < endAt do Wait(10) end
    return HasAnimDictLoaded(dict)
end

local function requestClipSet(clipset, timeout)
    if not clipset or clipset == '' then return false end
    if HasClipSetLoaded(clipset) then return true end
    RequestClipSet(clipset)
    local endAt = GetGameTimer() + (timeout or 1500)
    while not HasClipSetLoaded(clipset) and GetGameTimer() < endAt do Wait(10) end
    return HasClipSetLoaded(clipset)
end

local function playPedAnim(ped, dict, anim, duration, flag)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return false end
    if not requestAnimDict(dict) then return false end
    TaskPlayAnim(ped, dict, anim, 3.0, 3.0, duration or -1, flag or 49, 0.0, false, false, false)
    return true
end

local function setPedMoveStyle(ped, clipset)
    if not ped or ped == 0 or not DoesEntityExist(ped) or not clipset or clipset == '' then return end
    if requestClipSet(clipset) then SetPedMovementClipset(ped, clipset, 0.25) end
end

local function clearPedMoveStyle(ped)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end
    ResetPedMovementClipset(ped, 0.25)
    ResetPedStrafeClipset(ped)
end

local function faceEntity(ped, target)
    if ped and target and DoesEntityExist(ped) and DoesEntityExist(target) then
        TaskTurnPedToFaceEntity(ped, target, 600)
    end
end

local function stableNPCControl(ped)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedKeepTask(ped, true)
    SetPedCanRagdoll(ped, false)
    SetPedDropsWeaponsWhenDead(ped, false)
    SetPedFleeAttributes(ped, 0, false)
    SetPedFleeAttributes(ped, 512, true)
    SetPedCombatAttributes(ped, 17, true)
    SetPedCombatAttributes(ped, 46, true)
    SetPedCombatAbility(ped, 0)
    SetPedCombatMovement(ped, 0)
    SetPedCombatRange(ped, 0)
    SetPedAlertness(ped, 0)
end

local function lockPedForRobbery(ped)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return false end
    if IsPedAPlayer(ped) or IsPedDeadOrDying(ped, true) then return false end

    ClearPedTasksImmediately(ped)
    ClearPedSecondaryTask(ped)
    stableNPCControl(ped)
    SetPedSeeingRange(ped, 0.0)
    SetPedHearingRange(ped, 0.0)
    SetPedConfigFlag(ped, 17, true)
    SetPedConfigFlag(ped, 208, true)
    FreezeEntityPosition(ped, true)
    faceEntity(ped, PlayerPedId())

    local a = animCfg()
    if a.enabled ~= false and a.useNativeHandsUp ~= false then
        TaskHandsUp(ped, (cfg().npc and cfg().npc.handsUpTime) or 90000, PlayerPedId(), -1, true)
    elseif a.enabled ~= false then
        playPedAnim(ped, a.surrenderDict or 'random@mugging3', a.surrenderAnim or 'handsup_standing_base', -1, 49)
    else
        TaskHandsUp(ped, (cfg().npc and cfg().npc.handsUpTime) or 90000, PlayerPedId(), -1, true)
    end

    RDRobbery.surrenderPed = ped
    return true
end

local function unlockRobberyPed(ped, flee)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end
    FreezeEntityPosition(ped, false)
    clearPedMoveStyle(ped)
    SetPedCanRagdoll(ped, true)
    SetPedKeepTask(ped, false)
    SetBlockingOfNonTemporaryEvents(ped, false)
    SetPedFleeAttributes(ped, 0, true)
    SetPedCombatAttributes(ped, 17, false)
    SetPedCombatAttributes(ped, 46, false)
    SetPedSeeingRange(ped, 50.0)
    SetPedHearingRange(ped, 50.0)
    ClearPedTasks(ped)
    ClearPedSecondaryTask(ped)
    if flee then TaskSmartFleePed(ped, PlayerPedId(), 80.0, -1, false, false) end
end

local function unfreezeForMenuAction(ped)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end
    SetEntityAsMissionEntity(ped, true, true)
    FreezeEntityPosition(ped, false)
    stableNPCControl(ped)
    SetPedCanRagdoll(ped, false)
    SetPedSeeingRange(ped, 50.0)
    SetPedHearingRange(ped, 50.0)
    SetPedConfigFlag(ped, 17, false)
    SetPedConfigFlag(ped, 208, false)
    ClearPedTasksImmediately(ped)
    ClearPedSecondaryTask(ped)
end

local function commandFollowPed(ped)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end
    local a = animCfg()
    unfreezeForMenuAction(ped)
    if a.enabled ~= false then setPedMoveStyle(ped, a.followMoveClipset or 'move_m@prisoner_cuffed') end
    TaskFollowToOffsetOfEntity(ped, PlayerPedId(), 0.0, -1.45, 0.0, a.followSpeed or 1.25, -1, a.followStopDistance or 1.8, true)
    SetPedKeepTask(ped, true)
end

local function commandHostagePed(ped)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end
    local a = animCfg()
    unfreezeForMenuAction(ped)
    if a.enabled ~= false then setPedMoveStyle(ped, a.hostageMoveClipset or 'move_m@prisoner_cuffed') end
    TaskFollowToOffsetOfEntity(ped, PlayerPedId(), 0.0, 0.85, 0.0, 1.1, -1, a.hostageStopDistance or 0.95, true)
    SetPedKeepTask(ped, true)
end

local function handsUpPed(ped)
    return lockPedForRobbery(ped)
end

local robberyTargetAdded = false

local function canRobPlayerEntity(entity)
    if not entity or entity == 0 or entity == PlayerPedId() or not IsPedAPlayer(entity) then return false end
    local c = cfg()
    local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(entity))
    if dist > ((c.deadBody and c.deadBody.distance) or 2.0) + 0.25 then return false end
    if c.deadBody and c.deadBody.allowOnlyWhenTargetDead == false then return true end
    return IsEntityDead(entity) or IsPedDeadOrDying(entity, true) or GetEntityHealth(entity) <= 101
end

local function robPlayerBody(entity)
    local serverId = getPlayerServerIdFromPed(entity)
    if not serverId then return notify('No dead/downed player nearby', 'error') end
    sendDispatch('deadBodyRobbery', PlayerPedId())
    TriggerServerEvent('rd_inventory:robbery:tryOpenPlayer', serverId)
end

local function robNpcNow(ped)
    if not ped or ped == 0 or IsPedAPlayer(ped) then return notify('No NPC nearby', 'error') end
    handsUpPed(ped)
    sendDispatch('npcRobbery', ped)
    local a = animCfg()
    faceEntity(PlayerPedId(), ped)
    if a.enabled ~= false then playPedAnim(PlayerPedId(), a.playerRobDict or 'amb@prop_human_bum_bin@base', a.playerRobAnim or 'base', a.playerRobTime or 2500, 49) end
    Wait((a.playerRobTime or 2500))
    TriggerServerEvent('rd_inventory:robbery:npcReward', NetworkGetNetworkIdFromEntity(ped))
    FreezeEntityPosition(ped, false)
    if a.enabled ~= false then
        playPedAnim(ped, a.robbedDict or 'random@arrests', a.robbedAnim or 'kneeling_arrest_idle', a.robbedTime or 2500, 49)
        Wait(a.robbedTime or 2500)
    end
    unlockRobberyPed(ped, true)
end

local function ensureRobberyTargets()
    local c = cfg()
    local t = c.target or c.oxTarget or {}
    if robberyTargetAdded or t.enabled == false then return end

    if rdUseOxTarget() then
        robberyTargetAdded = true
        exports.ox_target:addGlobalPlayer({
            {
                name = 'rd_inventory_rob_dead_body',
                icon = (c.deadBody and c.deadBody.icon) or 'fa-solid fa-hand-holding',
                label = (c.deadBody and c.deadBody.label) or 'Search / Rob Body',
                distance = (c.deadBody and c.deadBody.distance) or 2.0,
                canInteract = function(entity) return canRobPlayerEntity(entity) end,
                onSelect = function(data) robPlayerBody(data.entity) end
            }
        })
        exports.ox_target:addGlobalPed({
            {
                name = 'rd_inventory_rob_npc',
                icon = t.icon or 'fa-solid fa-mask',
                label = t.robNpcLabel or 'Rob NPC',
                distance = t.distance or 2.5,
                canInteract = function(entity)
                    if not entity or entity == 0 or IsPedAPlayer(entity) or IsPedDeadOrDying(entity, true) or ignoredNPC(entity) then return false end
                    if t.onlySurrenderedNPC == false then return true end
                    return RDRobbery.surrenderPed == entity or RDRobbery.hostagePed == entity or RDRobbery.followPed == entity
                end,
                onSelect = function(data) robNpcNow(data.entity) end
            },
            {
                name = 'rd_inventory_npc_follow',
                icon = 'fa-solid fa-person-walking-arrow-right',
                label = 'Make NPC Follow',
                distance = t.distance or 2.5,
                canInteract = function(entity) return entity and entity ~= 0 and not IsPedAPlayer(entity) and RDRobbery.surrenderPed == entity end,
                onSelect = function(data) commandFollowPed(data.entity); RDRobbery.followPed = data.entity; RDRobbery.hostagePed = nil; RDRobbery.surrenderPed = data.entity; notify('NPC is following you', 'success') end
            },
            {
                name = 'rd_inventory_npc_hostage',
                icon = 'fa-solid fa-user-lock',
                label = 'Take Hostage',
                distance = t.distance or 2.5,
                canInteract = function(entity) return entity and entity ~= 0 and not IsPedAPlayer(entity) and RDRobbery.surrenderPed == entity end,
                onSelect = function(data) commandHostagePed(data.entity); RDRobbery.hostagePed = data.entity; RDRobbery.followPed = nil; RDRobbery.surrenderPed = data.entity; sendDispatch('hostage', data.entity); notify('Hostage mode started', 'success') end
            },
            {
                name = 'rd_inventory_npc_release',
                icon = 'fa-solid fa-person-walking-dashed-line-arrow-right',
                label = 'Release NPC',
                distance = t.distance or 2.5,
                canInteract = function(entity) return entity and entity ~= 0 and (RDRobbery.hostagePed == entity or RDRobbery.followPed == entity or RDRobbery.surrenderPed == entity) end,
                onSelect = function() RDRobbery.releaseNPC() end
            }
        })
        return
    end

    if rdUseQbTarget() then
        robberyTargetAdded = true
        exports['qb-target']:AddGlobalPlayer({
            options = {{
                icon = (c.deadBody and c.deadBody.icon) or 'fas fa-hand-holding',
                label = (c.deadBody and c.deadBody.label) or 'Search / Rob Body',
                canInteract = function(entity) return canRobPlayerEntity(entity) end,
                action = function(entity) robPlayerBody(entity) end
            }},
            distance = (c.deadBody and c.deadBody.distance) or 2.0
        })
        exports['qb-target']:AddGlobalPed({
            options = {
                { icon = t.icon or 'fas fa-mask', label = t.robNpcLabel or 'Rob NPC', canInteract = function(entity) return entity and entity ~= 0 and not IsPedAPlayer(entity) and not IsPedDeadOrDying(entity, true) and not ignoredNPC(entity) and (t.onlySurrenderedNPC == false or RDRobbery.surrenderPed == entity or RDRobbery.hostagePed == entity or RDRobbery.followPed == entity) end, action = function(entity) robNpcNow(entity) end },
                { icon = 'fas fa-person-walking-arrow-right', label = 'Make NPC Follow', canInteract = function(entity) return entity and entity ~= 0 and not IsPedAPlayer(entity) and RDRobbery.surrenderPed == entity end, action = function(entity) commandFollowPed(entity); RDRobbery.followPed = entity; RDRobbery.hostagePed = nil; RDRobbery.surrenderPed = entity; notify('NPC is following you', 'success') end },
                { icon = 'fas fa-user-lock', label = 'Take Hostage', canInteract = function(entity) return entity and entity ~= 0 and not IsPedAPlayer(entity) and RDRobbery.surrenderPed == entity end, action = function(entity) commandHostagePed(entity); RDRobbery.hostagePed = entity; RDRobbery.followPed = nil; RDRobbery.surrenderPed = entity; sendDispatch('hostage', entity); notify('Hostage mode started', 'success') end },
                { icon = 'fas fa-person-walking-dashed-line-arrow-right', label = 'Release NPC', canInteract = function(entity) return entity and entity ~= 0 and (RDRobbery.hostagePed == entity or RDRobbery.followPed == entity or RDRobbery.surrenderPed == entity) end, action = function() RDRobbery.releaseNPC() end }
            },
            distance = t.distance or 2.5
        })
    end
end


function RDRobbery.releaseNPC()
    local ped = RDRobbery.hostagePed or RDRobbery.followPed
    if ped and DoesEntityExist(ped) then
        unlockRobberyPed(ped, true)
    end
    if RDRobbery.surrenderPed and DoesEntityExist(RDRobbery.surrenderPed) and RDRobbery.surrenderPed ~= ped then
        unlockRobberyPed(RDRobbery.surrenderPed, true)
    end
    RDRobbery.hostagePed = nil
    RDRobbery.followPed = nil
    RDRobbery.surrenderPed = nil
    notify('NPC released', 'success')
end

function RDRobbery.openMenu(targetPed)
    local c = cfg()
    if c.enabled == false then return end
    targetPed = targetPed or getAimedPed()
    if (not targetPed or targetPed == 0) and RDRobbery.surrenderPed and DoesEntityExist(RDRobbery.surrenderPed) then
        local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(RDRobbery.surrenderPed))
        if dist <= ((c.npc and c.npc.distance) or 8.0) then targetPed = RDRobbery.surrenderPed end
    end
    local playerId = targetPed and getPlayerServerIdFromPed(targetPed) or nil
    if not playerId then playerId = getClosestPlayer((c.menu and c.menu.distance) or 2.5) end

    local options = {
        {
            title = 'Rob / Search',
            description = playerId and ('Open player/body inventory ID ' .. playerId) or 'Closest dead/downed player body',
            icon = 'fa-solid fa-mask',
            onSelect = function()
                local target = playerId or getClosestPlayer((c.deadBody and c.deadBody.distance) or 2.0)
                if not target then return notify('No player nearby', 'error') end
                sendDispatch('deadBodyRobbery', PlayerPedId())
                TriggerServerEvent('rd_inventory:robbery:tryOpenPlayer', target)
            end
        },

        {
            title = 'Rob NPC',
            description = 'Take cash/items from surrendered NPC',
            icon = 'fa-solid fa-hand-holding-dollar',
            disabled = not targetPed or targetPed == 0 or IsPedAPlayer(targetPed),
            onSelect = function()
                local ped = getAimedPed() or RDRobbery.surrenderPed
                if not ped or IsPedAPlayer(ped) then return notify('Aim at an NPC first', 'error') end
                handsUpPed(ped)
                sendDispatch('npcRobbery', ped)
                local a = animCfg()
                faceEntity(PlayerPedId(), ped)
                if a.enabled ~= false then playPedAnim(PlayerPedId(), a.playerRobDict or 'amb@prop_human_bum_bin@base', a.playerRobAnim or 'base', a.playerRobTime or 2500, 49) end
                Wait((a.playerRobTime or 2500))
                TriggerServerEvent('rd_inventory:robbery:npcReward', NetworkGetNetworkIdFromEntity(ped))
                FreezeEntityPosition(ped, false)
                if a.enabled ~= false then
                    playPedAnim(ped, a.robbedDict or 'random@arrests', a.robbedAnim or 'kneeling_arrest_idle', a.robbedTime or 2500, 49)
                    Wait(a.robbedTime or 2500)
                end
                unlockRobberyPed(ped, true)
            end
        },
        {
            title = 'Follow',
            description = 'Make NPC follow you',
            icon = 'fa-solid fa-person-walking-arrow-right',
            disabled = not targetPed or targetPed == 0 or IsPedAPlayer(targetPed),
            onSelect = function()
                local ped = getAimedPed() or RDRobbery.surrenderPed
                if not ped or IsPedAPlayer(ped) then return notify('Aim at an NPC first', 'error') end
                commandFollowPed(ped)
                RDRobbery.followPed = ped
                RDRobbery.hostagePed = nil
                RDRobbery.surrenderPed = ped
                notify('NPC is following you', 'success')
            end
        },
        {
            title = 'Hostage',
            description = 'Hold NPC as hostage / close escort',
            icon = 'fa-solid fa-user-lock',
            disabled = not targetPed or targetPed == 0 or IsPedAPlayer(targetPed),
            onSelect = function()
                local ped = getAimedPed() or RDRobbery.surrenderPed
                if not ped or IsPedAPlayer(ped) then return notify('Aim at an NPC first', 'error') end
                commandHostagePed(ped)
                RDRobbery.hostagePed = ped
                RDRobbery.followPed = nil
                RDRobbery.surrenderPed = ped
                sendDispatch('hostage', ped)
                notify('Hostage mode started. Use /rdreleasehostage to release.', 'success')
            end
        },
        {
            title = 'Release NPC',
            description = 'Release current follow/hostage NPC',
            icon = 'fa-solid fa-person-walking-dashed-line-arrow-right',
            onSelect = function() RDRobbery.releaseNPC() end
        }
    }

    if lib and lib.registerContext then
        lib.registerContext({ id = 'rd_robbery_menu', title = 'RD Robbery', options = options })
        lib.showContext('rd_robbery_menu')
    else
        notify('ox_lib context menu is required', 'error')
    end
end

RegisterNetEvent('rd_inventory:robbery:openPlayerInventory', function(targetId)
    if RDInvClient and RDInvClient.openTargetInventory then RDInvClient.openTargetInventory(targetId, 'Rob Body / Player') end
end)

if cfg().menu and cfg().menu.commandsEnabled == true then
    RegisterCommand((cfg().menu and cfg().menu.command) or 'robmenu', function()
        RDRobbery.openMenu(getAimedPed())
    end, false)
end

if cfg().deadBody and cfg().deadBody.commandsEnabled == true then
    RegisterCommand((cfg().deadBody and cfg().deadBody.command) or 'robdead', function()
        local target = getClosestPlayer((cfg().deadBody and cfg().deadBody.distance) or 2.0)
        if not target then return notify('No dead/downed player nearby', 'error') end
        sendDispatch('deadBodyRobbery', PlayerPedId())
        TriggerServerEvent('rd_inventory:robbery:tryOpenPlayer', target)
    end, false)
end

if cfg().hostage and cfg().hostage.commandsEnabled == true then
    RegisterCommand((cfg().hostage and cfg().hostage.releaseCommand) or 'rdreleasehostage', function()
        RDRobbery.releaseNPC()
    end, false)
end

CreateThread(function()
    Wait(1500)
    ensureRobberyTargets()
end)

CreateThread(function()
    while true do
        Wait(300)
        local c = cfg()
        if c.enabled ~= false and c.npc and c.npc.enabled ~= false then
            local myPed = PlayerPedId()
            local ped = getAimedPed()
            if isArmed(myPed) and ped and not IsPedAPlayer(ped) and not IsPedDeadOrDying(ped, true) and not ignoredNPC(ped)
                and ped ~= RDRobbery.followPed and ped ~= RDRobbery.hostagePed then
                local dist = #(GetEntityCoords(myPed) - GetEntityCoords(ped))
                if dist <= (c.npc.distance or 8.0) then
                    if handsUpPed(ped) then
                        -- keep it frozen while aiming; H can open menu even if you stop aiming for a moment
                    end
                    local netId = NetworkGetNetworkIdFromEntity(ped)
                    local last = RDRobbery.npcCooldowns[netId] or 0
                    if GetGameTimer() - last > (c.npc.cooldown or 120000) then
                        RDRobbery.npcCooldowns[netId] = GetGameTimer()
                        notify('NPC surrendered. Use target eye for Rob / Follow / Hostage.', 'info')
                    end
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        local a = animCfg()
        Wait(a.retaskEveryMs or 1300)
        local myPed = PlayerPedId()
        if RDRobbery.hostagePed and DoesEntityExist(RDRobbery.hostagePed) then
            FreezeEntityPosition(RDRobbery.hostagePed, false)
            stableNPCControl(RDRobbery.hostagePed)
            local dist = #(GetEntityCoords(myPed) - GetEntityCoords(RDRobbery.hostagePed))
            if dist > (a.hostageStopDistance or 0.95) + 0.45 or IsPedStill(RDRobbery.hostagePed) then
                commandHostagePed(RDRobbery.hostagePed)
            end
        end
        if RDRobbery.followPed and DoesEntityExist(RDRobbery.followPed) then
            FreezeEntityPosition(RDRobbery.followPed, false)
            stableNPCControl(RDRobbery.followPed)
            local dist = #(GetEntityCoords(myPed) - GetEntityCoords(RDRobbery.followPed))
            if dist > (a.followSprintDistance or 9.0) then
                TaskFollowToOffsetOfEntity(RDRobbery.followPed, myPed, 0.0, -1.45, 0.0, 2.2, -1, a.followStopDistance or 1.8, true)
            elseif dist > (a.followStopDistance or 1.8) + 0.75 or IsPedStill(RDRobbery.followPed) then
                commandFollowPed(RDRobbery.followPed)
            end
        end
    end
end)

RegisterNetEvent('rd_inventory:robbery:clientDispatchFallback', function(payload)
    local d = dispatchCfg()
    if d.enabled == false then return end
    local system = tostring(d.system or 'rd_mdt'):lower()
    if system ~= 'rd_mdt' and system ~= 'rd_ndt' and system ~= 'rdmdt' and system ~= 'rdndt' then return end
    payload = payload or {}
    local coords = payload.coords or {}
    if not coords.x then return end
    notify((payload.code or '10-31') .. ' - ' .. (payload.title or 'Robbery Alert'), 'warning')
    local blip = AddBlipForCoord(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
    SetBlipSprite(blip, payload.sprite or 156)
    SetBlipColour(blip, payload.colour or 1)
    SetBlipScale(blip, payload.scale or 1.0)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(payload.title or 'Robbery Alert')
    EndTextCommandSetBlipName(blip)
    SetTimeout((payload.time or 60) * 1000, function()
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end)
end)
