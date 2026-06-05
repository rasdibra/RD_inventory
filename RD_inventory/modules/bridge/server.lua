RDBridge = RDBridge or {}
RDBridge.standaloneMoney = RDBridge.standaloneMoney or {}

function RDBridge.getIdentifier(src)
    if RD.Framework == 'esx' and RDBridge.ESX then return RDBridge.ESX.getIdentifier(src) end
    if (RD.Framework == 'qb' or RD.Framework == 'qbx') and RDBridge.QB then return RDBridge.QB.getIdentifier(src) end
    return nil
end

function RDBridge.getMoney(src, account)
    account = account or 'cash'
    if RD.Framework == 'esx' and RDBridge.ESX then return RDBridge.ESX.getMoney(src, account) end
    if (RD.Framework == 'qb' or RD.Framework == 'qbx') and RDBridge.QB then return RDBridge.QB.getMoney(src, account) end
    local id = RDBridge.getIdentifier(src) or tostring(src)
    if RDBridge.standaloneMoney[id] == nil then
        RDBridge.standaloneMoney[id] = (RDConfig and RDConfig.money and RDConfig.money.startAmount) or 5000
    end
    return RDBridge.standaloneMoney[id]
end

function RDBridge.removeMoney(src, amount, account)
    account = account or 'cash'
    if amount <= 0 then return true end
    if RD.Framework == 'esx' and RDBridge.ESX then return RDBridge.ESX.removeMoney(src, amount, account) end
    if (RD.Framework == 'qb' or RD.Framework == 'qbx') and RDBridge.QB then return RDBridge.QB.removeMoney(src, amount, account) end
    local id = RDBridge.getIdentifier(src) or tostring(src)
    local current = RDBridge.getMoney(src)
    if current < amount then return false end
    RDBridge.standaloneMoney[id] = current - amount
    return true
end

function RDBridge.addMoney(src, amount, account)
    account = account or 'cash'
    amount = tonumber(amount) or 0
    if amount <= 0 then return true end
    if RD.Framework == 'esx' and RDBridge.ESX and RDBridge.ESX.addMoney then return RDBridge.ESX.addMoney(src, amount, account) end
    if (RD.Framework == 'qb' or RD.Framework == 'qbx') and RDBridge.QB and RDBridge.QB.addMoney then return RDBridge.QB.addMoney(src, amount, account) end
    local id = RDBridge.getIdentifier(src) or tostring(src)
    RDBridge.standaloneMoney[id] = RDBridge.getMoney(src) + amount
    return true
end
