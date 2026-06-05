RDInvClient = RDInvClient or {}
RDInvClient.open = false
RDInvClient.items = {}
RDInvClient.currentOther = nil
RDInvClient.currentVehicleDoor = nil
RDInvClient.trunkPromptVisible = false
RDInvClient.busy = false
RDInvClient.lastToggle = 0
RDInvClient.lastOpen = 0
RDInvClient.lastClose = 0
RDInvClient.lastTrunkLockNotify = 0
RDInvClient.drops = {}
RDInvClient.dropProps = RDInvClient.dropProps or {}
RDInvClient.dropPropModel = (RDConfig and RDConfig.drops and joaat(RDConfig.drops.prop)) or `prop_cs_heist_bag_02`

local function rdLoadModel(model)
    if type(model) == 'string' then model = joaat(model) end
    if not IsModelInCdimage(model) then return nil end
    RequestModel(model)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do Wait(0) end
    if not HasModelLoaded(model) and fallbackModel then
        model = joaat(fallbackModel)
        RequestModel(model)
        timeout = GetGameTimer() + 5000
        while not HasModelLoaded(model) and GetGameTimer() < timeout do Wait(0) end
    end
    if not HasModelLoaded(model) then return nil end
    return model
end

local function rdDeleteDropProp(dropId)
    local obj = RDInvClient.dropProps and RDInvClient.dropProps[dropId]
    if obj and DoesEntityExist(obj) then
        DeleteEntity(obj)
    end
    if RDInvClient.dropProps then RDInvClient.dropProps[dropId] = nil end
end

local function rdSyncDropProps(drops)
    drops = drops or {}

    for dropId, obj in pairs(RDInvClient.dropProps or {}) do
        if not drops[dropId] then rdDeleteDropProp(dropId) end
    end

    for dropId, drop in pairs(drops) do
        if drop.coords and not RDInvClient.dropProps[dropId] then
            local model = rdLoadModel(drop.prop or RDInvClient.dropPropModel)
            if model then
                local x, y, z = drop.coords.x + 0.0, drop.coords.y + 0.0, drop.coords.z + 0.0
                local obj = CreateObject(model, x, y, z - 0.95, false, false, false)
                if obj and obj ~= 0 then
                    SetEntityAsMissionEntity(obj, true, true)
                    PlaceObjectOnGroundProperly(obj)
                    FreezeEntityPosition(obj, true)
                    SetEntityCollision(obj, true, true)
                    RDInvClient.dropProps[dropId] = obj
                end
                SetModelAsNoLongerNeeded(model)
            end
        end
    end
end

local function formatItems(inv, defs)
    local out = {}
    for _, it in ipairs(inv.items or {}) do
        local def = defs[it.name] or {}
        out[#out + 1] = {
            slot = it.slot,
            name = it.name,
            label = def.label or it.name,
            count = it.count or 1,
            weight = def.weight or 0,
            image = def.image or (it.name .. '.png'),
            description = def.description or '',
            type = def.type,
            metadata = it.metadata or {}
        }
    end
    return out
end

local function plateFromVehicle(veh)
    if veh and veh ~= 0 then return string.gsub(GetVehicleNumberPlateText(veh), "%s+", "") end
    return nil
end

local function getNearestVehicle()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)

    -- IMPORTANT:
    -- TAB inventory must NOT auto-open trunk just because a vehicle is close.
    -- Ox style: normal TAB = player + nearby drops. Vehicle storage opens only when you are IN the vehicle
    -- for glovebox, or when a trunk/glovebox event/target calls openVehicleInventory().
    if veh ~= 0 then return veh, true end

    return 0, false
end

local function rdGetClosestVehicleForTrunk()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local cfg = (RDConfig and RDConfig.vehicles) or {}
    local searchDistance = (cfg.trunkSearchDistance or cfg.trunkDistance or 4.0) + 0.0
    local rearDistance = (cfg.trunkRearDistance or cfg.trunkDistance or 1.8) + 0.0

    local closest, closestRearDist = 0, 999.0
    local vehicles = GetGamePool and GetGamePool('CVehicle') or {}

    for _, veh in ipairs(vehicles) do
        if DoesEntityExist(veh) then
            local vehCoords = GetEntityCoords(veh)
            if #(coords - vehCoords) <= searchDistance then
                local rear = GetOffsetFromEntityInWorldCoords(veh, 0.0, (cfg.trunkRearOffsetY or -2.65) + 0.0, 0.0)
                local rearDist = #(coords - rear)
                if rearDist <= rearDistance and rearDist < closestRearDist then
                    closest = veh
                    closestRearDist = rearDist
                end
            end
        end
    end

    if closest == 0 then return 0, 999.0 end
    return closest, closestRearDist
end

local function rdIsVehicleLocked(veh)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return true end
    local status = GetVehicleDoorLockStatus(veh)
    -- GTA/FiveM lock statuses: 0/1 unlocked, 2+ locked/restricted.
    return status and status > 1
end

local function rdNotifyTrunkLocked()
    local now = GetGameTimer()
    if (now - (RDInvClient.lastTrunkLockNotify or 0)) > 1200 then
        RDInvClient.lastTrunkLockNotify = now
        RDUtils.notify('Makina eshte lock', 'error')
    end
end

local function rdDrawTrunkHelp()
    if not (RDConfig and RDConfig.vehicles and RDConfig.vehicles.showTrunkPrompt) then return end
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName('Press ~r~K~s~ to open vehicle trunk')
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function rdPlayTrunkAnim()
    if not (RDConfig and RDConfig.vehicles and RDConfig.vehicles.trunkAnim) then return end
    local ped = PlayerPedId()
    RequestAnimDict('mini@repair')
    local timeout = GetGameTimer() + 2000
    while not HasAnimDictLoaded('mini@repair') and GetGameTimer() < timeout do Wait(0) end
    if HasAnimDictLoaded('mini@repair') then
        TaskPlayAnim(ped, 'mini@repair', 'fixing_a_ped', 8.0, -8.0, 900, 49, 0.0, false, false, false)
        Wait(450)
        ClearPedTasks(ped)
    end
end

local function rdOpenVehicleDoorForInventory(veh, invType)
    if not (RDConfig and RDConfig.vehicles and RDConfig.vehicles.openTrunkDoor) then return end
    if not veh or veh == 0 or not DoesEntityExist(veh) then return end
    if invType ~= 'trunk' then return end
    SetVehicleDoorOpen(veh, 5, false, false)
    RDInvClient.currentVehicleDoor = { vehicle = veh, door = 5 }
end

local function rdCloseVehicleDoorForInventory()
    if not (RDConfig and RDConfig.vehicles and RDConfig.vehicles.closeTrunkDoorOnInventoryClose) then return end
    local d = RDInvClient.currentVehicleDoor
    if d and d.vehicle and DoesEntityExist(d.vehicle) then
        SetVehicleDoorShut(d.vehicle, d.door or 5, false)
    end
    RDInvClient.currentVehicleDoor = nil
end





-- RD FULL FIX: disable GTA weapon wheel 100% so keys 1-5 belong only to RD_inventory hotbar.
-- This blocks TAB/weapon wheel every frame, hides the HUD wheel text, and ignores wheel selection.
local RD_BLOCKED_WEAPON_WHEEL_CONTROLS = {
    37,  -- INPUT_SELECT_WEAPON / TAB weapon wheel
    157, -- INPUT_SELECT_WEAPON_UNARMED / 1
    158, -- INPUT_SELECT_WEAPON_MELEE / 2
    160, -- INPUT_SELECT_WEAPON_HANDGUN / 3
    164, -- INPUT_SELECT_WEAPON_SHOTGUN / 4
    165, -- INPUT_SELECT_WEAPON_SMG / 5
    159, -- INPUT_SELECT_WEAPON_SHOTGUN alt
    161, -- INPUT_SELECT_WEAPON_HEAVY
    162, -- INPUT_SELECT_WEAPON_SPECIAL
    163, -- INPUT_SELECT_CHARACTER_MICHAEL
}

CreateThread(function()
    while true do
        Wait(0)

        -- Native block for the wheel itself.
        pcall(function() BlockWeaponWheelThisFrame() end)
        pcall(function() HudWeaponWheelIgnoreSelection() end)
        pcall(function() SetPedCanSwitchWeapon(PlayerPedId(), false) end)

        -- Disable on all common control groups, because some servers/HUDs read group 1/2.
        for _, control in ipairs(RD_BLOCKED_WEAPON_WHEEL_CONTROLS) do
            DisableControlAction(0, control, true)
            DisableControlAction(1, control, true)
            DisableControlAction(2, control, true)
        end

        -- Hide weapon wheel and weapon stats HUD components/text.
        HideHudComponentThisFrame(19)
        HideHudComponentThisFrame(20)
        HideHudComponentThisFrame(22)
    end
end)

local function rdHasExport(resource, exportName)
    return GetResourceState(resource) == 'started'
end

local function rdApplyStatus(status)
    if not status then return end
    for name, value in pairs(status) do
        -- ESX status support
        pcall(function()
            TriggerEvent('esx_status:add', name, value)
        end)
        -- QB/QBX common metadata fallback
        if name == 'hunger' or name == 'thirst' or name == 'stress' then
            pcall(function()
                TriggerServerEvent('rd_inventory:server:addStatus', name, value)
            end)
        end
    end
end



-- RD weapon draw / holster animation system.
local RDPlayerJob = nil
local RDWeaponDrawBusy = false

local function rdRefreshPlayerJob()
    local job = nil
    pcall(function()
        if GetResourceState('es_extended') == 'started' then
            local ESX = exports['es_extended']:getSharedObject()
            local data = ESX and ESX.GetPlayerData and ESX.GetPlayerData()
            job = data and data.job and data.job.name or job
        end
    end)
    pcall(function()
        if GetResourceState('qb-core') == 'started' then
            local QBCore = exports['qb-core']:GetCoreObject()
            local data = QBCore and QBCore.Functions and QBCore.Functions.GetPlayerData and QBCore.Functions.GetPlayerData()
            job = data and data.job and data.job.name or job
        end
    end)
    pcall(function()
        if GetResourceState('qbx_core') == 'started' then
            local data = exports.qbx_core:GetPlayerData()
            job = data and data.job and data.job.name or job
        end
    end)
    RDPlayerJob = job or RDPlayerJob
    return RDPlayerJob
end

CreateThread(function()
    Wait(1500)
    rdRefreshPlayerJob()
end)

RegisterNetEvent('esx:setJob', function(job)
    RDPlayerJob = job and job.name or RDPlayerJob
end)
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    RDPlayerJob = job and job.name or RDPlayerJob
end)
RegisterNetEvent('qbx_core:client:onJobUpdate', function(job)
    RDPlayerJob = job and job.name or RDPlayerJob
end)

local function rdRequestAnimDict(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 3000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do Wait(10) end
    return HasAnimDictLoaded(dict)
end

local function rdIsNormalHolsterJob()
    local cfg = RDConfig and RDConfig.weapons and RDConfig.weapons.holster
    local job = rdRefreshPlayerJob()
    local whitelist = cfg and cfg.whitelistJobs or { police = true, sheriff = true, ambulance = true }
    return job and whitelist[job] == true
end

local function rdPlayWeaponDrawAnim()
    local cfg = RDConfig and RDConfig.weapons and RDConfig.weapons.holster
    if cfg and cfg.enabled == false then return end
    if RDWeaponDrawBusy then return end

    local ped = PlayerPedId()
    if not ped or ped == 0 or IsEntityDead(ped) then return end
    if IsPedInAnyVehicle(ped, false) and not (cfg and cfg.allowInVehicle) then return end

    RDWeaponDrawBusy = true
    local normal = rdIsNormalHolsterJob()
    local anim = normal and (cfg and cfg.normalAnim) or (cfg and cfg.gangsterAnim)
    anim = anim or {}
    local dict = anim.dict or (normal and 'reaction@intimidation@cop@unarmed' or 'reaction@intimidation@1h')
    local clip = anim.clip or 'intro'
    local flag = tonumber(anim.flag or 48) or 48
    local duration = tonumber(anim.duration or (normal and 850 or 1200)) or 1000
    local drawAt = tonumber(anim.drawAt or math.floor(duration * 0.55)) or 600

    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
    if rdRequestAnimDict(dict) then
        TaskPlayAnim(ped, dict, clip, 8.0, -8.0, duration, flag, 0.0, false, false, false)
        Wait(drawAt)
    end
    RDWeaponDrawBusy = false
end

local function rdHolsterCurrentWeapon(showNotify)
    if RDWeaponDrawBusy then return true end
    local ped = PlayerPedId()
    if not ped or ped == 0 or IsEntityDead(ped) then return true end
    local current = GetSelectedPedWeapon(ped)
    if not current or current == `WEAPON_UNARMED` then return true end

    local cfg = RDConfig and RDConfig.weapons
    local holsterCfg = cfg and cfg.holster
    RDWeaponDrawBusy = true

    if not IsPedInAnyVehicle(ped, false) or (holsterCfg and holsterCfg.allowInVehicle) then
        local normal = rdIsNormalHolsterJob()
        local anim = normal and (holsterCfg and holsterCfg.normalAnim) or (holsterCfg and holsterCfg.gangsterAnim)
        anim = anim or {}
        local dict = anim.dict or (normal and 'reaction@intimidation@cop@unarmed' or 'reaction@intimidation@1h')
        local clip = anim.clip or 'outro'
        local duration = tonumber((cfg and cfg.unquipAnimTime) or 650) or 650
        local flag = tonumber(anim.flag or 48) or 48
        if rdRequestAnimDict(dict) then
            TaskPlayAnim(ped, dict, clip, 8.0, -8.0, duration, flag, 0.0, false, false, false)
            Wait(math.floor(duration * 0.55))
        end
    end

    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
    ClearPedTasks(ped)
    RDWeaponDrawBusy = false
    if showNotify ~= false then RDUtils.notify('Weapon holstered', 'success') end
    return true
end

local function rdUseWeaponItem(name, item)
    local ped = PlayerPedId()
    local weaponName = item and (item.weapon or item.hash or item.name) or name
    if type(weaponName) ~= 'string' then weaponName = name end

    local upper = weaponName:upper()
    if not upper:find('WEAPON_') and not upper:find('GADGET_') then
        return false
    end

    local hash = joaat(upper)

    -- Pressing the same hotbar/use weapon again toggles it OFF instead of leaving it stuck in hand.
    if (RDConfig and RDConfig.weapons and RDConfig.weapons.toggleSameHotbarToUnquip) ~= false then
        local current = GetSelectedPedWeapon(ped)
        if current == hash then
            rdHolsterCurrentWeapon(true)
            return true
        end
    end

    rdPlayWeaponDrawAnim()
    ped = PlayerPedId()
    if HasPedGotWeapon(ped, hash, false) then
        SetCurrentPedWeapon(ped, hash, true)
    else
        GiveWeaponToPed(ped, hash, tonumber((RDConfig and RDConfig.weapons and RDConfig.weapons.startAmmo) or 0) or 0, false, true)
        SetPedAmmo(ped, hash, tonumber((RDConfig and RDConfig.weapons and RDConfig.weapons.startAmmo) or 0) or 0)
        SetCurrentPedWeapon(ped, hash, true)
    end
    RDUtils.notify('Equipped: ' .. ((item and item.label) or name), 'success')
    return true
end



local rdProgressBar

-- RD real weapon ammo / reload / attachments system.
local RDWeaponAmmoByWeapon = {
    [joaat('WEAPON_PISTOL')] = 'ammo-9', [joaat('WEAPON_PISTOL_MK2')] = 'ammo-9', [joaat('WEAPON_COMBATPISTOL')] = 'ammo-9', [joaat('WEAPON_APPISTOL')] = 'ammo-9', [joaat('WEAPON_MACHINEPISTOL')] = 'ammo-9',
    [joaat('WEAPON_MICROSMG')] = 'ammo-9', [joaat('WEAPON_SMG')] = 'ammo-9', [joaat('WEAPON_SMG_MK2')] = 'ammo-9', [joaat('WEAPON_ASSAULTSMG')] = 'ammo-9', [joaat('WEAPON_COMBATPDW')] = 'ammo-9', [joaat('WEAPON_MINISMG')] = 'ammo-9',
    [joaat('WEAPON_SNSPISTOL')] = 'ammo-45', [joaat('WEAPON_HEAVYPISTOL')] = 'ammo-45', [joaat('WEAPON_VINTAGEPISTOL')] = 'ammo-45',
    [joaat('WEAPON_PISTOL50')] = 'ammo-50',
    [joaat('WEAPON_ASSAULTRIFLE')] = 'ammo-rifle', [joaat('WEAPON_ASSAULTRIFLE_MK2')] = 'ammo-rifle', [joaat('WEAPON_CARBINERIFLE')] = 'ammo-rifle', [joaat('WEAPON_CARBINERIFLE_MK2')] = 'ammo-rifle', [joaat('WEAPON_ADVANCEDRIFLE')] = 'ammo-rifle', [joaat('WEAPON_SPECIALCARBINE')] = 'ammo-rifle', [joaat('WEAPON_SPECIALCARBINE_MK2')] = 'ammo-rifle', [joaat('WEAPON_BULLPUPRIFLE')] = 'ammo-rifle', [joaat('WEAPON_BULLPUPRIFLE_MK2')] = 'ammo-rifle', [joaat('WEAPON_COMPACTRIFLE')] = 'ammo-rifle', [joaat('WEAPON_MILITARYRIFLE')] = 'ammo-rifle', [joaat('WEAPON_HEAVYRIFLE')] = 'ammo-rifle', [joaat('WEAPON_MG')] = 'ammo-rifle', [joaat('WEAPON_COMBATMG')] = 'ammo-rifle', [joaat('WEAPON_COMBATMG_MK2')] = 'ammo-rifle', [joaat('WEAPON_GUSENBERG')] = 'ammo-rifle', [joaat('WEAPON_SNIPERRIFLE')] = 'ammo-rifle', [joaat('WEAPON_HEAVYSNIPER')] = 'ammo-rifle', [joaat('WEAPON_MARKSMANRIFLE')] = 'ammo-rifle', [joaat('WEAPON_PRECISIONRIFLE')] = 'ammo-rifle',
    [joaat('WEAPON_PUMPSHOTGUN')] = 'ammo-shotgun', [joaat('WEAPON_PUMPSHOTGUN_MK2')] = 'ammo-shotgun', [joaat('WEAPON_SAWNOFFSHOTGUN')] = 'ammo-shotgun', [joaat('WEAPON_ASSAULTSHOTGUN')] = 'ammo-shotgun', [joaat('WEAPON_BULLPUPSHOTGUN')] = 'ammo-shotgun', [joaat('WEAPON_DBSHOTGUN')] = 'ammo-shotgun', [joaat('WEAPON_AUTOSHOTGUN')] = 'ammo-shotgun', [joaat('WEAPON_COMBATSHOTGUN')] = 'ammo-shotgun'
}

local RDWeaponNameByHash = {}
for hash, _ in pairs(RDWeaponAmmoByWeapon) do
    -- filled below for exact weapon names
end
for _, n in ipairs({
    'WEAPON_PISTOL','WEAPON_PISTOL_MK2','WEAPON_COMBATPISTOL','WEAPON_APPISTOL','WEAPON_PISTOL50','WEAPON_SNSPISTOL','WEAPON_HEAVYPISTOL','WEAPON_VINTAGEPISTOL','WEAPON_MACHINEPISTOL','WEAPON_MICROSMG','WEAPON_SMG','WEAPON_SMG_MK2','WEAPON_ASSAULTSMG','WEAPON_COMBATPDW','WEAPON_MINISMG','WEAPON_ASSAULTRIFLE','WEAPON_ASSAULTRIFLE_MK2','WEAPON_CARBINERIFLE','WEAPON_CARBINERIFLE_MK2','WEAPON_ADVANCEDRIFLE','WEAPON_SPECIALCARBINE','WEAPON_SPECIALCARBINE_MK2','WEAPON_BULLPUPRIFLE','WEAPON_BULLPUPRIFLE_MK2','WEAPON_COMPACTRIFLE','WEAPON_MILITARYRIFLE','WEAPON_HEAVYRIFLE','WEAPON_PUMPSHOTGUN','WEAPON_PUMPSHOTGUN_MK2','WEAPON_SAWNOFFSHOTGUN','WEAPON_ASSAULTSHOTGUN','WEAPON_BULLPUPSHOTGUN','WEAPON_DBSHOTGUN','WEAPON_AUTOSHOTGUN','WEAPON_COMBATSHOTGUN','WEAPON_MG','WEAPON_COMBATMG','WEAPON_COMBATMG_MK2','WEAPON_GUSENBERG','WEAPON_SNIPERRIFLE','WEAPON_HEAVYSNIPER','WEAPON_MARKSMANRIFLE','WEAPON_PRECISIONRIFLE'
}) do RDWeaponNameByHash[joaat(n)] = n end

local RDAttachmentComponents = {
    at_flashlight = { WEAPON_PISTOL='COMPONENT_AT_PI_FLSH', WEAPON_PISTOL_MK2='COMPONENT_AT_PI_FLSH_02', WEAPON_COMBATPISTOL='COMPONENT_AT_PI_FLSH', WEAPON_APPISTOL='COMPONENT_AT_PI_FLSH', WEAPON_PISTOL50='COMPONENT_AT_PI_FLSH', WEAPON_HEAVYPISTOL='COMPONENT_AT_PI_FLSH', WEAPON_SNSPISTOL_MK2='COMPONENT_AT_PI_FLSH_03', WEAPON_MICROSMG='COMPONENT_AT_PI_FLSH', WEAPON_SMG='COMPONENT_AT_AR_FLSH', WEAPON_SMG_MK2='COMPONENT_AT_AR_FLSH', WEAPON_ASSAULTRIFLE='COMPONENT_AT_AR_FLSH', WEAPON_ASSAULTRIFLE_MK2='COMPONENT_AT_AR_FLSH', WEAPON_CARBINERIFLE='COMPONENT_AT_AR_FLSH', WEAPON_CARBINERIFLE_MK2='COMPONENT_AT_AR_FLSH', WEAPON_ADVANCEDRIFLE='COMPONENT_AT_AR_FLSH', WEAPON_SPECIALCARBINE='COMPONENT_AT_AR_FLSH', WEAPON_SPECIALCARBINE_MK2='COMPONENT_AT_AR_FLSH', WEAPON_BULLPUPRIFLE='COMPONENT_AT_AR_FLSH', WEAPON_BULLPUPRIFLE_MK2='COMPONENT_AT_AR_FLSH', WEAPON_COMBATPDW='COMPONENT_AT_AR_FLSH', WEAPON_PUMPSHOTGUN='COMPONENT_AT_AR_FLSH', WEAPON_PUMPSHOTGUN_MK2='COMPONENT_AT_AR_FLSH', WEAPON_ASSAULTSHOTGUN='COMPONENT_AT_AR_FLSH', WEAPON_BULLPUPSHOTGUN='COMPONENT_AT_AR_FLSH', WEAPON_COMBATSHOTGUN='COMPONENT_AT_AR_FLSH' },
    at_suppressor_light = { WEAPON_PISTOL='COMPONENT_AT_PI_SUPP_02', WEAPON_COMBATPISTOL='COMPONENT_AT_PI_SUPP', WEAPON_APPISTOL='COMPONENT_AT_PI_SUPP', WEAPON_PISTOL50='COMPONENT_AT_AR_SUPP_02', WEAPON_HEAVYPISTOL='COMPONENT_AT_PI_SUPP', WEAPON_VINTAGEPISTOL='COMPONENT_AT_PI_SUPP', WEAPON_MICROSMG='COMPONENT_AT_AR_SUPP_02', WEAPON_SMG='COMPONENT_AT_PI_SUPP', WEAPON_ASSAULTSMG='COMPONENT_AT_AR_SUPP_02' },
    at_suppressor_heavy = { WEAPON_ASSAULTRIFLE='COMPONENT_AT_AR_SUPP_02', WEAPON_ASSAULTRIFLE_MK2='COMPONENT_AT_AR_SUPP_02', WEAPON_CARBINERIFLE='COMPONENT_AT_AR_SUPP', WEAPON_CARBINERIFLE_MK2='COMPONENT_AT_AR_SUPP', WEAPON_ADVANCEDRIFLE='COMPONENT_AT_AR_SUPP', WEAPON_SPECIALCARBINE='COMPONENT_AT_AR_SUPP_02', WEAPON_SPECIALCARBINE_MK2='COMPONENT_AT_AR_SUPP_02', WEAPON_BULLPUPRIFLE='COMPONENT_AT_AR_SUPP', WEAPON_BULLPUPRIFLE_MK2='COMPONENT_AT_AR_SUPP', WEAPON_COMBATPDW='COMPONENT_AT_AR_SUPP', WEAPON_PUMPSHOTGUN='COMPONENT_AT_SR_SUPP', WEAPON_PUMPSHOTGUN_MK2='COMPONENT_AT_SR_SUPP_03', WEAPON_ASSAULTSHOTGUN='COMPONENT_AT_AR_SUPP', WEAPON_BULLPUPSHOTGUN='COMPONENT_AT_AR_SUPP_02', WEAPON_COMBATSHOTGUN='COMPONENT_AT_AR_SUPP', WEAPON_SNIPERRIFLE='COMPONENT_AT_AR_SUPP_02', WEAPON_MARKSMANRIFLE='COMPONENT_AT_AR_SUPP' },
    at_clip_extended_pistol = { WEAPON_PISTOL='COMPONENT_PISTOL_CLIP_02', WEAPON_PISTOL_MK2='COMPONENT_PISTOL_MK2_CLIP_02', WEAPON_COMBATPISTOL='COMPONENT_COMBATPISTOL_CLIP_02', WEAPON_APPISTOL='COMPONENT_APPISTOL_CLIP_02', WEAPON_PISTOL50='COMPONENT_PISTOL50_CLIP_02', WEAPON_SNSPISTOL='COMPONENT_SNSPISTOL_CLIP_02', WEAPON_HEAVYPISTOL='COMPONENT_HEAVYPISTOL_CLIP_02', WEAPON_VINTAGEPISTOL='COMPONENT_VINTAGEPISTOL_CLIP_02', WEAPON_MACHINEPISTOL='COMPONENT_MACHINEPISTOL_CLIP_02' },
    at_clip_extended_smg = { WEAPON_MICROSMG='COMPONENT_MICROSMG_CLIP_02', WEAPON_SMG='COMPONENT_SMG_CLIP_02', WEAPON_SMG_MK2='COMPONENT_SMG_MK2_CLIP_02', WEAPON_ASSAULTSMG='COMPONENT_ASSAULTSMG_CLIP_02', WEAPON_COMBATPDW='COMPONENT_COMBATPDW_CLIP_02', WEAPON_MINISMG='COMPONENT_MINISMG_CLIP_02' },
    at_clip_extended_rifle = { WEAPON_ASSAULTRIFLE='COMPONENT_ASSAULTRIFLE_CLIP_02', WEAPON_ASSAULTRIFLE_MK2='COMPONENT_ASSAULTRIFLE_MK2_CLIP_02', WEAPON_CARBINERIFLE='COMPONENT_CARBINERIFLE_CLIP_02', WEAPON_CARBINERIFLE_MK2='COMPONENT_CARBINERIFLE_MK2_CLIP_02', WEAPON_ADVANCEDRIFLE='COMPONENT_ADVANCEDRIFLE_CLIP_02', WEAPON_SPECIALCARBINE='COMPONENT_SPECIALCARBINE_CLIP_02', WEAPON_SPECIALCARBINE_MK2='COMPONENT_SPECIALCARBINE_MK2_CLIP_02', WEAPON_BULLPUPRIFLE='COMPONENT_BULLPUPRIFLE_CLIP_02', WEAPON_BULLPUPRIFLE_MK2='COMPONENT_BULLPUPRIFLE_MK2_CLIP_02', WEAPON_COMPACTRIFLE='COMPONENT_COMPACTRIFLE_CLIP_02', WEAPON_MILITARYRIFLE='COMPONENT_MILITARYRIFLE_CLIP_02', WEAPON_HEAVYRIFLE='COMPONENT_HEAVYRIFLE_CLIP_02' },
    at_clip_drum = { WEAPON_ASSAULTRIFLE='COMPONENT_ASSAULTRIFLE_CLIP_03', WEAPON_CARBINERIFLE='COMPONENT_CARBINERIFLE_CLIP_03', WEAPON_SPECIALCARBINE='COMPONENT_SPECIALCARBINE_CLIP_03', WEAPON_COMPACTRIFLE='COMPONENT_COMPACTRIFLE_CLIP_03', WEAPON_SMG='COMPONENT_SMG_CLIP_03', WEAPON_COMBATPDW='COMPONENT_COMBATPDW_CLIP_03', WEAPON_MACHINEPISTOL='COMPONENT_MACHINEPISTOL_CLIP_03' },
    at_scope_small = { WEAPON_MICROSMG='COMPONENT_AT_SCOPE_MACRO', WEAPON_SMG='COMPONENT_AT_SCOPE_MACRO_02', WEAPON_ASSAULTSMG='COMPONENT_AT_SCOPE_MACRO', WEAPON_COMBATPDW='COMPONENT_AT_SCOPE_SMALL', WEAPON_ASSAULTRIFLE='COMPONENT_AT_SCOPE_MACRO', WEAPON_CARBINERIFLE='COMPONENT_AT_SCOPE_MEDIUM', WEAPON_ADVANCEDRIFLE='COMPONENT_AT_SCOPE_SMALL', WEAPON_SPECIALCARBINE='COMPONENT_AT_SCOPE_MEDIUM', WEAPON_BULLPUPRIFLE='COMPONENT_AT_SCOPE_SMALL', WEAPON_MG='COMPONENT_AT_SCOPE_SMALL_02' },
    at_scope_medium = { WEAPON_SMG_MK2='COMPONENT_AT_SCOPE_SMALL_SMG_MK2', WEAPON_ASSAULTRIFLE_MK2='COMPONENT_AT_SCOPE_MACRO_MK2', WEAPON_CARBINERIFLE_MK2='COMPONENT_AT_SCOPE_MEDIUM_MK2', WEAPON_SPECIALCARBINE_MK2='COMPONENT_AT_SCOPE_MEDIUM_MK2', WEAPON_BULLPUPRIFLE_MK2='COMPONENT_AT_SCOPE_MACRO_02_MK2', WEAPON_COMBATMG='COMPONENT_AT_SCOPE_MEDIUM', WEAPON_COMBATMG_MK2='COMPONENT_AT_SCOPE_MEDIUM_MK2', WEAPON_MARKSMANRIFLE='COMPONENT_AT_SCOPE_LARGE_FIXED_ZOOM' },
    at_scope_large = { WEAPON_SNIPERRIFLE='COMPONENT_AT_SCOPE_LARGE', WEAPON_HEAVYSNIPER='COMPONENT_AT_SCOPE_LARGE', WEAPON_MARKSMANRIFLE='COMPONENT_AT_SCOPE_LARGE_FIXED_ZOOM', WEAPON_PRECISIONRIFLE='COMPONENT_AT_SCOPE_LARGE' },
    at_grip = { WEAPON_COMBATPDW='COMPONENT_AT_AR_AFGRIP', WEAPON_ASSAULTRIFLE='COMPONENT_AT_AR_AFGRIP', WEAPON_ASSAULTRIFLE_MK2='COMPONENT_AT_AR_AFGRIP_02', WEAPON_CARBINERIFLE='COMPONENT_AT_AR_AFGRIP', WEAPON_CARBINERIFLE_MK2='COMPONENT_AT_AR_AFGRIP_02', WEAPON_SPECIALCARBINE='COMPONENT_AT_AR_AFGRIP', WEAPON_SPECIALCARBINE_MK2='COMPONENT_AT_AR_AFGRIP_02', WEAPON_BULLPUPRIFLE='COMPONENT_AT_AR_AFGRIP', WEAPON_BULLPUPRIFLE_MK2='COMPONENT_AT_AR_AFGRIP_02', WEAPON_HEAVYRIFLE='COMPONENT_AT_AR_AFGRIP', WEAPON_COMBATMG='COMPONENT_AT_AR_AFGRIP', WEAPON_COMBATMG_MK2='COMPONENT_AT_AR_AFGRIP_02', WEAPON_ASSAULTSHOTGUN='COMPONENT_AT_AR_AFGRIP', WEAPON_BULLPUPSHOTGUN='COMPONENT_AT_AR_AFGRIP' },
    at_barrel = { WEAPON_SMG_MK2='COMPONENT_AT_SB_BARREL_02', WEAPON_ASSAULTRIFLE_MK2='COMPONENT_AT_AR_BARREL_02', WEAPON_CARBINERIFLE_MK2='COMPONENT_AT_CR_BARREL_02', WEAPON_SPECIALCARBINE_MK2='COMPONENT_AT_SC_BARREL_02', WEAPON_BULLPUPRIFLE_MK2='COMPONENT_AT_BP_BARREL_02', WEAPON_COMBATMG_MK2='COMPONENT_AT_MG_BARREL_02' },
    at_luxary_finish = { WEAPON_PISTOL='COMPONENT_PISTOL_VARMOD_LUXE', WEAPON_COMBATPISTOL='COMPONENT_COMBATPISTOL_VARMOD_LOWRIDER', WEAPON_APPISTOL='COMPONENT_APPISTOL_VARMOD_LUXE', WEAPON_PISTOL50='COMPONENT_PISTOL50_VARMOD_LUXE', WEAPON_SMG='COMPONENT_SMG_VARMOD_LUXE', WEAPON_ASSAULTRIFLE='COMPONENT_ASSAULTRIFLE_VARMOD_LUXE', WEAPON_CARBINERIFLE='COMPONENT_CARBINERIFLE_VARMOD_LUXE', WEAPON_ADVANCEDRIFLE='COMPONENT_ADVANCEDRIFLE_VARMOD_LUXE', WEAPON_SPECIALCARBINE='COMPONENT_SPECIALCARBINE_VARMOD_LOWRIDER', WEAPON_BULLPUPRIFLE='COMPONENT_BULLPUPRIFLE_VARMOD_LOW', WEAPON_PUMPSHOTGUN='COMPONENT_PUMPSHOTGUN_VARMOD_LOWRIDER', WEAPON_SNIPERRIFLE='COMPONENT_SNIPERRIFLE_VARMOD_LUXE' }
}

-- compatibility aliases for older item names / shop items
RDAttachmentComponents.at_suppressor = RDAttachmentComponents.at_suppressor_heavy
RDAttachmentComponents.at_clip_extended = RDAttachmentComponents.at_clip_extended_rifle
RDAttachmentComponents.at_scope_holo = RDAttachmentComponents.at_scope_small
RDAttachmentComponents.at_scope = RDAttachmentComponents.at_scope_small
RDAttachmentComponents.at_scope_small = RDAttachmentComponents.at_scope_small
RDAttachmentComponents.at_color_luxury = RDAttachmentComponents.at_luxary_finish
RDAttachmentComponents.tint_boom = RDAttachmentComponents.at_luxary_finish
RDAttachmentComponents.tint_leopard = RDAttachmentComponents.at_luxary_finish


local RDCurrentWeaponAttachments = RDCurrentWeaponAttachments or {}

local function rdGetEquippedAttachmentsForWeapon(weaponName)
    local out = {}
    local ped = PlayerPedId()
    local weaponHash = joaat(weaponName)
    for itemName, components in pairs(RDAttachmentComponents or {}) do
        local comp = components[weaponName]
        if comp and HasPedGotWeaponComponent(ped, weaponHash, joaat(comp)) then
            local def = RDInvClient.items and RDInvClient.items[itemName] or {}
            out[#out + 1] = { name = itemName, label = def.label or itemName, image = def.image or (itemName .. '.png'), component = comp }
        end
    end
    return out
end

local function rdClearUsingItem(slot, name)
    TriggerServerEvent('rd_inventory:clearUsingItem', slot, name)
end

local function rdIsWeaponDef(name, item)
    local weaponName = item and (item.weapon or item.hash or item.name) or name
    if type(weaponName) ~= 'string' then return false end
    local upper = weaponName:upper()
    return upper:find('WEAPON_', 1, true) == 1 or upper:find('GADGET_', 1, true) == 1, upper
end

local function rdOpenAttachmentUiForWeapon(name, item, weaponSlot)
    local okWeapon, weaponName = rdIsWeaponDef(name, item)
    if not okWeapon then return false end
    local available = {}
    local savedEquipped = nil
    local inv = lib.callback.await('rd_inventory:getInventory', false)
    for _, wItem in ipairs((inv and inv.items) or {}) do
        if wItem.name == name and (not weaponSlot or tonumber(wItem.slot) == tonumber(weaponSlot)) then
            local meta = wItem.metadata or {}
            if type(meta.attachments) == 'table' then
                savedEquipped = {}
                for comp, attachName in pairs(meta.attachments) do
                    local def = RDInvClient.items and RDInvClient.items[attachName] or {}
                    savedEquipped[#savedEquipped + 1] = { name = attachName, label = def.label or attachName, image = def.image or (attachName .. '.png'), component = comp }
                end
            end
            break
        end
    end
    for _, invItem in ipairs((inv and inv.items) or {}) do
        local attachName = invItem.name
        local components = RDAttachmentComponents[attachName]
        if components and components[weaponName] then
            local def = RDInvClient.items and RDInvClient.items[attachName] or {}
            available[#available + 1] = {
                name = attachName,
                label = def.label or attachName,
                image = def.image or (attachName .. '.png'),
                slot = invItem.slot,
                count = invItem.count or 1,
                component = components[weaponName]
            }
        end
    end
    SendNUIMessage({ action = 'attachments', weapon = { name = name, slot = weaponSlot, label = (item and item.label) or name, weapon = weaponName, image = (item and item.image) or (weaponName .. '.png') }, attachments = available, equipped = savedEquipped or rdGetEquippedAttachmentsForWeapon(weaponName) })
    return true
end


local function rdSelectedWeaponInfo()
    local ped = PlayerPedId()
    local weapon = GetSelectedPedWeapon(ped)
    if not weapon or weapon == `WEAPON_UNARMED` or not IsPedArmed(ped, 4) then return nil end
    return ped, weapon, RDWeaponNameByHash[weapon], RDWeaponAmmoByWeapon[weapon]
end

local function rdUseAmmoItem(name)
    local ped, weapon, weaponName, ammoItem = rdSelectedWeaponInfo()
    if not ped or ammoItem ~= name then
        RDUtils.notify('Mbaj ne dore armen e duhur per kete ammo', 'error')
        return true
    end
    local amount = tonumber((RDConfig and RDConfig.weapons and RDConfig.weapons.reloadAmount) or 12) or 12
    CreateThread(function()
        rdProgressBar('RELOADING', tonumber((RDConfig and RDConfig.weapons and RDConfig.weapons.ammoUseTime) or 1400) or 1400)
        TriggerServerEvent('rd_inventory:serverReloadWeapon', name, amount)
    end)
    return true
end

local function rdUseAttachmentItem(name)
    local components = RDAttachmentComponents[name]
    if components then
        RDUtils.notify('Hap armen nga inventory dhe vendose attachment te sloti i armes.', 'error')
        return true
    end
    return false
end

RegisterNetEvent('rd_inventory:reloadResult', function(ok, ammoItem, amount, msg)
    if not ok then return RDUtils.notify(msg or 'No ammo', 'error') end
    local ped, weapon = rdSelectedWeaponInfo()
    if not ped then return end
    AddAmmoToPed(ped, weapon, tonumber(amount) or 0)
    MakePedReload(ped)
    RDUtils.notify(('Reloaded +%s'):format(tonumber(amount) or 0), 'success')
end)

RegisterNetEvent('rd_inventory:attachmentResult', function(ok, itemName, weaponName, componentName, msg)
    if not ok then return RDUtils.notify(msg or 'Attachment failed', 'error') end
    local ped = PlayerPedId()
    local weapon = joaat(weaponName)
    if not HasPedGotWeapon(ped, weapon, false) then return end
    GiveWeaponComponentToPed(ped, weapon, joaat(componentName))
    RDCurrentWeaponAttachments[weaponName] = RDCurrentWeaponAttachments[weaponName] or {}
    RDCurrentWeaponAttachments[weaponName][componentName] = itemName
    RDUtils.notify('Attachment u vendos', 'success')
end)

local function rdHasPhoneItem()
    local ok, hasPhone = pcall(function()
        return lib.callback.await('rd_inventory:hasPhoneItem', false)
    end)
    return ok and hasPhone == true
end

local function rdSetExternalPhoneDisabled(disabled)
    pcall(function() exports.npwd:setPhoneDisabled(disabled) end)
    pcall(function() exports['qs-smartphone']:setPhoneDisabled(disabled) end)
    pcall(function() exports['qs-smartphone']:SetPhoneDisabled(disabled) end)
    pcall(function() exports['qs-smartphone-pro']:setPhoneDisabled(disabled) end)
end

local function rdOpenPhone(forceChecked)
    if not forceChecked and not rdHasPhoneItem() then
        rdSetExternalPhoneDisabled(true)
        RDUtils.notify('Nuk ke telefon ne inventory.', 'error')
        return false
    end

    rdSetExternalPhoneDisabled(false)
    local opened = false
    pcall(function() exports['qs-smartphone']:openPhone() opened = true end)
    pcall(function() exports['qs-smartphone']:OpenPhone() opened = true end)
    pcall(function() exports['qs-smartphone-pro']:openPhone() opened = true end)
    pcall(function() exports['qs-smartphone-pro']:OpenPhone() opened = true end)
    pcall(function() exports['lb-phone']:ToggleOpen(true) opened = true end)
    pcall(function() exports['npwd']:setPhoneVisible(true) opened = true end)
    pcall(function() TriggerEvent('qs-smartphone:client:openPhone') opened = true end)
    pcall(function() TriggerEvent('qs-smartphone-pro:client:openPhone') opened = true end)
    pcall(function() TriggerEvent('lb-phone:client:openPhone') opened = true end)
    pcall(function() TriggerEvent('phone:open') opened = true end)
    if not opened then RDUtils.notify('Phone item used', 'success') end
    return true
end

-- Blocks QS Phone V3 / other phone resources from opening without RD_inventory phone item.
-- IMPORTANT: start RD_inventory AFTER the phone resource in server.cfg so these commands/keybinds win.
local function rdPhoneCommandGate()
    if not rdHasPhoneItem() then
        rdSetExternalPhoneDisabled(true)
        RDUtils.notify('Nuk ke telefon ne inventory.', 'error')
        return
    end
    rdOpenPhone(true)
end

RegisterCommand('phone', rdPhoneCommandGate, false)
RegisterCommand('openphone', rdPhoneCommandGate, false)
RegisterCommand('openPhone', rdPhoneCommandGate, false)
RegisterCommand('qsphone', rdPhoneCommandGate, false)
RegisterCommand('smartphone', rdPhoneCommandGate, false)
RegisterKeyMapping('phone', 'Open phone (requires RD_inventory phone item)', 'keyboard', 'M')

CreateThread(function()
    Wait(2500)
    while true do
        local hasPhone = rdHasPhoneItem()
        rdSetExternalPhoneDisabled(not hasPhone)
        Wait(hasPhone and 15000 or 3000)
    end
end)

function RDInvClient.openVehicleInventory(invType, vehicle)
    local veh = vehicle or GetVehiclePedIsIn(PlayerPedId(), false)
    if veh == 0 then
        local coords = GetEntityCoords(PlayerPedId())
        veh = GetClosestVehicle(coords.x, coords.y, coords.z, 4.0, 0, 71)
    end
    if veh == 0 then return RDUtils.notify('No vehicle nearby', 'error') end

    local plate = plateFromVehicle(veh)
    invType = invType or (GetVehiclePedIsIn(PlayerPedId(), false) ~= 0 and 'glovebox' or 'trunk')

    if invType == 'trunk' then
        if (RDConfig and RDConfig.vehicles and RDConfig.vehicles.checkVehicleLocked) ~= false and rdIsVehicleLocked(veh) then
            rdNotifyTrunkLocked()
            return
        end
        rdPlayTrunkAnim()
        rdOpenVehicleDoorForInventory(veh, invType)
    end

    local inv, defs = lib.callback.await('rd_inventory:getInventory', false)
    local vehInv, vehDefs = lib.callback.await('rd_inventory:getVehicleInventory', false, plate, invType)
    local uiSettings = lib.callback.await('rd_inventory:getUISettings', false)

    local other = {
        type = invType,
        label = invType == 'glovebox' and 'GLOVEBOX' or 'TRUNK',
        subtitle = invType == 'glovebox' and 'Vehicle glovebox' or 'Vehicle trunk',
        plate = plate,
        vehicleType = invType,
        items = formatItems(vehInv or {}, vehDefs or defs or {}),
        slots = vehInv and vehInv.slots or 25,
        maxWeight = vehInv and vehInv.maxWeight or ((invType == 'glovebox') and ((RDConfig and RDConfig.vehicles and RDConfig.vehicles.gloveboxWeight) or 10000) or ((RDConfig and RDConfig.vehicles and RDConfig.vehicles.trunkWeight) or 60000))
    }

    RDInvClient.items = defs or {}
    RDInvClient.currentOther = other
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        type = 'inventory',
        items = formatItems(inv or {}, defs or {}),
        other = other,
        hotbar = inv and inv.hotbar or {},
        maxWeight = inv and inv.maxWeight or RD.MaxWeight,
        slots = inv and inv.slots or RD.MaxSlots,
        uiSettings = uiSettings or {}
    })
    RDInvClient.open = true
    RDUtils.playAnim('open')
    SetTimeout(150, function() RDInvClient.busy = false end)
end

RegisterNetEvent('rd_inventory:client:openVehicleInventory', RDInvClient.openVehicleInventory)

function RDInvClient.getOtherInventory()
    local ped = PlayerPedId()
    local veh, inside = getNearestVehicle()

    if veh ~= 0 then
        local plate = plateFromVehicle(veh)
        local invType = inside and 'glovebox' or 'trunk'
        local inv, defs = lib.callback.await('rd_inventory:getVehicleInventory', false, plate, invType)
        return {
            type = invType,
            label = inside and 'GLOVEBOX' or 'TRUNK',
            subtitle = inside and 'Vehicle glovebox' or 'Vehicle trunk',
            plate = plate,
            vehicleType = invType,
            items = formatItems(inv or {}, defs or {}),
            slots = inv and inv.slots or 25,
            maxWeight = inv and inv.maxWeight or ((invType == 'glovebox') and ((RDConfig and RDConfig.vehicles and RDConfig.vehicles.gloveboxWeight) or 10000) or ((RDConfig and RDConfig.vehicles and RDConfig.vehicles.trunkWeight) or 60000))
        }
    end

    local drops, defs = lib.callback.await('rd_inventory:getGroundDrops', false)
    RDInvClient.drops = drops or {}
    rdSyncDropProps(RDInvClient.drops)

    -- only show drops if actually near a drop
    local coords = GetEntityCoords(ped)
    local nearestId, nearestItems = nil, {}

    for id, drop in pairs(drops or {}) do
        if drop.coords then
            local d = #(coords - vec3(drop.coords.x, drop.coords.y, drop.coords.z))
            if d < ((RDConfig and RDConfig.drops and RDConfig.drops.distance) or 3.0) then
                nearestId = id
                nearestItems = formatItems(drop, defs or {})
                break
            end
        end
    end

    if nearestId then
        return {
            type = 'ground',
            label = 'GROUND DROPS',
            subtitle = 'Drop / pickup items',
            dropId = nearestId,
            items = nearestItems,
            slots = (RDConfig and RDConfig.drops and RDConfig.drops.slots) or 25
        }
    end

    return {
        type = 'ground',
        label = 'GROUND DROPS',
        subtitle = 'No drops nearby',
        dropId = nil,
        items = {},
        slots = (RDConfig and RDConfig.drops and RDConfig.drops.slots) or 25,
        maxWeight = 0
    }
end



function RDInvClient.openTargetInventory(targetId, label)
    targetId = tonumber(targetId)
    if not targetId then return end
    local inv, defs = lib.callback.await('rd_inventory:getInventory', false)
    local targetInv, targetDefs = lib.callback.await('rd_inventory:getPlayerTargetInventory', false, targetId)
    if not targetInv then
        RDUtils.notify('Player is not searchable / too far', 'error')
        return
    end
    local uiSettings = lib.callback.await('rd_inventory:getUISettings', false)

    local other = {
        type = 'playerTarget',
        label = label or ('Player ID ' .. targetId),
        subtitle = 'Rob / search body',
        targetId = targetId,
        items = formatItems(targetInv or {}, targetDefs or defs or {}),
        slots = targetInv and targetInv.slots or RD.MaxSlots,
        maxWeight = targetInv and targetInv.maxWeight or RD.MaxWeight
    }

    RDInvClient.items = defs or {}
    RDInvClient.currentOther = other
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        type = 'inventory',
        items = formatItems(inv or {}, defs or {}),
        other = other,
        hotbar = inv and inv.hotbar or {},
        maxWeight = inv and inv.maxWeight or RD.MaxWeight,
        slots = inv and inv.slots or RD.MaxSlots,
        uiSettings = uiSettings or {}
    })
    RDInvClient.open = true
    RDUtils.playAnim('open')
end

RegisterNetEvent('rd_inventory:client:openTargetInventory', RDInvClient.openTargetInventory)

function RDInvClient.openStash(stashId, label)
    if not stashId then return end
    local inv, defs = lib.callback.await('rd_inventory:getInventory', false)
    local stash, stashDefs = lib.callback.await('rd_inventory:getStashInventory', false, stashId)
    if not stash then
        RDUtils.notify('You do not have access to this stash', 'error')
        return
    end
    local uiSettings = lib.callback.await('rd_inventory:getUISettings', false)

    local other = {
        type = 'stash',
        label = label or (stash and stash.label) or 'STASH',
        subtitle = 'Stash storage',
        stashId = stashId,
        items = formatItems(stash or {}, stashDefs or defs or {}),
        slots = stash and stash.slots or 50,
        maxWeight = stash and stash.maxWeight or 0
    }

    RDInvClient.items = defs or {}
    RDInvClient.currentOther = other
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        type = 'inventory',
        items = formatItems(inv or {}, defs or {}),
        other = other,
        hotbar = inv and inv.hotbar or {},
        maxWeight = inv and inv.maxWeight or RD.MaxWeight,
        slots = inv and inv.slots or RD.MaxSlots,
        uiSettings = uiSettings or {}
    })
    RDInvClient.open = true
    RDUtils.playAnim('open')
end

RegisterNetEvent('rd_inventory:client:openStash', RDInvClient.openStash)
RegisterCommand('rd_openstash', function(_, args)
    RDInvClient.openStash(args[1] or 'default', args[2] or 'STASH')
end)

function RDInvClient.canToggleInventory()
    local cfg = (RDConfig and RDConfig.inventory) or {}
    local now = GetGameTimer()
    local cd = cfg.toggleCooldown or 350
    if RDInvClient.busy then return false end
    if (now - (RDInvClient.lastToggle or 0)) < cd then return false end
    RDInvClient.lastToggle = now
    return true
end

function RDInvClient.openInventory()
    local cfg = (RDConfig and RDConfig.inventory) or {}
    local now = GetGameTimer()
    if RDInvClient.open then return RDInvClient.closeInventory() end
    if RDInvClient.busy or ((now - (RDInvClient.lastOpen or 0)) < (cfg.openCooldown or 450)) then return end
    RDInvClient.busy = true
    RDInvClient.lastOpen = now

    local inv, defs = lib.callback.await('rd_inventory:getInventory', false)
    local uiSettings = lib.callback.await('rd_inventory:getUISettings', false)
    local other = RDInvClient.getOtherInventory()

    RDInvClient.items = defs or {}
    RDInvClient.currentOther = other

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        type = 'inventory',
        items = formatItems(inv or {}, defs or {}),
        other = other,
        hotbar = inv and inv.hotbar or {},
        maxWeight = inv and inv.maxWeight or RD.MaxWeight,
        slots = inv and inv.slots or RD.MaxSlots,
        uiSettings = uiSettings or {}
    })

    RDInvClient.open = true
    RDUtils.playAnim('open')
end

function RDInvClient.closeInventory()
    local cfg = (RDConfig and RDConfig.inventory) or {}
    local now = GetGameTimer()
    if not RDInvClient.open and not RDInvClient.busy then return end
    if ((now - (RDInvClient.lastClose or 0)) < (cfg.closeCooldown or 250)) then return end
    RDInvClient.lastClose = now
    RDInvClient.busy = true

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ action = 'close' })
    RDInvClient.open = false
    rdCloseVehicleDoorForInventory()
    SetTimeout(120, function() RDInvClient.busy = false end)
end

RegisterCommand(RD.Command, function()
    if not RDInvClient.canToggleInventory() then return end
    if RDInvClient.open then return RDInvClient.closeInventory() end
    RDInvClient.openInventory()
end, false)
RegisterKeyMapping(RD.Command, 'Open Inventory', 'keyboard', RD.OpenKey)

RegisterCommand((RDConfig and RDConfig.vehicles and RDConfig.vehicles.trunkKeyCommand) or 'rd_trunk', function()
    if RDInvClient.open then return end
    if not (RDConfig and RDConfig.vehicles and RDConfig.vehicles.trunkKeyEnabled) then return end

    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        return RDUtils.notify('Dil nga makina per te hapur bagazhin', 'error')
    end

    local veh, dist = rdGetClosestVehicleForTrunk()
    local maxDist = (RDConfig and RDConfig.vehicles and (RDConfig.vehicles.trunkRearDistance or RDConfig.vehicles.trunkDistance)) or 1.8
    if veh == 0 or dist > maxDist then
        return RDUtils.notify('Duhet te jesh pas makines per bagazhin', 'error')
    end

    if (RDConfig and RDConfig.vehicles and RDConfig.vehicles.checkVehicleLocked) ~= false and rdIsVehicleLocked(veh) then
        return rdNotifyTrunkLocked()
    end

    RDInvClient.openVehicleInventory('trunk', veh)
end, false)

if RDConfig and RDConfig.vehicles and RDConfig.vehicles.trunkKeyEnabled then
    RegisterKeyMapping((RDConfig and RDConfig.vehicles and RDConfig.vehicles.trunkKeyCommand) or 'rd_trunk', 'Open vehicle trunk / bagazh', 'keyboard', (RDConfig and RDConfig.vehicles and RDConfig.vehicles.trunkKey) or 'K')
end

CreateThread(function()
    while true do
        local sleep = 750
        if RDConfig and RDConfig.vehicles and RDConfig.vehicles.trunkKeyEnabled and RDConfig.vehicles.showTrunkPrompt then
            local ped = PlayerPedId()
            if not RDInvClient.open and not IsPedInAnyVehicle(ped, false) then
                local veh, dist = rdGetClosestVehicleForTrunk()
                local maxDist = RDConfig.vehicles.trunkDistance or 3.0
                if veh ~= 0 and dist <= maxDist then
                    sleep = 0
                    rdDrawTrunkHelp()
                end
            end
        end
        Wait(sleep)
    end
end)

RegisterCommand('rd_hotbar', function()
    local inv, defs = lib.callback.await('rd_inventory:getInventory', false)
    SendNUIMessage({
        action = 'hotbar',
        items = formatItems(inv or {}, defs or {}),
        hotbar = inv and inv.hotbar or {}
    })
end)
RegisterKeyMapping('rd_hotbar', 'Show Hotbar', 'keyboard', RD.HotbarKey or 'Z')

-- Hotbar 1-5: first inventory row is the usable hotbar.
local function useHotbarSlot(slot)
    if RDInvClient.open then return end
    TriggerServerEvent('rd_inventory:useItemSlot', tonumber(slot))
end

for i = 1, (RD.HotbarSlots or 5) do
    RegisterCommand(('rd_use_hotbar_%s'):format(i), function() useHotbarSlot(i) end, false)
    local key = (RD.HotbarUseKeys and RD.HotbarUseKeys[i]) or tostring(i)
    RegisterKeyMapping(('rd_use_hotbar_%s'):format(i), ('Use inventory hotbar %s'):format(i), 'keyboard', key)
end

-- X: hands up / cancel weapon in hand. This only holsters the weapon, it does not remove it from inventory.
RegisterCommand((RDConfig and RDConfig.weapons and RDConfig.weapons.unquipCommand) or 'rd_weapon_unquip', function()
    rdHolsterCurrentWeapon(true)
end, false)

if not RDConfig or not RDConfig.weapons or RDConfig.weapons.unquipKeyEnabled ~= false then
    RegisterKeyMapping((RDConfig and RDConfig.weapons and RDConfig.weapons.unquipCommand) or 'rd_weapon_unquip', 'Hands up / holster weapon', 'keyboard', (RDConfig and RDConfig.weapons and RDConfig.weapons.unquipKey) or 'X')
end


RegisterNetEvent('rd_inventory:refresh', function(inv)
    if not RDInvClient.open then return end

    local other = RDInvClient.currentOther

    -- Keep the same right-side context open after actions.
    -- Shop must stay shop until X/ESC; stash/trunk/glovebox refresh their real contents.
    if other and other.type == 'shop' then
        -- keep shop list as-is
    elseif other and other.type == 'stash' then
        local stash, defs = lib.callback.await('rd_inventory:getStashInventory', false, other.stashId)
        other.items = formatItems(stash or {}, defs or RDInvClient.items or {})
        other.slots = stash and stash.slots or other.slots or 50
        other.maxWeight = stash and stash.maxWeight or other.maxWeight or 0
    elseif other and other.type == 'playerTarget' then
        local targetInv, defs = lib.callback.await('rd_inventory:getPlayerTargetInventory', false, other.targetId)
        other.items = formatItems(targetInv or {}, defs or RDInvClient.items or {})
        other.slots = targetInv and targetInv.slots or other.slots or RD.MaxSlots
        other.maxWeight = targetInv and targetInv.maxWeight or other.maxWeight or RD.MaxWeight
    elseif other and (other.type == 'trunk' or other.type == 'glovebox') then
        local vehInv, defs = lib.callback.await('rd_inventory:getVehicleInventory', false, other.plate, other.vehicleType or other.type)
        other.items = formatItems(vehInv or {}, defs or RDInvClient.items or {})
        other.slots = vehInv and vehInv.slots or other.slots or 25
        other.maxWeight = vehInv and vehInv.maxWeight or other.maxWeight or ((other.vehicleType == 'glovebox') and ((RDConfig and RDConfig.vehicles and RDConfig.vehicles.gloveboxWeight) or 10000) or ((RDConfig and RDConfig.vehicles and RDConfig.vehicles.trunkWeight) or 60000))
    else
        other = RDInvClient.getOtherInventory()
    end

    RDInvClient.currentOther = other
    SendNUIMessage({
        action = 'refresh',
        items = formatItems(inv or {}, RDInvClient.items or {}),
        other = other,
        hotbar = inv.hotbar or {},
        maxWeight = inv and inv.maxWeight or RD.MaxWeight,
        slots = inv and inv.slots or RD.MaxSlots
    })
end)

RegisterNetEvent('rd_inventory:updateDrops', function(drops)
    RDInvClient.drops = drops or {}
    rdSyncDropProps(RDInvClient.drops)
    if RDInvClient.open then
        local currentType = RDInvClient.currentOther and RDInvClient.currentOther.type
        if currentType == 'ground' or not currentType then
            local other = RDInvClient.getOtherInventory()
            RDInvClient.currentOther = other
            SendNUIMessage({ action = 'refreshOther', other = other })
        end
    end
end)

CreateThread(function()
    Wait(2500)
    local drops = lib.callback.await('rd_inventory:getGroundDrops', false)
    RDInvClient.drops = drops or {}
    rdSyncDropProps(RDInvClient.drops)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    rdCloseVehicleDoorForInventory()
    if RDInvStopClothesCamera then RDInvStopClothesCamera() end
    FreezeEntityPosition(PlayerPedId(), false)
    for dropId in pairs(RDInvClient.dropProps or {}) do
        rdDeleteDropProp(dropId)
    end
end)


function rdProgressBar(label, duration)
    duration = tonumber(duration or 0) or 0
    if duration <= 0 then return true end
    SendNUIMessage({ action = 'progress', label = label or 'WORKING', duration = duration })
    Wait(duration)
    return true
end

RegisterNetEvent('rd_inventory:progressbar', function(label, duration)
    rdProgressBar(label, duration)
end)

exports('Progressbar', function(label, duration)
    return rdProgressBar(label, duration)
end)

exports('StartProgress', function(label, duration)
    return rdProgressBar(label, duration)
end)


-- RD real reload with R: consumes the correct ammo item, then adds bullets.
CreateThread(function()
    while true do
        Wait(0)
        if IsControlJustPressed(0, 45) then -- R reload
            local ped, weapon, weaponName, ammoItem = rdSelectedWeaponInfo()
            if ped and ammoItem then
                local amount = tonumber((RDConfig and RDConfig.weapons and RDConfig.weapons.reloadAmount) or 12) or 12
                CreateThread(function()
                    rdProgressBar('RELOADING', tonumber((RDConfig and RDConfig.weapons and RDConfig.weapons.reloadTime) or 1600) or 1600)
                    TriggerServerEvent('rd_inventory:serverReloadWeapon', ammoItem, amount)
                end)
            end
        end
    end
end)



-- RD REAL FOOD / DRINK PROPS
-- Props stay attached while the progressbar runs, then get cleaned safely.
local function rdLoadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(10) end
    return hash
end

local function rdAttachUseProp(ped, prop)
    if not prop or not prop.model then return nil end
    local hash = rdLoadModel(prop.model)
    if not HasModelLoaded(hash) then return nil end
    local obj = CreateObject(hash, 0.0, 0.0, 0.0, true, true, false)
    local bone = GetPedBoneIndex(ped, prop.bone or 57005)
    local pos = prop.pos or vec3(0.0, 0.0, 0.0)
    local rot = prop.rot or vec3(0.0, 0.0, 0.0)
    AttachEntityToEntity(obj, ped, bone,
        pos.x or 0.0, pos.y or 0.0, pos.z or 0.0,
        rot.x or 0.0, rot.y or 0.0, rot.z or 0.0,
        true, true, false, true, 1, true
    )
    SetModelAsNoLongerNeeded(hash)
    return obj
end

local function rdPlayUseAnim(anim)
    if not anim then return end
    local a = type(anim) == 'string' and (RDAnimations and RDAnimations[anim]) or anim
    if not a or not a.dict or not a.clip then return end
    RequestAnimDict(a.dict)
    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(a.dict) and GetGameTimer() < timeout do Wait(10) end
    TaskPlayAnim(PlayerPedId(), a.dict, a.clip, 8.0, -8.0, -1, a.flag or 49, 0, false, false, false)
end

local function rdRunUseAction(client, item, label, duration)
    local ped = PlayerPedId()
    local spawned = {}

    -- supports client.prop and client.props = { ... } for fork + plate / spoon + bowl.
    if client.prop then spawned[#spawned+1] = rdAttachUseProp(ped, client.prop) end
    if client.props then
        for _, prop in ipairs(client.props) do
            spawned[#spawned+1] = rdAttachUseProp(ped, prop)
        end
    end

    rdPlayUseAnim(client.anim or item.anim)

    if duration > 0 then
        rdProgressBar(label, duration)
    else
        Wait(800)
    end

    ClearPedTasks(ped)
    for _, obj in ipairs(spawned) do
        if obj and DoesEntityExist(obj) then DeleteEntity(obj) end
    end
end

-- Starts the real use action first. Item effects/consume happen only AFTER this progress finishes.
RegisterNetEvent('rd_inventory:itemUseStart', function(name, item, slot)
    item = item or {}
    local client = item.client or {}

    -- Ammo and attachments are real weapon actions.
    if RDWeaponAmmoByWeapon then
        for _, ammoItem in pairs(RDWeaponAmmoByWeapon) do
            if name == ammoItem then
                if rdUseAmmoItem(name) then
                    rdClearUsingItem(slot, name)
                    return
                end
            end
        end
    end
    if rdUseAttachmentItem(name) then
        rdClearUsingItem(slot, name)
        return
    end

    -- Weapons and phone are instant/special actions.
    if rdUseWeaponItem(name, item) then
        rdClearUsingItem(slot, name)
        return
    end
    if name == 'phone' or name == 'smartphone' then
        rdOpenPhone(true)
        rdClearUsingItem(slot, name)
        return
    end

    local waitTime = tonumber(client.usetime or item.usetime or 0) or 0
    local progressLabel = client.progressLabel or client.label or item.progressLabel or item.label or name

    if client.anim or client.prop or client.props or waitTime > 0 then
        rdRunUseAction(client, item, progressLabel, waitTime)
    end

    TriggerServerEvent('rd_inventory:finishUseItem', name, slot)
end)

-- Server confirms the item was consumed/used, then we apply status/notification/equip.
RegisterNetEvent('rd_inventory:itemUsed', function(name, item)
    item = item or {}
    local client = item.client or {}

    if item.type then
        TriggerEvent('rd_inventory:client:equipClothing', item.type, name)
        SendNUIMessage({ action = 'clothEquipped', item = { name = name, label = item.label or name, image = item.image or (name .. '.png'), type = item.type, metadata = item.metadata or {} } })
    end

    if client.status then
        rdApplyStatus(client.status)
    end

    if client.event then
        TriggerEvent(client.event, name, item)
        return
    end

    RDUtils.notify(client.notification or ('Used: ' .. (item.label or name)), 'success')
end)

RegisterNUICallback('close', function(_, cb)
    FreezeEntityPosition(PlayerPedId(), false)
    RDInvClient.closeInventory()
    cb(true)
end)

RegisterNUICallback('useItem', function(data, cb)
    local def = RDInvClient.items and RDInvClient.items[data.name]
    if (RDConfig and RDConfig.weapons and RDConfig.weapons.openAttachmentsOnWeaponClick) ~= false then
        local isWeapon = rdIsWeaponDef(data.name, def)
        if isWeapon and RDInvClient.open then
            rdOpenAttachmentUiForWeapon(data.name, def, data.slot)
            cb(true)
            return
        end
    end
    if not def or def.close ~= false then
        RDInvClient.closeInventory()
    end
    TriggerServerEvent('rd_inventory:useItem', data.name, data.slot)
    cb(true)
end)

RegisterNUICallback('useAttachmentItem', function(data, cb)
    CreateThread(function()
        rdProgressBar('VENDOS ATTACHMENT', tonumber((RDConfig and RDConfig.weapons and RDConfig.weapons.attachmentUseTime) or 1800) or 1800)
        TriggerServerEvent('rd_inventory:serverUseAttachment', data.name, data.weapon, data.component, data.weaponSlot, data.slot)
    end)
    cb(true)
end)

RegisterNUICallback('removeWeaponAttachment', function(data, cb)
    local ped = PlayerPedId()
    local weaponName = tostring(data.weapon or '')
    local component = tostring(data.component or '')
    local itemName = tostring(data.name or '')
    if weaponName ~= '' and component ~= '' and itemName ~= '' then
        local weaponHash = joaat(weaponName)
        local compHash = joaat(component)
        -- remove visually if player currently holds/has it, but ALWAYS update saved weapon metadata
        if HasPedGotWeaponComponent(ped, weaponHash, compHash) then
            RemoveWeaponComponentFromPed(ped, weaponHash, compHash)
        end
        rdProgressBar('HEQ ATTACHMENT', tonumber((RDConfig and RDConfig.weapons and RDConfig.weapons.attachmentRemoveTime) or 1200) or 1200)
        TriggerServerEvent('rd_inventory:serverReturnAttachment', itemName, weaponName, component)
        RDUtils.notify('Attachment u hoq dhe u kthye ne inventory', 'success')
    end
    cb(true)
end)

RegisterNUICallback('notify', function(data, cb)
    RDUtils.notify(data.message or 'Inventory', data.type or 'inform')
    cb(true)
end)

RegisterNUICallback('dropItem', function(data, cb)
    local coords = GetEntityCoords(PlayerPedId())
    TriggerServerEvent('rd_inventory:dropItem', data.name, data.count or 1, data.slot, { x = coords.x, y = coords.y, z = coords.z }, data.dropId, data.toSlot)
    cb(true)
end)


RegisterNUICallback('giveItem', function(data, cb)
    local targetId = tonumber(data.targetId)

    -- Ox-style GIVE: when UI sends a server ID, use it directly.
    -- Fallback: if no ID was sent, use closest player within 3m.
    if not targetId or targetId < 1 then
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local closestPlayer, closestDist = -1, 999.0

        for _, player in ipairs(GetActivePlayers()) do
            local serverId = GetPlayerServerId(player)
            if player ~= PlayerId() then
                local targetPed = GetPlayerPed(player)
                local dist = #(coords - GetEntityCoords(targetPed))
                if dist < closestDist then
                    closestPlayer = serverId
                    closestDist = dist
                end
            end
        end

        if closestPlayer == -1 or closestDist > 3.0 then
            RDUtils.notify('No player nearby', 'error')
            cb(false)
            return
        end

        targetId = closestPlayer
    end

    TriggerServerEvent('rd_inventory:giveItem', targetId, data.name, data.count or 1, data.slot)
    cb(true)
end)

RegisterNUICallback('pickupDrop', function(data, cb)
    TriggerServerEvent('rd_inventory:pickupDrop', data.dropId, data.slot, data.toSlot, data.count)
    cb(true)
end)

RegisterNUICallback('moveItem', function(data, cb)
    TriggerServerEvent('rd_inventory:moveItem', data.fromSlot, data.toSlot, data.count, data.name)
    cb(true)
end)

RegisterNUICallback('moveBetweenInventories', function(data, cb)
    local other = RDInvClient.currentOther or {}
    data.plate = other.plate
    data.vehicleType = other.vehicleType
    data.shopId = data.shopId or other.shopId
    data.stashId = data.stashId or other.stashId
    data.targetId = data.targetId or other.targetId

    -- Owned Store stock: kur owner fut item ne stock, pyet direkt Amount + Price.
    if other.type == 'stash' and tostring(data.stashId or ''):find('^ownedstore:') and data.fromType == 'player' and data.toType == 'stash' then
        local maxAmount = tonumber(data.count) or 1
        local input = lib.inputDialog('Add item to store stock', {
            { type = 'number', label = 'How many?', required = true, min = 1, default = maxAmount },
            { type = 'number', label = 'Sell price per item $', required = true, min = 1, default = tonumber(data.price) or 10 }
        })
        if not input then cb(false) return end
        data.count = math.max(1, math.floor(tonumber(input[1]) or 1))
        data.price = math.max(1, math.floor(tonumber(input[2]) or 1))
    end

    TriggerServerEvent('rd_inventory:moveBetweenInventories', data)
    cb(true)
end)

RegisterNUICallback('buyItem', function(data, cb)
    local other = RDInvClient.currentOther or {}
    if other.type == 'ownedshop' then
        TriggerServerEvent('RD_STORES:server:buyItem', data.shopId or other.shopId, data.name, data.count or 1, data.fromSlot or data.slot, data.toSlot or data.slot, data.payMethod or data.method or 'cash')
    else
        TriggerServerEvent('rd_inventory:buyItem', data.shopId, data.name, data.count or 1, data.slot or data.toSlot, data.payMethod or data.method or 'cash')
    end
    cb(true)
end)

RegisterNUICallback('closeForShopPayment', function(data, cb)
    RDInvClient.open = false
    SetNuiFocus(false, false)
    cb(true)
end)

RegisterNUICallback('moveOtherItem', function(data, cb)
    local other = RDInvClient.currentOther or {}
    data.plate = data.plate or other.plate
    data.vehicleType = data.vehicleType or other.vehicleType
    data.stashId = data.stashId or other.stashId
    TriggerServerEvent('rd_inventory:moveOtherItem', data)
    cb(true)
end)

RegisterNUICallback('moveGroundItem', function(data, cb)
    local other = RDInvClient.currentOther or {}
    data.dropId = data.dropId or other.dropId
    TriggerServerEvent('rd_inventory:moveGroundItem', data)
    cb(true)
end)

RegisterNUICallback('unequipClothingToInventory', function(data, cb)
    -- Server validates that this clothing item was really equipped.
    -- Do not visually remove/spawn anything here, otherwise clothes can desync.
    TriggerServerEvent('rd_inventory:unequipClothingToInventory', data.type, data.name, data.toSlot)
    cb(true)
end)

RegisterNUICallback('setHotbar', function(data, cb)
    TriggerServerEvent('rd_inventory:setHotbar', data.hotbarSlot, data.itemSlot)
    cb(true)
end)

RegisterNUICallback('saveUISettings', function(data, cb)
    TriggerServerEvent('rd_inventory:saveUISettings', data or {})
    cb(true)
end)

RegisterNUICallback('equipClothing', function(data, cb)
    TriggerServerEvent('rd_inventory:equipClothingItem', data.name, data.slot, data.type)
    cb(true)
end)



-- RD CLOTHES UI CAMERA: puts camera in front of frozen character while clothes UI is open.
local rdClothesCam = nil
local rdOldHeading = nil

local function rdStopClothesCamera()
    if rdClothesCam then
        RenderScriptCams(false, true, 350, true, true)
        DestroyCam(rdClothesCam, false)
        rdClothesCam = nil
    end
end

RDInvStopClothesCamera = rdStopClothesCamera

local function rdStartClothesCamera()
    rdStopClothesCamera()
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then return end

    rdOldHeading = GetEntityHeading(ped)
    ClearPedTasksImmediately(ped)
    FreezeEntityPosition(ped, true)

    -- Small clean idle pose so clothes view looks real.
    RequestAnimDict('amb@world_human_hang_out_street@male_c@base')
    local untilTime = GetGameTimer() + 800
    while not HasAnimDictLoaded('amb@world_human_hang_out_street@male_c@base') and GetGameTimer() < untilTime do Wait(0) end
    if HasAnimDictLoaded('amb@world_human_hang_out_street@male_c@base') then
        TaskPlayAnim(ped, 'amb@world_human_hang_out_street@male_c@base', 'base', 2.0, 2.0, -1, 1, 0.0, false, false, false)
    end

    local coords = GetEntityCoords(ped)
    local camCoords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.65, 0.82)
    rdClothesCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(rdClothesCam, camCoords.x, camCoords.y, camCoords.z)
    PointCamAtCoord(rdClothesCam, coords.x, coords.y, coords.z + 0.62)
    SetCamFov(rdClothesCam, 36.0)
    SetCamActive(rdClothesCam, true)
    RenderScriptCams(true, true, 350, true, true)
end

local rdClothesUiOpen = false
RegisterNUICallback('openClothesUI', function(_, cb)
    local c = (RDConfig and RDConfig.clothes) or {}
    if c.useDpClothing then
        -- dpclothing is merged inside RD_inventoryV3, so no separate ensure is needed.
        if RDInvClient and RDInvClient.closeInventory and c.closeInventoryWhenOpenDp ~= false then
            RDInvClient.closeInventory()
        else
            SetNuiFocus(false, false)
            SetNuiFocusKeepInput(false)
        end
        SetTimeout(180, function()
            TriggerEvent(c.dpEvent or 'dpc:ToggleMenu')
        end)
        cb(true)
        return
    end

    rdClothesUiOpen = true
    rdStartClothesCamera()
    SetNuiFocus(true, true)
    cb(true)
end)

RegisterNUICallback('closeClothesUI', function(data, cb)
    rdClothesUiOpen = false
    rdStopClothesCamera()
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    ClearPedTasks(ped)
    if data and data.keepFocus == false then
        SetNuiFocus(false, false)
    else
        SetNuiFocus(true, true)
    end
    cb(true)
end)


RegisterNUICallback('removeClothing', function(data, cb)
    TriggerServerEvent('rd_inventory:unequipClothingToInventory', data.type, data.name, data.toSlot)
    cb(true)
end)

-- RD CLOTHES FIX: real FiveM clothing equip/remove when item is USED from inventory.
-- The old code only showed a notification, so clothes disappeared from inventory but did not appear on the ped.
local RDClothesEquipped = RDClothesEquipped or {}

local function rdClampDrawable(ped, component, drawable)
    local max = GetNumberOfPedDrawableVariations(ped, component) or 0
    if max <= 0 then return 0 end
    drawable = tonumber(drawable) or 0
    if drawable >= max then drawable = max - 1 end
    if drawable < 0 then drawable = 0 end
    return drawable
end

local function rdClampTexture(ped, component, drawable, texture)
    local max = GetNumberOfPedTextureVariations(ped, component, drawable) or 0
    if max <= 0 then return 0 end
    texture = tonumber(texture) or 0
    if texture >= max then texture = max - 1 end
    if texture < 0 then texture = 0 end
    return texture
end

local function rdSetComponentSafe(ped, component, drawable, texture)
    drawable = rdClampDrawable(ped, component, drawable)
    texture = rdClampTexture(ped, component, drawable, texture or 0)
    SetPedComponentVariation(ped, component, drawable, texture, 2)
end

local function rdSetPropSafe(ped, prop, drawable, texture)
    local max = GetNumberOfPedPropDrawableVariations(ped, prop) or 0
    if max <= 0 then return end
    drawable = tonumber(drawable) or 0
    if drawable >= max then drawable = max - 1 end
    if drawable < 0 then drawable = 0 end
    local tmax = GetNumberOfPedPropTextureVariations(ped, prop, drawable) or 0
    texture = tonumber(texture) or 0
    if tmax > 0 and texture >= tmax then texture = tmax - 1 end
    if texture < 0 then texture = 0 end
    SetPedPropIndex(ped, prop, drawable, texture, true)
end

local function rdSaveCurrentClothing(ped, clothType)
    if RDClothesEquipped[clothType] then return end
    if clothType == 'hat' then
        RDClothesEquipped[clothType] = { prop = 0, drawable = GetPedPropIndex(ped, 0), texture = GetPedPropTextureIndex(ped, 0) }
    elseif clothType == 'mask' then
        RDClothesEquipped[clothType] = { comp = 1, drawable = GetPedDrawableVariation(ped, 1), texture = GetPedTextureVariation(ped, 1) }
    elseif clothType == 'shirt' then
        RDClothesEquipped[clothType] = {
            top = { drawable = GetPedDrawableVariation(ped, 11), texture = GetPedTextureVariation(ped, 11) },
            undershirt = { drawable = GetPedDrawableVariation(ped, 8), texture = GetPedTextureVariation(ped, 8) },
            arms = { drawable = GetPedDrawableVariation(ped, 3), texture = GetPedTextureVariation(ped, 3) }
        }
    elseif clothType == 'gloves' then
        RDClothesEquipped[clothType] = { comp = 3, drawable = GetPedDrawableVariation(ped, 3), texture = GetPedTextureVariation(ped, 3) }
    elseif clothType == 'pants' then
        RDClothesEquipped[clothType] = { comp = 4, drawable = GetPedDrawableVariation(ped, 4), texture = GetPedTextureVariation(ped, 4) }
    elseif clothType == 'shoes' then
        RDClothesEquipped[clothType] = { comp = 6, drawable = GetPedDrawableVariation(ped, 6), texture = GetPedTextureVariation(ped, 6) }
    elseif clothType == 'jacket' then
        RDClothesEquipped[clothType] = { comp = 11, drawable = GetPedDrawableVariation(ped, 11), texture = GetPedTextureVariation(ped, 11) }
    elseif clothType == 'bag' then
        RDClothesEquipped[clothType] = { comp = 5, drawable = GetPedDrawableVariation(ped, 5), texture = GetPedTextureVariation(ped, 5) }
    elseif clothType == 'chain' then
        RDClothesEquipped[clothType] = { comp = 7, drawable = GetPedDrawableVariation(ped, 7), texture = GetPedTextureVariation(ped, 7) }
    elseif clothType == 'glasses' then
        RDClothesEquipped[clothType] = { prop = 1, drawable = GetPedPropIndex(ped, 1), texture = GetPedPropTextureIndex(ped, 1) }
    elseif clothType == 'earrings' then
        RDClothesEquipped[clothType] = { prop = 2, drawable = GetPedPropIndex(ped, 2), texture = GetPedPropTextureIndex(ped, 2) }
    elseif clothType == 'watch' then
        RDClothesEquipped[clothType] = { prop = 6, drawable = GetPedPropIndex(ped, 6), texture = GetPedPropTextureIndex(ped, 6) }
    end
end

local function rdApplyClothing(clothType)
    local ped = PlayerPedId()
    rdSaveCurrentClothing(ped, clothType)

    -- Safe visible default clothes. Values are clamped so they do not break custom peds.
    if clothType == 'hat' then
        rdSetPropSafe(ped, 0, 5, 0)
    elseif clothType == 'mask' then
        rdSetComponentSafe(ped, 1, 1, 0)
    elseif clothType == 'shirt' then
        rdSetComponentSafe(ped, 3, 0, 0)   -- arms
        rdSetComponentSafe(ped, 8, 15, 0)  -- undershirt
        rdSetComponentSafe(ped, 11, 4, 0)  -- top/jacket
    elseif clothType == 'gloves' then
        rdSetComponentSafe(ped, 3, 15, 0)
    elseif clothType == 'pants' then
        rdSetComponentSafe(ped, 4, 4, 0)
    elseif clothType == 'shoes' then
        rdSetComponentSafe(ped, 6, 1, 0)
    elseif clothType == 'jacket' then
        rdSetComponentSafe(ped, 11, 4, 0)
    elseif clothType == 'bag' then
        rdSetComponentSafe(ped, 5, 1, 0)
    elseif clothType == 'chain' then
        rdSetComponentSafe(ped, 7, 1, 0)
    elseif clothType == 'glasses' then
        rdSetPropSafe(ped, 1, 1, 0)
    elseif clothType == 'earrings' then
        rdSetPropSafe(ped, 2, 1, 0)
    elseif clothType == 'watch' then
        rdSetPropSafe(ped, 6, 1, 0)
    end
end

local function rdRestoreClothing(clothType)
    local ped = PlayerPedId()
    local old = RDClothesEquipped[clothType]

    if clothType == 'hat' then
        if old and old.drawable and old.drawable >= 0 then
            rdSetPropSafe(ped, 0, old.drawable, old.texture or 0)
        else
            ClearPedProp(ped, 0)
        end
    elseif (clothType == 'glasses' or clothType == 'earrings' or clothType == 'watch') then
        local prop = clothType == 'glasses' and 1 or clothType == 'earrings' and 2 or 6
        if old and old.drawable and old.drawable >= 0 then
            rdSetPropSafe(ped, prop, old.drawable, old.texture or 0)
        else
            ClearPedProp(ped, prop)
        end
    elseif clothType == 'shirt' and old then
        rdSetComponentSafe(ped, 11, old.top and old.top.drawable or 15, old.top and old.top.texture or 0)
        rdSetComponentSafe(ped, 8, old.undershirt and old.undershirt.drawable or 15, old.undershirt and old.undershirt.texture or 0)
        rdSetComponentSafe(ped, 3, old.arms and old.arms.drawable or 15, old.arms and old.arms.texture or 0)
    elseif old and old.comp then
        rdSetComponentSafe(ped, old.comp, old.drawable or 0, old.texture or 0)
    else
        -- fallback naked/default remove
        if clothType == 'mask' then rdSetComponentSafe(ped, 1, 0, 0) end
        if clothType == 'gloves' then rdSetComponentSafe(ped, 3, 15, 0) end
        if clothType == 'pants' then rdSetComponentSafe(ped, 4, 14, 0) end
        if clothType == 'shoes' then rdSetComponentSafe(ped, 6, 34, 0) end
        if clothType == 'jacket' then rdSetComponentSafe(ped, 11, 15, 0) end
        if clothType == 'bag' then rdSetComponentSafe(ped, 5, 0, 0) end
        if clothType == 'chain' then rdSetComponentSafe(ped, 7, 0, 0) end
    end

    RDClothesEquipped[clothType] = nil
end


RegisterNetEvent('rd_inventory:client:clothesSync', function(items)
    SendNUIMessage({ action = 'clothSync', items = items or {} })
end)

RegisterNetEvent('rd_inventory:client:equipClothing', function(clothType, itemName)
    if not clothType then return end
    rdApplyClothing(clothType)
    RDUtils.notify(('Equipped %s'):format(clothType or itemName), 'success')
end)

RegisterNetEvent('rd_inventory:client:removeClothing', function(clothType)
    if not clothType then return end
    rdRestoreClothing(clothType)
    SendNUIMessage({ action = 'removeClothing', type = clothType })
    RDUtils.notify(('Removed %s'):format(clothType), 'inform')
end)

RegisterNetEvent('rd_inventory:notify', function(msg, typ)
    -- Single notification path only. Do not also send NUI toast, because that creates double notifications.
    RDUtils.notify(msg, typ or 'info')
end)

RegisterNetEvent('rd_inventory:itemNotify', function(data)
    data = data or {}
    SendNUIMessage({
        action = 'itemNotify',
        name = data.name,
        label = data.label or data.name or 'Item',
        count = tonumber(data.count) or 1,
        image = data.image or ((data.name or 'item') .. '.png'),
        type = data.type or 'add'
    })
end)


-- RD Shop payment result: close inventory, play realistic cash/card animation, then shopping bag prop.
local function rdLoadAnimDict(dict)
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do Wait(0) end
    return HasAnimDictLoaded(dict)
end

local function rdCreateHandProp(modelName, pos, rot, fallbackModel)
    local ped = PlayerPedId()
    local model = type(modelName) == 'number' and modelName or joaat(modelName)
    RequestModel(model)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do Wait(0) end
    if not HasModelLoaded(model) then return nil end
    local obj = CreateObject(model, GetEntityCoords(ped), true, true, false)
    pos = pos or vec3(0.12, 0.02, -0.02)
    rot = rot or vec3(0.0, 90.0, 0.0)
    AttachEntityToEntity(obj, ped, GetPedBoneIndex(ped, 57005), pos.x or 0.0, pos.y or 0.0, pos.z or 0.0, rot.x or 0.0, rot.y or 0.0, rot.z or 0.0, true, true, false, true, 1, true)
    return obj
end

local function rdPlayShopPayment(method, shopId)
    if RDShopsClient and RDShopsClient.playNpcPayment then
        CreateThread(function() RDShopsClient.playNpcPayment(shopId or (RDShopsClient and RDShopsClient.lastShopId), method) end)
    end
    local ped = PlayerPedId()
    local prop = nil

    if method == 'bank' then
        prop = rdCreateHandProp('prop_cs_credit_card', vec3(0.12, 0.03, -0.01), vec3(0.0, 90.0, 0.0))
        if rdLoadAnimDict('mp_common') then
            TaskPlayAnim(ped, 'mp_common', 'givetake1_a', 8.0, -8.0, 1700, 49, 0, false, false, false)
        end
        Wait(1700)
    else
        prop = rdCreateHandProp('prop_anim_cash_note', vec3(0.10, 0.03, -0.01), vec3(0.0, 90.0, 0.0))
        if rdLoadAnimDict('mp_common') then
            TaskPlayAnim(ped, 'mp_common', 'givetake1_a', 8.0, -8.0, 1700, 49, 0, false, false, false)
        end
        Wait(1700)
    end

    ClearPedTasks(ped)
    if prop and DoesEntityExist(prop) then DeleteEntity(prop) end

    local bag = rdCreateHandProp('prop_food_cb_bag_01', vec3(0.16, 0.02, -0.14), vec3(250.0, 90.0, 0.0), 'prop_food_bs_bag_01')
    if rdLoadAnimDict('move_weapon@jerrycan@generic') then
        TaskPlayAnim(ped, 'move_weapon@jerrycan@generic', 'idle', 5.0, -5.0, 3500, 49, 0, false, false, false)
    end
    Wait(3500)
    ClearPedTasks(ped)
    if bag and DoesEntityExist(bag) then DeleteEntity(bag) end
end

RegisterNetEvent('rd_inventory:shopPurchaseResult', function(success, method, price, shopId)
    if not success then return end
    SendNUIMessage({ action = 'forceClose' })
    RDInvClient.open = false
    SetNuiFocus(false, false)
    CreateThread(function()
        rdPlayShopPayment(method or 'cash', shopId)
    end)
end)

-- RD admin/helper open commands from server.
RegisterNetEvent('rd_inventory:client:openNearestTrunk', function()
    if RDInvClient.open then return end
    local veh = 0
    if rdGetClosestVehicleForTrunk then veh = rdGetClosestVehicleForTrunk() end
    if veh and veh ~= 0 then RDInvClient.openVehicleInventory('trunk', veh) end
end)

RegisterNetEvent('rd_inventory:client:openCurrentGlovebox', function()
    if RDInvClient.open then return end
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh and veh ~= 0 then RDInvClient.openVehicleInventory('glovebox', veh) end
end)

-- RD UPDATE: Clothes button closes inventory first, then opens merged dpclothing UI.
RegisterNUICallback('openDpClothingAndCloseInventory', function(_, cb)
    -- HARD FIX: CLOTHES button must close RD inventory and force-open dpclothing wheel.
    if RDInvStopClothesCamera then RDInvStopClothesCamera() end

    local ped = PlayerPedId()
    if DoesEntityExist(ped) then
        FreezeEntityPosition(ped, false)
        ClearPedTasks(ped)
    end

    -- Mark RD inventory closed locally first, otherwise dpclothing opens for 1 frame and gets closed.
    if RDInvClient then RDInvClient.open = false end

    SendNUIMessage({ action = 'forceClose' })
    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    TriggerServerEvent('rd_inventory:closeInventory')

    cb(true)

    CreateThread(function()
        Wait(220)
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        -- This event is added inside merged dpclothing and forces the wheel open reliably.
        TriggerEvent('dpc:RDInventoryOpen')
    end)
end)

-- =========================================================
-- RD_inventory client exports for phone/inventory bridges
-- =========================================================
exports('GetPlayerItems', function()
    if lib and lib.callback then
        return lib.callback.await('RD_inventory:getItems', false) or {}
    end
    return {}
end)

exports('getItems', function()
    if lib and lib.callback then
        return lib.callback.await('RD_inventory:getItems', false) or {}
    end
    return {}
end)

exports('HasItem', function(itemName, amount)
    amount = tonumber(amount) or 1
    if lib and lib.callback then
        return lib.callback.await('RD_inventory:hasItem', false, itemName, amount) == true
    end
    return false
end)
