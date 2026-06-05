RD = RD or {}

--[[
    RD_inventory Shops
    Coords format: vector4(x, y, z, heading)
    - x/y/z = location
    - heading = ped direction
    Edit only these lines when you want to move a shop.
]]

RDShops = {
    General = {
        label = '24/7 Supermarket',
        slots = 20,
        blip = { enabled = true, sprite = 52, colour = 2, scale = 0.65 },
        ped = { enabled = true, model = 'mp_m_shopkeep_01', scenario = 'WORLD_HUMAN_STAND_IMPATIENT' },
        items = {
            { name = 'water', price = 5, count = 50 },
            { name = 'bread', price = 8, count = 50 },
            { name = 'burger', price = 12, count = 50 },
            { name = 'sprunk', price = 8, count = 50 },
            { name = 'phone', price = 250, count = 10 },
            { name = 'radio', price = 150, count = 10 },
            { name = 'lockpick', price = 75, count = 20 },
            { name = 'paperbag', price = 2, count = 100 },
            { name = 'general_store_license', price = 2, count = 100 }
        },
        locations = {
            -- 24/7 Strawberry
            vector4(24.47, -1346.62, 29.50, 270.0),
            -- 24/7 Ineseno Road
            vector4(-3039.54, 584.38, 7.91, 15.0),
            -- 24/7 Barbareno Road
            vector4(-3242.97, 1001.35, 12.83, 355.0),
            -- 24/7 Paleto Bay
            vector4(1728.07, 6415.63, 35.04, 240.0),
            -- 24/7 Sandy Shores
            vector4(1959.82, 3740.48, 32.34, 300.0),
            -- 24/7 Route 68
            vector4(549.13, 2670.85, 42.16, 95.0),
            -- 24/7 Senora Freeway
            vector4(2677.47, 3279.76, 55.24, 330.0),
            -- 24/7 Clinton Avenue
            vector4(373.55, 325.56, 103.57, 255.0),
            -- 24/7 Palomino Freeway
            vector4(2556.66, 382.07, 108.62, 355.0)
        }
    },

    Liquor = {
        label = 'LTD / Liquor Shop',
        slots = 16,
        blip = { enabled = true, sprite = 93, colour = 5, scale = 0.65 },
        ped = { enabled = true, model = 'mp_m_shopkeep_01', scenario = 'WORLD_HUMAN_STAND_IMPATIENT' },
        items = {
            { name = 'water', price = 5, count = 50 },
            { name = 'sprunk', price = 8, count = 50 },
            { name = 'mustard', price = 10, count = 20 },
            { name = 'phone', price = 250, count = 5 }
        },
        locations = {
            -- LTD Grove Street
            vector4(-48.49, -1757.47, 29.42, 45.0),
            -- LTD Mirror Park
            vector4(1163.37, -323.80, 69.21, 100.0),
            -- LTD Little Seoul
            vector4(-707.50, -914.26, 19.22, 90.0),
            -- Liquor Great Ocean Highway
            vector4(-1820.52, 792.51, 138.12, 130.0),
            -- LTD Grapeseed
            vector4(1698.38, 4924.40, 42.06, 325.0)
        }
    },

    Ammunation = {
        label = 'Weapon Shop',
        slots = 30,
        license = 'weapon',
        blip = { enabled = true, sprite = 110, colour = 1, scale = 0.72 },
        ped = { enabled = true, model = 's_m_y_ammucity_01', scenario = 'WORLD_HUMAN_COP_IDLES' },
        items = {
            { name = 'WEAPON_KNIFE', price = 300, count = 10, license = 'weapon' },
            { name = 'WEAPON_BAT', price = 300, count = 10, license = 'weapon' },
            { name = 'WEAPON_FLASHLIGHT', price = 300, count = 10, license = 'weapon' },
            { name = 'WEAPON_PISTOL', price = 2500, count = 10, license = 'weapon' },
            { name = 'WEAPON_PISTOL_MK2', price = 2500, count = 10, license = 'weapon' },
            { name = 'WEAPON_COMBATPISTOL', price = 300, count = 10, license = 'weapon' },
            { name = 'WEAPON_APPISTOL', price = 2500, count = 10, license = 'weapon' },
            { name = 'WEAPON_PISTOL50', price = 2500, count = 10, license = 'weapon' },
            { name = 'WEAPON_SNSPISTOL', price = 2500, count = 10, license = 'weapon' },
            { name = 'WEAPON_HEAVYPISTOL', price = 2500, count = 10, license = 'weapon' },
            { name = 'WEAPON_VINTAGEPISTOL', price = 2500, count = 10, license = 'weapon' },
            { name = 'WEAPON_MACHINEPISTOL', price = 2500, count = 10, license = 'weapon' },
            { name = 'WEAPON_MICROSMG', price = 5500, count = 10, license = 'weapon' },
            { name = 'WEAPON_SMG', price = 5500, count = 10, license = 'weapon' },
            { name = 'WEAPON_SMG_MK2', price = 5500, count = 10, license = 'weapon' },
            { name = 'WEAPON_ASSAULTSMG', price = 5500, count = 10, license = 'weapon' },
            { name = 'WEAPON_COMBATPDW', price = 300, count = 10, license = 'weapon' },
            { name = 'WEAPON_MINISMG', price = 5500, count = 10, license = 'weapon' },
            { name = 'WEAPON_ASSAULTRIFLE', price = 9000, count = 10, license = 'weapon' },
            { name = 'WEAPON_ASSAULTRIFLE_MK2', price = 9000, count = 10, license = 'weapon' },
            { name = 'WEAPON_CARBINERIFLE', price = 9000, count = 10, license = 'weapon' },
            { name = 'WEAPON_CARBINERIFLE_MK2', price = 9000, count = 10, license = 'weapon' },
            { name = 'WEAPON_ADVANCEDRIFLE', price = 9000, count = 10, license = 'weapon' },
            { name = 'WEAPON_SPECIALCARBINE', price = 9000, count = 10, license = 'weapon' },
            { name = 'WEAPON_SPECIALCARBINE_MK2', price = 9000, count = 10, license = 'weapon' },
            { name = 'WEAPON_BULLPUPRIFLE', price = 9000, count = 10, license = 'weapon' },
            { name = 'WEAPON_BULLPUPRIFLE_MK2', price = 9000, count = 10, license = 'weapon' },
            { name = 'WEAPON_COMPACTRIFLE', price = 9000, count = 10, license = 'weapon' },
            { name = 'WEAPON_MILITARYRIFLE', price = 9000, count = 10, license = 'weapon' },
            { name = 'WEAPON_HEAVYRIFLE', price = 9000, count = 10, license = 'weapon' },
            { name = 'WEAPON_PUMPSHOTGUN', price = 7000, count = 10, license = 'weapon' },
            { name = 'WEAPON_PUMPSHOTGUN_MK2', price = 7000, count = 10, license = 'weapon' },
            { name = 'WEAPON_SAWNOFFSHOTGUN', price = 7000, count = 10, license = 'weapon' },
            { name = 'WEAPON_ASSAULTSHOTGUN', price = 7000, count = 10, license = 'weapon' },
            { name = 'WEAPON_BULLPUPSHOTGUN', price = 7000, count = 10, license = 'weapon' },
            { name = 'WEAPON_DBSHOTGUN', price = 7000, count = 10, license = 'weapon' },
            { name = 'WEAPON_AUTOSHOTGUN', price = 7000, count = 10, license = 'weapon' },
            { name = 'WEAPON_COMBATSHOTGUN', price = 300, count = 10, license = 'weapon' },
            { name = 'WEAPON_MG', price = 9000, count = 10, license = 'weapon' },
            { name = 'WEAPON_COMBATMG', price = 300, count = 10, license = 'weapon' },
            { name = 'WEAPON_COMBATMG_MK2', price = 300, count = 10, license = 'weapon' },
            { name = 'WEAPON_GUSENBERG', price = 9000, count = 10, license = 'weapon' },
            { name = 'WEAPON_SNIPERRIFLE', price = 15000, count = 10, license = 'weapon' },
            { name = 'WEAPON_HEAVYSNIPER', price = 15000, count = 10, license = 'weapon' },
            { name = 'WEAPON_MARKSMANRIFLE', price = 15000, count = 10, license = 'weapon' },
            { name = 'WEAPON_PRECISIONRIFLE', price = 15000, count = 10, license = 'weapon' },
            { name = 'ammo-9', price = 50, count = 50 },
            { name = 'ammo-45', price = 50, count = 50 },
            { name = 'ammo-50', price = 50, count = 50 },
            { name = 'ammo-rifle', price = 50, count = 50 },
            { name = 'ammo-shotgun', price = 50, count = 50 },
            { name = 'at_flashlight', price = 350, count = 50 },
            { name = 'at_suppressor_light', price = 1500, count = 50 },
            { name = 'at_suppressor_heavy', price = 1500, count = 50 },
            { name = 'at_suppressor', price = 1500, count = 50 },
            { name = 'at_clip_extended_pistol', price = 350, count = 50 },
            { name = 'at_clip_extended_smg', price = 350, count = 50 },
            { name = 'at_clip_extended_rifle', price = 350, count = 50 },
            { name = 'at_clip_extended', price = 350, count = 50 },
            { name = 'at_clip_drum', price = 350, count = 50 },
            { name = 'at_scope_small', price = 1200, count = 50 },
            { name = 'at_scope_medium', price = 1200, count = 50 },
            { name = 'at_scope_holo', price = 1200, count = 50 },
            { name = 'at_scope_large', price = 1200, count = 50 },
            { name = 'at_grip', price = 1000, count = 50 },
            { name = 'at_barrel', price = 1000, count = 50 },
            { name = 'at_luxary_finish', price = 800, count = 50 },
            { name = 'at_color_luxury', price = 800, count = 50 },
            { name = 'tint_boom', price = 800, count = 50 },
            { name = 'tint_leopard', price = 800, count = 50 },
        },
        locations = {
            -- Ammu-Nation Little Seoul
            vector4(-662.18, -934.96, 21.83, 180.0),
            -- Ammu-Nation La Mesa
            vector4(810.25, -2157.60, 29.62, 360.0),
            -- Ammu-Nation Sandy Shores
            vector4(1693.44, 3760.16, 34.71, 225.0),
            -- Ammu-Nation Paleto Bay
            vector4(-330.24, 6083.88, 31.45, 225.0),
            -- Ammu-Nation Pillbox Hill
            vector4(252.63, -50.00, 69.94, 70.0),
            -- Ammu-Nation Downtown
            vector4(22.56, -1109.89, 29.80, 160.0),
            -- Ammu-Nation Tataviam
            vector4(2567.69, 294.38, 108.73, 360.0),
            -- Ammu-Nation Zancudo
            vector4(-1117.58, 2698.61, 18.55, 220.0),
            -- Ammu-Nation Vespucci
            vector4(842.44, -1033.42, 28.19, 360.0)
        }
    },

    DigitalDen = {
        label = 'Digital Den',
        slots = 12,
        blip = { enabled = true, sprite = 521, colour = 3, scale = 0.65 },
        ped = { enabled = true, model = 'mp_m_shopkeep_01', scenario = 'WORLD_HUMAN_STAND_MOBILE' },
        items = {
            { name = 'phone', price = 250, count = 30 },
            { name = 'radio', price = 150, count = 30 },
            { name = 'mastercard', price = 25, count = 20 }
        },
        locations = {
            -- Digital Den Little Seoul
            vector4(-656.78, -858.73, 24.50, 360.0),
            -- Digital Den Sandy / Route 68
            vector4(1137.98, -469.12, 66.73, 75.0)
        }
    },

    PoliceArmory = {
        label = 'Police Armory',
        slots = 40,
        jobs = { police = 0 },
        blip = { enabled = false },
        ped = { enabled = false },
        items = {
            { name = 'WEAPON_STUNGUN', price = 0, count = 20 },
            { name = 'WEAPON_NIGHTSTICK', price = 0, count = 20 },
            { name = 'WEAPON_FLASHLIGHT', price = 0, count = 20 },
            { name = 'WEAPON_COMBATPISTOL', price = 0, count = 20 },
            { name = 'ammo-9', price = 0, count = 500 },
            { name = 'armour', price = 0, count = 50 },
            { name = 'radio', price = 0, count = 50 },
            { name = 'evidence_bag', price = 0, count = 100 }
        },
        locations = {
            -- Mission Row PD Armory
            vector4(482.27, -995.75, 30.69, 90.0)
        }
    }
}

RD.Shops = RDShops
return RDShops
