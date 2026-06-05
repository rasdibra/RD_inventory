RDRobberyServer = RDRobberyServer or {}

local function cfg()
    return (RDConfig and RDConfig.robbery) or {}
end

local function notify(src, msg, typ)
    TriggerClientEvent('rd_inventory:notify', src, msg, typ or 'info')
end

local function isTargetDead(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    return IsEntityDead(ped) or GetEntityHealth(ped) <= 101 or Player(src).state.isDead == true or Player(src).state.dead == true or Player(src).state.inlaststand == true
end

RegisterNetEvent('rd_inventory:robbery:tryOpenPlayer', function(targetId)
    local src = source
    local c = cfg()
    if not c.enabled or not c.deadBody or c.deadBody.enabled == false then return end
    targetId = tonumber(targetId)
    if not targetId or targetId == src or not GetPlayerName(targetId) then return notify(src, 'No player nearby', 'error') end

    local srcPed, targetPed = GetPlayerPed(src), GetPlayerPed(targetId)
    if not srcPed or not targetPed or srcPed == 0 or targetPed == 0 then return end
    local dist = #(GetEntityCoords(srcPed) - GetEntityCoords(targetPed))
    if dist > ((c.deadBody.distance or 2.0) + 0.75) then return notify(src, 'Player too far', 'error') end

    if c.deadBody.allowOnlyWhenTargetDead ~= false and not isTargetDead(targetId) then
        return notify(src, 'Target is not dead/downed', 'error')
    end

    TriggerClientEvent('rd_inventory:robbery:openPlayerInventory', src, targetId)
    if RDLog and RDLog.send then RDLog.send('rob_open_body', src, { target = tostring(targetId) }) end
end)

RegisterNetEvent('rd_inventory:robbery:npcReward', function(netId)
    local src = source
    local c = cfg()
    if not c.enabled or not c.npc or c.npc.enabled == false then return end
    local rewards = c.npc.rewards or {}
    if rewards.enabled == false then return end

    local moneyName = (RDConfig and RDConfig.money and RDConfig.money.item) or 'money'
    local amount = math.random(tonumber(rewards.minMoney) or 20, tonumber(rewards.maxMoney) or 150)
    if RDInv and RDInv.addItem then RDInv.addItem(src, moneyName, amount, {}) end

    if math.random(100) <= (tonumber(rewards.chanceItem) or 0) then
        local list = rewards.items or {}
        if #list > 0 then
            local pick = list[math.random(#list)]
            if pick and pick.name and RDItems and RDItems[pick.name] then
                RDInv.addItem(src, pick.name, math.random(pick.min or 1, pick.max or 1), {})
            end
        end
    end

    notify(src, ('NPC robbed: +%s cash'):format(amount), 'success')
    if RDLog and RDLog.send then RDLog.send('rob_npc', src, { money = tostring(amount), netId = tostring(netId or '') }) end
end)

RegisterNetEvent('rd_inventory:robbery:dispatchAlert', function(payload)
    local src = source
    local c = cfg()
    local d = c.dispatch or {}
    if d.enabled == false then return end
    payload = payload or {}
    payload.source = src

    local system = tostring(d.system or 'rd_mdt'):lower()

    -- CUSTOM: vendos event/export tek config.lua dhe s'ke nevojë të prekësh kodin.
    if system == 'custom_event' then
        if d.custom and d.custom.serverEvent and d.custom.serverEvent ~= '' then
            TriggerEvent(d.custom.serverEvent, payload)
        end
        if d.custom and d.custom.exportResource and d.custom.exportResource ~= '' and d.custom.exportName and d.custom.exportName ~= '' and GetResourceState(d.custom.exportResource) == 'started' then
            pcall(function() exports[d.custom.exportResource][d.custom.exportName](payload) end)
        end
        return
    end

    -- RD_MDT / RD_NDT compatible fallbacks. Në RD_MDT mund të dëgjosh cilindo nga këto events.
    if system == 'rd_mdt' or system == 'rd_ndt' or system == 'rdmdt' or system == 'rdndt' then
        TriggerEvent('RD_MDT:server:createDispatch', payload)
        TriggerEvent('rd_mdt:server:createDispatch', payload)
        TriggerEvent('RD_NDT:server:createDispatch', payload)
        TriggerEvent('rd_ndt:server:createDispatch', payload)
        TriggerClientEvent('RD_MDT:client:dispatchAlert', -1, payload)
        TriggerClientEvent('rd_mdt:client:dispatchAlert', -1, payload)
        TriggerClientEvent('RD_NDT:client:dispatchAlert', -1, payload)
        TriggerClientEvent('rd_ndt:client:dispatchAlert', -1, payload)
    end

    -- Built-in fallback notification/blip so alerts still show even without MDT resource.
    TriggerClientEvent('rd_inventory:robbery:clientDispatchFallback', -1, payload)

    if RDLog and RDLog.send then RDLog.send('dispatch_' .. tostring(payload.type or 'robbery'), src, { code = tostring(payload.code or ''), title = tostring(payload.title or '') }) end
end)
