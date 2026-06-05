RDCraftingClient = RDCraftingClient or {}

local openBenchId = nil
local cam = nil
local frozen = false

local function notify(msg, typ)
    if RDUtils and RDUtils.notify then RDUtils.notify(msg, typ or 'info') else print('[RD Crafting] '..msg) end
end

local function loadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(10) end
    return hash
end

local function startCraftCamera()
    local ped = PlayerPedId()
    if frozen then return end
    frozen = true
    FreezeEntityPosition(ped, true)
    ClearPedTasks(ped)
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_CLIPBOARD', 0, true)
    local coords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(cam, coords.x + forward.x * 1.45, coords.y + forward.y * 1.45, coords.z + 0.72)
    PointCamAtCoord(cam, coords.x, coords.y, coords.z + 0.55)
    SetCamFov(cam, 46.0)
    RenderScriptCams(true, true, 350, true, true)
end

local function stopCraftCamera()
    local ped = PlayerPedId()
    if frozen then
        ClearPedTasks(ped)
        FreezeEntityPosition(ped, false)
    end
    frozen = false
    if cam then
        RenderScriptCams(false, true, 250, true, true)
        DestroyCam(cam, false)
        cam = nil
    end
end

local function canUseBench(bench)
    if not bench.jobs then return true end
    local ok = true
    -- Light client check only; server validates again if framework helper exists.
    return ok
end



-- Spawn real workbench props for crafting tables.
-- Configure each bench in data/crafting.lua with:
-- prop = { enabled=true, model='gr_prop_gr_bench_02a', offset=vec3(0,0,-1.0), placeOnGround=true, freeze=true }
local spawnedCraftProps = {}
RD.CraftPropsRegistered = false

local function requestCraftModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(hash) then
        print(('[RD Crafting] Missing/invalid prop model: %s'):format(tostring(model)))
        return nil
    end
    RequestModel(hash)
    local timeout = GetGameTimer() + 8000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(10) end
    if not HasModelLoaded(hash) then return nil end
    return hash
end

local function spawnCraftWorkbench(id, bench)
    if spawnedCraftProps[id] or not bench or not bench.coords or not bench.prop or bench.prop.enabled == false then return end
    local prop = bench.prop
    local hash = requestCraftModel(prop.model or 'gr_prop_gr_bench_02a')
    if not hash then return end
    local c = bench.coords
    local off = prop.offset or vec3(0.0, 0.0, 0.0)
    local obj = CreateObject(hash, c.x + off.x, c.y + off.y, c.z + off.z, false, false, false)
    SetEntityHeading(obj, c.w or prop.heading or 0.0)
    if prop.placeOnGround ~= false then PlaceObjectOnGroundProperly(obj) end
    FreezeEntityPosition(obj, prop.freeze ~= false)
    SetEntityAsMissionEntity(obj, true, true)
    spawnedCraftProps[id] = obj
    SetModelAsNoLongerNeeded(hash)

    if RD.Interaction and RD.Interaction.system == 'target' and GetResourceState('ox_target') == 'started' then
        exports.ox_target:addLocalEntity(obj, {{
            name = 'rd_craft_prop_' .. id,
            icon = 'fa-solid fa-gun',
            label = bench.label or 'Weapon Workbench',
            distance = bench.radius or 2.0,
            onSelect = function() RDCraftingClient.openBench(id) end
        }})
    end
end

CreateThread(function()
    Wait(1200)
    for id, bench in pairs(RDCrafting or {}) do
        spawnCraftWorkbench(id, bench)
    end
    RD.CraftPropsRegistered = true
end)

function RDCraftingClient.openBench(benchId)
    local bench = RDCrafting and RDCrafting[benchId]
    if not bench then return notify('Craft bench not found', 'error') end
    if not canUseBench(bench) then return notify('You cannot use this crafting table', 'error') end
    openBenchId = benchId
    local data = lib.callback.await('rd_inventory:crafting:getBenchData', false, benchId)
    if not data then return notify('Crafting data missing', 'error') end
    SetNuiFocus(true, true)
    startCraftCamera()
    SendNUIMessage({ action = 'openCraft', bench = data.bench, recipes = data.recipes, inventory = data.inventory, level = data.level, xp = data.xp, nextXp = data.nextXp })
end

RegisterNetEvent('rd_inventory:client:openCrafting', function(benchId) RDCraftingClient.openBench(benchId) end)

RegisterNUICallback('craftClose', function(_, cb)
    SetNuiFocus(false, false)
    stopCraftCamera()
    openBenchId = nil
    cb({ ok = true })
end)

RegisterNUICallback('craftStart', function(data, cb)
    if not openBenchId then cb({ ok = false }); return end
    local benchToCraft = openBenchId
    TriggerServerEvent('rd_inventory:crafting:craftRecipe', benchToCraft, data and data.recipeId)
    -- After the player presses CREATE and wins the small minigame, close the UI.
    SetNuiFocus(false, false)
    stopCraftCamera()
    openBenchId = nil
    SendNUIMessage({ action = 'forceCloseCraft' })
    cb({ ok = true })
end)

RegisterNetEvent('rd_inventory:crafting:update', function(payload)
    SendNUIMessage({ action = 'craftUpdate', inventory = payload.inventory, level = payload.level, xp = payload.xp, nextXp = payload.nextXp, recipeId = payload.recipeId })
end)

local craftingNow = false
local function playWorkbenchCraft(label, duration)
    if craftingNow then return end
    craftingNow = true
    duration = duration or 30000
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    ClearPedTasks(ped)
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_WELDING', 0, true)

    if lib and lib.progressBar then
        lib.progressBar({
            duration = duration,
            label = label or 'Crafting on workbench...',
            useWhileDead = false,
            canCancel = false,
            disable = { move = true, car = true, combat = true, mouse = false }
        })
    else
        local endTime = GetGameTimer() + duration
        while GetGameTimer() < endTime do
            Wait(0)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 30, true)
            DisableControlAction(0, 31, true)
            BeginTextCommandDisplayHelp('STRING')
            AddTextComponentSubstringPlayerName(('Crafting %s...'):format(label or 'item'))
            EndTextCommandDisplayHelp(0, false, true, 1)
        end
    end

    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)
    craftingNow = false
end

RegisterNetEvent('rd_inventory:crafting:progress', function(label, duration)
    CreateThread(function()
        playWorkbenchCraft(label, duration or 30000)
    end)
end)

CreateThread(function()
    Wait(1500)
    if RD.Interaction and RD.Interaction.system == 'target' and GetResourceState('ox_target') == 'started' then
        for id, craft in pairs(RDCrafting or {}) do
            if craft.coords and craft.target and not spawnedCraftProps[id] then
                exports.ox_target:addSphereZone({
                    coords = vec3(craft.coords.x, craft.coords.y, craft.coords.z),
                    radius = craft.radius or 2.0,
                    debug = false,
                    options = {{
                        name = 'rd_craft_ui_' .. id,
                        icon = 'fa-solid fa-screwdriver-wrench',
                        label = craft.label or 'Crafting Table',
                        distance = 2.5,
                        onSelect = function() RDCraftingClient.openBench(id) end
                    }}
                })
            end
        end
    end
end)

CreateThread(function()
    while true do
        local wait = 1000
        local ped = PlayerPedId()
        local p = GetEntityCoords(ped)
        for id, craft in pairs(RDCrafting or {}) do
            if craft.coords then
                local c = vec3(craft.coords.x, craft.coords.y, craft.coords.z)
                local dist = #(p - c)
                if dist < (craft.radius or 2.0) + 4.0 then
                    wait = 0
                    DrawMarker(2, c.x, c.y, c.z + 0.25, 0,0,0, 0,0,0, 0.25,0.25,0.25, 0,120,255,160, false,true,2,false,nil,nil,false)
                    if dist <= (craft.radius or 2.0) then
                        BeginTextCommandDisplayHelp('STRING')
                        AddTextComponentSubstringPlayerName(('Press ~INPUT_CONTEXT~ to open ~b~%s~s~'):format(craft.label or 'Crafting'))
                        EndTextCommandDisplayHelp(0, false, true, 1)
                        if IsControlJustReleased(0, 38) then RDCraftingClient.openBench(id) end
                    end
                end
            end
        end
        Wait(wait)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        stopCraftCamera()
        for _, obj in pairs(spawnedCraftProps) do if DoesEntityExist(obj) then DeleteEntity(obj) end end
    end
end)
