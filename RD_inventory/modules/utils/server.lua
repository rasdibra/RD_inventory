RDUtils = RDUtils or {}

local function firstLicense(src)
    for _, identifier in ipairs(GetPlayerIdentifiers(src) or {}) do
        if identifier:find('license:', 1, true) then return identifier end
    end
    return nil
end

function RDUtils.identifier(src)
    src = tonumber(src)
    if not src or src <= 0 then return nil end

    -- ESX Legacy multichar returns identifiers like char1:license:xxxxx.
    -- Use the framework character identifier first so each character has its own inventory.
    if RDBridge and RDBridge.getIdentifier then
        local ok, id = pcall(RDBridge.getIdentifier, src)
        if ok and id and tostring(id) ~= '' then
            return tostring(id)
        end
    end

    -- Extra ESX fallback in case the bridge has not finished initialising yet.
    if GetResourceState('es_extended') == 'started' then
        local ok, ESX = pcall(function() return exports.es_extended:getSharedObject() end)
        if ok and ESX and ESX.GetPlayerFromId then
            local xPlayer = ESX.GetPlayerFromId(src)
            if xPlayer and xPlayer.identifier and tostring(xPlayer.identifier) ~= '' then
                return tostring(xPlayer.identifier)
            end
        end
    end

    -- Extra QB/QBX fallback: citizenid is per character.
    if GetResourceState('qbx_core') == 'started' then
        local ok, p = pcall(function() return exports.qbx_core:GetPlayer(src) end)
        if ok and p then
            local cid = (p.PlayerData and p.PlayerData.citizenid) or p.citizenid
            if cid and tostring(cid) ~= '' then return tostring(cid) end
        end
    elseif GetResourceState('qb-core') == 'started' then
        local ok, core = pcall(function() return exports['qb-core']:GetCoreObject() end)
        if ok and core and core.Functions and core.Functions.GetPlayer then
            local p = core.Functions.GetPlayer(src)
            local cid = p and p.PlayerData and p.PlayerData.citizenid
            if cid and tostring(cid) ~= '' then return tostring(cid) end
        end
    end

    -- Last fallback only for standalone/no framework. This is NOT per character.
    return firstLicense(src) or ('source:%s'):format(src)
end

function RDUtils.copy(t)
    local r = {}
    for k,v in pairs(t or {}) do
        if type(v) == 'table' then r[k] = RDUtils.copy(v) else r[k] = v end
    end
    return r
end

function RDUtils.itemWeight(name, count)
    local item = RDItems[name]
    return (item and item.weight or 0) * (count or 1)
end
