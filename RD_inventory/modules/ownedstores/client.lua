
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

RDOwnedStoresClient = RDOwnedStoresClient or { stores = {}, peds = {}, zones = {} }

local function notify(msg, typ) TriggerEvent('rd_inventory:notify', msg, typ or 'info') end
local function isOwner(storeId)
    local ok, info = lib.callback.await('RD_STORES:server:isOwner', false, tostring(storeId))
    return ok, info or {}
end
local function v3(c) return vec3(tonumber(c.x), tonumber(c.y), tonumber(c.z)) end

local function loadModel(model)
    local hash = type(model) == 'number' and model or joaat(model or 'mp_m_shopkeep_01')
    if not IsModelInCdimage(hash) then hash = joaat('mp_m_shopkeep_01') end
    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(0) end
    if not HasModelLoaded(hash) then return nil end
    return hash
end

local function openStoreShop(storeId)
    local shop = lib.callback.await('RD_STORES:server:getShopItems', false, tostring(storeId))
    if not shop then return notify('Store nuk u gjet', 'error') end
    local inv, defs = lib.callback.await('rd_inventory:getInventory', false)
    local uiSettings = lib.callback.await('rd_inventory:getUISettings', false)
    RDInvClient = RDInvClient or {}
    RDInvClient.items = defs or RDItems or {}
    RDInvClient.currentOther = { type = 'ownedshop', label = shop.label, subtitle = 'Buy from owned store', shopId = tostring(storeId), items = shop.items or {}, slots = shop.slots or 10, maxWeight = shop.maxWeight or 20000 }
    RDInvClient.open = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openShop', shopId = tostring(storeId), shopLabel = shop.label, shopItems = shop.items or {}, shopSlots = shop.slots or 80,
        playerItems = (function()
            local out = {}
            for _, it in ipairs((inv and inv.items) or {}) do
                local def = (defs and defs[it.name]) or {}
                out[#out+1] = { slot=it.slot, name=it.name, label=def.label or it.name, count=it.count or 1, weight=def.weight or 0, image=def.image or (it.name..'.png'), description=def.description or '', metadata=it.metadata or {} }
            end
            return out
        end)(),
        hotbar = inv and inv.hotbar or {}, maxWeight = inv and inv.maxWeight or RD.MaxWeight, slots = inv and inv.slots or RD.MaxSlots, uiSettings = uiSettings or {}
    })
end

local function setPrice(storeId)
    local input = lib.inputDialog('Set Store Price', {
        { type = 'number', label = 'Stock slot', required = true, min = 1 },
        { type = 'number', label = 'Price $', required = true, min = 1 }
    })
    if not input then return end
    TriggerServerEvent('RD_STORES:server:setPrice', tostring(storeId), input[1], input[2])
end

local function openOwnerMenu(storeId)
    local ok, info = isOwner(storeId)
    if not ok then return notify('Vetem owner mund te hape Manage', 'error') end
    local income = tonumber(info.income) or 0
    local slots = tonumber(info.slots) or 80
    lib.registerContext({
        id = 'rd_owned_store_' .. tostring(storeId),
        title = 'Manage Store - $' .. income .. ' collected',
        options = {
            { title = 'Open Stock Inventory', description = 'Kur fut item ne stock del Amount + Price automatik', icon = 'box', onSelect = function() TriggerServerEvent('RD_STORES:server:openStock', tostring(storeId)) end },
            { title = 'Withdraw Store Money: $' .. income, description = 'Merr leket e mbledhura nga shitjet', icon = 'money-bill', onSelect = function() TriggerServerEvent('RD_STORES:server:withdrawIncome', tostring(storeId)) end },
            { title = 'Increase Stock Slots (' .. slots .. '/200)', description = 'Default 10 slots, paguan per +10 slots', icon = 'plus', onSelect = function() TriggerServerEvent('RD_STORES:server:upgradeSlots', tostring(storeId)) end },
            { title = 'Increase Stock KG (' .. math.floor((tonumber(info.maxWeight) or 20000)/1000) .. 'kg/200kg)', description = 'Default 20kg, paguan per +10kg', icon = 'weight-hanging', onSelect = function() TriggerServerEvent('RD_STORES:server:upgradeWeight', tostring(storeId)) end },
            { title = 'Add Buy Request / Sell Order', description = 'Owner kerkon te bleje item nga players', icon = 'cart-shopping', onSelect = function()
                local input = lib.inputDialog('Buy Request', {
                    { type='input', label='Item name (psh water)', required=true },
                    { type='number', label='Price per item $', required=true, min=1 },
                    { type='number', label='Max count', required=true, min=1 }
                })
                if input then TriggerServerEvent('RD_STORES:server:addBuyOrder', tostring(storeId), input[1], input[2], input[3]) end
            end },
            { title = 'Open Shop View', description = 'Shiko si klient', icon = 'store', onSelect = function() openStoreShop(storeId) end }
        }
    })
    lib.showContext('rd_owned_store_' .. tostring(storeId))
end

local function openSellMenu(storeId)
    local shop = lib.callback.await('RD_STORES:server:getShopItems', false, tostring(storeId))
    local opts = {}
    for i, o in ipairs((shop and shop.buyOrders) or {}) do
        opts[#opts+1] = { title = ('Sell %s'):format(o.name), description = ('Store pays $%s each | wants %s'):format(o.price, o.max), icon='hand-holding-dollar', onSelect=function()
            local input = lib.inputDialog('Sell to store', { { type='number', label='Amount', required=true, min=1, max=tonumber(o.max) or 9999 } })
            if input then TriggerServerEvent('RD_STORES:server:sellToStore', tostring(storeId), i, input[1]) end
        end }
    end
    if #opts == 0 then opts[1] = { title='No buy requests', description='Owner has not requested items yet', disabled=true } end
    lib.registerContext({ id='rd_owned_sell_'..tostring(storeId), title='Sell Items To Store', options=opts })
    lib.showContext('rd_owned_sell_'..tostring(storeId))
end

local function addTargets(st)
    local id = tostring(st.id)
    local coords = v3(st.coords)
    if not coords then return end
    if RDOwnedStoresClient.peds[id] and DoesEntityExist(RDOwnedStoresClient.peds[id]) then return end
    local hash = loadModel('mp_m_shopkeep_01')
    if hash then
        local ped = CreatePed(0, hash, coords.x, coords.y, coords.z - 1.0, tonumber(st.coords.h) or 0.0, false, true)
        if ped and ped ~= 0 then
            SetEntityInvincible(ped, true); FreezeEntityPosition(ped, true); SetBlockingOfNonTemporaryEvents(ped, true)
            TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_STAND_IMPATIENT', 0, true)
            RDOwnedStoresClient.peds[id] = ped
            if rdUseOxTarget() then
                exports.ox_target:addLocalEntity(ped, {
                    { name='rd_owned_buy_'..id, icon='fa-solid fa-store', label='Open Store', distance=2.5, onSelect=function() openStoreShop(id) end },
                    { name='rd_owned_sell_'..id, icon='fa-solid fa-hand-holding-dollar', label='Sell To Store', distance=2.5, onSelect=function() openSellMenu(id) end },
                    { name='rd_owned_stock_'..id, icon='fa-solid fa-boxes-stacked', label='Owner Manage', distance=2.5, canInteract=function() return isOwner(id) end, onSelect=function() openOwnerMenu(id) end }
                })
            elseif rdUseQbTarget() then
                exports['qb-target']:AddTargetEntity(ped, { options = {
                    { icon='fas fa-store', label='Open Store', action=function() openStoreShop(id) end },
                    { icon='fas fa-dollar-sign', label='Sell To Store', action=function() openSellMenu(id) end },
                    { icon='fas fa-box', label='Owner Manage', action=function() openOwnerMenu(id) end, canInteract=function() return isOwner(id) end }
                }, distance = 2.5 })
            end
        end
        SetModelAsNoLongerNeeded(hash)
    end
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 52); SetBlipColour(blip, 1); SetBlipScale(blip, 0.65); SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING'); AddTextComponentString(st.label or 'Owned Store'); EndTextCommandSetBlipName(blip)
end

local function syncStores(stores)
    RDOwnedStoresClient.stores = stores or {}
    for _, st in pairs(RDOwnedStoresClient.stores) do addTargets(st) end
end

RegisterNetEvent('RD_STORES:client:syncStores', syncStores)

RegisterNetEvent('RD_STORES:client:useLicense', function()
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)
    local input = lib.inputDialog('Create General Store', {
        { type = 'input', label = 'Store name', required = true, default = 'General Store' }
    })
    if not input then return end
    TriggerServerEvent('RD_STORES:server:createStore', input[1], { x = c.x, y = c.y, z = c.z, h = h })
end)

CreateThread(function()
    Wait(2500)
    local stores = lib.callback.await('RD_STORES:server:getStores', false) or {}
    syncStores(stores)
end)

-- TextUI / E key, only when config mode = 'textui'.
CreateThread(function()
    while true do
        if not rdUseTextUI() then
            Wait(1500)
        else
            local sleep = 1000
        local pc = GetEntityCoords(PlayerPedId())
        for _, st in pairs(RDOwnedStoresClient.stores or {}) do
            local coords = v3(st.coords)
            if coords then
                local d = #(pc - coords)
                if d < 8.0 then
                    sleep = 0
                    DrawMarker(2, coords.x, coords.y, coords.z + 0.25, 0,0,0, 0,0,0, 0.25,0.25,0.25, 255,30,30,180, false,true,2,false,nil,nil,false)
                    if d < 2.0 then
                        local owner = isOwner(tostring(st.id))
                        BeginTextCommandDisplayHelp('STRING'); AddTextComponentSubstringPlayerName(owner and 'Press ~r~E~s~ Store / ~r~H~s~ Sell / ~r~G~s~ Manage' or 'Press ~r~E~s~ Store / ~r~H~s~ Sell'); EndTextCommandDisplayHelp(0, false, true, -1)
                        if IsControlJustReleased(0, 38) then openStoreShop(tostring(st.id)) end
                        if IsControlJustReleased(0, 74) then openSellMenu(tostring(st.id)) end
                        if owner and IsControlJustReleased(0, 47) then openOwnerMenu(tostring(st.id)) end
                    end
                end
            end
        end
            Wait(sleep)
        end
    end
end)
