RDItemsServer = {}

RegisterNetEvent('rd_inventory:giveItemToPlayer', function(target, name, count)
    local src = source
    target = tonumber(target)
    count = tonumber(count) or 1
    if not target or not GetPlayerName(target) then return end
    if RDInv.removeItem(src, name, count) then
        RDInv.addItem(target, name, count)
    end
end)


-- RD admin/test helpers: make craft materials easy to get while testing.
-- Usage:
--   /giveitem [id] item count        -> admin gives item to a player
--   /giveme item count               -> self test command
--   /givecraftitems [id]             -> gives all common crafting materials
local function rdIsAdmin(src)
    if src == 0 then return true end
    if IsPlayerAceAllowed(src, 'command.giveitem') or IsPlayerAceAllowed(src, 'rd_inventory.admin') or IsPlayerAceAllowed(src, 'admin') then return true end
    return false
end

local function rdNotify(src, msg, typ)
    if src == 0 then print('[RD_inventory] '..msg) return end
    TriggerClientEvent('rd_inventory:notify', src, msg, typ or 'info')
end

local function rdGive(src, target, item, count)
    target = tonumber(target or src)
    count = tonumber(count) or 1
    if not target or not GetPlayerName(target) then return false, 'Player not online' end
    if not item or not RDItems or not RDItems[item] then return false, ('Invalid item: %s'):format(tostring(item)) end
    local ok, err = RDInv.addItem(target, item, count, {})
    if not ok then return false, tostring(err or 'Inventory full') end
    if RDLog and RDLog.send then RDLog.send('admin_giveitem', src, { target = tostring(target), item = item, count = count }) end
    rdNotify(target, ('Received %sx %s'):format(count, RDItems[item].label or item), 'success')
    return true
end

RegisterCommand('giveitem', function(src, args)
    if not rdIsAdmin(src) then return rdNotify(src, 'No permission', 'error') end
    local target = tonumber(args[1]) or src
    local item = args[2]
    local count = tonumber(args[3]) or 1
    local ok, err = rdGive(src, target, item, count)
    rdNotify(src, ok and ('Gave %sx %s to ID %s'):format(count, item, target) or err, ok and 'success' or 'error')
end, false)

RegisterCommand('giveme', function(src, args)
    if src == 0 then return print('Use /giveitem from console: giveitem id item count') end
    local item = args[1]
    local count = tonumber(args[2]) or 1
    local ok, err = rdGive(src, src, item, count)
    rdNotify(src, ok and ('Added %sx %s'):format(count, item) or err, ok and 'success' or 'error')
end, false)

RegisterCommand('givecraftitems', function(src, args)
    if not rdIsAdmin(src) then return rdNotify(src, 'No permission', 'error') end
    local target = tonumber(args[1]) or src
    local pack = {
        scrapmetal = 250, weapon_parts = 180, steel = 250, rubber = 80, cloth = 80,
        electronics = 80, gunpowder = 80, brass = 120, glass = 50, paint = 50, wood = 80,
        pistol_body = 8, smg_body = 6, rifle_body = 5, shotgun_body = 5
    }
    for item, count in pairs(pack) do if RDItems[item] then RDInv.addItem(target, item, count, {}) end end
    rdNotify(src, ('Craft pack given to ID %s'):format(target), 'success')
    if target ~= src then rdNotify(target, 'You received craft materials pack', 'success') end
end, false)
