
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

RDShopsClient = RDShopsClient or {}
RDShopsClient.peds = {}
RDShopsClient.props = {}
RDShopsClient.zones = {}
RDShopsClient.blips = {}
RDShopsClient.list = {}

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



local function drawShop3DText(coords, text)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if not onScreen then return end
    SetTextScale(0.34, 0.34)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 230)
    SetTextCentre(true)
    SetTextDropshadow(0, 0, 0, 0, 180)
    SetTextEdge(2, 0, 0, 0, 180)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

function RDShopsClient.playNpcPayment(shopId, method)
    local ped = RDShopsClient.peds and RDShopsClient.peds[tostring(shopId or RDShopsClient.lastShopId or '')]
    if not ped or not DoesEntityExist(ped) then
        local player = PlayerPedId()
        local pc = GetEntityCoords(player)
        local best, bestDist = nil, 3.5
        for _, p in pairs(RDShopsClient.peds or {}) do
            if DoesEntityExist(p) then
                local d = #(pc - GetEntityCoords(p))
                if d < bestDist then best, bestDist = p, d end
            end
        end
        ped = best
    end
    if not ped or not DoesEntityExist(ped) then return end

    local player = PlayerPedId()
    TaskTurnPedToFaceEntity(ped, player, 800)
    Wait(250)
    local dict = 'mp_common'
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 3000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do Wait(0) end
    if HasAnimDictLoaded(dict) then
        TaskPlayAnim(ped, dict, 'givetake1_b', 8.0, -8.0, 1800, 49, 0, false, false, false)
    end
end

local function getRawShops()
    return RDShops or RD.Shops or Shops or {}
end

local function buildShopList()
    local raw = getRawShops()
    local out = {}

    -- Supports ox_inventory style:
    -- General = { label='', items={}, locations={ vec3(...) } }
    -- Also supports RD style array: { { id='', coords=vec3(...) } }
    for key, shop in pairs(raw) do
        if type(shop) == 'table' then
            local locations = shop.locations or shop.coordsList or shop.points

            if locations and type(locations) == 'table' then
                for i, loc in ipairs(locations) do
                    local coords = vec3from(loc)
                    if coords then
                        out[#out + 1] = {
                            id = tostring(shop.id or key) .. '_' .. tostring(i),
                            group = tostring(shop.id or key),
                            label = shop.label or tostring(key),
                            coords = coords,
                            heading = headingFrom(loc, shop.heading or 0.0),
                            radius = shop.radius or 2.0,
                            items = shop.items or {},
                            slots = shop.slots or 25,
                            jobs = shop.jobs,
                            groups = shop.groups,
                            license = shop.license,
                            blip = shop.blip,
                            marker = shop.marker,
                            ped = shop.ped == false and false or (shop.ped or { enabled = true, model = shop.pedModel or 'mp_m_shopkeep_01', scenario = 'WORLD_HUMAN_STAND_IMPATIENT' }),
                            props = shop.props
                        }
                    end
                end
            else
                local coords = vec3from(shop.coords or shop.location)
                if coords then
                    out[#out + 1] = {
                        id = tostring(shop.id or key),
                        group = tostring(shop.group or key),
                        label = shop.label or tostring(key),
                        coords = coords,
                        heading = headingFrom(shop.coords or shop.location, shop.heading or 0.0),
                        radius = shop.radius or 2.0,
                        items = shop.items or {},
                        slots = shop.slots or 25,
                        jobs = shop.jobs,
                        groups = shop.groups,
                        license = shop.license,
                        blip = shop.blip,
                        marker = shop.marker,
                        ped = shop.ped == false and false or (shop.ped or { enabled = true, model = shop.pedModel or 'mp_m_shopkeep_01', scenario = 'WORLD_HUMAN_STAND_IMPATIENT' }),
                        props = shop.props
                    }
                end
            end
        end
    end

    table.sort(out, function(a, b) return a.id < b.id end)
    RDShopsClient.list = out
    return out
end

local function getShops()
    if not RDShopsClient.list or #RDShopsClient.list == 0 then
        return buildShopList()
    end
    return RDShopsClient.list
end

local function formatShopPlayerItems(inv, defs)
    local out = {}
    for _, it in ipairs((inv and inv.items) or {}) do
        local def = (defs and defs[it.name]) or {}
        out[#out + 1] = {
            slot = it.slot, name = it.name, label = def.label or it.label or it.name, count = it.count or 1,
            weight = def.weight or 0, image = def.image or (def.client and def.client.image) or it.image or (it.name .. '.png'),
            description = def.description or '', type = def.type, metadata = it.metadata or {}
        }
    end
    return out
end

local function loadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(hash) then
        if RD and RD.Debug then print('[RD_inventory] Invalid model:', tostring(model)) end
        hash = joaat('mp_m_shopkeep_01')
        if not IsModelInCdimage(hash) then return nil end
    end
    RequestModel(hash)
    local timeout = GetGameTimer() + 8000
    while not HasModelLoaded(hash) do
        Wait(10)
        if GetGameTimer() > timeout then
            if RD and RD.Debug then print('[RD_inventory] Model load timeout:', tostring(model)) end
            return nil
        end
    end
    return hash
end

local function canUseShop(shop)
    local pdata = nil
    if RD and RD.GetPlayerData then pdata = RD.GetPlayerData() end
    local jobName = pdata and pdata.job and (pdata.job.name or pdata.job.label)
    local grade = pdata and pdata.job and (pdata.job.grade or pdata.job.grade_level or 0) or 0

    if shop.jobs then
        local min = shop.jobs[jobName]
        if min == nil then return false end
        if tonumber(grade) < tonumber(min or 0) then return false end
    end
    return true
end

local function addOxTargetToPed(ped, shop)
    if not rdUseOxTarget() then return false end
    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'rd_inventory_shop_ped_' .. shop.id,
            icon = 'fa-solid fa-store',
            label = 'Open ' .. shop.label,
            distance = 2.5,
            canInteract = function()
                return canUseShop(shop)
            end,
            onSelect = function()
                RDShopsClient.openShop(shop.id)
            end
        }
    })
    return true
end

local function addQbTargetToPed(ped, shop)
    if not rdUseQbTarget() then return false end
    exports['qb-target']:AddTargetEntity(ped, {
        options = {
            {
                icon = 'fas fa-store',
                label = 'Open ' .. shop.label,
                action = function()
                    RDShopsClient.openShop(shop.id)
                end,
                canInteract = function()
                    return canUseShop(shop)
                end
            }
        },
        distance = 2.5
    })
    return true
end

local function addOxTargetZone(shop)
    if not rdUseOxTarget() then return false end
    exports.ox_target:addSphereZone({
        coords = shop.coords,
        radius = shop.radius or 2.0,
        debug = false,
        options = {
            {
                name = 'rd_inventory_shop_zone_' .. shop.id,
                icon = 'fa-solid fa-basket-shopping',
                label = 'Open ' .. shop.label,
                distance = 2.5,
                canInteract = function()
                    return canUseShop(shop)
                end,
                onSelect = function()
                    RDShopsClient.openShop(shop.id)
                end
            }
        }
    })
    return true
end

local function spawnShopPed(shop)
    if shop.ped == false or (type(shop.ped) == 'table' and shop.ped.enabled == false) then return false end

    local pedCfg = type(shop.ped) == 'table' and shop.ped or {}
    local pedCoords = pedCfg.coords or vec4(shop.coords.x, shop.coords.y, shop.coords.z, shop.heading or 0.0)
    local c3 = vec3from(pedCoords) or shop.coords
    local h = headingFrom(pedCoords, shop.heading or 0.0)
    local hash = loadModel(pedCfg.model or 'mp_m_shopkeep_01')
    if not hash then return false end

    local ped = CreatePed(4, hash, c3.x, c3.y, c3.z - 1.0, h, false, true)
    if not DoesEntityExist(ped) then
        if RD and RD.Debug then print('[RD_inventory] Failed to create shop ped:', shop.id) end
        return false
    end

    SetEntityAsMissionEntity(ped, true, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    SetEntityHeading(ped, h)

    if pedCfg.scenario then
        TaskStartScenarioInPlace(ped, pedCfg.scenario, 0, true)
    end

    RDShopsClient.peds[shop.id] = ped

    local targetOK = addOxTargetToPed(ped, shop)
    if not targetOK then addQbTargetToPed(ped, shop) end

    if RD and RD.Debug then print(('[RD_inventory] Shop ped spawned + target: %s at %.2f %.2f %.2f'):format(shop.id, c3.x, c3.y, c3.z)) end
    return true
end

local function spawnShopProps(shop)
    for _, prop in ipairs(shop.props or {}) do
        local hash = loadModel(prop.model)
        if hash then
            local c = prop.coords
            local c3 = vec3from(c)
            if c3 then
                local obj = CreateObject(hash, c3.x, c3.y, c3.z - 1.0, false, false, false)
                SetEntityHeading(obj, headingFrom(c, 0.0))
                FreezeEntityPosition(obj, true)
                SetEntityAsMissionEntity(obj, true, true)
                RDShopsClient.props[#RDShopsClient.props + 1] = obj
            end
        end
    end
end

local function createBlip(shop)
    if shop.blip and shop.blip.enabled == false then return end
    local blipCfg = shop.blip or {}
    local blip = AddBlipForCoord(shop.coords.x, shop.coords.y, shop.coords.z)
    SetBlipSprite(blip, blipCfg.sprite or 52)
    SetBlipColour(blip, blipCfg.colour or blipCfg.color or 2)
    SetBlipScale(blip, blipCfg.scale or 0.65)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(blipCfg.label or shop.label)
    EndTextCommandSetBlipName(blip)
    RDShopsClient.blips[shop.id] = blip
end

CreateThread(function()
    Wait(2000)
    local shops = buildShopList()
    if not shops or #shops == 0 then
        if RD and RD.Debug then print('[RD_inventory] ERROR: No shops loaded. Supports ox style shops.lua and RD style shops.lua.') end
        return
    end

    if RD and RD.Debug then print(('[RD_inventory] Loaded %s shop locations. ox_target=%s qb-target=%s'):format(#shops, GetResourceState('ox_target'), GetResourceState('qb-target'))) end

    for _, shop in ipairs(shops) do
        local hasPed = spawnShopPed(shop)
        spawnShopProps(shop)
        createBlip(shop)
        if not hasPed then addOxTargetZone(shop) end
    end
end)

function RDShopsClient.openShop(shopId)
    RDShopsClient.lastShopId = tostring(shopId or '')
    local shop
    for _, s in ipairs(getShops()) do
        if s.id == shopId then shop = s break end
    end

    if not shop then
        notify('Shop not found: ' .. tostring(shopId))
        return
    end
    if not canUseShop(shop) then
        notify('You do not have access to this shop')
        return
    end

    local items = {}
    for i, item in ipairs(shop.items or {}) do
        local def = RDItems and RDItems[item.name] or {}
        items[#items + 1] = {
            slot = i,
            name = item.name,
            label = item.label or def.label or item.name,
            count = item.count or 1,
            price = item.price or 0,
            image = item.image or def.image or (def.client and def.client.image) or (item.name .. '.png'),
            description = def.description or '',
            license = item.license or shop.license
        }
    end

    local inv, defs = lib.callback.await('rd_inventory:getInventory', false)
    local uiSettings = lib.callback.await('rd_inventory:getUISettings', false)

    RDInvClient = RDInvClient or {}
    RDInvClient.items = defs or RDItems or {}
    RDInvClient.currentOther = {
        type = 'shop', label = shop.label, subtitle = 'Drag item to your inventory to buy', shopId = shop.id, items = items, slots = shop.slots or 25
    }
    RDInvClient.open = true

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openShop',
        shopId = shop.id,
        shopLabel = shop.label,
        shopItems = items,
        shopSlots = shop.slots or 25,
        playerItems = formatShopPlayerItems(inv or {}, defs or {}),
        hotbar = inv and inv.hotbar or {},
        maxWeight = inv and inv.maxWeight or RD.MaxWeight,
        slots = inv and inv.slots or RD.MaxSlots,
        uiSettings = uiSettings or {}
    })
end

-- TextUI / E key, only when config mode = 'textui'.
CreateThread(function()
    while true do
        if not rdUseTextUI() then
            Wait(1500)
        else
            local sleep = 1000
        local coords = GetEntityCoords(PlayerPedId())
        local showing = false
        for _, shop in ipairs(getShops()) do
            local dist = #(coords - shop.coords)
            if dist < 8.0 then
                sleep = 0
                if shop.marker ~= false then
                    DrawMarker(2, shop.coords.x, shop.coords.y, shop.coords.z + 0.25, 0,0,0, 0,0,0, 0.25,0.25,0.25, 255,30,30,180, false,true,2,false,nil,nil,false)
                end
                if dist < (shop.radius or 2.0) and canUseShop(shop) then
                    showing = true
                    drawShop3DText(vec3(shop.coords.x, shop.coords.y, shop.coords.z + 1.05), '~g~[E]~s~ ' .. shop.label)
                    if IsControlJustReleased(0, 38) then
                        RDShopsClient.openShop(shop.id)
                    end
                end
            end
        end
        if not showing and lib and lib.hideTextUI then lib.hideTextUI() end
            Wait(sleep)
        end
    end
end)

RegisterCommand('rd_shopdebug', function()
    buildShopList()
    if RD and RD.Debug then print('[RD_inventory] shop locations:', #RDShopsClient.list) end
    if RD and RD.Debug then print('[RD_inventory] ox_target:', GetResourceState('ox_target'), 'qb-target:', GetResourceState('qb-target')) end
    if RD and RD.Debug then print('[RD_inventory] RDShops exists:', RDShops ~= nil, 'RD.Shops exists:', RD and RD.Shops ~= nil) end
    for id, ped in pairs(RDShopsClient.peds or {}) do
        if RD and RD.Debug then print('[RD_inventory] ped', id, DoesEntityExist(ped), ped) end
    end
end)

RegisterCommand('rd_reloadshops', function()
    for _, ped in pairs(RDShopsClient.peds or {}) do if DoesEntityExist(ped) then DeleteEntity(ped) end end
    for _, blip in pairs(RDShopsClient.blips or {}) do if DoesBlipExist(blip) then RemoveBlip(blip) end end
    RDShopsClient.peds = {}; RDShopsClient.blips = {}; RDShopsClient.list = {}; buildShopList()
    for _, shop in ipairs(RDShopsClient.list) do local hasPed = spawnShopPed(shop); if not hasPed then addOxTargetZone(shop) end; createBlip(shop) end
    notify('RD shops reloaded', 'success')
end)
