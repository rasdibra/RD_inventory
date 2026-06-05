fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'RD'
description 'RD_inventory - ESX/QB/QBX inventory with ox style red/black UI'
version '1.0.0'

ui_page 'web/build/index.html'

files {
    'web/build/index.html',
    'web/build/assets/*.js',
    'web/build/assets/*.css',
    'web/images/*',
    'stream/*.ytd'
}

shared_scripts {
    '@ox_lib/init.lua',
    'init.lua',
    'data/*.lua',
    'locales/*.lua'
}

client_scripts {
    'client.lua',
    'modules/dpclothing/Client/Functions.lua',
    'modules/dpclothing/Locale/*.lua',
    'modules/dpclothing/Client/Config.lua',
    'modules/dpclothing/Client/Variations.lua',
    'modules/dpclothing/Client/Clothing.lua',
    'modules/dpclothing/Client/GUI.lua',
    'modules/utils/client.lua',
    'modules/bridge/client.lua',
    'modules/bridge/esx/client.lua',
    'modules/bridge/qbx/client.lua',
    'modules/bridge/ox/client.lua',
    'modules/inventory/client.lua',
    'modules/items/client.lua',
    'modules/shops/client.lua',
    'modules/ownedstores/client.lua',
    'modules/stashes/client.lua',
    'modules/crafting/client.lua',
    'modules/weapon/client.lua',
    'modules/target/client.lua',
    'modules/robbery/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'modules/mysql/server.lua',
    'modules/utils/server.lua',
    'modules/bridge/server.lua',
    'modules/bridge/esx/server.lua',
    'modules/bridge/qbx/server.lua',
    'modules/bridge/ox/server.lua',
    'modules/hooks/server.lua',
    'modules/stashes/server.lua',
    'modules/admin/server.lua',
    'modules/inventory/server.lua',
    'modules/inventory/ui_settings_server.lua',
    'modules/items/server.lua',
    'modules/shops/server.lua',
    'modules/ownedstores/server.lua',
    'modules/crafting/server.lua',
    'modules/weapon/server.lua',
    'modules/robbery/server.lua',
    'server.lua'
}

dependencies {
    'ox_lib',
    'oxmysql'
}

client_exports {
    'HasItem',
    'GetPlayerItems',
    'getItems'
}

server_exports {
    'HasItem',
    'GetItemCount',
    'GetInventory',
    'GetPlayerItems',
    'getItems',
    'GetItems',
    'GetItem',
    'Search',
    'SetMetadata',
    'SetItemMetadata',
    'SetItemData',
    'UpdateItemMetadata',
    'GetItemBySlot'
}

provides {
    --'rd_inventory',
    --'ox_inventory',
    --'qs-inventory',
    --'qb-inventory'
}
