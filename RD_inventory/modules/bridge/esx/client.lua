RDBridge = RDBridge or {}
CreateThread(function()
    if GetResourceState('es_extended') == 'started' then
        RDBridge.ESX = exports.es_extended:getSharedObject()
    end
end)
