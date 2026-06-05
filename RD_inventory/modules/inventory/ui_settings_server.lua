lib.callback.register('rd_inventory:getUISettings', function(src)
    local owner = RDUtils.identifier(src)
    return RDMySQL.loadUI(owner) or (RDUI and RDUI.default) or {}
end)

RegisterNetEvent('rd_inventory:saveUISettings', function(settings)
    local src = source
    local owner = RDUtils.identifier(src)
    RDMySQL.saveUI(owner, settings or {})
    TriggerClientEvent('rd_inventory:notify', src, 'Settings u ruajten me sukses', 'success')
end)
