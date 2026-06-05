RDInv = RDInv or {}
RDInv.cache = {}
RDInv.sourceOwners = RDInv.sourceOwners or {}
RDInv.groundDrops = {}
RDInv.DropLifeSeconds = (RDConfig and RDConfig.drops and RDConfig.drops.lifeSeconds) or 300
RDInv.vehicleInventories = {}
RDInv.hotbars = {}

RDInv.stashes = RDInv.stashes or {}

local function normalizeSlot(slot)
    slot = tonumber(slot)
    if not slot or slot < 1 then return nil end
    return slot
end

local function getItemDef(name)
    return RDItems and RDItems[name]
end

local function moneyItemName()
    return (RDConfig and RDConfig.money and RDConfig.money.item) or 'money'
end

local function isMoneyItem(name)
    if not (RDConfig and RDConfig.money and RDConfig.money.asItem) then return false end
    if name == moneyItemName() then return true end
    for _, alias in ipairs(RDConfig.money.aliases or {}) do
        if name == alias then return true end
    end
    return false
end

local function applyInventoryLimits(inv)
    inv.slots = tonumber(inv.slots) or RD.MaxSlots or 40
    inv.maxWeight = tonumber(inv.maxWeight) or RD.MaxWeight or 50000
    if inv.slots < (RD.MaxSlots or inv.slots) then inv.slots = RD.MaxSlots end
    if inv.maxWeight < (RD.MaxWeight or inv.maxWeight) then inv.maxWeight = RD.MaxWeight end
    return inv
end

local function isStackable(name)
    local def = getItemDef(name)
    return def and def.stack == true
end

local function findFreeSlot(inv)
    local maxSlots = inv.slots or RD.MaxSlots or 40
    for s = 1, maxSlots do
        local used = false
        for _, item in ipairs(inv.items or {}) do
            if tonumber(item.slot) == s then used = true break end
        end
        if not used then return s end
    end
end



local function rdIsWeaponName(name)
    if type(name) ~= 'string' then return false end
    local upper = name:upper()
    local def = RDItems and RDItems[name]
    return upper:find('WEAPON_', 1, true) == 1 or (def and type(def.weapon) == 'string')
end

local function rdCreateMetadata(name, metadata)
    metadata = metadata or {}
    if rdIsWeaponName(name) then
        metadata.ammo = tonumber(metadata.ammo or (RDConfig and RDConfig.weapons and RDConfig.weapons.startAmmo) or 0) or 0
        metadata.durability = metadata.durability or 100
        metadata.attachments = metadata.attachments or {}
    end
    return metadata
end

local function addToInventoryTable(inv, name, count, metadata, preferredSlot)
    count = tonumber(count) or 1
    inv.items = inv.items or {}
    preferredSlot = normalizeSlot(preferredSlot)

    -- Stack first when no exact slot is requested.
    if isStackable(name) and not preferredSlot then
        for _, item in ipairs(inv.items) do
            if item.name == name then
                item.count = (item.count or 0) + count
                return true, item.slot
            end
        end
    end

    -- If dropped on a slot with the same stackable item, merge it.
    if preferredSlot then
        for _, item in ipairs(inv.items) do
            if tonumber(item.slot) == preferredSlot then
                if item.name == name and isStackable(name) then
                    item.count = (item.count or 0) + count
                    return true, preferredSlot
                end
                -- Ox style quality-of-life: if target slot is busy with another item,
                -- place the item in the next free slot instead of failing the drag/drop.
                preferredSlot = nil
                break
            end
        end
    end

    local slot = preferredSlot or findFreeSlot(inv)
    if not slot then return false, 'no_slot' end

    inv.items[#inv.items + 1] = { slot = slot, name = name, count = count, metadata = rdCreateMetadata(name, metadata) }
    return true, slot
end

local function removeFromInventoryTable(inv, name, count, slot)
    count = tonumber(count) or 1
    slot = normalizeSlot(slot)
    inv.items = inv.items or {}
    for i, item in ipairs(inv.items) do
        if item.name == name and (not slot or item.slot == slot) then
            if (item.count or 0) < count then return false end
            local removed = { slot = item.slot, name = item.name, count = count, metadata = item.metadata or {} }
            item.count = (item.count or 0) - count
            if item.count <= 0 then table.remove(inv.items, i) end
            return true, removed
        end
    end
    return false
end



-- RD exact drag/drop helpers: keeps items in the slot where the mouse drops them.
local function findItemBySlot(inv, slot)
    slot = normalizeSlot(slot)
    if not slot then return nil, nil end
    inv.items = inv.items or {}
    for i, item in ipairs(inv.items) do
        if tonumber(item.slot) == slot then return item, i end
    end
    return nil, nil
end

local function canCarryItem(inv, name, count, ignoreSlot)
    -- Existing resource has simple slot limits, so this protects slot count.
    inv.items = inv.items or {}
    local maxSlots = inv.slots or RD.MaxSlots or 40
    local used = 0
    for _, item in ipairs(inv.items) do
        if tonumber(item.slot) ~= tonumber(ignoreSlot) then used = used + 1 end
    end
    if isStackable(name) then
        for _, item in ipairs(inv.items) do
            if item.name == name and tonumber(item.slot) ~= tonumber(ignoreSlot) then return true end
        end
    end
    return used < maxSlots
end

local function addToExactSlotOrStack(inv, name, count, metadata, preferredSlot)
    preferredSlot = normalizeSlot(preferredSlot)
    if preferredSlot then
        local target = findItemBySlot(inv, preferredSlot)
        if target then
            if target.name == name and isStackable(name) then
                target.count = (target.count or 0) + (tonumber(count) or 1)
                return true, preferredSlot, 'stacked'
            end
            return false, 'occupied'
        end
    end
    return addToInventoryTable(inv, name, count, metadata, preferredSlot)
end

local function moveBetweenTablesExact(fromInv, toInv, name, count, fromSlot, toSlot)
    count = tonumber(count) or 1
    fromSlot, toSlot = normalizeSlot(fromSlot), normalizeSlot(toSlot)
    if not fromInv or not toInv or not name or count < 1 then return false, 'invalid' end

    local sourceItem = findItemBySlot(fromInv, fromSlot)
    if not sourceItem or sourceItem.name ~= name then return false, 'missing_source' end
    local sourceCount = sourceItem.count or 1
    if sourceCount < count then return false, 'not_enough' end

    local targetItem = findItemBySlot(toInv, toSlot)
    if targetItem and targetItem.name == name and isStackable(name) then
        local ok, removed = removeFromInventoryTable(fromInv, name, count, fromSlot)
        if not ok then return false, 'remove_failed' end
        targetItem.count = (targetItem.count or 0) + count
        return true, 'stacked', removed
    end

    if targetItem then
        local targetIndex
        _, targetIndex = findItemBySlot(toInv, toSlot)
        local sourceIndex
        _, sourceIndex = findItemBySlot(fromInv, fromSlot)
        if not targetIndex or not sourceIndex then return false, 'swap_failed' end

        -- If amount is smaller than the stack, split only that amount into the target slot
        -- and push the old target item to the first free slot in the destination inventory.
        if count < sourceCount then
            local freeSlot = nil
            local maxSlots = toInv.slots or RD.MaxSlots or 40
            for s = 1, maxSlots do
                if s ~= toSlot and not findItemBySlot(toInv, s) then freeSlot = s break end
            end
            if not freeSlot then return false, 'no_target_space' end
            targetItem.slot = freeSlot
            sourceItem.count = sourceCount - count
            toInv.items[#toInv.items + 1] = { slot = toSlot, name = sourceItem.name, count = count, metadata = sourceItem.metadata or {} }
            return true, 'split_replace'
        end

        -- Full amount/full stack on different item = normal slot swap.
        if not canCarryItem(fromInv, targetItem.name, targetItem.count or 1, fromSlot) then return false, 'no_source_space' end
        toInv.items[targetIndex] = { slot = toSlot, name = sourceItem.name, count = sourceItem.count or 1, metadata = sourceItem.metadata or {} }
        fromInv.items[sourceIndex] = { slot = fromSlot, name = targetItem.name, count = targetItem.count or 1, metadata = targetItem.metadata or {} }
        return true, 'swapped'
    end

    local ok, removed = removeFromInventoryTable(fromInv, name, count, fromSlot)
    if not ok then return false, 'remove_failed' end
    local added = addToExactSlotOrStack(toInv, name, count, removed.metadata or {}, toSlot)
    if not added then
        addToInventoryTable(fromInv, name, count, removed.metadata or {}, fromSlot)
        return false, 'add_failed'
    end
    return true, 'moved', removed
end
function RDInv.getStashInv(stashId, src)
    local realId, cfg = stashId, nil

    if RDStash and RDStash.resolveId and src then
        realId, cfg = RDStash.resolveId(src, stashId)
    elseif RDStash and RDStash.find then
        cfg = RDStash.find(stashId)
        realId = (cfg and cfg.id) or tostring(stashId or 'default')
    else
        local raw = RDStashes or (RD and RD.Stashes) or {}
        for key, s in pairs(raw) do
            if type(s) == 'table' then
                s.id = s.id or tostring(key)
                if s.id == stashId then cfg = s break end
            end
        end
        realId = (cfg and cfg.id) or tostring(stashId or 'default')
    end

    if not RDInv.stashes[realId] then
        local loaded = RDMySQL and RDMySQL.load and RDMySQL.load('stash:' .. tostring(realId)) or nil
        RDInv.stashes[realId] = loaded or {
            id = realId,
            baseId = tostring(stashId or realId),
            label = (cfg and cfg.label) or 'STASH',
            slots = (cfg and cfg.slots) or 50,
            maxWeight = (cfg and (cfg.maxWeight or cfg.weight)) or 100000,
            items = {}
        }
        RDInv.stashes[realId].id = realId
        RDInv.stashes[realId].baseId = tostring(stashId or realId)
        RDInv.stashes[realId].label = (cfg and cfg.label) or RDInv.stashes[realId].label or 'STASH'
        RDInv.stashes[realId].slots = (cfg and cfg.slots) or RDInv.stashes[realId].slots or 50
        RDInv.stashes[realId].maxWeight = (cfg and (cfg.maxWeight or cfg.weight)) or RDInv.stashes[realId].maxWeight or 100000
        RDInv.stashes[realId].items = RDInv.stashes[realId].items or {}
    end

    return RDInv.stashes[realId], realId, cfg
end

function RDInv.saveStash(stashId, src)
    local inv, realId = RDInv.getStashInv(stashId, src)
    if inv and RDMySQL and RDMySQL.save then
        RDMySQL.save('stash:' .. tostring(realId), inv)
    end
    if inv and RDStash and RDStash.save then RDStash.save(realId) end
end


local function defaultInventory()
    return {
        slots = RD.MaxSlots,
        maxWeight = RD.MaxWeight,
        hotbar = {},
        items = {
            { slot = 1, name = 'water', count = 3, metadata = {} },
            { slot = 2, name = 'bread', count = 2, metadata = {} }
        }
    }
end

local function makeDropId()
    return ('drop_%s_%s'):format(os.time(), math.random(1000, 9999))
end

function RDInv.getOwner(src)
    local owner = RDUtils.identifier(src)
    if not owner or owner == '' then owner = ('source:%s'):format(tostring(src)) end
    RDInv.sourceOwners[src] = owner
    return owner
end

function RDInv.get(src)
    local owner = RDInv.getOwner(src)
    if RDInv.cache[owner] then return RDInv.cache[owner] end
    local inv = applyInventoryLimits(RDMySQL.load(owner) or defaultInventory())
    inv.hotbar = inv.hotbar or {}
    RDInv.cache[owner] = inv
    return inv
end

function RDInv.save(src)
    local owner = RDInv.sourceOwners[src] or RDInv.getOwner(src)
    if owner and RDInv.cache[owner] then RDMySQL.save(owner, RDInv.cache[owner]) end
end

function RDInv.clearSource(src)
    RDInv.sourceOwners[src] = nil
end

function RDInv.nextSlot(inv)
    for s = 1, inv.slots or RD.MaxSlots do
        local used = false
        for _, item in ipairs(inv.items or {}) do
            if item.slot == s then used = true break end
        end
        if not used then return s end
    end
end

function RDInv.findSlot(inv, name)
    for i, item in ipairs(inv.items or {}) do
        if item.name == name and (RDItems[name] and RDItems[name].stack) then return i, item end
    end
end

local function cloneInventoryForClient(src, inv)
    local out = {
        slots = inv.slots,
        maxWeight = inv.maxWeight,
        hotbar = inv.hotbar or {},
        items = {}
    }

    for _, item in ipairs(inv.items or {}) do
        if not isMoneyItem(item.name) then
            out.items[#out.items + 1] = {
                slot = item.slot,
                name = item.name,
                count = item.count,
                metadata = item.metadata or {}
            }
        end
    end

    if RDConfig and RDConfig.money and RDConfig.money.asItem then
        local cash = tonumber(RDBridge.getMoney(src)) or 0
        if cash > 0 then
            local preferred = tonumber(RDConfig.money.preferredSlot) or 1
            local used = {}
            for _, item in ipairs(out.items) do used[item.slot] = true end
            local slot = preferred
            if used[slot] then
                slot = nil
                for s = 1, out.slots or RD.MaxSlots or 40 do
                    if not used[s] then slot = s break end
                end
            end
            if slot then
                out.items[#out.items + 1] = { slot = slot, name = moneyItemName(), count = cash, metadata = { account = 'cash' } }
            end
        end
    end

    return out
end

local function rdSendItemNotify(src, name, count, typ)
    if not src or src == 0 or not name then return end
    local def = RDItems and RDItems[name] or {}
    local label = def.label or name
    local image = def.image or (name .. '.png')
    TriggerClientEvent('rd_inventory:itemNotify', src, {
        name = name,
        label = label,
        count = tonumber(count) or 1,
        image = image,
        type = typ or 'add'
    })
end

function RDInv.addItem(src, name, count, metadata, preferredSlot)
    count = tonumber(count) or 1
    if not RDItems[name] then return false, 'Invalid item' end
    if isMoneyItem(name) then
        local ok = RDBridge.addMoney(src, count)
        if ok then
            TriggerClientEvent('rd_inventory:refresh', src, cloneInventoryForClient(src, RDInv.get(src)))
            rdSendItemNotify(src, name, count, 'add')
        end
        return ok
    end
    local inv = RDInv.get(src)
    local ok, err = addToInventoryTable(inv, name, count, metadata, preferredSlot)
    if not ok then return false, err end
    RDInv.save(src)
    TriggerClientEvent('rd_inventory:refresh', src, cloneInventoryForClient(src, inv))
    rdSendItemNotify(src, name, count, 'add')
    return true
end

function RDInv.removeItem(src, name, count, slot)
    count = tonumber(count) or 1
    if isMoneyItem(name) then
        local ok = RDBridge.removeMoney(src, count)
        if ok then TriggerClientEvent('rd_inventory:refresh', src, cloneInventoryForClient(src, RDInv.get(src))) end
        return ok, { slot = slot, name = name, count = count, metadata = { account = 'cash' } }
    end
    local inv = RDInv.get(src)
    local ok, removed = removeFromInventoryTable(inv, name, count, slot)
    if not ok then return false end
    RDInv.save(src)
    TriggerClientEvent('rd_inventory:refresh', src, cloneInventoryForClient(src, inv))
    return true, removed
end

function RDInv.getVehicleInv(plate, invType)
    local key = ("%s:%s"):format(invType or 'trunk', plate or 'UNKNOWN')
    RDInv.vehicleInventories[key] = RDInv.vehicleInventories[key] or {
        id = key,
        label = invType == 'glovebox' and 'Glovebox' or 'Trunk',
        slots = invType == 'glovebox' and ((RDConfig and RDConfig.vehicles and RDConfig.vehicles.gloveboxSlots) or 10) or ((RDConfig and RDConfig.vehicles and RDConfig.vehicles.trunkSlots) or 30),
        maxWeight = invType == 'glovebox' and ((RDConfig and RDConfig.vehicles and RDConfig.vehicles.gloveboxWeight) or 10000) or ((RDConfig and RDConfig.vehicles and RDConfig.vehicles.trunkWeight) or 60000),
        items = {}
    }
    return RDInv.vehicleInventories[key]
end

lib.callback.register('rd_inventory:getInventory', function(src)
    return cloneInventoryForClient(src, RDInv.get(src)), RDItems
end)


lib.callback.register('rd_inventory:getPlayerTargetInventory', function(src, targetId)
    targetId = tonumber(targetId)
    if not targetId or not GetPlayerName(targetId) then return nil, RDItems end
    local srcPed, targetPed = GetPlayerPed(src), GetPlayerPed(targetId)
    if not srcPed or not targetPed or srcPed == 0 or targetPed == 0 then return nil, RDItems end
    local dist = #(GetEntityCoords(srcPed) - GetEntityCoords(targetPed))
    local maxDist = (RDConfig and RDConfig.robbery and RDConfig.robbery.deadBody and RDConfig.robbery.deadBody.distance) or 2.5
    if dist > (maxDist + 1.0) then return nil, RDItems end
    return cloneInventoryForClient(targetId, RDInv.get(targetId)), RDItems
end)

lib.callback.register('rd_inventory:getGroundDrops', function(src)
    return RDInv.groundDrops, RDItems
end)

CreateThread(function()
    while true do
        Wait(30000)
        local now = os.time()
        local changed = false
        for dropId, drop in pairs(RDInv.groundDrops or {}) do
            if drop.expiresAt and drop.expiresAt <= now then
                RDInv.groundDrops[dropId] = nil
                changed = true
            end
        end
        if changed then
            TriggerClientEvent('rd_inventory:updateDrops', -1, RDInv.groundDrops)
        end
    end
end)

lib.callback.register('rd_inventory:getVehicleInventory', function(src, plate, invType)
    return RDInv.getVehicleInv(plate, invType), RDItems
end)

lib.callback.register('rd_inventory:getStashInventory', function(src, stashId)
    stashId = tostring(stashId or 'default')
    if stashId:find('^ownedstore:') and RDOwnedStores and RDOwnedStores.canAccessStock then
        if not RDOwnedStores.canAccessStock(src, stashId) then
            TriggerClientEvent('rd_inventory:notify', src, 'Vetem owner hap stock', 'error')
            return nil, RDItems
        end
    elseif RDStash and RDStash.canOpen then
        local ok, cfg, reason = RDStash.canOpen(src, stashId)
        if not ok then
            TriggerClientEvent('rd_inventory:notify', src, reason or 'No access to this stash', 'error')
            return nil, RDItems
        end
    end
    return RDInv.getStashInv(stashId, src), RDItems
end)

local function findShop(shopId)
    local raw = RDShops or RD.Shops or {}
    local id = tostring(shopId or '')
    local group = id:gsub('_%d+$', '')

    for key, shop in pairs(raw) do
        if type(shop) == 'table' then
            local shopKey = tostring(shop.id or key)
            if id == shopKey or group == shopKey then
                return shop
            end
        end
    end
end

local RDUsingItems = {}
local RDClothesEquippedServer = {}

local function rdHasItemInSlot(src, name, slot)
    local inv = RDInv.get(src)
    slot = tonumber(slot)
    for _, item in ipairs(inv.items or {}) do
        if item.name == name and (not slot or tonumber(item.slot) == slot) and (tonumber(item.count) or 1) > 0 then
            return true, item.slot
        end
    end
    return false, slot
end

RegisterNetEvent('rd_inventory:useItem', function(name, slot)
    local src = source
    local item = RDItems[name]
    if not item then return end
    local has, realSlot = rdHasItemInSlot(src, name, slot)
    if not has then return end
    RDUsingItems[src] = RDUsingItems[src] or {}
    if RDUsingItems[src][realSlot or name] then return end
    RDUsingItems[src][realSlot or name] = name
    TriggerClientEvent('rd_inventory:itemUseStart', src, name, item, realSlot)
end)

RegisterNetEvent('rd_inventory:useItemSlot', function(slot)
    local src = source
    slot = tonumber(slot)
    if not slot or slot < 1 or slot > (RD.HotbarSlots or 5) then return end
    local inv = RDInv.get(src)
    local found
    for _, item in ipairs(inv.items or {}) do
        if item.slot == slot then found = item break end
    end
    if not found then
        TriggerClientEvent('rd_inventory:notify', src, ('Hotbar %s is empty'):format(slot), 'error')
        return
    end
    local def = RDItems[found.name]
    if not def then return end
    RDUsingItems[src] = RDUsingItems[src] or {}
    if RDUsingItems[src][slot] then return end
    RDUsingItems[src][slot] = found.name
    TriggerClientEvent('rd_inventory:itemUseStart', src, found.name, def, slot)
end)


RegisterNetEvent('rd_inventory:clearUsingItem', function(slot, name)
    local src = source
    slot = tonumber(slot)
    local key = slot or name
    if RDUsingItems[src] then
        RDUsingItems[src][key] = nil
    end
end)


local function rdCallItemExport(exportString, src, itemName, itemDef, slot)
    if type(exportString) ~= 'string' or exportString == '' then return false end
    local resource, exportName = exportString:match('^([^%.]+)%.(.+)$')
    if not resource or not exportName then return false end
    local ok, err = pcall(function()
        return exports[resource][exportName](src, itemName, itemDef, slot)
    end)
    if not ok then
        print(('[RD_inventory] item export error %s: %s'):format(tostring(exportString), tostring(err)))
    end
    return ok
end

RegisterNetEvent('rd_inventory:finishUseItem', function(name, slot)
    local src = source
    slot = tonumber(slot)
    local key = slot or name
    if not RDUsingItems[src] or RDUsingItems[src][key] ~= name then return end
    RDUsingItems[src][key] = nil

    local item = RDItems[name]
    if not item then return end

    if RDInv.usableCallbacks and RDInv.usableCallbacks[name] then
        local ok, err = pcall(RDInv.usableCallbacks[name], src, item, slot)
        if not ok then print('[RD_inventory] usable item error '..tostring(name)..': '..tostring(err)) end
        return
    end

    if item.server and item.server.export then
        rdCallItemExport(item.server.export, src, name, item, slot)
        TriggerClientEvent('rd_inventory:itemUsed', src, name, item)
        return
    end

    if item.type then
        local clothType = tostring(item.type)
        local ok, removed = RDInv.removeItem(src, name, 1, slot)
        if not ok or not removed then
            TriggerClientEvent('rd_inventory:notify', src, 'Nuk e ke kete rrobe ne inventory', 'error')
            return
        end

        RDClothesEquippedServer[src] = RDClothesEquippedServer[src] or {}

        -- If player already has the same clothing category equipped, return the old exact item first.
        local old = RDClothesEquippedServer[src][clothType]
        if old and old.name and RDItems[old.name] then
            RDInv.addItem(src, old.name, old.count or 1, old.metadata or {}, old.slot)
        end

        -- Store the EXACT removed inventory item, including metadata/slot/name. No fake defaults.
        RDClothesEquippedServer[src][clothType] = {
            name = removed.name or name,
            count = removed.count or 1,
            metadata = removed.metadata or {},
            slot = removed.slot or tonumber(slot),
            label = item.label or name,
            image = item.image or ((removed.name or name) .. '.png'),
            type = clothType
        }

        local sendItem = table.clone and table.clone(item) or item
        sendItem.type = clothType
        sendItem.image = sendItem.image or ((removed.name or name) .. '.png')
        sendItem.metadata = removed.metadata or {}
        TriggerClientEvent('rd_inventory:itemUsed', src, removed.name or name, sendItem)
        return
    elseif item.consume and item.consume > 0 then
        if not RDInv.removeItem(src, name, item.consume, slot) then return end
    end

    TriggerClientEvent('rd_inventory:itemUsed', src, name, item)
end)

AddEventHandler('playerDropped', function()
    RDUsingItems[source] = nil
end)

local function rdCountItem(src, name)
    local inv = RDInv.get(src)
    local total = 0
    for _, item in ipairs(inv.items or {}) do
        if item.name == name then total = total + (tonumber(item.count) or 1) end
    end
    return total
end

RegisterNetEvent('rd_inventory:serverReloadWeapon', function(ammoItem, requestAmount)
    local src = source
    ammoItem = tostring(ammoItem or '')
    requestAmount = math.max(1, math.min(tonumber(requestAmount) or 1, tonumber((RDConfig and RDConfig.weapons and RDConfig.weapons.reloadAmount) or 12) or 12))
    if not RDItems[ammoItem] then return end
    local have = rdCountItem(src, ammoItem)
    if have <= 0 then
        TriggerClientEvent('rd_inventory:reloadResult', src, false, ammoItem, 0, 'No ammo')
        return
    end
    local take = math.min(have, requestAmount)
    local ok = RDInv.removeItem(src, ammoItem, take)
    if not ok then
        TriggerClientEvent('rd_inventory:reloadResult', src, false, ammoItem, 0, 'No ammo')
        return
    end
    TriggerClientEvent('rd_inventory:reloadResult', src, true, ammoItem, take)
end)

local function rdFindWeaponItem(inv, weaponName, weaponSlot)
    weaponName = tostring(weaponName or ''):upper()
    weaponSlot = tonumber(weaponSlot)
    for _, item in ipairs(inv.items or {}) do
        local def = RDItems and RDItems[item.name] or {}
        local w = tostring(def.weapon or def.hash or item.name or ''):upper()
        if w == weaponName and (not weaponSlot or tonumber(item.slot) == weaponSlot) then
            item.metadata = item.metadata or {}
            item.metadata.attachments = item.metadata.attachments or {}
            return item
        end
    end
end

RegisterNetEvent('rd_inventory:serverUseAttachment', function(itemName, weaponName, componentName, weaponSlot, attachmentSlot)
    local src = source
    itemName = tostring(itemName or '')
    weaponName = tostring(weaponName or ''):upper()
    componentName = tostring(componentName or '')
    if itemName == '' or weaponName == '' or componentName == '' or not RDItems[itemName] then return end

    local inv = RDInv.get(src)
    local weaponItem = rdFindWeaponItem(inv, weaponName, weaponSlot)
    if not weaponItem then
        TriggerClientEvent('rd_inventory:attachmentResult', src, false, itemName, weaponName, componentName, 'Hap armen nga inventory per attachment')
        return
    end
    if weaponItem.metadata.attachments[componentName] then
        TriggerClientEvent('rd_inventory:attachmentResult', src, false, itemName, weaponName, componentName, 'Ky slot ka attachment')
        return
    end

    local ok = RDInv.removeItem(src, itemName, 1, attachmentSlot)
    if not ok then
        TriggerClientEvent('rd_inventory:attachmentResult', src, false, itemName, weaponName, componentName, 'Missing attachment')
        return
    end

    inv = RDInv.get(src)
    weaponItem = rdFindWeaponItem(inv, weaponName, weaponSlot)
    if weaponItem then
        weaponItem.metadata.attachments[componentName] = itemName
        RDInv.save(src)
        TriggerClientEvent('rd_inventory:refresh', src, cloneInventoryForClient(src, inv))
    end
    TriggerClientEvent('rd_inventory:attachmentResult', src, true, itemName, weaponName, componentName, 'Attachment u vendos dhe u ruajt')
    TriggerClientEvent('rd_inventory:notify', src, 'Attachment u vendos dhe u ruajt', 'success')
end)

RegisterNetEvent('rd_inventory:serverReturnAttachment', function(itemName, weaponName, componentName)
    local src = source
    itemName = tostring(itemName or '')
    weaponName = tostring(weaponName or ''):upper()
    componentName = tostring(componentName or '')
    if itemName == '' or not RDItems[itemName] then return end

    local inv = RDInv.get(src)
    local weaponItem = rdFindWeaponItem(inv, weaponName, nil)
    local removed = false
    if weaponItem and weaponItem.metadata and weaponItem.metadata.attachments then
        if weaponItem.metadata.attachments[componentName] then
            weaponItem.metadata.attachments[componentName] = nil
            removed = true
        else
            -- fallback: remove by item name in case component name changed between updates
            for comp, attach in pairs(weaponItem.metadata.attachments) do
                if attach == itemName then
                    weaponItem.metadata.attachments[comp] = nil
                    removed = true
                    break
                end
            end
        end
        if removed then RDInv.save(src) end
    end
    if removed then
        RDInv.addItem(src, itemName, 1, {})
        inv = RDInv.get(src)
        TriggerClientEvent('rd_inventory:refresh', src, cloneInventoryForClient(src, inv))
        TriggerClientEvent('rd_inventory:notify', src, 'Attachment u hoq dhe u kthye ne inventory', 'success')
    else
        TriggerClientEvent('rd_inventory:notify', src, 'Attachment nuk u gjet ne kete arme', 'error')
    end
end)

RegisterNetEvent('rd_inventory:dropItem', function(name, count, slot, coords, dropId, toSlot)
    local src = source
    count = tonumber(count) or 1
    toSlot = tonumber(toSlot)
    if not name or count < 1 then return end

    local ok, item = RDInv.removeItem(src, name, count, slot)
    if not ok then return end

    local drop = dropId and RDInv.groundDrops[dropId]
    if not drop then
        dropId = makeDropId()
        drop = {
            id = dropId,
            coords = coords,
            createdAt = os.time(),
            expiresAt = os.time() + (RDInv.DropLifeSeconds or 300),
            prop = (RDConfig and RDConfig.drops and RDConfig.drops.prop) or 'prop_cs_heist_bag_02',
            slots = (RDConfig and RDConfig.drops and RDConfig.drops.slots) or 25,
            items = {}
        }
        RDInv.groundDrops[dropId] = drop
    else
        drop.expiresAt = os.time() + (RDInv.DropLifeSeconds or 300)
        drop.slots = drop.slots or ((RDConfig and RDConfig.drops and RDConfig.drops.slots) or 25)
    end

    local added = addToExactSlotOrStack(drop, name, count, item.metadata or {}, toSlot)
    if not added then
        RDInv.addItem(src, name, count, item.metadata or {}, slot)
        TriggerClientEvent('rd_inventory:notify', src, 'Drop slot is busy or full', 'error')
        return
    end

    TriggerClientEvent('rd_inventory:notify', src, ('Dropped %sx %s'):format(count, name), 'success')
    if RDLog and RDLog.send then RDLog.send('drop', src, { item = name, count = count, drop = dropId }) end
    TriggerClientEvent('rd_inventory:updateDrops', -1, RDInv.groundDrops)
    TriggerClientEvent('rd_inventory:refresh', src, cloneInventoryForClient(src, RDInv.get(src)))
end)

RegisterNetEvent('rd_inventory:pickupDrop', function(dropId, itemSlot, toSlot, count)
    local src = source
    local drop = RDInv.groundDrops[dropId]
    if not drop then return end
    itemSlot = tonumber(itemSlot or 1)
    count = tonumber(count) or 0

    for i, item in ipairs(drop.items or {}) do
        if tonumber(item.slot) == itemSlot then
            local takeCount = count > 0 and math.min(count, item.count or 1) or (item.count or 1)
            local inv = RDInv.get(src)
            local ok = addToExactSlotOrStack(inv, item.name, takeCount, item.metadata, tonumber(toSlot))
            if ok then
                item.count = (item.count or 1) - takeCount
                if item.count <= 0 then table.remove(drop.items, i) end
                if #(drop.items or {}) <= 0 then RDInv.groundDrops[dropId] = nil end
                RDInv.save(src)
                TriggerClientEvent('rd_inventory:updateDrops', -1, RDInv.groundDrops)
                TriggerClientEvent('rd_inventory:notify', src, ('Picked up %sx %s'):format(takeCount, item.name), 'success')
                if RDLog and RDLog.send then RDLog.send('pickup', src, { item = item.name, count = takeCount, drop = dropId }) end
                TriggerClientEvent('rd_inventory:refresh', src, cloneInventoryForClient(src, inv))
            else
                TriggerClientEvent('rd_inventory:notify', src, 'That inventory slot is busy', 'error')
            end
            return
        end
    end
end)


RegisterNetEvent('rd_inventory:giveItem', function(target, name, count, slot)
    local src = source
    target = tonumber(target)
    count = tonumber(count) or 1
    slot = tonumber(slot)
    if not target or target == src or not name or count < 1 then return end

    local srcPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(target)
    if not srcPed or not targetPed or srcPed == 0 or targetPed == 0 then return end
    local dist = #(GetEntityCoords(srcPed) - GetEntityCoords(targetPed))
    if dist > 3.5 then
        TriggerClientEvent('rd_inventory:notify', src, 'Player too far', 'error')
        return
    end

    local ok, removed = RDInv.removeItem(src, name, count, slot)
    if not ok then return end
    local added = RDInv.addItem(target, name, count, removed.metadata)
    if not added then
        RDInv.addItem(src, name, count, removed.metadata, slot)
        TriggerClientEvent('rd_inventory:notify', src, 'Target inventory full', 'error')
        return
    end

    TriggerClientEvent('rd_inventory:notify', src, ('Gave %sx %s'):format(count, name), 'success')
    TriggerClientEvent('rd_inventory:notify', target, ('Received %sx %s'):format(count, name), 'success')
    if RDLog and RDLog.send then RDLog.send('give', src, { target = tostring(target), item = name, count = count }) end
end)

local function moveInsideInventoryByAmount(inv, fromSlot, toSlot, count, expectedName)
    fromSlot, toSlot = normalizeSlot(fromSlot), normalizeSlot(toSlot)
    count = tonumber(count) or 1
    if not inv or not fromSlot or not toSlot or count < 1 or fromSlot == toSlot then return false, 'invalid' end

    local fromItem, fromIndex = findItemBySlot(inv, fromSlot)
    local toItem, toIndex = findItemBySlot(inv, toSlot)
    if not fromItem then return false, 'missing_source' end
    if expectedName and fromItem.name ~= expectedName then return false, 'wrong_item' end

    local sourceCount = tonumber(fromItem.count) or 1
    if sourceCount < count then return false, 'not_enough' end

    -- Same stackable item: only move the amount box value.
    if toItem and toItem.name == fromItem.name and isStackable(fromItem.name) then
        fromItem.count = sourceCount - count
        toItem.count = (tonumber(toItem.count) or 1) + count
        if fromItem.count <= 0 then table.remove(inv.items, fromIndex) end
        return true, 'stacked'
    end

    -- Empty target slot: split stack if amount is smaller, otherwise move the whole slot.
    if not toItem then
        if count < sourceCount then
            fromItem.count = sourceCount - count
            inv.items[#inv.items + 1] = { slot = toSlot, name = fromItem.name, count = count, metadata = fromItem.metadata or {} }
        else
            fromItem.slot = toSlot
        end
        return true, 'moved'
    end

    -- Different item in target slot. Full stack = normal swap. Partial stack = put selected amount
    -- into target slot and push the old target item to the first free slot, so nothing is lost/glitched.
    if count >= sourceCount then
        toItem.slot = fromSlot
        fromItem.slot = toSlot
        return true, 'swapped'
    end

    local freeSlot = nil
    local maxSlots = inv.slots or RD.MaxSlots or 40
    for s = 1, maxSlots do
        if s ~= fromSlot and s ~= toSlot and not findItemBySlot(inv, s) then freeSlot = s break end
    end
    if not freeSlot then return false, 'no_free_slot' end

    toItem.slot = freeSlot
    fromItem.count = sourceCount - count
    inv.items[#inv.items + 1] = { slot = toSlot, name = fromItem.name, count = count, metadata = fromItem.metadata or {} }
    return true, 'split_replace'
end

RegisterNetEvent('rd_inventory:moveItem', function(fromSlot, toSlot, count, name)
    local src = source
    local inv = RDInv.get(src)
    local ok, reason = moveInsideInventoryByAmount(inv, fromSlot, toSlot, count, name)
    if not ok then
        TriggerClientEvent('rd_inventory:notify', src, reason == 'no_free_slot' and 'No free slot to move the old item' or 'Cannot move item there', 'error')
        return
    end
    RDInv.save(src)
    TriggerClientEvent('rd_inventory:notify', src, 'Item moved', 'success')
    TriggerClientEvent('rd_inventory:refresh', src, cloneInventoryForClient(src, inv))
end)

RegisterNetEvent('rd_inventory:moveBetweenInventories', function(data)
    local src = source
    data = data or {}
    local fromType = data.fromType
    local toType = data.toType
    local name = data.name
    local count = tonumber(data.count) or 1
    local fromSlot = tonumber(data.fromSlot)
    local toSlot = tonumber(data.toSlot)

    if not name or count < 1 then return end



    -- Buying from owned player store by drag/drop: ownedshop -> player.
    if fromType == 'ownedshop' and toType == 'player' then
        local st = RDOwnedStores and RDOwnedStores.get and RDOwnedStores.get(data.shopId)
        if not st then return end
        local stash = RDInv.getStashInv(st.stashId)
        local stockItem, unitPrice
        for _, it in ipairs(stash.items or {}) do
            if tonumber(it.slot) == tonumber(fromSlot) and it.name == name then
                stockItem = it
                unitPrice = tonumber(it.metadata and it.metadata.price) or tonumber(RDItems[name] and RDItems[name].price) or 10
                break
            end
        end
        if not stockItem or (tonumber(stockItem.count) or 1) < count then TriggerClientEvent('rd_inventory:notify', src, 'Stock nuk mjafton', 'error') return end
        local total = unitPrice * count
        local payMethod = tostring(data.payMethod or data.method or 'cash'):lower(); if payMethod ~= 'bank' then payMethod = 'cash' end
        if RDBridge.getMoney(src, payMethod) < total then TriggerClientEvent('rd_inventory:notify', src, 'Nuk ke mjaftueshem para', 'error') return end
        local inv = RDInv.get(src)
        if not RDBridge.removeMoney(src, total, payMethod) then return end
        local ok = addToExactSlotOrStack(inv, name, count, stockItem.metadata or {}, toSlot)
        if not ok then RDBridge.addMoney(src, total, payMethod); TriggerClientEvent('rd_inventory:notify', src, 'That slot is busy', 'error') return end
        stockItem.count = (tonumber(stockItem.count) or 1) - count
        if stockItem.count <= 0 then
            for i=#stash.items,1,-1 do if stash.items[i] == stockItem then table.remove(stash.items, i) break end end
        end
        RDInv.save(src); RDInv.saveStash(st.stashId)
        MySQL.update.await('UPDATE rd_owned_stores SET income = income + ? WHERE id = ?', { total, st.id })
        TriggerClientEvent('rd_inventory:notify', src, ('Bleve %sx %s per $%s'):format(count, name, total), 'success')
        TriggerClientEvent('rd_inventory:refresh', src, cloneInventoryForClient(src, inv))
        return
    end

    -- Buying from shop by drag/drop: shop -> exact player slot.
    if fromType == 'shop' and toType == 'player' then
        local payMethod = tostring(data.payMethod or data.method or 'cash'):lower()
        if payMethod ~= 'bank' then payMethod = 'cash' end
        local shop = findShop(data.shopId)
        if not shop then return end
        local price
        for _, it in ipairs(shop.items or {}) do
            if it.name == name then price = (it.price or 0) * count break end
        end
        if not price then return end
        if RDBridge.getMoney(src, payMethod) < price then
            TriggerClientEvent('rd_inventory:notify', src, ('Not enough %s'):format(payMethod), 'error')
            TriggerClientEvent('rd_inventory:shopPurchaseResult', src, false)
            return
        end
        if not RDItems[name] then
            TriggerClientEvent('rd_inventory:notify', src, 'Item is not configured: ' .. tostring(name), 'error')
            TriggerClientEvent('rd_inventory:shopPurchaseResult', src, false)
            return
        end
        local inv = RDInv.get(src)
        if RDBridge.removeMoney(src, price, payMethod) then
            local ok = addToExactSlotOrStack(inv, name, count, rdCreateMetadata(name, nil), toSlot)
            if not ok then
                RDBridge.addMoney(src, price, payMethod)
                TriggerClientEvent('rd_inventory:notify', src, 'That slot is busy', 'error')
                TriggerClientEvent('rd_inventory:shopPurchaseResult', src, false)
                return
            end
            RDInv.save(src)
            TriggerClientEvent('rd_inventory:notify', src, ('Paid by %s: %sx %s'):format(payMethod, count, name), 'success')
            TriggerClientEvent('rd_inventory:refresh', src, cloneInventoryForClient(src, inv))
            TriggerClientEvent('rd_inventory:shopPurchaseResult', src, true, payMethod, price, data.shopId)
        end
        return
    end

    local function getOtherInv(invType)
        if invType == 'trunk' or invType == 'glovebox' then
            return RDInv.getVehicleInv(data.plate, data.vehicleType or invType)
        elseif invType == 'stash' then
            return RDInv.getStashInv(data.stashId or data.id or 'default', src)
        end
        return nil
    end

    if (fromType == 'stash' or toType == 'stash') then
        local sid = tostring(data.stashId or data.id or 'default')
        if sid:find('^ownedstore:') and RDOwnedStores and RDOwnedStores.canAccessStock then
            if not RDOwnedStores.canAccessStock(src, sid) then
                TriggerClientEvent('rd_inventory:notify', src, 'Vetem owner hap stock', 'error')
                return
            end
        elseif RDStash and RDStash.canOpen then
            local ok, cfg, reason = RDStash.canOpen(src, sid)
            if not ok then
                TriggerClientEvent('rd_inventory:notify', src, reason or 'No access to this stash', 'error')
                return
            end
        end
    end

    local playerInv = RDInv.get(src)

    if (fromType == 'playerTarget' or toType == 'playerTarget') then
        local targetId = tonumber(data.targetId)
        if not targetId or not GetPlayerName(targetId) or targetId == src then return end
        local srcPed, targetPed = GetPlayerPed(src), GetPlayerPed(targetId)
        if not srcPed or not targetPed or srcPed == 0 or targetPed == 0 then return end
        local dist = #(GetEntityCoords(srcPed) - GetEntityCoords(targetPed))
        local maxDist = (RDConfig and RDConfig.robbery and RDConfig.robbery.deadBody and RDConfig.robbery.deadBody.distance) or 2.5
        if dist > (maxDist + 1.0) then
            TriggerClientEvent('rd_inventory:notify', src, 'Player too far', 'error')
            return
        end

        local targetInv = RDInv.get(targetId)
        local ok, reason
        if fromType == 'playerTarget' and toType == 'player' then
            ok, reason = moveBetweenTablesExact(targetInv, playerInv, name, count, fromSlot, toSlot)
        elseif fromType == 'player' and toType == 'playerTarget' then
            ok, reason = moveBetweenTablesExact(playerInv, targetInv, name, count, fromSlot, toSlot)
        else
            return
        end
        if not ok then
            TriggerClientEvent('rd_inventory:notify', src, 'Cannot move item', 'error')
            return
        end
        RDInv.save(src)
        RDInv.save(targetId)
        TriggerClientEvent('rd_inventory:refresh', src, cloneInventoryForClient(src, playerInv))
        TriggerClientEvent('rd_inventory:refresh', targetId, cloneInventoryForClient(targetId, targetInv))
        if RDLog and RDLog.send then RDLog.send('rob_player', src, { target = tostring(targetId), item = tostring(name), count = tostring(count) }) end
        return
    end

    if fromType == 'player' and (toType == 'trunk' or toType == 'glovebox' or toType == 'stash') then
        local other = getOtherInv(toType)
        if not other then return end
        local ok, reason = moveBetweenTablesExact(playerInv, other, name, count, fromSlot, toSlot)
        if not ok then
            TriggerClientEvent('rd_inventory:notify', src, 'Cannot move item there', 'error')
            return
        end
        -- Owned Store stock: vendos cmimin tek item-i qe sapo u fut ne stock.
        if toType == 'stash' and tostring(data.stashId or data.id or ''):find('^ownedstore:') then
            local price = math.max(1, math.floor(tonumber(data.price) or tonumber(RDItems[name] and RDItems[name].price) or 10))
            local target = findItemBySlot(other, toSlot)
            if target and target.name == name then
                target.metadata = target.metadata or {}
                target.metadata.price = price
            end
        end
        RDInv.save(src)
        if toType == 'stash' then RDInv.saveStash(data.stashId or data.id or 'default', src) end
        local label = toType == 'stash' and 'stash' or (toType == 'glovebox' and 'glovebox' or 'trunk')
        TriggerClientEvent('rd_inventory:notify', src, ('Stored %sx %s in %s'):format(count, name, label), 'success')

    elseif (fromType == 'trunk' or fromType == 'glovebox' or fromType == 'stash') and toType == 'player' then
        local other = getOtherInv(fromType)
        if not other then return end
        local ok, reason = moveBetweenTablesExact(other, playerInv, name, count, fromSlot, toSlot)
        if not ok then
            TriggerClientEvent('rd_inventory:notify', src, 'Cannot move item there', 'error')
            return
        end
        RDInv.save(src)
        if fromType == 'stash' then RDInv.saveStash(data.stashId or data.id or 'default', src) end
        local label = fromType == 'stash' and 'stash' or (fromType == 'glovebox' and 'glovebox' or 'trunk')
        TriggerClientEvent('rd_inventory:notify', src, ('Took %sx %s from %s'):format(count, name, label), 'success')
    end

    TriggerClientEvent('rd_inventory:refresh', src, cloneInventoryForClient(src, playerInv))
end)


RegisterNetEvent('rd_inventory:moveOtherItem', function(data)
    local src = source
    data = data or {}
    local invType = data.invType
    local fromSlot, toSlot = tonumber(data.fromSlot), tonumber(data.toSlot)
    if not invType or not fromSlot or not toSlot then return end

    if invType == 'stash' then
        local sid = tostring(data.stashId or 'default')
        if sid:find('^ownedstore:') and RDOwnedStores and RDOwnedStores.canAccessStock then
            if not RDOwnedStores.canAccessStock(src, sid) then
                TriggerClientEvent('rd_inventory:notify', src, 'Vetem owner hap stock', 'error')
                return
            end
        elseif RDStash and RDStash.canOpen then
            local ok, cfg, reason = RDStash.canOpen(src, sid)
            if not ok then
                TriggerClientEvent('rd_inventory:notify', src, reason or 'No access to this stash', 'error')
                return
            end
        end
    end

    local inv
    if invType == 'trunk' or invType == 'glovebox' then
        inv = RDInv.getVehicleInv(data.plate, data.vehicleType or invType)
    elseif invType == 'stash' then
        inv = RDInv.getStashInv(data.stashId or 'default', src)
    else
        return
    end

    local fromItem, toItem
    for _, item in ipairs(inv.items or {}) do
        if item.slot == fromSlot then fromItem = item end
        if item.slot == toSlot then toItem = item end
    end
    if not fromItem then return end
    if toItem then toItem.slot = fromSlot end
    fromItem.slot = toSlot
    if invType == 'stash' then RDInv.saveStash(data.stashId or 'default', src) end
    TriggerClientEvent('rd_inventory:notify', src, 'Storage slot moved', 'success')
    TriggerClientEvent('rd_inventory:refresh', src, cloneInventoryForClient(src, RDInv.get(src)))
end)


RegisterNetEvent('rd_inventory:moveGroundItem', function(data)
    local src = source
    data = data or {}
    local dropId = data.dropId
    local fromSlot, toSlot = tonumber(data.fromSlot), tonumber(data.toSlot)
    if not dropId or not fromSlot or not toSlot then return end
    local drop = RDInv.groundDrops[dropId]
    if not drop then return end

    local fromItem, toItem
    for _, item in ipairs(drop.items or {}) do
        if tonumber(item.slot) == fromSlot then fromItem = item end
        if tonumber(item.slot) == toSlot then toItem = item end
    end
    if not fromItem then return end
    if toItem then toItem.slot = fromSlot end
    fromItem.slot = toSlot
    drop.expiresAt = os.time() + (RDInv.DropLifeSeconds or 300)
    TriggerClientEvent('rd_inventory:notify', src, 'Drop slot moved', 'success')
    TriggerClientEvent('rd_inventory:updateDrops', -1, RDInv.groundDrops)
end)


RegisterNetEvent('rd_inventory:requestClothesSync', function()
    local src = source
    local equipped = RDClothesEquippedServer[src] or {}
    local list = {}
    for ctype, worn in pairs(equipped) do
        if worn and worn.name and RDItems[worn.name] then
            list[#list + 1] = {
                name = worn.name,
                count = worn.count or 1,
                metadata = worn.metadata or {},
                slot = worn.slot,
                label = worn.label or RDItems[worn.name].label or worn.name,
                image = worn.image or RDItems[worn.name].image or (worn.name .. '.png'),
                type = worn.type or ctype
            }
        end
    end
    TriggerClientEvent('rd_inventory:client:clothesSync', src, list)
end)

RegisterNetEvent('rd_inventory:equipClothingItem', function(name, slot, clothType)
    local src = source
    local def = RDItems[name]
    if not def or not def.type then
        TriggerClientEvent('rd_inventory:notify', src, 'Ky item nuk eshte rrobe', 'error')
        return
    end

    local ok, removed = RDInv.removeItem(src, name, 1, slot)
    if not ok or not removed then
        TriggerClientEvent('rd_inventory:notify', src, 'Nuk e ke kete rrobe ne inventory', 'error')
        return
    end

    local ctype = tostring(clothType or def.type)
    RDClothesEquippedServer[src] = RDClothesEquippedServer[src] or {}
    local old = RDClothesEquippedServer[src][ctype]
    if old and old.name and RDItems[old.name] then
        RDInv.addItem(src, old.name, old.count or 1, old.metadata or {}, old.slot)
    end

    RDClothesEquippedServer[src][ctype] = {
        name = removed.name or name,
        count = removed.count or 1,
        metadata = removed.metadata or {},
        slot = removed.slot or tonumber(slot),
        label = def.label or name,
        image = def.image or ((removed.name or name) .. '.png'),
        type = ctype
    }

    local sendItem = table.clone and table.clone(def) or def
    sendItem.type = ctype
    sendItem.image = sendItem.image or ((removed.name or name) .. '.png')
    sendItem.metadata = removed.metadata or {}
    TriggerClientEvent('rd_inventory:itemUsed', src, removed.name or name, sendItem)
end)

RegisterNetEvent('rd_inventory:unequipClothingToInventory', function(clothType, name, toSlot)
    local src = source
    local ctype = tostring(clothType or '')
    if ctype == '' then return end

    RDClothesEquippedServer[src] = RDClothesEquippedServer[src] or {}
    local worn = RDClothesEquippedServer[src][ctype]

    -- Never spawn fake/default clothes. Only return the exact item that was equipped.
    if not worn or not worn.name or not RDItems[worn.name] then
        TriggerClientEvent('rd_inventory:notify', src, 'Nuk ke rrobe te veshur ketu', 'error')
        return
    end

    local ok = RDInv.addItem(src, worn.name, worn.count or 1, worn.metadata or {}, tonumber(toSlot) or worn.slot)
    if ok then
        RDClothesEquippedServer[src][ctype] = nil
        TriggerClientEvent('rd_inventory:client:removeClothing', src, ctype)
        TriggerClientEvent('rd_inventory:notify', src, ('U hoq %s'):format(ctype), 'success')
    else
        TriggerClientEvent('rd_inventory:notify', src, 'Inventory full / slot i zene', 'error')
    end
end)

RegisterNetEvent('rd_inventory:setHotbar', function(slot, itemSlot)
    local src = source
    local inv = RDInv.get(src)
    slot = tonumber(slot)
    itemSlot = tonumber(itemSlot)
    if not slot or slot < 1 or slot > (RD.HotbarSlots or 5) then return end
    inv.hotbar = inv.hotbar or {}
    inv.hotbar[tostring(slot)] = itemSlot
    RDInv.save(src)
    TriggerClientEvent('rd_inventory:notify', src, ('Hotbar %s saved'):format(slot), 'success')
    TriggerClientEvent('rd_inventory:refresh', src, cloneInventoryForClient(src, inv))
end)

AddEventHandler('playerDropped', function()
    local src = source
    RDInv.save(src)
    if RDClothesEquippedServer then RDClothesEquippedServer[src] = nil end
    if RDInv.clearSource then RDInv.clearSource(src) end
end)

exports('AddItem', RDInv.addItem)
exports('RemoveItem', RDInv.removeItem)
exports('GetInventory', RDInv.get)

-- RD FIX: QB/QBX optional status metadata fallback for usable food/drinks.
RegisterNetEvent('rd_inventory:server:addStatus', function(statusName, value)
    local src = source
    value = tonumber(value) or 0
    if value == 0 then return end
    if RD.Framework == 'qb' or RD.Framework == 'qbx' then
        local core = nil
        pcall(function() core = exports['qb-core']:GetCoreObject() end)
        pcall(function() core = core or exports.qbx_core:GetCoreObject() end)
        if core and core.Functions and core.Functions.GetPlayer then
            local Player = core.Functions.GetPlayer(src)
            if Player and Player.Functions and Player.PlayerData and Player.PlayerData.metadata then
                local cur = tonumber(Player.PlayerData.metadata[statusName]) or 0
                local add = math.floor(value / 10000)
                local newVal = math.max(0, math.min(100, cur + add))
                Player.Functions.SetMetaData(statusName, newVal)
            end
        end
    end
end)




-- RD phone gate: phone scripts must ask RD_inventory if player owns a phone item.
lib.callback.register('rd_inventory:hasPhoneItem', function(src)
    local count = 0
    if exports and exports[GetCurrentResourceName()] and exports[GetCurrentResourceName()].GetItemCount then
        count = (exports[GetCurrentResourceName()]:GetItemCount(src, 'phone') or 0) + (exports[GetCurrentResourceName()]:GetItemCount(src, 'smartphone') or 0)
    else
        local inv = RDInv.get(src)
        for _, item in ipairs(inv.items or {}) do
            if item.name == 'phone' or item.name == 'smartphone' then count = count + (tonumber(item.count) or 1) end
        end
    end
    return count > 0, count
end)

-- Compatibility exports for scripts written around ox_inventory / qs-inventory style calls.
exports('CanCarryItem', function(src, name, count) return RDItems[name] ~= nil end)
exports('GetItem', function(src, name)
    if isMoneyItem(name) then
        return { slot = (RDConfig and RDConfig.money and RDConfig.money.preferredSlot) or 1, name = name, count = RDBridge.getMoney(src), metadata = { account = 'cash' } }
    end
    local inv = RDInv.get(src)
    for _, item in ipairs(inv.items or {}) do if item.name == name then return item end end
    return nil
end)
exports('GetItemCount', function(src, name)
    if isMoneyItem(name) then return RDBridge.getMoney(src) end
    local inv, total = RDInv.get(src), 0
    for _, item in ipairs(inv.items or {}) do if item.name == name then total = total + (item.count or 1) end end
    return total
end)
exports('Search', function(src, search, name)
    if search == 'count' then
        if isMoneyItem(name) then return RDBridge.getMoney(src) end
        local inv, total = RDInv.get(src), 0
        for _, item in ipairs(inv.items or {}) do if item.name == name then total = total + (item.count or 1) end end
        return total
    end
    return exports[GetCurrentResourceName()]:GetItem(src, name)
end)


-- Compatibility exports for qb/qs/ox-style external scripts (RD_STORES, garages, jobs, etc).
RDInv.usableCallbacks = RDInv.usableCallbacks or {}
exports('CreateUsableItem', function(name, cb)
    if type(name) == 'string' and type(cb) == 'function' then
        RDInv.usableCallbacks[name] = cb
        return true
    end
    return false
end)
exports('RegisterUsableItem', function(name, cb)
    if type(name) == 'string' and type(cb) == 'function' then
        RDInv.usableCallbacks[name] = cb
        return true
    end
    return false
end)
exports('HasItem', function(src, name, count)
    count = tonumber(count) or 1
    return (exports[GetCurrentResourceName()]:GetItemCount(src, name) or 0) >= count
end)
exports('SetStashItems', function(stashId, items, slots, maxWeight, label)
    local inv = RDInv.getStashInv(tostring(stashId or 'default'))
    inv.items = items or inv.items or {}
    inv.slots = tonumber(slots) or inv.slots or 50
    inv.maxWeight = tonumber(maxWeight) or inv.maxWeight or 100000
    inv.label = label or inv.label or 'STASH'
    RDInv.saveStash(tostring(stashId or 'default'))
    return true
end)
exports('GetStashItems', function(stashId)
    local inv = RDInv.getStashInv(tostring(stashId or 'default'))
    return inv and inv.items or {}
end)

-- =========================================================
-- RD_inventory <-> qs-smartphone / ox_lib compatibility FIX
-- Provides server callbacks + exports that phone adapters can call.
-- =========================================================

local function RD_QS_NormalizeItems(src)
    local inv = RDInv and RDInv.get and RDInv.get(src) or {}
    local list = {}

    local rawItems = inv.items or inv or {}
    for slot, item in pairs(rawItems) do
        if item and item.name then
            local amount = tonumber(item.amount or item.count or item.quantity) or 1
            list[#list + 1] = {
                name = item.name,
                label = (RDItems and RDItems[item.name] and RDItems[item.name].label) or item.label or item.name,
                amount = amount,
                count = amount,
                quantity = amount,
                slot = tonumber(item.slot or slot) or slot,
                metadata = item.metadata or item.info or {},
                info = item.info or item.metadata or {},
                weight = item.weight or (RDItems and RDItems[item.name] and RDItems[item.name].weight) or 0,
                type = item.type or (RDItems and RDItems[item.name] and RDItems[item.name].type) or 'item',
                image = item.image or ((item.name or 'item') .. '.png')
            }
        end
    end

    return list
end

exports('GetPlayerItems', function(src)
    src = tonumber(src) or source
    return RD_QS_NormalizeItems(src)
end)

exports('getItems', function(src)
    src = tonumber(src) or source
    return RD_QS_NormalizeItems(src)
end)

exports('GetItems', function(src)
    src = tonumber(src) or source
    return RD_QS_NormalizeItems(src)
end)



-- =========================================================
-- RD PHONE METADATA SAVE FIX
-- qs-smartphone / phone scripts store the phone account, sim, number,
-- imei/serial etc inside item metadata. Without these exports the phone
-- opens as a new phone/account every time.
-- =========================================================
local function RD_SetItemMetadata(src, slot, metadata)
    src = tonumber(src) or source
    slot = tonumber(slot)
    if not src or not slot then return false end

    local inv = RDInv.get(src)
    if not inv or not inv.items then return false end

    for _, item in ipairs(inv.items) do
        if tonumber(item.slot) == slot then
            item.metadata = metadata or {}
            item.info = item.metadata -- compatibility alias for QB/QS style scripts
            RDInv.save(src)
            TriggerClientEvent('rd_inventory:refresh', src, RDInv.toClient(src))
            return true
        end
    end

    return false
end

local function RD_GetItemBySlot(src, slot)
    src = tonumber(src) or source
    slot = tonumber(slot)
    if not src or not slot then return nil end

    local inv = RDInv.get(src)
    for _, item in ipairs((inv and inv.items) or {}) do
        if tonumber(item.slot) == slot then
            return {
                name = item.name,
                label = (RDItems and RDItems[item.name] and RDItems[item.name].label) or item.label or item.name,
                amount = tonumber(item.amount or item.count or item.quantity) or 1,
                count = tonumber(item.amount or item.count or item.quantity) or 1,
                quantity = tonumber(item.amount or item.count or item.quantity) or 1,
                slot = tonumber(item.slot),
                metadata = item.metadata or item.info or {},
                info = item.info or item.metadata or {},
                weight = item.weight or (RDItems and RDItems[item.name] and RDItems[item.name].weight) or 0,
                type = item.type or (RDItems and RDItems[item.name] and RDItems[item.name].type) or 'item',
                image = item.image or ((item.name or 'item') .. '.png')
            }
        end
    end
    return nil
end

exports('SetMetadata', RD_SetItemMetadata)
exports('SetItemMetadata', RD_SetItemMetadata)
exports('SetItemData', RD_SetItemMetadata)
exports('UpdateItemMetadata', RD_SetItemMetadata)
exports('GetItemBySlot', RD_GetItemBySlot)

if lib and lib.callback then
    lib.callback.register('RD_inventory:setMetadata', function(src, slot, metadata)
        return RD_SetItemMetadata(src, slot, metadata)
    end)

    lib.callback.register('RD_inventory:getItemBySlot', function(src, slot)
        return RD_GetItemBySlot(src, slot)
    end)
end

if lib and lib.callback then
    lib.callback.register('RD_inventory:getItems', function(src)
        return RD_QS_NormalizeItems(src)
    end)

    lib.callback.register('RD_inventory:GetPlayerItems', function(src)
        return RD_QS_NormalizeItems(src)
    end)

    lib.callback.register('RD_inventory:hasItem', function(src, itemName, amount)
        amount = tonumber(amount) or 1
        return (exports[GetCurrentResourceName()]:GetItemCount(src, itemName) or 0) >= amount
    end)
end
