RDBridge = RDBridge or {}
RDBridge.QB = {}

local QBCore
CreateThread(function()
    if GetResourceState('qbx_core') == 'started' then
        QBCore = exports.qbx_core
    elseif GetResourceState('qb-core') == 'started' then
        QBCore = exports['qb-core']:GetCoreObject()
    end
end)

function RDBridge.QB.getPlayer(src)
    if RD.Framework == 'qbx' and exports.qbx_core then
        return exports.qbx_core:GetPlayer(src)
    end
    if QBCore and QBCore.Functions then
        return QBCore.Functions.GetPlayer(src)
    end
    return nil
end

function RDBridge.QB.getIdentifier(src)
    local p = RDBridge.QB.getPlayer(src)
    return p and (p.PlayerData and p.PlayerData.citizenid or p.citizenid)
end

function RDBridge.QB.getMoney(src, account)
    local p = RDBridge.QB.getPlayer(src)
    if not p then return 0 end
    account = account or 'cash'
    if p.PlayerData and p.PlayerData.money then return p.PlayerData.money[account] or 0 end
    return 0
end

function RDBridge.QB.removeMoney(src, amount, account)
    local p = RDBridge.QB.getPlayer(src)
    if not p then return false end
    account = account or 'cash'
    if p.Functions and p.Functions.RemoveMoney then
        return p.Functions.RemoveMoney(account, amount, 'rd_inventory_buy')
    end
    return false
end

function RDBridge.QB.addMoney(src, amount, account)
    local p = RDBridge.QB.getPlayer(src)
    if not p then return false end
    account = account or 'cash'
    if p.Functions and p.Functions.AddMoney then
        return p.Functions.AddMoney(account, amount, 'rd_inventory_refund')
    end
    return false
end
