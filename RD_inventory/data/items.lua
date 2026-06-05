RDItems = {
    water = {
        label = 'Water',
        weight = 500,
        stack = true,
        close = true,
        consume = 1,
        description = 'Bottle of water',
        image = 'water.png',
        client = {
            image = 'water.png',
            status = { thirst = 200000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle', flag = 49 },
            prop = { model = 'prop_ld_flow_bottle', bone = 57005, pos = vec3(0.03, 0.03, 0.02), rot = vec3(0.0, 0.0, -1.5) },
            usetime = 4500,
            progressLabel = 'DRINKING WATER',
            cancel = true,
            notification = 'You drank water'
        }
    },

    vehicle_key = {
        label = 'Vehicle Key',
        weight = 50,
        stack = false,
        close = true,
        description = 'Key linked to one vehicle plate',
        image = 'vehicle_key.png',
        unique = true,
        useable = true,
        client = {
            event = 'rd_vehiclekeys:client:openRemote'
        }
    },

    bread = {
        label = 'Bread',
        weight = 300,
        stack = true,
        close = true,
        consume = 1,
        description = 'Fresh bread',
        image = 'bread.png',
        client = {
            image = 'bread.png',
            status = { hunger = 200000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp', flag = 49 },
            prop = { model = 'prop_sandwich_01', bone = 57005, pos = vec3(0.13, 0.05, 0.02), rot = vec3(-50.0, 16.0, 60.0) },
            usetime = 4500,
            progressLabel = 'EATING BREAD',
            cancel = true,
            notification = 'You ate bread'
        }
    },

    burger = {
        label = 'Burger',
        weight = 350,
        stack = true,
        close = true,
        consume = 1,
        description = 'Fast food burger',
        image = 'burger.png',
        client = {
            image = 'burger.png',
            status = { hunger = 220000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp', flag = 49 },
            prop = { model = 'prop_cs_burger_01', bone = 57005, pos = vec3(0.12, 0.03, 0.02), rot = vec3(-70.0, 20.0, 10.0) },
            usetime = 5200,
            progressLabel = 'EATING BURGER',
            cancel = true,
            notification = 'You ate a burger'
        }
    },

    sprunk = {
        label = 'Sprunk',
        weight = 350,
        stack = true,
        close = true,
        consume = 1,
        description = 'Can of soda',
        image = 'sprunk.png',
        client = {
            image = 'sprunk.png',
            status = { thirst = 180000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle', flag = 49 },
            prop = { model = 'prop_ecola_can', bone = 57005, pos = vec3(0.02, 0.02, 0.06), rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4200,
            progressLabel = 'DRINKING SPRUNK',
            cancel = true,
            notification = 'You drank a Sprunk'
        }
    },

    coffee = {
        label = 'Coffee',
        weight = 250,
        stack = true,
        close = true,
        consume = 1,
        description = 'Hot coffee cup',
        image = 'coffee.png',
        client = {
            image = 'coffee.png',
            status = { thirst = 120000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle', flag = 49 },
            prop = { model = 'p_amb_coffeecup_01', bone = 57005, pos = vec3(0.12, 0.02, -0.03), rot = vec3(-75.0, 0.0, 0.0) },
            usetime = 5000,
            progressLabel = 'DRINKING COFFEE',
            cancel = true,
            notification = 'You drank coffee'
        }
    },

    cola = {
        label = 'Cola',
        weight = 350,
        stack = true,
        close = true,
        consume = 1,
        description = 'Cold cola can',
        image = 'cola.png',
        client = {
            image = 'cola.png',
            status = { thirst = 180000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle', flag = 49 },
            prop = { model = 'prop_ecola_can', bone = 57005, pos = vec3(0.02, 0.02, 0.06), rot = vec3(0.0, 0.0, 0.0) },
            usetime = 4200,
            progressLabel = 'DRINKING COLA',
            cancel = true,
            notification = 'You drank cola'
        }
    },

    sandwich = {
        label = 'Sandwich',
        weight = 320,
        stack = true,
        close = true,
        consume = 1,
        description = 'Packed sandwich',
        image = 'sandwich.png',
        client = {
            image = 'sandwich.png',
            status = { hunger = 190000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp', flag = 49 },
            prop = { model = 'prop_sandwich_01', bone = 57005, pos = vec3(0.13, 0.05, 0.02), rot = vec3(-50.0, 16.0, 60.0) },
            usetime = 4800,
            progressLabel = 'EATING SANDWICH',
            cancel = true,
            notification = 'You ate a sandwich'
        }
    },

    donut = {
        label = 'Donut',
        weight = 180,
        stack = true,
        close = true,
        consume = 1,
        description = 'Sweet donut',
        image = 'donut.png',
        client = {
            image = 'donut.png',
            status = { hunger = 95000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp', flag = 49 },
            prop = { model = 'prop_donut_02', bone = 57005, pos = vec3(0.13, 0.04, 0.02), rot = vec3(-20.0, 0.0, 0.0) },
            usetime = 3600,
            progressLabel = 'EATING DONUT',
            cancel = true,
            notification = 'You ate a donut'
        }
    },

    soup = {
        label = 'Soup',
        weight = 500,
        stack = true,
        close = true,
        consume = 1,
        description = 'Hot soup with spoon',
        image = 'soup.png',
        client = {
            image = 'soup.png',
            status = { hunger = 240000, thirst = 60000 },
            anim = { dict = 'amb@world_human_clipboard@male@idle_a', clip = 'idle_c', flag = 49 },
            props = {
                { model = 'prop_cs_bowl_01', bone = 18905, pos = vec3(0.13, 0.02, 0.02), rot = vec3(-70.0, 15.0, 15.0) },
                { model = 'prop_cs_spoon', bone = 57005, pos = vec3(0.12, 0.03, -0.01), rot = vec3(15.0, 45.0, 0.0) }
            },
            usetime = 7000,
            progressLabel = 'EATING SOUP',
            cancel = true,
            notification = 'You ate soup'
        }
    },

    steak = {
        label = 'Steak Plate',
        weight = 650,
        stack = true,
        close = true,
        consume = 1,
        description = 'Plate food with fork and knife',
        image = 'steak.png',
        client = {
            image = 'steak.png',
            status = { hunger = 300000 },
            anim = { dict = 'amb@world_human_clipboard@male@idle_a', clip = 'idle_c', flag = 49 },
            props = {
                { model = 'prop_cs_plate_01', bone = 18905, pos = vec3(0.13, 0.02, 0.02), rot = vec3(-70.0, 15.0, 15.0) },
                { model = 'prop_cs_fork', bone = 57005, pos = vec3(0.12, 0.03, -0.01), rot = vec3(15.0, 45.0, 0.0) },
                { model = 'prop_cs_bowie_knife', bone = 18905, pos = vec3(0.02, -0.08, 0.03), rot = vec3(0.0, 95.0, 25.0) }
            },
            usetime = 8000,
            progressLabel = 'EATING WITH FORK',
            cancel = true,
            notification = 'You ate food with fork and knife'
        }
    },

    fries = {
        label = 'Fries',
        weight = 220,
        stack = true,
        close = true,
        consume = 1,
        description = 'Box of fries',
        image = 'fries.png',
        client = {
            image = 'fries.png',
            status = { hunger = 140000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp', flag = 49 },
            prop = { model = 'prop_food_bs_chips', bone = 57005, pos = vec3(0.12, 0.03, 0.02), rot = vec3(-70.0, 25.0, 10.0) },
            usetime = 4500,
            progressLabel = 'EATING FRIES',
            cancel = true,
            notification = 'You ate fries'
        }
    },

    ['phone'] = {
        label = 'Phone',
        weight = 190,
        stack = false,
        consume = 0
    },

    ['wireless_earbuds'] = {
        label = 'Wireless Earbuds',
        weight = 120,
        stack = true,
        close = true,
        server = {
            export = 'qs-smartphone.useWirelessEarbuds'
        }
    },

    ['powerbank'] = {
        label = 'Powerbank',
        weight = 300,
        stack = true,
        close = true,
        server = {
            export = 'qs-smartphone.usePowerbank'
        }
    },

    ['phone_sim'] = {
        label = 'SIM Card',
        weight = 45,
        stack = false,
        consume = 0,
        close = true,
        server = {
            export = 'qs-smartphone.useSimCard'
        }
    },

    money = {
        label = 'Cash',
        weight = 0,
        stack = true,
        close = false,
        consume = 0,
        description = 'Money',
        image = 'money.png',
        client = { image = 'money.png' }
    },

    cash = {
        label = 'Cash',
        weight = 0,
        stack = true,
        close = false,
        consume = 0,
        description = 'Cash money',
        image = 'money.png',
        client = { image = 'money.png' }
    },

    burger = {
        label = 'Burger',
        weight = 350,
        stack = true,
        close = true,
        consume = 1,
        description = 'Fast food burger',
        image = 'burger.png',
        client = {
            image = 'burger.png',
            status = { hunger = 220000 },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            usetime = 2500,
            progressLabel = 'EATING',
            notification = 'You ate a burger'
        }
    },

    sprunk = {
        label = 'Sprunk',
        weight = 350,
        stack = true,
        close = true,
        consume = 1,
        description = 'Can of soda',
        image = 'sprunk.png',
        client = {
            image = 'sprunk.png',
            status = { thirst = 180000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            usetime = 2200,
            progressLabel = 'DRINKING',
            notification = 'You drank a Sprunk'
        }
    },

    mustard = {
        label = 'Mustard',
        weight = 250,
        stack = true,
        close = true,
        consume = 1,
        description = 'Bottle of mustard',
        image = 'mustard.png',
        client = { image = 'mustard.png', status = { hunger = 60000 }, usetime = 1600, notification = 'You used mustard' }
    },

    radio = {
        label = 'Radio',
        weight = 700,
        stack = false,
        close = true,
        consume = 0,
        description = 'Portable radio',
        image = 'radio.png',
        client = { image = 'radio.png', notification = 'Radio item used' }
    },

    lockpick = {
        label = 'Lockpick',
        weight = 120,
        stack = true,
        close = true,
        consume = 0,
        description = 'Lockpick tool',
        image = 'lockpick.png',
        client = { image = 'lockpick.png' }
    },

    paperbag = {
        label = 'Paper Bag',
        weight = 50,
        stack = true,
        close = true,
        consume = 0,
        description = 'Small paper bag',
        image = 'paperbag.png',
        client = { image = 'paperbag.png' }
    },

    mastercard = {
        label = 'Mastercard',
        weight = 20,
        stack = false,
        close = false,
        consume = 0,
        description = 'Bank card',
        image = 'mastercard.png',
        client = { image = 'mastercard.png' }
    },

    armour = {
        label = 'Body Armour',
        weight = 2500,
        stack = true,
        close = true,
        consume = 1,
        description = 'Protective vest',
        image = 'armour.png',
        client = { image = 'armour.png', usetime = 2500, progressLabel = 'USING ARMOUR', notification = 'Armour used' }
    },

    evidence_bag = {
        label = 'Evidence Bag',
        weight = 20,
        stack = true,
        close = false,
        consume = 0,
        description = 'Police evidence bag',
        image = 'evidence_bag.png',
        client = { image = 'evidence_bag.png' }
    },

    general_store_license = {
        label = 'General Store License',
        weight = 2500,
        stack = false,
        close = true,
        consume = 0,
        description = 'Place your own store',
        image = 'general_store_license.png',

        client = {
            event = 'RD_STORES:client:useLicense'
        }
    },

    ['ammo-9'] = { label = '9mm Ammo', weight = 8, stack = true, close = false, consume = 0, description = '9mm ammunition', image = 'ammo-9.png', client = { image = 'ammo-9.png' } },
    ['ammo-45'] = { label = '.45 Ammo', weight = 10, stack = true, close = false, consume = 0, description = '.45 ammunition', image = 'ammo-45.png', client = { image = 'ammo-45.png' } },
    ['ammo-50'] = { label = '.50 Ammo', weight = 12, stack = true, close = false, consume = 0, description = '.50 ammunition', image = 'ammo-50.png', client = { image = 'ammo-50.png' } },
    ['ammo-rifle'] = { label = 'Rifle Ammo', weight = 14, stack = true, close = false, consume = 0, description = 'Rifle ammunition', image = 'ammo-rifle.png', client = { image = 'ammo-rifle.png' } },
    ['ammo-shotgun'] = { label = 'Shotgun Ammo', weight = 18, stack = true, close = false, consume = 0, description = 'Shotgun shells', image = 'ammo-shotgun.png', client = { image = 'ammo-shotgun.png' } },
    at_flashlight = { label = 'Weapon Flashlight', weight = 120, stack = true, close = false, consume = 0, description = 'Weapon attachment', image = 'at_flashlight.png', client = { image = 'at_flashlight.png' } },
    at_suppressor_light = { label = 'Light Suppressor', weight = 220, stack = true, close = false, consume = 0, description = 'Weapon attachment', image = 'at_suppressor_light.png', client = { image = 'at_suppressor_light.png' } },
    at_clip_extended_pistol = { label = 'Pistol Extended Clip', weight = 180, stack = true, close = false, consume = 0, description = 'Weapon attachment', image = 'at_clip_extended_pistol.png', client = { image = 'at_clip_extended_pistol.png' } },

    hat_black = {
        label = 'Black Hat',
        weight = 250,
        stack = false,
        close = false,
        consume = 0,
        type = 'hat',
        description = 'Clothing item',
        image = 'hat.png',
        client = {
            image = 'hat.png',
            anim = { dict = 'mp_masks@standard_car@ds@', clip = 'put_on_mask', flag = 49 },
            usetime = 1200,
            notification = 'Hat equipped'
        }
    },

    mask_black = {
        label = 'Black Mask',
        weight = 250,
        stack = false,
        close = false,
        consume = 0,
        type = 'mask',
        description = 'Clothing item',
        image = 'mask.png',
        client = {
            image = 'mask.png',
            anim = { dict = 'mp_masks@standard_car@ds@', clip = 'put_on_mask', flag = 49 },
            usetime = 1200,
            notification = 'Mask equipped'
        }
    },

    shirt_white = {
        label = 'White Shirt',
        weight = 250,
        stack = false,
        close = false,
        consume = 0,
        type = 'shirt',
        description = 'Clothing item',
        image = 'shirt.png',
        client = {
            image = 'shirt.png',
            anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d', flag = 49 },
            usetime = 1500,
            notification = 'Shirt equipped'
        }
    },

    gloves_black = {
        label = 'Black Gloves',
        weight = 100,
        stack = false,
        close = false,
        consume = 0,
        type = 'gloves',
        description = 'Clothing item',
        image = 'gloves.png',
        client = {
            image = 'gloves.png',
            anim = { dict = 'nmt_3_rcm-10', clip = 'cs_nigel_dual-10', flag = 49 },
            usetime = 1200,
            notification = 'Gloves equipped'
        }
    },

    pants_blue = {
        label = 'Blue Pants',
        weight = 300,
        stack = false,
        close = false,
        consume = 0,
        type = 'pants',
        description = 'Clothing item',
        image = 'pants.png',
        client = {
            image = 'pants.png',
            anim = { dict = 're@construction', clip = 'out_of_breath', flag = 49 },
            usetime = 1500,
            notification = 'Pants equipped'
        }
    },

    shoes_black = {
        label = 'Black Shoes',
        weight = 300,
        stack = false,
        close = false,
        consume = 0,
        type = 'shoes',
        description = 'Clothing item',
        image = 'shoes.png',
        client = {
            image = 'shoes.png',
            anim = { dict = 'random@domestic', clip = 'pickup_low', flag = 49 },
            usetime = 1200,
            notification = 'Shoes equipped'
        }
    }
,
    weapon_pistol = {
        label = 'Pistol',
        weight = 1200,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_PISTOL',
        description = 'Pistol weapon',
        image = 'weapon_pistol.png',
        client = { image = 'weapon_pistol.png', notification = 'Pistol equipped' }
    },

    WEAPON_PISTOL = {
        label = 'Pistol',
        weight = 1200,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_PISTOL',
        description = 'Pistol weapon',
        image = 'weapon_pistol.png',
        client = { image = 'weapon_pistol.png', notification = 'Pistol equipped' }
    },

    WEAPON_KNIFE = {
        label = 'Knife',
        weight = 1000,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_KNIFE',
        description = 'Knife',
        image = 'weapon_knife.png',
        client = { image = 'weapon_knife.png', notification = 'Knife equipped' }
    },

    WEAPON_BAT = {
        label = 'Baseball Bat',
        weight = 1200,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_BAT',
        description = 'Baseball bat',
        image = 'weapon_bat.png',
        client = { image = 'weapon_bat.png', notification = 'Bat equipped' }
    },

    WEAPON_COMBATPISTOL = {
        label = 'Combat Pistol',
        weight = 1250,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_COMBATPISTOL',
        description = 'Combat pistol',
        image = 'weapon_combatpistol.png',
        client = { image = 'weapon_combatpistol.png', notification = 'Combat pistol equipped' }
    },

    WEAPON_STUNGUN = {
        label = 'Taser',
        weight = 1000,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_STUNGUN',
        description = 'Police taser',
        image = 'weapon_stungun.png',
        client = { image = 'weapon_stungun.png', notification = 'Taser equipped' }
    },

    WEAPON_NIGHTSTICK = {
        label = 'Nightstick',
        weight = 1000,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_NIGHTSTICK',
        description = 'Police nightstick',
        image = 'weapon_nightstick.png',
        client = { image = 'weapon_nightstick.png', notification = 'Nightstick equipped' }
    },

    WEAPON_FLASHLIGHT = {
        label = 'Flashlight',
        weight = 125,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_FLASHLIGHT',
        description = 'Flashlight',
        image = 'weapon_flashlight.png',
        client = { image = 'weapon_flashlight.png', notification = 'Flashlight equipped' }
    },

    -- RD Crafting materials + PRO attachment/tint items
    scrapmetal = {
        label = 'Scrap Metal',
        weight = 120,
        stack = true,
        close = false,
        consume = 0,
        description = 'Crafting material',
        image = 'scrapmetal.png',
        client = { image = 'scrapmetal.png' }
    },
    weapon_parts = {
        label = 'Weapon Parts',
        weight = 180,
        stack = true,
        close = false,
        consume = 0,
        description = 'Weapon crafting parts',
        image = 'scrapmetal.png',
        client = { image = 'scrapmetal.png' }
    },
    steel = {
        label = 'Steel',
        weight = 160,
        stack = true,
        close = false,
        consume = 0,
        description = 'Steel material',
        image = 'scrapmetal.png',
        client = { image = 'scrapmetal.png' }
    },
    rubber = {
        label = 'Rubber',
        weight = 60,
        stack = true,
        close = false,
        consume = 0,
        description = 'Rubber material',
        image = 'garbage.png',
        client = { image = 'garbage.png' }
    },
    cloth = {
        label = 'Cloth',
        weight = 40,
        stack = true,
        close = false,
        consume = 0,
        description = 'Cloth material',
        image = 'shirt.png',
        client = { image = 'shirt.png' }
    },
    electronics = {
        label = 'Electronics',
        weight = 120,
        stack = true,
        close = false,
        consume = 0,
        description = 'Electronic parts',
        image = 'radio.png',
        client = { image = 'radio.png' }
    },
    gunpowder = {
        label = 'Gunpowder',
        weight = 30,
        stack = true,
        close = false,
        consume = 0,
        description = 'Ammo material',
        image = 'ammo-rifle.png',
        client = { image = 'ammo-rifle.png' }
    },
    brass = {
        label = 'Brass',
        weight = 35,
        stack = true,
        close = false,
        consume = 0,
        description = 'Ammo casing material',
        image = 'ammo-9.png',
        client = { image = 'ammo-9.png' }
    },
    glass = {
        label = 'Glass',
        weight = 50,
        stack = true,
        close = false,
        consume = 0,
        description = 'Glass material',
        image = 'garbage.png',
        client = { image = 'garbage.png' }
    },
    paint = {
        label = 'Paint',
        weight = 80,
        stack = true,
        close = false,
        consume = 0,
        description = 'Weapon paint material',
        image = 'mustard.png',
        client = { image = 'mustard.png' }
    },
    wood = {
        label = 'Wood',
        weight = 90,
        stack = true,
        close = false,
        consume = 0,
        description = 'Wood material',
        image = 'wood.png',
        client = { image = 'wood.png' }
    },
    pistol_body = {
        label = 'Pistol Body',
        weight = 450,
        stack = true,
        close = false,
        consume = 0,
        description = 'Pistol receiver/body',
        image = 'WEAPON_PISTOL.png',
        client = { image = 'WEAPON_PISTOL.png' }
    },
    smg_body = {
        label = 'SMG Body',
        weight = 750,
        stack = true,
        close = false,
        consume = 0,
        description = 'SMG receiver/body',
        image = 'WEAPON_SMG.png',
        client = { image = 'WEAPON_SMG.png' }
    },
    rifle_body = {
        label = 'Rifle Body',
        weight = 1000,
        stack = true,
        close = false,
        consume = 0,
        description = 'Rifle receiver/body',
        image = 'WEAPON_CARBINERIFLE.png',
        client = { image = 'WEAPON_CARBINERIFLE.png' }
    },
    shotgun_body = {
        label = 'Shotgun Body',
        weight = 1000,
        stack = true,
        close = false,
        consume = 0,
        description = 'Shotgun receiver/body',
        image = 'WEAPON_PUMPSHOTGUN.png',
        client = { image = 'WEAPON_PUMPSHOTGUN.png' }
    },

    at_suppressor = { label = 'Suppressor', weight = 220, stack = true, close = false, consume = 0, description = 'Weapon attachment', image = 'at_suppressor.png', client = { image = 'at_suppressor.png' } },
    at_clip_extended = { label = 'Extended Clip', weight = 180, stack = true, close = false, consume = 0, description = 'Weapon attachment', image = 'at_clip_extended.png', client = { image = 'at_clip_extended.png' } },
    at_grip = { label = 'Grip', weight = 160, stack = true, close = false, consume = 0, description = 'Weapon attachment', image = 'at_grip.png', client = { image = 'at_grip.png' } },
    at_scope_medium = { label = 'Scope', weight = 260, stack = true, close = false, consume = 0, description = 'Weapon scope', image = 'at_scope_medium.png', client = { image = 'at_scope_medium.png' } },
    at_scope_holo = { label = 'Holographic Sight', weight = 220, stack = true, close = false, consume = 0, description = 'Weapon optic', image = 'at_scope_holo.png', client = { image = 'at_scope_holo.png' } },
    at_scope_large = { label = 'Large Scope', weight = 340, stack = true, close = false, consume = 0, description = 'Large weapon scope', image = 'at_scope_large.png', client = { image = 'at_scope_large.png' } },
    tint_boom = { label = 'Boom Camo', weight = 40, stack = true, close = false, consume = 0, description = 'Weapon tint/camo', image = 'tint_boom.png', client = { image = 'tint_boom.png' } },
    tint_leopard = { label = 'Leopard Camo', weight = 40, stack = true, close = false, consume = 0, description = 'Weapon tint/camo', image = 'tint_leopard.png', client = { image = 'tint_leopard.png' } },

    -- ================================================================
    -- RD CRAFTING OUTPUT ITEMS (auto-added: every crafted item exists)
    -- ================================================================

    repairkit = {
        label = 'Repair Kit',
        weight = 250,
        stack = true,
        close = true,
        consume = 1,
        description = 'Repair Kit',
        image = 'repairkit.png',
        client = { image = 'repairkit.png' }
    },

    bandage = {
        label = 'Bandage',
        weight = 250,
        stack = true,
        close = true,
        consume = 1,
        description = 'Bandage',
        image = 'bandage.png',
        client = { image = 'bandage.png' }
    },

    WEAPON_PISTOL_MK2 = {
        label = 'Pistol Mk II',
        weight = 1500,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_PISTOL_MK2',
        description = 'Pistol Mk II crafted weapon',
        image = 'WEAPON_PISTOL_MK2.png',
        client = {
            image = 'WEAPON_PISTOL_MK2.png',
            notification = 'Pistol Mk II equipped'
        }
    },

    WEAPON_APPISTOL = {
        label = 'AP Pistol',
        weight = 1500,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_APPISTOL',
        description = 'AP Pistol crafted weapon',
        image = 'WEAPON_APPISTOL.png',
        client = {
            image = 'WEAPON_APPISTOL.png',
            notification = 'AP Pistol equipped'
        }
    },

    WEAPON_PISTOL50 = {
        label = 'Pistol .50',
        weight = 1500,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_PISTOL50',
        description = 'Pistol .50 crafted weapon',
        image = 'WEAPON_PISTOL50.png',
        client = {
            image = 'WEAPON_PISTOL50.png',
            notification = 'Pistol .50 equipped'
        }
    },

    WEAPON_SNSPISTOL = {
        label = 'SNS Pistol',
        weight = 1500,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_SNSPISTOL',
        description = 'SNS Pistol crafted weapon',
        image = 'WEAPON_SNSPISTOL.png',
        client = {
            image = 'WEAPON_SNSPISTOL.png',
            notification = 'SNS Pistol equipped'
        }
    },

    WEAPON_HEAVYPISTOL = {
        label = 'Heavy Pistol',
        weight = 1500,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_HEAVYPISTOL',
        description = 'Heavy Pistol crafted weapon',
        image = 'WEAPON_HEAVYPISTOL.png',
        client = {
            image = 'WEAPON_HEAVYPISTOL.png',
            notification = 'Heavy Pistol equipped'
        }
    },

    WEAPON_VINTAGEPISTOL = {
        label = 'Vintage Pistol',
        weight = 1500,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_VINTAGEPISTOL',
        description = 'Vintage Pistol crafted weapon',
        image = 'WEAPON_VINTAGEPISTOL.png',
        client = {
            image = 'WEAPON_VINTAGEPISTOL.png',
            notification = 'Vintage Pistol equipped'
        }
    },

    WEAPON_MACHINEPISTOL = {
        label = 'Machine Pistol',
        weight = 1500,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_MACHINEPISTOL',
        description = 'Machine Pistol crafted weapon',
        image = 'WEAPON_MACHINEPISTOL.png',
        client = {
            image = 'WEAPON_MACHINEPISTOL.png',
            notification = 'Machine Pistol equipped'
        }
    },

    WEAPON_MICROSMG = {
        label = 'Micro SMG',
        weight = 3200,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_MICROSMG',
        description = 'Micro SMG crafted weapon',
        image = 'WEAPON_MICROSMG.png',
        client = {
            image = 'WEAPON_MICROSMG.png',
            notification = 'Micro SMG equipped'
        }
    },

    WEAPON_SMG = {
        label = 'SMG',
        weight = 3200,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_SMG',
        description = 'SMG crafted weapon',
        image = 'WEAPON_SMG.png',
        client = {
            image = 'WEAPON_SMG.png',
            notification = 'SMG equipped'
        }
    },

    WEAPON_SMG_MK2 = {
        label = 'SMG Mk II',
        weight = 3200,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_SMG_MK2',
        description = 'SMG Mk II crafted weapon',
        image = 'WEAPON_SMG_MK2.png',
        client = {
            image = 'WEAPON_SMG_MK2.png',
            notification = 'SMG Mk II equipped'
        }
    },

    WEAPON_ASSAULTSMG = {
        label = 'Assault SMG',
        weight = 3200,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_ASSAULTSMG',
        description = 'Assault SMG crafted weapon',
        image = 'WEAPON_ASSAULTSMG.png',
        client = {
            image = 'WEAPON_ASSAULTSMG.png',
            notification = 'Assault SMG equipped'
        }
    },

    WEAPON_COMBATPDW = {
        label = 'Combat PDW',
        weight = 500,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_COMBATPDW',
        description = 'Combat PDW crafted weapon',
        image = 'WEAPON_COMBATPDW.png',
        client = {
            image = 'WEAPON_COMBATPDW.png',
            notification = 'Combat PDW equipped'
        }
    },

    WEAPON_MINISMG = {
        label = 'Mini SMG',
        weight = 3200,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_MINISMG',
        description = 'Mini SMG crafted weapon',
        image = 'WEAPON_MINISMG.png',
        client = {
            image = 'WEAPON_MINISMG.png',
            notification = 'Mini SMG equipped'
        }
    },

    WEAPON_ASSAULTRIFLE = {
        label = 'Assault Rifle',
        weight = 3200,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_ASSAULTRIFLE',
        description = 'Assault Rifle crafted weapon',
        image = 'WEAPON_ASSAULTRIFLE.png',
        client = {
            image = 'WEAPON_ASSAULTRIFLE.png',
            notification = 'Assault Rifle equipped'
        }
    },

    WEAPON_ASSAULTRIFLE_MK2 = {
        label = 'Assault Rifle Mk II',
        weight = 3200,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_ASSAULTRIFLE_MK2',
        description = 'Assault Rifle Mk II crafted weapon',
        image = 'WEAPON_ASSAULTRIFLE_MK2.png',
        client = {
            image = 'WEAPON_ASSAULTRIFLE_MK2.png',
            notification = 'Assault Rifle Mk II equipped'
        }
    },

    WEAPON_CARBINERIFLE = {
        label = 'Carbine Rifle',
        weight = 3200,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_CARBINERIFLE',
        description = 'Carbine Rifle crafted weapon',
        image = 'WEAPON_CARBINERIFLE.png',
        client = {
            image = 'WEAPON_CARBINERIFLE.png',
            notification = 'Carbine Rifle equipped'
        }
    },

    WEAPON_CARBINERIFLE_MK2 = {
        label = 'Carbine Rifle Mk II',
        weight = 3200,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_CARBINERIFLE_MK2',
        description = 'Carbine Rifle Mk II crafted weapon',
        image = 'WEAPON_CARBINERIFLE_MK2.png',
        client = {
            image = 'WEAPON_CARBINERIFLE_MK2.png',
            notification = 'Carbine Rifle Mk II equipped'
        }
    },

    WEAPON_ADVANCEDRIFLE = {
        label = 'Advanced Rifle',
        weight = 3200,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_ADVANCEDRIFLE',
        description = 'Advanced Rifle crafted weapon',
        image = 'WEAPON_ADVANCEDRIFLE.png',
        client = {
            image = 'WEAPON_ADVANCEDRIFLE.png',
            notification = 'Advanced Rifle equipped'
        }
    },

    WEAPON_SPECIALCARBINE = {
        label = 'Special Carbine',
        weight = 500,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_SPECIALCARBINE',
        description = 'Special Carbine crafted weapon',
        image = 'WEAPON_SPECIALCARBINE.png',
        client = {
            image = 'WEAPON_SPECIALCARBINE.png',
            notification = 'Special Carbine equipped'
        }
    },

    WEAPON_SPECIALCARBINE_MK2 = {
        label = 'Special Carbine Mk II',
        weight = 500,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_SPECIALCARBINE_MK2',
        description = 'Special Carbine Mk II crafted weapon',
        image = 'WEAPON_SPECIALCARBINE_MK2.png',
        client = {
            image = 'WEAPON_SPECIALCARBINE_MK2.png',
            notification = 'Special Carbine Mk II equipped'
        }
    },

    WEAPON_BULLPUPRIFLE = {
        label = 'Bullpup Rifle',
        weight = 3200,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_BULLPUPRIFLE',
        description = 'Bullpup Rifle crafted weapon',
        image = 'WEAPON_BULLPUPRIFLE.png',
        client = {
            image = 'WEAPON_BULLPUPRIFLE.png',
            notification = 'Bullpup Rifle equipped'
        }
    },

    WEAPON_BULLPUPRIFLE_MK2 = {
        label = 'Bullpup Rifle Mk II',
        weight = 3200,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_BULLPUPRIFLE_MK2',
        description = 'Bullpup Rifle Mk II crafted weapon',
        image = 'WEAPON_BULLPUPRIFLE_MK2.png',
        client = {
            image = 'WEAPON_BULLPUPRIFLE_MK2.png',
            notification = 'Bullpup Rifle Mk II equipped'
        }
    },

    WEAPON_COMPACTRIFLE = {
        label = 'Compact Rifle',
        weight = 3200,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_COMPACTRIFLE',
        description = 'Compact Rifle crafted weapon',
        image = 'WEAPON_COMPACTRIFLE.png',
        client = {
            image = 'WEAPON_COMPACTRIFLE.png',
            notification = 'Compact Rifle equipped'
        }
    },

    WEAPON_MILITARYRIFLE = {
        label = 'Military Rifle',
        weight = 3200,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_MILITARYRIFLE',
        description = 'Military Rifle crafted weapon',
        image = 'WEAPON_MILITARYRIFLE.png',
        client = {
            image = 'WEAPON_MILITARYRIFLE.png',
            notification = 'Military Rifle equipped'
        }
    },

    WEAPON_HEAVYRIFLE = {
        label = 'Heavy Rifle',
        weight = 3200,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_HEAVYRIFLE',
        description = 'Heavy Rifle crafted weapon',
        image = 'WEAPON_HEAVYRIFLE.png',
        client = {
            image = 'WEAPON_HEAVYRIFLE.png',
            notification = 'Heavy Rifle equipped'
        }
    },

    WEAPON_PUMPSHOTGUN = {
        label = 'Pump Shotgun',
        weight = 3200,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_PUMPSHOTGUN',
        description = 'Pump Shotgun crafted weapon',
        image = 'WEAPON_PUMPSHOTGUN.png',
        client = {
            image = 'WEAPON_PUMPSHOTGUN.png',
            notification = 'Pump Shotgun equipped'
        }
    },

    WEAPON_PUMPSHOTGUN_MK2 = {
        label = 'Pump Shotgun Mk II',
        weight = 3200,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_PUMPSHOTGUN_MK2',
        description = 'Pump Shotgun Mk II crafted weapon',
        image = 'WEAPON_PUMPSHOTGUN_MK2.png',
        client = {
            image = 'WEAPON_PUMPSHOTGUN_MK2.png',
            notification = 'Pump Shotgun Mk II equipped'
        }
    },

    WEAPON_SAWNOFFSHOTGUN = {
        label = 'Sawed-Off Shotgun',
        weight = 3200,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_SAWNOFFSHOTGUN',
        description = 'Sawed-Off Shotgun crafted weapon',
        image = 'WEAPON_SAWNOFFSHOTGUN.png',
        client = {
            image = 'WEAPON_SAWNOFFSHOTGUN.png',
            notification = 'Sawed-Off Shotgun equipped'
        }
    },

    WEAPON_ASSAULTSHOTGUN = {
        label = 'Assault Shotgun',
        weight = 3200,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_ASSAULTSHOTGUN',
        description = 'Assault Shotgun crafted weapon',
        image = 'WEAPON_ASSAULTSHOTGUN.png',
        client = {
            image = 'WEAPON_ASSAULTSHOTGUN.png',
            notification = 'Assault Shotgun equipped'
        }
    },

    WEAPON_BULLPUPSHOTGUN = {
        label = 'Bullpup Shotgun',
        weight = 3200,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_BULLPUPSHOTGUN',
        description = 'Bullpup Shotgun crafted weapon',
        image = 'WEAPON_BULLPUPSHOTGUN.png',
        client = {
            image = 'WEAPON_BULLPUPSHOTGUN.png',
            notification = 'Bullpup Shotgun equipped'
        }
    },

    WEAPON_DBSHOTGUN = {
        label = 'Double Barrel Shotgun',
        weight = 3200,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_DBSHOTGUN',
        description = 'Double Barrel Shotgun crafted weapon',
        image = 'WEAPON_DBSHOTGUN.png',
        client = {
            image = 'WEAPON_DBSHOTGUN.png',
            notification = 'Double Barrel Shotgun equipped'
        }
    },

    WEAPON_AUTOSHOTGUN = {
        label = 'Sweeper Shotgun',
        weight = 3200,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_AUTOSHOTGUN',
        description = 'Sweeper Shotgun crafted weapon',
        image = 'WEAPON_AUTOSHOTGUN.png',
        client = {
            image = 'WEAPON_AUTOSHOTGUN.png',
            notification = 'Sweeper Shotgun equipped'
        }
    },

    WEAPON_COMBATSHOTGUN = {
        label = 'Combat Shotgun',
        weight = 3200,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_COMBATSHOTGUN',
        description = 'Combat Shotgun crafted weapon',
        image = 'WEAPON_COMBATSHOTGUN.png',
        client = {
            image = 'WEAPON_COMBATSHOTGUN.png',
            notification = 'Combat Shotgun equipped'
        }
    },

    WEAPON_MG = {
        label = 'MG',
        weight = 3200,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_MG',
        description = 'MG crafted weapon',
        image = 'WEAPON_MG.png',
        client = {
            image = 'WEAPON_MG.png',
            notification = 'MG equipped'
        }
    },

    WEAPON_COMBATMG = {
        label = 'Combat MG',
        weight = 3200,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_COMBATMG',
        description = 'Combat MG crafted weapon',
        image = 'WEAPON_COMBATMG.png',
        client = {
            image = 'WEAPON_COMBATMG.png',
            notification = 'Combat MG equipped'
        }
    },

    WEAPON_COMBATMG_MK2 = {
        label = 'Combat MG Mk II',
        weight = 3200,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_COMBATMG_MK2',
        description = 'Combat MG Mk II crafted weapon',
        image = 'WEAPON_COMBATMG_MK2.png',
        client = {
            image = 'WEAPON_COMBATMG_MK2.png',
            notification = 'Combat MG Mk II equipped'
        }
    },

    WEAPON_GUSENBERG = {
        label = 'Gusenberg Sweeper',
        weight = 500,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_GUSENBERG',
        description = 'Gusenberg Sweeper crafted weapon',
        image = 'WEAPON_GUSENBERG.png',
        client = {
            image = 'WEAPON_GUSENBERG.png',
            notification = 'Gusenberg Sweeper equipped'
        }
    },

    WEAPON_SNIPERRIFLE = {
        label = 'Sniper Rifle',
        weight = 3200,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_SNIPERRIFLE',
        description = 'Sniper Rifle crafted weapon',
        image = 'WEAPON_SNIPERRIFLE.png',
        client = {
            image = 'WEAPON_SNIPERRIFLE.png',
            notification = 'Sniper Rifle equipped'
        }
    },

    WEAPON_HEAVYSNIPER = {
        label = 'Heavy Sniper',
        weight = 3200,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_HEAVYSNIPER',
        description = 'Heavy Sniper crafted weapon',
        image = 'WEAPON_HEAVYSNIPER.png',
        client = {
            image = 'WEAPON_HEAVYSNIPER.png',
            notification = 'Heavy Sniper equipped'
        }
    },

    WEAPON_MARKSMANRIFLE = {
        label = 'Marksman Rifle',
        weight = 3200,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_MARKSMANRIFLE',
        description = 'Marksman Rifle crafted weapon',
        image = 'WEAPON_MARKSMANRIFLE.png',
        client = {
            image = 'WEAPON_MARKSMANRIFLE.png',
            notification = 'Marksman Rifle equipped'
        }
    },

    WEAPON_PRECISIONRIFLE = {
        label = 'Precision Rifle',
        weight = 3200,
        stack = false,
        close = true,
        consume = 0,
        weapon = 'WEAPON_PRECISIONRIFLE',
        description = 'Precision Rifle crafted weapon',
        image = 'WEAPON_PRECISIONRIFLE.png',
        client = {
            image = 'WEAPON_PRECISIONRIFLE.png',
            notification = 'Precision Rifle equipped'
        }
    },

    -- RD FINAL extra weapon attachments / colors
    at_suppressor_heavy = { label = 'Heavy Suppressor', weight = 220, stack = true, close = false, consume = 0, description = 'Weapon attachment', image = 'at_suppressor_heavy.png', client = { image = 'at_suppressor_heavy.png' } },
    at_clip_extended_smg = { label = 'SMG Extended Clip', weight = 180, stack = true, close = false, consume = 0, description = 'Weapon attachment', image = 'at_clip_extended_smg.png', client = { image = 'at_clip_extended_smg.png' } },
    at_clip_extended_rifle = { label = 'Rifle Extended Clip', weight = 180, stack = true, close = false, consume = 0, description = 'Weapon attachment', image = 'at_clip_extended_rifle.png', client = { image = 'at_clip_extended_rifle.png' } },
    at_clip_drum = { label = 'Drum Magazine', weight = 240, stack = true, close = false, consume = 0, description = 'Weapon attachment', image = 'at_clip_drum.png', client = { image = 'at_clip_drum.png' } },
    at_scope_small = { label = 'Small Scope', weight = 220, stack = true, close = false, consume = 0, description = 'Weapon attachment', image = 'at_scope_small.png', client = { image = 'at_scope_small.png' } },
    at_barrel = { label = 'Heavy Barrel', weight = 220, stack = true, close = false, consume = 0, description = 'Weapon attachment', image = 'at_barrel.png', client = { image = 'at_barrel.png' } },
    at_luxary_finish = { label = 'Luxury Weapon Finish', weight = 40, stack = true, close = false, consume = 0, description = 'Weapon attachment', image = 'at_luxary_finish.png', client = { image = 'at_luxary_finish.png' } },
    at_color_luxury = { label = 'Luxury Weapon Color', weight = 40, stack = true, close = false, consume = 0, description = 'Weapon attachment', image = 'at_luxary_finish.png', client = { image = 'at_luxary_finish.png' } },

}

return RDItems
