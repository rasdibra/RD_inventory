RD.ClientReady = false
CreateThread(function()
    Wait(1000)
    RD.Print('client started, framework:', RD.Framework)
    RD.ClientReady = true
end)
