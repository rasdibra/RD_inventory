RDBridge = RDBridge or {}
RDBridge.ESX = {}

local ESX
CreateThread(function()
    if GetResourceState('es_extended') == 'started' then
        ESX = exports.es_extended:getSharedObject()
    end
end)

function RDBridge.ESX.getPlayer(src)
    if not ESX then return nil end
    return ESX.GetPlayerFromId(src)
end

function RDBridge.ESX.getIdentifier(src)
    local xPlayer = RDBridge.ESX.getPlayer(src)
    return xPlayer and xPlayer.identifier
end

function RDBridge.ESX.getMoney(src, account)
    local xPlayer = RDBridge.ESX.getPlayer(src)
    if not xPlayer then return 0 end
    account = account or 'cash'
    if account == 'bank' and xPlayer.getAccount then
        local acc = xPlayer.getAccount('bank')
        return acc and acc.money or 0
    end
    return xPlayer.getMoney() or 0
end

function RDBridge.ESX.removeMoney(src, amount, account)
    local xPlayer = RDBridge.ESX.getPlayer(src)
    if not xPlayer then return false end
    account = account or 'cash'
    if account == 'bank' and xPlayer.getAccount and xPlayer.removeAccountMoney then
        local acc = xPlayer.getAccount('bank')
        if not acc or (acc.money or 0) < amount then return false end
        xPlayer.removeAccountMoney('bank', amount)
        return true
    end
    if xPlayer.getMoney() < amount then return false end
    xPlayer.removeMoney(amount)
    return true
end

function RDBridge.ESX.addMoney(src, amount, account)
    local xPlayer = RDBridge.ESX.getPlayer(src)
    if not xPlayer then return false end
    account = account or 'cash'
    if account == 'bank' and xPlayer.addAccountMoney then
        xPlayer.addAccountMoney('bank', amount)
    else
        xPlayer.addMoney(amount)
    end
    return true
end
