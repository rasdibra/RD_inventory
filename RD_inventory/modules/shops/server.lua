RDShopsServer = RDShopsServer or {}

local function rdShopMetadata(name)
    local meta = {}
    local def = RDItems and RDItems[name]
    if type(name) == 'string' and (name:upper():find('WEAPON_', 1, true) == 1 or (def and type(def.weapon) == 'string')) then
        meta.ammo = tonumber((RDConfig and RDConfig.weapons and RDConfig.weapons.startAmmo) or 0) or 0
        meta.durability = 100
        meta.attachments = {}
    end
    return meta
end


local function getShops()
    return RDShops or RD.Shops or {}
end

local function findShop(shopId)
    local id = tostring(shopId or '')
    local group = id:gsub('_%d+$', '')

    for key, shop in pairs(getShops()) do
        if type(shop) == 'table' then
            local shopKey = tostring(shop.id or key)
            if id == shopKey or group == shopKey then
                return shop
            end
        end
    end
end

lib.callback.register('rd_inventory:getShop', function(src, shopId)
    return findShop(shopId), RDItems
end)

RegisterNetEvent('rd_inventory:buyItem', function(shopId, name, count, preferredSlot, payMethod)
    local src = source
    count = tonumber(count) or 1
    payMethod = tostring(payMethod or 'cash'):lower()
    if payMethod ~= 'bank' then payMethod = 'cash' end

    local shop = findShop(shopId)
    if not shop then return end

    local price
    for _, it in ipairs(shop.items or {}) do
        if it.name == name then
            price = (it.price or 0) * count
            break
        end
    end

    if not price then return end
    if not RDItems[name] then
        TriggerClientEvent('rd_inventory:notify', src, 'Item is not configured: ' .. tostring(name), 'error')
        return
    end

    if RDBridge.getMoney(src, payMethod) < price then
        TriggerClientEvent('rd_inventory:notify', src, ('Not enough %s'):format(payMethod), 'error')
        TriggerClientEvent('rd_inventory:shopPurchaseResult', src, false)
        return
    end

    if RDBridge.removeMoney(src, price, payMethod) then
        local ok = RDInv.addItem(src, name, count, rdShopMetadata(name), preferredSlot)
        if not ok then
            RDBridge.addMoney(src, price, payMethod)
            TriggerClientEvent('rd_inventory:notify', src, 'Inventory full', 'error')
            TriggerClientEvent('rd_inventory:shopPurchaseResult', src, false)
            return
        end
        TriggerClientEvent('rd_inventory:notify', src, ('Paid by %s: %sx %s'):format(payMethod, count, name), 'success')
        TriggerClientEvent('rd_inventory:shopPurchaseResult', src, true, payMethod, price, shopId)
    else
        TriggerClientEvent('rd_inventory:notify', src, ('Payment failed: %s'):format(payMethod), 'error')
        TriggerClientEvent('rd_inventory:shopPurchaseResult', src, false)
    end
end)
