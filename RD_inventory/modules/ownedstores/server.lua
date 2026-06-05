RDOwnedStores = RDOwnedStores or {}
RDOwnedStores.cache = RDOwnedStores.cache or {}

local function ident(src)
    return (RDUtils and RDUtils.identifier and RDUtils.identifier(src)) or (RDBridge and RDBridge.getIdentifier and RDBridge.getIdentifier(src)) or tostring(src)
end

local function ensureTable()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS rd_owned_stores (
            id INT NOT NULL AUTO_INCREMENT,
            owner VARCHAR(100) NOT NULL,
            label VARCHAR(80) NOT NULL,
            x DOUBLE NOT NULL,
            y DOUBLE NOT NULL,
            z DOUBLE NOT NULL,
            h DOUBLE NOT NULL DEFAULT 0,
            stash_id VARCHAR(100) NOT NULL,
            income INT NOT NULL DEFAULT 0,
            slots INT NOT NULL DEFAULT 10,
            max_weight INT NOT NULL DEFAULT 20000,
            buy_orders LONGTEXT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            UNIQUE KEY stash_id (stash_id)
        )
    ]])
    pcall(function() MySQL.query.await('ALTER TABLE rd_owned_stores ADD COLUMN slots INT NOT NULL DEFAULT 10') end)
    pcall(function() MySQL.query.await('ALTER TABLE rd_owned_stores ADD COLUMN max_weight INT NOT NULL DEFAULT 20000') end)
    pcall(function() MySQL.query.await('ALTER TABLE rd_owned_stores ADD COLUMN buy_orders LONGTEXT NULL') end)
end

local function rowToStore(r)
    if not r then return nil end
    return {
        id = tonumber(r.id), owner = r.owner, label = r.label,
        coords = { x = tonumber(r.x), y = tonumber(r.y), z = tonumber(r.z), h = tonumber(r.h) or 0.0 },
        stashId = r.stash_id, income = tonumber(r.income) or 0, slots = tonumber(r.slots) or 10, maxWeight = tonumber(r.max_weight) or 20000, buyOrders = json.decode(r.buy_orders or '[]') or {}
    }
end

function RDOwnedStores.reload()
    ensureTable()
    local rows = MySQL.query.await('SELECT * FROM rd_owned_stores', {}) or {}
    RDOwnedStores.cache = {}
    for _, r in ipairs(rows) do
        local st = rowToStore(r)
        if st then RDOwnedStores.cache[tostring(st.id)] = st end
    end
    return RDOwnedStores.cache
end

function RDOwnedStores.get(id)
    id = tostring(id or '')
    return RDOwnedStores.cache[id]
end

function RDOwnedStores.isOwner(src, idOrStash)
    local owner = ident(src)
    idOrStash = tostring(idOrStash or '')
    for _, st in pairs(RDOwnedStores.cache or {}) do
        if (tostring(st.id) == idOrStash or tostring(st.stashId) == idOrStash) and st.owner == owner then
            return true, st
        end
    end
    return false, nil
end

function RDOwnedStores.canAccessStock(src, stashId)
    local ok = RDOwnedStores.isOwner(src, stashId)
    return ok
end

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    SetTimeout(1500, function()
        RDOwnedStores.reload()
        TriggerClientEvent('RD_STORES:client:syncStores', -1, RDOwnedStores.cache)
        print(('[RD_inventory] owned stores loaded: %s'):format(#(MySQL.query.await('SELECT id FROM rd_owned_stores', {}) or {})))
    end)
end)

lib.callback.register('RD_STORES:server:getStores', function(src)
    if not next(RDOwnedStores.cache or {}) then RDOwnedStores.reload() end
    return RDOwnedStores.cache
end)

RegisterNetEvent('RD_STORES:server:createStore', function(label, coords)
    local src = source
    label = tostring(label or 'Owned Store'):sub(1, 70)
    coords = coords or {}
    if not RDInv.removeItem(src, 'general_store_license', 1) then
        TriggerClientEvent('rd_inventory:notify', src, 'Nuk ke General Store License', 'error')
        return
    end
    ensureTable()
    local owner = ident(src)
    local x, y, z, h = tonumber(coords.x), tonumber(coords.y), tonumber(coords.z), tonumber(coords.h) or 0.0
    if not x or not y or not z then return end
    local stashId = ('ownedstore:%s:%s'):format(owner:gsub('[^%w]', ''), os.time())
    local id = MySQL.insert.await('INSERT INTO rd_owned_stores (owner,label,x,y,z,h,stash_id) VALUES (?,?,?,?,?,?,?)', { owner, label, x, y, z, h, stashId })
    local inv = RDInv.getStashInv(stashId)
    inv.label = label .. ' STOCK'
    inv.slots = 10
    inv.maxWeight = 20000
    RDInv.saveStash(stashId)
    RDOwnedStores.reload()
    TriggerClientEvent('RD_STORES:client:syncStores', -1, RDOwnedStores.cache)
    TriggerClientEvent('rd_inventory:notify', src, ('Store u krijua: %s'):format(label), 'success')
end)

RegisterNetEvent('RD_STORES:server:openStock', function(storeId)
    local src = source
    local ok, st = RDOwnedStores.isOwner(src, storeId)
    if not ok then
        TriggerClientEvent('rd_inventory:notify', src, 'Vetem owner hap stock', 'error')
        return
    end
    TriggerClientEvent('rd_inventory:client:openStash', src, st.stashId, st.label .. ' STOCK')
end)

RegisterNetEvent('RD_STORES:server:setPrice', function(storeId, slot, price)
    local src = source
    local ok, st = RDOwnedStores.isOwner(src, storeId)
    if not ok then return end
    slot, price = tonumber(slot), math.max(1, math.floor(tonumber(price) or 1))
    local stash = RDInv.getStashInv(st.stashId)
    for _, it in ipairs(stash.items or {}) do
        if tonumber(it.slot) == slot then
            it.metadata = it.metadata or {}
            it.metadata.price = price
            RDInv.saveStash(st.stashId)
            TriggerClientEvent('rd_inventory:notify', src, ('Cmimi u vendos: $%s'):format(price), 'success')
            return
        end
    end
    TriggerClientEvent('rd_inventory:notify', src, 'Slot bosh ne stock', 'error')
end)

lib.callback.register('RD_STORES:server:getShopItems', function(src, storeId)
    local st = RDOwnedStores.get(storeId)
    if not st then return nil end
    local stash = RDInv.getStashInv(st.stashId)
    local items = {}
    for _, it in ipairs(stash.items or {}) do
        local def = RDItems[it.name] or {}
        items[#items+1] = {
            slot = it.slot, name = it.name, count = it.count or 1,
            label = def.label or it.name,
            price = tonumber(it.metadata and it.metadata.price) or tonumber(def.price) or 10,
            image = def.image or (it.name .. '.png'),
            description = def.description or ''
        }
    end
    return { id = st.id, label = st.label, items = items, slots = tonumber(st.slots) or 10, maxWeight = tonumber(st.maxWeight) or 20000, income = tonumber(st.income) or 0, buyOrders = st.buyOrders or {} }
end)

RegisterNetEvent('RD_STORES:server:buyItem', function(storeId, name, count, fromSlot, toSlot, payMethod)
    local src = source
    local st = RDOwnedStores.get(storeId)
    if not st then return end
    count = math.max(1, tonumber(count) or 1)
    payMethod = tostring(payMethod or 'cash'):lower(); if payMethod ~= 'bank' then payMethod = 'cash' end
    local stash = RDInv.getStashInv(st.stashId)
    local stockItem, unitPrice
    for _, it in ipairs(stash.items or {}) do
        if tonumber(it.slot) == tonumber(fromSlot) and it.name == name then
            stockItem = it
            unitPrice = tonumber(it.metadata and it.metadata.price) or tonumber(RDItems[name] and RDItems[name].price) or 10
            break
        end
    end
    if not stockItem or (tonumber(stockItem.count) or 1) < count then
        TriggerClientEvent('rd_inventory:notify', src, 'Stock nuk mjafton', 'error')
        return
    end
    local total = unitPrice * count
    if RDBridge.getMoney(src, payMethod) < total then
        TriggerClientEvent('rd_inventory:notify', src, 'Nuk ke mjaftueshem para', 'error')
        return
    end
    if not RDBridge.removeMoney(src, total, payMethod) then return end
    local ok = RDInv.addItem(src, name, count, stockItem.metadata or {}, tonumber(toSlot))
    if not ok then
        RDBridge.addMoney(src, total, payMethod)
        TriggerClientEvent('rd_inventory:notify', src, 'Inventory full', 'error')
        return
    end
    local remaining = count
    for i = #stash.items, 1, -1 do
        local it = stash.items[i]
        if it.name == name and tonumber(it.slot) == tonumber(fromSlot) then
            local c = tonumber(it.count) or 1
            if c > remaining then
                it.count = c - remaining
                remaining = 0
            else
                table.remove(stash.items, i)
                remaining = remaining - c
            end
            break
        end
    end
    RDInv.saveStash(st.stashId)
    MySQL.update.await('UPDATE rd_owned_stores SET income = income + ? WHERE id = ?', { total, st.id })
    RDInv.save(src)
    TriggerClientEvent('rd_inventory:notify', src, ('Bleve %sx %s per $%s'):format(count, name, total), 'success')
end)



lib.callback.register('RD_STORES:server:isOwner', function(src, storeId)
    local ok, st = RDOwnedStores.isOwner(src, storeId)
    return ok, st and { income = st.income or 0, slots = st.slots or 10, maxWeight = st.maxWeight or 20000, buyOrders = st.buyOrders or {} } or nil
end)

RegisterNetEvent('RD_STORES:server:withdrawIncome', function(storeId)
    local src = source
    local ok, st = RDOwnedStores.isOwner(src, storeId)
    if not ok then return end
    RDOwnedStores.reload(); st = RDOwnedStores.get(storeId)
    local amount = tonumber(st and st.income) or 0
    if amount <= 0 then TriggerClientEvent('rd_inventory:notify', src, 'Nuk ka lek per te terhequr', 'error') return end
    MySQL.update.await('UPDATE rd_owned_stores SET income = 0 WHERE id = ?', { st.id })
    RDBridge.addMoney(src, amount, 'cash')
    RDOwnedStores.reload()
    TriggerClientEvent('RD_STORES:client:syncStores', -1, RDOwnedStores.cache)
    TriggerClientEvent('rd_inventory:notify', src, ('More $%s nga shitjet'):format(amount), 'success')
end)

RegisterNetEvent('RD_STORES:server:upgradeSlots', function(storeId)
    local src = source
    local ok, st = RDOwnedStores.isOwner(src, storeId)
    if not ok then return end
    local slots = tonumber(st.slots) or 10
    if slots >= 200 then TriggerClientEvent('rd_inventory:notify', src, 'Slotet jane max 200', 'error') return end
    local add, cost = 10, 2500 + math.max(0, (slots - 10)) * 250
    if RDBridge.getMoney(src, 'cash') < cost then TriggerClientEvent('rd_inventory:notify', src, ('Duhen $%s cash'):format(cost), 'error') return end
    if not RDBridge.removeMoney(src, cost, 'cash') then return end
    local newSlots = math.min(200, slots + add)
    MySQL.update.await('UPDATE rd_owned_stores SET slots = ? WHERE id = ?', { newSlots, st.id })
    local inv = RDInv.getStashInv(st.stashId); inv.slots = newSlots; RDInv.saveStash(st.stashId)
    RDOwnedStores.reload(); TriggerClientEvent('RD_STORES:client:syncStores', -1, RDOwnedStores.cache)
    TriggerClientEvent('rd_inventory:notify', src, ('Stock slots u bene %s'):format(newSlots), 'success')
end)

RegisterNetEvent('RD_STORES:server:upgradeWeight', function(storeId)
    local src = source
    local ok, st = RDOwnedStores.isOwner(src, storeId)
    if not ok then return end
    local weight = tonumber(st.maxWeight) or 20000
    if weight >= 200000 then TriggerClientEvent('rd_inventory:notify', src, 'KG eshte max 200kg', 'error') return end
    local add, cost = 10000, 3000 + math.floor((weight - 20000) / 10000) * 2000
    if RDBridge.getMoney(src, 'cash') < cost then TriggerClientEvent('rd_inventory:notify', src, ('Duhen $%s cash'):format(cost), 'error') return end
    if not RDBridge.removeMoney(src, cost, 'cash') then return end
    local newWeight = math.min(200000, weight + add)
    MySQL.update.await('UPDATE rd_owned_stores SET max_weight = ? WHERE id = ?', { newWeight, st.id })
    local inv = RDInv.getStashInv(st.stashId); inv.maxWeight = newWeight; RDInv.saveStash(st.stashId)
    RDOwnedStores.reload(); TriggerClientEvent('RD_STORES:client:syncStores', -1, RDOwnedStores.cache)
    TriggerClientEvent('rd_inventory:notify', src, ('Stock kg u be %skg'):format(math.floor(newWeight/1000)), 'success')
end)

RegisterNetEvent('RD_STORES:server:addBuyOrder', function(storeId, itemName, price, maxCount)
    local src = source
    local ok, st = RDOwnedStores.isOwner(src, storeId)
    if not ok then return end
    itemName = tostring(itemName or ''):lower(); price = math.floor(tonumber(price) or 0); maxCount = math.floor(tonumber(maxCount) or 0)
    if itemName == '' or price < 1 or maxCount < 1 then TriggerClientEvent('rd_inventory:notify', src, 'Te dhena gabim', 'error') return end
    local orders = st.buyOrders or {}
    orders[#orders+1] = { name = itemName, price = price, max = maxCount }
    MySQL.update.await('UPDATE rd_owned_stores SET buy_orders = ? WHERE id = ?', { json.encode(orders), st.id })
    RDOwnedStores.reload(); TriggerClientEvent('RD_STORES:client:syncStores', -1, RDOwnedStores.cache)
    TriggerClientEvent('rd_inventory:notify', src, ('Kerkese blerje: %s $%s'):format(itemName, price), 'success')
end)

RegisterNetEvent('RD_STORES:server:sellToStore', function(storeId, orderIndex, count)
    local src = source
    local st = RDOwnedStores.get(storeId); if not st then return end
    orderIndex = tonumber(orderIndex); count = math.max(1, tonumber(count) or 1)
    local order = (st.buyOrders or {})[orderIndex]; if not order then return end
    count = math.min(count, tonumber(order.max) or count)
    if not RDInv.removeItem(src, order.name, count) then TriggerClientEvent('rd_inventory:notify', src, 'Nuk ke item per sell', 'error') return end
    local total = count * (tonumber(order.price) or 1)
    RDBridge.addMoney(src, total, 'cash')
    RDInv.save(src)
    order.max = (tonumber(order.max) or 0) - count
    local orders = st.buyOrders or {}
    if order.max <= 0 then table.remove(orders, orderIndex) end
    MySQL.update.await('UPDATE rd_owned_stores SET buy_orders = ? WHERE id = ?', { json.encode(orders), st.id })
    local stash = RDInv.getStashInv(st.stashId)
    local added = false
    for _, it in ipairs(stash.items or {}) do
        if it.name == order.name and json.encode(it.metadata or {}) == '{}' then
            it.count = (tonumber(it.count) or 0) + count
            added = true
            break
        end
    end
    if not added then
        stash.items = stash.items or {}
        local used = {}; for _, it in ipairs(stash.items) do used[tonumber(it.slot)] = true end
        local slot = 1; while used[slot] and slot <= (tonumber(stash.slots) or 80) do slot = slot + 1 end
        stash.items[#stash.items+1] = { name = order.name, count = count, slot = slot, metadata = {} }
    end
    RDInv.saveStash(st.stashId)
    RDOwnedStores.reload(); TriggerClientEvent('RD_STORES:client:syncStores', -1, RDOwnedStores.cache)
    TriggerClientEvent('rd_inventory:notify', src, ('Shite %sx %s per $%s'):format(count, order.name, total), 'success')
end)

-- Usable license direct fallback, even if item client.event is not used.
CreateThread(function()
    Wait(2000)
    if RDInv and RDInv.usableCallbacks then
        RDInv.usableCallbacks['general_store_license'] = function(src)
            TriggerClientEvent('RD_STORES:client:useLicense', src)
        end
    end
end)
