RDAdmin = RDAdmin or {}
RDLog = RDLog or {}

local function cfg()
    return (RDConfig and RDConfig.webhooks) or {}
end

function RDAdmin.isAdmin(src)
    if src == 0 then return true end
    return IsPlayerAceAllowed(src, 'rd_inventory.admin')
        or IsPlayerAceAllowed(src, 'command.giveitem')
        or IsPlayerAceAllowed(src, 'command.rd_give')
        or IsPlayerAceAllowed(src, 'admin')
end

local function notify(src, msg, typ)
    if src == 0 then print('[RD_inventory] '..msg) return end
    TriggerClientEvent('rd_inventory:notify', src, msg, typ or 'info')
end

local function playerName(src)
    if not src or tonumber(src) == 0 then return 'Console' end
    return ('%s [%s]'):format(GetPlayerName(src) or 'Unknown', src)
end

function RDLog.send(action, src, data)
    local c = cfg()
    if c.enabled == false then return end
    local url = c.default
    if c.events and c.events[action] and c.events[action] ~= '' then url = c.events[action] end
    if not url or url == '' or url:find('YOUR_DISCORD_WEBHOOK') then return end

    data = data or {}
    local fields = {
        { name = 'Player', value = playerName(src), inline = true },
        { name = 'Action', value = tostring(action), inline = true }
    }
    for k, v in pairs(data) do
        fields[#fields+1] = { name = tostring(k), value = tostring(v), inline = true }
    end

    local payload = {
        username = c.username or 'RD Inventory Logs',
        embeds = {{
            title = 'RD Inventory',
            color = tonumber(c.color or 15158332) or 15158332,
            fields = fields,
            footer = { text = os.date('%Y-%m-%d %H:%M:%S') }
        }}
    }
    PerformHttpRequest(url, function() end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
end

local function parseCount(v) return math.max(1, tonumber(v) or 1) end

RegisterCommand('rd_giveitem', function(src, args)
    if not RDAdmin.isAdmin(src) then return notify(src, 'No permission', 'error') end
    local target = tonumber(args[1]) or src
    local item = tostring(args[2] or '')
    local count = parseCount(args[3])
    if item == '' or not RDItems[item] then return notify(src, 'Item invalid: '..item, 'error') end
    if not GetPlayerName(target) then return notify(src, 'Player offline', 'error') end
    local ok, err = RDInv.addItem(target, item, count, {})
    notify(src, ok and ('Gave %sx %s to ID %s'):format(count, item, target) or tostring(err), ok and 'success' or 'error')
    if ok then RDLog.send('admin_giveitem', src, { target = playerName(target), item = item, count = count }) end
end, false)

RegisterCommand('rd_removeitem', function(src, args)
    if not RDAdmin.isAdmin(src) then return notify(src, 'No permission', 'error') end
    local target = tonumber(args[1]) or src
    local item = tostring(args[2] or '')
    local count = parseCount(args[3])
    if item == '' or not RDItems[item] then return notify(src, 'Item invalid: '..item, 'error') end
    if not GetPlayerName(target) then return notify(src, 'Player offline', 'error') end
    local ok = RDInv.removeItem(target, item, count)
    notify(src, ok and ('Removed %sx %s from ID %s'):format(count, item, target) or 'Item not found / not enough', ok and 'success' or 'error')
    if ok then RDLog.send('admin_removeitem', src, { target = playerName(target), item = item, count = count }) end
end, false)

RegisterCommand('rd_clearinv', function(src, args)
    if not RDAdmin.isAdmin(src) then return notify(src, 'No permission', 'error') end
    local target = tonumber(args[1]) or src
    if not GetPlayerName(target) then return notify(src, 'Player offline', 'error') end
    local inv = RDInv.get(target)
    inv.items = {}
    inv.hotbar = {}
    RDInv.save(target)
    TriggerClientEvent('rd_inventory:refresh', target, { slots = inv.slots, maxWeight = inv.maxWeight, hotbar = {}, items = {} })
    notify(src, ('Cleared inventory ID %s'):format(target), 'success')
    RDLog.send('admin_clearinv', src, { target = playerName(target) })
end, false)

RegisterCommand('rd_giveweapon', function(src, args)
    if not RDAdmin.isAdmin(src) then return notify(src, 'No permission', 'error') end
    local target = tonumber(args[1]) or src
    local weapon = tostring(args[2] or ''):upper()
    if weapon ~= '' and weapon:sub(1,7) ~= 'WEAPON_' then weapon = 'WEAPON_'..weapon end
    local ammo = tonumber(args[3]) or 0
    if weapon == '' or not RDItems[weapon] then return notify(src, 'Weapon invalid: '..weapon, 'error') end
    local ok, err = RDInv.addItem(target, weapon, 1, { ammo = ammo, durability = 100, attachments = {} })
    notify(src, ok and ('Gave %s to ID %s'):format(weapon, target) or tostring(err), ok and 'success' or 'error')
    if ok then RDLog.send('admin_giveweapon', src, { target = playerName(target), weapon = weapon, ammo = ammo }) end
end, false)

RegisterCommand('rd_openstash', function(src, args)
    if src == 0 then return print('Use in-game: /rd_openstash stashId') end
    local stash = args[1] or 'default'
    TriggerClientEvent('rd_inventory:client:openStash', src, stash, args[2] or 'STASH')
    RDLog.send('open_stash_command', src, { stash = stash })
end, false)

RegisterCommand('rd_opentrunk', function(src)
    if src == 0 then return end
    TriggerClientEvent('rd_inventory:client:openNearestTrunk', src)
end, false)

RegisterCommand('rd_openglovebox', function(src)
    if src == 0 then return end
    TriggerClientEvent('rd_inventory:client:openCurrentGlovebox', src)
end, false)

RegisterCommand('rd_invhelp', function(src)
    local text = 'Commands: /inventory /rd_trunk /rd_openstash [id] /rd_opentrunk /rd_openglovebox /giveitem [id] item count /giveme item count /givecraftitems [id] /rd_giveitem [id] item count /rd_removeitem [id] item count /rd_clearinv [id] /rd_giveweapon [id] WEAPON_PISTOL ammo'
    notify(src, text, 'info')
end, false)
