RD.ServerReady = false
CreateThread(function()
    Wait(1000)
    RD.Print('Framework:', RD.Framework)
    if RDMySQL and RDMySQL.ensureTables then RDMySQL.ensureTables() end
    RD.ServerReady = true
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        RD.Print('started')
    end
end)
