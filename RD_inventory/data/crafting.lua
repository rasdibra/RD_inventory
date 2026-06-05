RD = RD or {}

-- RD Crafting PRO: weapon table / attachments / levels.
-- Coords format: vector4(x, y, z, heading)
RDCrafting = {
    public = {
        label = 'Public Workbench', coords = vector4(46.25, -1749.41, 29.64, 50.0), radius = 2.0, target = true,
        prop = { enabled = true, model = 'prop_tool_bench02_ld', placeOnGround = true, freeze = true, offset = vec3(0.0, 0.0, -1.0) },
        recipes = {
            'lockpick',
            'repairkit',
            'bandage',
            'ammo9',
            'ammoRifle'
        }
    },
    weapon_bench = {
        label = 'Weapon Crafting Table', coords = vector4(810.42, -2157.73, 29.62, 180.0), radius = 2.0, target = true,
        prop = { enabled = true, model = 'gr_prop_gr_bench_02a', placeOnGround = true, freeze = true, offset = vec3(0.0, 0.0, -1.0) },
        recipes = {
            'pistol',
            'pistol_mk2',
            'combatpistol',
            'appistol',
            'pistol50',
            'snspistol',
            'heavypistol',
            'vintagepistol',
            'machinepistol',
            'microsmg',
            'smg',
            'smg_mk2',
            'assaultsmg',
            'combatpdw',
            'minismg',
            'assaultrifle',
            'assaultrifle_mk2',
            'carbinerifle',
            'carbinerifle_mk2',
            'advancedrifle',
            'specialcarbine',
            'specialcarbine_mk2',
            'bullpuprifle',
            'bullpuprifle_mk2',
            'compactrifle',
            'militaryrifle',
            'heavyrifle',
            'pumpshotgun',
            'pumpshotgun_mk2',
            'sawnoffshotgun',
            'assaultshotgun',
            'bullpupshotgun',
            'dbshotgun',
            'autoshotgun',
            'combatshotgun',
            'mg',
            'combatmg',
            'combatmg_mk2',
            'gusenberg',
            'sniperrifle',
            'heavysniper',
            'marksmanrifle',
            'precisionrifle',
            'flashlight_att',
            'suppressor_att',
            'extendedclip_att',
            'grip_att',
            'scope_att',
            'holo_att',
            'large_scope_att',
            'boom_camo',
            'leopard_camo'
        }
    },
    police = {
        label = 'Police Armory Craft', coords = vector4(482.27, -995.75, 30.69, 180.0), radius = 2.0, target = true, jobs = { police = 0 },
        prop = { enabled = true, model = 'gr_prop_gr_bench_02a', placeOnGround = true, freeze = true, offset = vec3(0.0, 0.0, -1.0) },
        recipes = {
            'evidence_bag',
            'radio',
            'taser',
            'nightstick',
            'ammo9',
            'ammoRifle',
            'flashlight_att',
            'grip_att',
            'scope_att'
        }
    },
    mechanic = {
        label = 'Mechanic Crafting', coords = vector4(-345.24, -131.07, 39.01, 70.0), radius = 2.0, target = true, jobs = { mechanic = 0 },
        prop = { enabled = true, model = 'prop_tool_bench02_ld', placeOnGround = true, freeze = true, offset = vec3(0.0, 0.0, -1.0) },
        recipes = {
            'repairkit',
            'lockpick',
            'flashlight_att'
        }
    }
}

-- item = final item added to inventory. ingredients are removed from inventory.
RDRecipes = {

    lockpick = {
        label = 'Lockpick',
        category = 'tools',
        item = 'lockpick',
        count = 1,
        level = 1,
        xp = 8,
        duration = 30000,
        image = 'lockpick.png',
        ingredients = {
            scrapmetal = 5
        }
    },

    repairkit = {
        label = 'Repair Kit',
        category = 'tools',
        item = 'repairkit',
        count = 1,
        level = 1,
        xp = 12,
        duration = 30000,
        image = 'advancedkit.png',
        ingredients = {
            scrapmetal = 10,
            rubber = 2
        }
    },

    bandage = {
        label = 'Bandage',
        category = 'medical',
        item = 'bandage',
        count = 2,
        level = 1,
        xp = 5,
        duration = 30000,
        image = 'bandage.png',
        ingredients = {
            cloth = 2
        }
    },

    evidence_bag = {
        label = 'Evidence Bag',
        category = 'police',
        item = 'evidence_bag',
        count = 5,
        level = 1,
        xp = 4,
        duration = 30000,
        image = 'paperbag.png',
        ingredients = {
            paperbag = 1
        }
    },

    radio = {
        label = 'Radio',
        category = 'tools',
        item = 'radio',
        count = 1,
        level = 2,
        xp = 18,
        duration = 30000,
        image = 'radio.png',
        ingredients = {
            scrapmetal = 8,
            electronics = 2
        }
    },

    ammo9 = {
        label = '9mm Ammo x30',
        category = 'ammo',
        item = 'ammo-9',
        count = 30,
        level = 1,
        xp = 8,
        duration = 30000,
        image = 'ammo-9.png',
        ingredients = {
            gunpowder = 3,
            brass = 3
        }
    },

    ammoRifle = {
        label = 'Rifle Ammo x30',
        category = 'ammo',
        item = 'ammo-rifle',
        count = 30,
        level = 2,
        xp = 12,
        duration = 30000,
        image = 'ammo-rifle.png',
        ingredients = {
            gunpowder = 5,
            brass = 5
        }
    },

    pistol = {
        label = 'Pistol',
        category = 'weapons',
        item = 'WEAPON_PISTOL',
        count = 1,
        level = 2,
        xp = 40,
        duration = 30000,
        image = 'WEAPON_PISTOL.png',
        ingredients = {
            weapon_parts = 8,
            steel = 12,
            gunpowder = 2
        }
    },

    pistol_mk2 = {
        label = 'Pistol Mk II',
        category = 'weapons',
        item = 'WEAPON_PISTOL_MK2',
        count = 1,
        level = 3,
        xp = 55,
        duration = 30000,
        image = 'WEAPON_PISTOL_MK2.png',
        ingredients = {
            weapon_parts = 10,
            steel = 14,
            electronics = 2
        }
    },

    combatpistol = {
        label = 'Combat Pistol',
        category = 'weapons',
        item = 'WEAPON_COMBATPISTOL',
        count = 1,
        level = 3,
        xp = 55,
        duration = 30000,
        image = 'WEAPON_COMBATPISTOL.png',
        ingredients = {
            weapon_parts = 12,
            steel = 16,
            gunpowder = 3
        }
    },

    appistol = {
        label = 'AP Pistol',
        category = 'weapons',
        item = 'WEAPON_APPISTOL',
        count = 1,
        level = 4,
        xp = 75,
        duration = 30000,
        image = 'WEAPON_APPISTOL.png',
        ingredients = {
            weapon_parts = 16,
            steel = 18,
            electronics = 3
        }
    },

    pistol50 = {
        label = 'Pistol .50',
        category = 'weapons',
        item = 'WEAPON_PISTOL50',
        count = 1,
        level = 4,
        xp = 80,
        duration = 30000,
        image = 'WEAPON_PISTOL50.png',
        ingredients = {
            weapon_parts = 18,
            steel = 22,
            gunpowder = 5
        }
    },

    snspistol = {
        label = 'SNS Pistol',
        category = 'weapons',
        item = 'WEAPON_SNSPISTOL',
        count = 1,
        level = 2,
        xp = 35,
        duration = 30000,
        image = 'WEAPON_SNSPISTOL.png',
        ingredients = {
            weapon_parts = 7,
            steel = 10,
            rubber = 1
        }
    },

    heavypistol = {
        label = 'Heavy Pistol',
        category = 'weapons',
        item = 'WEAPON_HEAVYPISTOL',
        count = 1,
        level = 4,
        xp = 75,
        duration = 30000,
        image = 'WEAPON_HEAVYPISTOL.png',
        ingredients = {
            weapon_parts = 17,
            steel = 23,
            gunpowder = 4
        }
    },

    vintagepistol = {
        label = 'Vintage Pistol',
        category = 'weapons',
        item = 'WEAPON_VINTAGEPISTOL',
        count = 1,
        level = 3,
        xp = 50,
        duration = 30000,
        image = 'WEAPON_VINTAGEPISTOL.png',
        ingredients = {
            weapon_parts = 10,
            steel = 12,
            wood = 3
        }
    },

    machinepistol = {
        label = 'Machine Pistol',
        category = 'weapons',
        item = 'WEAPON_MACHINEPISTOL',
        count = 1,
        level = 5,
        xp = 95,
        duration = 30000,
        image = 'WEAPON_MACHINEPISTOL.png',
        ingredients = {
            weapon_parts = 22,
            steel = 26,
            electronics = 3
        }
    },

    microsmg = {
        label = 'Micro SMG',
        category = 'weapons',
        item = 'WEAPON_MICROSMG',
        count = 1,
        level = 5,
        xp = 95,
        duration = 30000,
        image = 'WEAPON_MICROSMG.png',
        ingredients = {
            weapon_parts = 24,
            steel = 28,
            rubber = 5
        }
    },

    smg = {
        label = 'SMG',
        category = 'weapons',
        item = 'WEAPON_SMG',
        count = 1,
        level = 5,
        xp = 100,
        duration = 30000,
        image = 'WEAPON_SMG.png',
        ingredients = {
            weapon_parts = 25,
            steel = 30,
            rubber = 5
        }
    },

    smg_mk2 = {
        label = 'SMG Mk II',
        category = 'weapons',
        item = 'WEAPON_SMG_MK2',
        count = 1,
        level = 6,
        xp = 130,
        duration = 30000,
        image = 'WEAPON_SMG_MK2.png',
        ingredients = {
            weapon_parts = 32,
            steel = 38,
            electronics = 6
        }
    },

    assaultsmg = {
        label = 'Assault SMG',
        category = 'weapons',
        item = 'WEAPON_ASSAULTSMG',
        count = 1,
        level = 6,
        xp = 130,
        duration = 30000,
        image = 'WEAPON_ASSAULTSMG.png',
        ingredients = {
            weapon_parts = 34,
            steel = 40,
            electronics = 5
        }
    },

    combatpdw = {
        label = 'Combat PDW',
        category = 'weapons',
        item = 'WEAPON_COMBATPDW',
        count = 1,
        level = 6,
        xp = 125,
        duration = 30000,
        image = 'WEAPON_COMBATPDW.png',
        ingredients = {
            weapon_parts = 32,
            steel = 38,
            rubber = 6
        }
    },

    minismg = {
        label = 'Mini SMG',
        category = 'weapons',
        item = 'WEAPON_MINISMG',
        count = 1,
        level = 4,
        xp = 80,
        duration = 30000,
        image = 'WEAPON_MINISMG.png',
        ingredients = {
            weapon_parts = 18,
            steel = 23,
            rubber = 4
        }
    },

    assaultrifle = {
        label = 'Assault Rifle',
        category = 'weapons',
        item = 'WEAPON_ASSAULTRIFLE',
        count = 1,
        level = 7,
        xp = 150,
        duration = 30000,
        image = 'WEAPON_ASSAULTRIFLE.png',
        ingredients = {
            rifle_body = 1,
            weapon_parts = 38,
            steel = 48,
            gunpowder = 8
        }
    },

    assaultrifle_mk2 = {
        label = 'Assault Rifle Mk II',
        category = 'weapons',
        item = 'WEAPON_ASSAULTRIFLE_MK2',
        count = 1,
        level = 8,
        xp = 180,
        duration = 30000,
        image = 'WEAPON_ASSAULTRIFLE_MK2.png',
        ingredients = {
            rifle_body = 1,
            weapon_parts = 48,
            steel = 58,
            electronics = 8
        }
    },

    carbinerifle = {
        label = 'Carbine Rifle',
        category = 'weapons',
        item = 'WEAPON_CARBINERIFLE',
        count = 1,
        level = 7,
        xp = 155,
        duration = 30000,
        image = 'WEAPON_CARBINERIFLE.png',
        ingredients = {
            rifle_body = 1,
            weapon_parts = 40,
            steel = 50,
            electronics = 4
        }
    },

    carbinerifle_mk2 = {
        label = 'Carbine Rifle Mk II',
        category = 'weapons',
        item = 'WEAPON_CARBINERIFLE_MK2',
        count = 1,
        level = 8,
        xp = 185,
        duration = 30000,
        image = 'WEAPON_CARBINERIFLE_MK2.png',
        ingredients = {
            rifle_body = 1,
            weapon_parts = 52,
            steel = 62,
            electronics = 8
        }
    },

    advancedrifle = {
        label = 'Advanced Rifle',
        category = 'weapons',
        item = 'WEAPON_ADVANCEDRIFLE',
        count = 1,
        level = 8,
        xp = 175,
        duration = 30000,
        image = 'WEAPON_ADVANCEDRIFLE.png',
        ingredients = {
            rifle_body = 1,
            weapon_parts = 48,
            steel = 58,
            electronics = 7
        }
    },

    specialcarbine = {
        label = 'Special Carbine',
        category = 'weapons',
        item = 'WEAPON_SPECIALCARBINE',
        count = 1,
        level = 7,
        xp = 160,
        duration = 30000,
        image = 'WEAPON_SPECIALCARBINE.png',
        ingredients = {
            rifle_body = 1,
            weapon_parts = 42,
            steel = 52,
            electronics = 5
        }
    },

    specialcarbine_mk2 = {
        label = 'Special Carbine Mk II',
        category = 'weapons',
        item = 'WEAPON_SPECIALCARBINE_MK2',
        count = 1,
        level = 9,
        xp = 205,
        duration = 30000,
        image = 'WEAPON_SPECIALCARBINE_MK2.png',
        ingredients = {
            rifle_body = 1,
            weapon_parts = 58,
            steel = 70,
            electronics = 10
        }
    },

    bullpuprifle = {
        label = 'Bullpup Rifle',
        category = 'weapons',
        item = 'WEAPON_BULLPUPRIFLE',
        count = 1,
        level = 7,
        xp = 150,
        duration = 30000,
        image = 'WEAPON_BULLPUPRIFLE.png',
        ingredients = {
            rifle_body = 1,
            weapon_parts = 38,
            steel = 48,
            rubber = 6
        }
    },

    bullpuprifle_mk2 = {
        label = 'Bullpup Rifle Mk II',
        category = 'weapons',
        item = 'WEAPON_BULLPUPRIFLE_MK2',
        count = 1,
        level = 9,
        xp = 200,
        duration = 30000,
        image = 'WEAPON_BULLPUPRIFLE_MK2.png',
        ingredients = {
            rifle_body = 1,
            weapon_parts = 56,
            steel = 68,
            electronics = 9
        }
    },

    compactrifle = {
        label = 'Compact Rifle',
        category = 'weapons',
        item = 'WEAPON_COMPACTRIFLE',
        count = 1,
        level = 6,
        xp = 135,
        duration = 30000,
        image = 'WEAPON_COMPACTRIFLE.png',
        ingredients = {
            rifle_body = 1,
            weapon_parts = 34,
            steel = 42,
            rubber = 5
        }
    },

    militaryrifle = {
        label = 'Military Rifle',
        category = 'weapons',
        item = 'WEAPON_MILITARYRIFLE',
        count = 1,
        level = 9,
        xp = 210,
        duration = 30000,
        image = 'WEAPON_MILITARYRIFLE.png',
        ingredients = {
            rifle_body = 1,
            weapon_parts = 60,
            steel = 72,
            electronics = 11
        }
    },

    heavyrifle = {
        label = 'Heavy Rifle',
        category = 'weapons',
        item = 'WEAPON_HEAVYRIFLE',
        count = 1,
        level = 9,
        xp = 220,
        duration = 30000,
        image = 'WEAPON_HEAVYRIFLE.png',
        ingredients = {
            rifle_body = 1,
            weapon_parts = 64,
            steel = 78,
            electronics = 12
        }
    },

    pumpshotgun = {
        label = 'Pump Shotgun',
        category = 'weapons',
        item = 'WEAPON_PUMPSHOTGUN',
        count = 1,
        level = 5,
        xp = 95,
        duration = 30000,
        image = 'WEAPON_PUMPSHOTGUN.png',
        ingredients = {
            weapon_parts = 22,
            steel = 30,
            rubber = 4
        }
    },

    pumpshotgun_mk2 = {
        label = 'Pump Shotgun Mk II',
        category = 'weapons',
        item = 'WEAPON_PUMPSHOTGUN_MK2',
        count = 1,
        level = 7,
        xp = 140,
        duration = 30000,
        image = 'WEAPON_PUMPSHOTGUN_MK2.png',
        ingredients = {
            weapon_parts = 38,
            steel = 48,
            electronics = 5
        }
    },

    sawnoffshotgun = {
        label = 'Sawed-Off Shotgun',
        category = 'weapons',
        item = 'WEAPON_SAWNOFFSHOTGUN',
        count = 1,
        level = 4,
        xp = 80,
        duration = 30000,
        image = 'WEAPON_SAWNOFFSHOTGUN.png',
        ingredients = {
            weapon_parts = 18,
            steel = 24,
            wood = 5
        }
    },

    assaultshotgun = {
        label = 'Assault Shotgun',
        category = 'weapons',
        item = 'WEAPON_ASSAULTSHOTGUN',
        count = 1,
        level = 8,
        xp = 175,
        duration = 30000,
        image = 'WEAPON_ASSAULTSHOTGUN.png',
        ingredients = {
            weapon_parts = 48,
            steel = 58,
            electronics = 7
        }
    },

    bullpupshotgun = {
        label = 'Bullpup Shotgun',
        category = 'weapons',
        item = 'WEAPON_BULLPUPSHOTGUN',
        count = 1,
        level = 7,
        xp = 145,
        duration = 30000,
        image = 'WEAPON_BULLPUPSHOTGUN.png',
        ingredients = {
            weapon_parts = 38,
            steel = 48,
            rubber = 7
        }
    },

    dbshotgun = {
        label = 'Double Barrel Shotgun',
        category = 'weapons',
        item = 'WEAPON_DBSHOTGUN',
        count = 1,
        level = 4,
        xp = 78,
        duration = 30000,
        image = 'WEAPON_DBSHOTGUN.png',
        ingredients = {
            weapon_parts = 16,
            steel = 22,
            wood = 5
        }
    },

    autoshotgun = {
        label = 'Sweeper Shotgun',
        category = 'weapons',
        item = 'WEAPON_AUTOSHOTGUN',
        count = 1,
        level = 7,
        xp = 150,
        duration = 30000,
        image = 'WEAPON_AUTOSHOTGUN.png',
        ingredients = {
            weapon_parts = 40,
            steel = 48,
            rubber = 8
        }
    },

    combatshotgun = {
        label = 'Combat Shotgun',
        category = 'weapons',
        item = 'WEAPON_COMBATSHOTGUN',
        count = 1,
        level = 8,
        xp = 180,
        duration = 30000,
        image = 'WEAPON_COMBATSHOTGUN.png',
        ingredients = {
            weapon_parts = 52,
            steel = 62,
            electronics = 7
        }
    },

    mg = {
        label = 'MG',
        category = 'weapons',
        item = 'WEAPON_MG',
        count = 1,
        level = 8,
        xp = 185,
        duration = 30000,
        image = 'WEAPON_MG.png',
        ingredients = {
            rifle_body = 1,
            weapon_parts = 58,
            steel = 75,
            gunpowder = 12
        }
    },

    combatmg = {
        label = 'Combat MG',
        category = 'weapons',
        item = 'WEAPON_COMBATMG',
        count = 1,
        level = 9,
        xp = 220,
        duration = 30000,
        image = 'WEAPON_COMBATMG.png',
        ingredients = {
            rifle_body = 1,
            weapon_parts = 70,
            steel = 90,
            electronics = 10
        }
    },

    combatmg_mk2 = {
        label = 'Combat MG Mk II',
        category = 'weapons',
        item = 'WEAPON_COMBATMG_MK2',
        count = 1,
        level = 10,
        xp = 260,
        duration = 30000,
        image = 'WEAPON_COMBATMG_MK2.png',
        ingredients = {
            rifle_body = 1,
            weapon_parts = 88,
            steel = 110,
            electronics = 14
        }
    },

    gusenberg = {
        label = 'Gusenberg Sweeper',
        category = 'weapons',
        item = 'WEAPON_GUSENBERG',
        count = 1,
        level = 7,
        xp = 150,
        duration = 30000,
        image = 'WEAPON_GUSENBERG.png',
        ingredients = {
            weapon_parts = 40,
            steel = 45,
            wood = 8
        }
    },

    sniperrifle = {
        label = 'Sniper Rifle',
        category = 'weapons',
        item = 'WEAPON_SNIPERRIFLE',
        count = 1,
        level = 9,
        xp = 230,
        duration = 30000,
        image = 'WEAPON_SNIPERRIFLE.png',
        ingredients = {
            rifle_body = 1,
            weapon_parts = 70,
            steel = 85,
            glass = 8
        }
    },

    heavysniper = {
        label = 'Heavy Sniper',
        category = 'weapons',
        item = 'WEAPON_HEAVYSNIPER',
        count = 1,
        level = 10,
        xp = 290,
        duration = 30000,
        image = 'WEAPON_HEAVYSNIPER.png',
        ingredients = {
            rifle_body = 1,
            weapon_parts = 95,
            steel = 120,
            glass = 12
        }
    },

    marksmanrifle = {
        label = 'Marksman Rifle',
        category = 'weapons',
        item = 'WEAPON_MARKSMANRIFLE',
        count = 1,
        level = 9,
        xp = 220,
        duration = 30000,
        image = 'WEAPON_MARKSMANRIFLE.png',
        ingredients = {
            rifle_body = 1,
            weapon_parts = 65,
            steel = 80,
            glass = 10
        }
    },

    precisionrifle = {
        label = 'Precision Rifle',
        category = 'weapons',
        item = 'WEAPON_PRECISIONRIFLE',
        count = 1,
        level = 10,
        xp = 300,
        duration = 30000,
        image = 'WEAPON_PRECISIONRIFLE.png',
        ingredients = {
            rifle_body = 1,
            weapon_parts = 100,
            steel = 125,
            glass = 15
        }
    },

    taser = {
        label = 'Police Taser',
        category = 'police',
        item = 'WEAPON_STUNGUN',
        count = 1,
        level = 2,
        xp = 30,
        duration = 30000,
        image = 'WEAPON_STUNGUN.png',
        ingredients = {
            electronics = 6,
            steel = 8
        }
    },

    nightstick = {
        label = 'Nightstick',
        category = 'police',
        item = 'WEAPON_NIGHTSTICK',
        count = 1,
        level = 1,
        xp = 10,
        duration = 30000,
        image = 'WEAPON_NIGHTSTICK.png',
        ingredients = {
            rubber = 4,
            steel = 2
        }
    },

    flashlight_att = {
        label = 'Flashlight Attachment',
        category = 'attachments',
        item = 'at_flashlight',
        count = 1,
        level = 1,
        xp = 12,
        duration = 30000,
        image = 'at_flashlight.png',
        ingredients = {
            electronics = 2,
            scrapmetal = 4
        }
    },

    suppressor_att = {
        label = 'Suppressor',
        category = 'attachments',
        item = 'at_suppressor',
        count = 1,
        level = 3,
        xp = 30,
        duration = 30000,
        image = 'at_suppressor.png',
        ingredients = {
            steel = 12,
            rubber = 3
        }
    },

    extendedclip_att = {
        label = 'Extended Clip',
        category = 'attachments',
        item = 'at_clip_extended',
        count = 1,
        level = 2,
        xp = 20,
        duration = 30000,
        image = 'at_clip_extended.png',
        ingredients = {
            steel = 10,
            weapon_parts = 3
        }
    },

    grip_att = {
        label = 'Grip',
        category = 'attachments',
        item = 'at_grip',
        count = 1,
        level = 2,
        xp = 18,
        duration = 30000,
        image = 'at_grip.png',
        ingredients = {
            rubber = 4,
            scrapmetal = 6
        }
    },

    scope_att = {
        label = 'Scope',
        category = 'attachments',
        item = 'at_scope_medium',
        count = 1,
        level = 3,
        xp = 28,
        duration = 30000,
        image = 'at_scope_medium.png',
        ingredients = {
            glass = 3,
            electronics = 3,
            steel = 5
        }
    },

    holo_att = {
        label = 'Holographic Sight',
        category = 'attachments',
        item = 'at_scope_holo',
        count = 1,
        level = 4,
        xp = 35,
        duration = 30000,
        image = 'at_scope_holo.png',
        ingredients = {
            glass = 4,
            electronics = 6,
            steel = 6
        }
    },

    large_scope_att = {
        label = 'Large Scope',
        category = 'attachments',
        item = 'at_scope_large',
        count = 1,
        level = 5,
        xp = 50,
        duration = 30000,
        image = 'at_scope_large.png',
        ingredients = {
            glass = 6,
            electronics = 8,
            steel = 8
        }
    },

    boom_camo = {
        label = 'Boom Camo',
        category = 'tints',
        item = 'tint_boom',
        count = 1,
        level = 3,
        xp = 18,
        duration = 30000,
        image = 'tint_boom.png',
        ingredients = {
            paint = 4,
            cloth = 2
        }
    },

    leopard_camo = {
        label = 'Leopard Camo',
        category = 'tints',
        item = 'tint_leopard',
        count = 1,
        level = 4,
        xp = 22,
        duration = 30000,
        image = 'tint_leopard.png',
        ingredients = {
            paint = 5,
            cloth = 3
        }
    }
}

RD.Crafting = RDCrafting
RD.Recipes = RDRecipes

return { benches = RDCrafting, recipes = RDRecipes }
