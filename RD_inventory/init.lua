RD = RD or {}

RD.Debug = false
RD.MaxWeight = 50000
RD.MaxSlots = 40
RD.OpenKey = 'TAB'
RD.HotbarKey = 'Z'
RD.HotbarSlots = 5
RD.HotbarUseKeys = { '1', '2', '3', '4', '5' }
RD.Command = 'inventory'
RD.ImagePath = 'nui://RD_inventory/web/images/'

RD.Framework = 'standalone'

if GetResourceState('es_extended') == 'started' then
    RD.Framework = 'esx'
elseif GetResourceState('qbx_core') == 'started' then
    RD.Framework = 'qbx'
elseif GetResourceState('qb-core') == 'started' then
    RD.Framework = 'qb'
end



function RD.Print(...)
    if RD.Debug then
        print('[RD_inventory]', ...)
    end
end
