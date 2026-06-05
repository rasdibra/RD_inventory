RDConfig = {
    debug = false, -- true vetem kur do logs ne console
    framework = 'esx', -- auto, esx, qb, qbx, standalone

    interaction = {
        -- ZGJIDH VETEM NJERIN: 'ox_target', 'qb-target', 'textui'
        -- ox_target  = vetem ox_target eye
        -- qb-target  = vetem qb-target eye
        -- textui     = vetem [E] TextUI / 3D text
        mode = 'ox_target',

        ox_target = true,
        qb_target = false,
        textui = false,
        key = 38, -- E

        -- kur mode eshte target, fallback [E] eshte OFF qe mos dalin dy here opsionet
        disableFallbackTextUIWhenTarget = true
    },

    inventory = {
        maxWeight = 120000, -- grams, 120 KG
        slots = 50,
        command = 'inventory',
        openKey = 'TAB',
        hotbarKey = 'Z',
        hotbarSlots = 5,

        -- Anti-glitch / fast open-close protection.
        -- Prevents TAB/ESX menu spam from freezing NUI focus.
        toggleCooldown = 350,
        openCooldown = 450,
        closeCooldown = 250,
        fastClose = true,

        hotbarUseKeys = { '1', '2', '3', '4', '5' }
    },

    money = {
        asItem = true,
        item = 'money',
        aliases = { 'cash' },
        label = 'Cash',
        startAmount = 5000,
        preferredSlot = 1
    },

    drops = {
        lifeSeconds = 300,
        prop = 'prop_cs_heist_bag_02',
        distance = 3.0,
        slots = 25
    },

    robbery = {
        enabled = true,

        -- Rob dead/downed player body. Works with ESX/QB death states and GTA native death check.
        deadBody = {
            enabled = true,
            -- ONLY TARGET: no E/G/H buttons and no key mapping.
            commandsEnabled = false,
            keyEnabled = false,
            command = 'robdead',
            key = 'G',
            distance = 2.0,
            label = 'Search / Rob Body',
            icon = 'fa-solid fa-hand-holding',
            requireHandsUpOrDead = false,
            allowOnlyWhenTargetDead = true
        },

        -- NPC robbery when you aim a weapon at a pedestrian.
        npc = {
            enabled = true,
            distance = 8.0,
            requireWeapon = true,
            handsUpTime = 90000,
            cooldown = 120000,
            ignoreModels = {
                [`mp_m_shopkeep_01`] = true,
                [`s_m_y_cop_01`] = true,
                [`s_f_y_cop_01`] = true
            },
            rewards = {
                enabled = true,
                minMoney = 20,
                maxMoney = 150,
                chanceItem = 15,
                items = {
                    { name = 'phone', min = 1, max = 1 },
                    { name = 'water', min = 1, max = 2 },
                    { name = 'bread', min = 1, max = 2 }
                }
            }
        },

        hostage = {
            enabled = true,
            distance = 2.0,
            commandsEnabled = false,
            followCommand = 'rdfollow',
            releaseCommand = 'rdreleasehostage'
        },

        -- Real NPC animations / movement. Keep enabled=true for no-glitch AI behavior.
        animations = {
            enabled = true,

            -- First surrender when aiming gun. Native hands-up is most stable.
            useNativeHandsUp = true,
            surrenderDict = 'random@mugging3',
            surrenderAnim = 'handsup_standing_base',

            -- Player search/rob animation when taking cash/items.
            playerRobDict = 'amb@prop_human_bum_bin@base',
            playerRobAnim = 'base',
            playerRobTime = 2500,

            -- NPC reaction after being robbed.
            robbedDict = 'random@arrests',
            robbedAnim = 'kneeling_arrest_idle',
            robbedTime = 2500,

            -- Follow/hostage walking style. These clipsets allow ped to walk without freezing/glitching.
            followMoveClipset = 'move_m@prisoner_cuffed',
            hostageMoveClipset = 'move_m@prisoner_cuffed',
            followSpeed = 1.25,
            followSprintDistance = 9.0,
            followStopDistance = 1.8,
            hostageStopDistance = 0.95,
            retaskEveryMs = 1300
        },

        menu = {
            commandsEnabled = false,
            command = 'robmenu',
            keyEnabled = false,
            key = 'H',
            distance = 2.5
        },

        target = {
            enabled = true,
            -- auto: ox_target first, if not started uses qb-target.
            system = 'auto',
            distance = 2.5,
            robNpcLabel = 'Rob NPC',
            icon = 'fa-solid fa-mask',
            onlySurrenderedNPC = true
        },

        -- old config name kept for compatibility
        oxTarget = {
            enabled = true,
            distance = 2.5,
            label = 'Open Robbery Menu',
            icon = 'fa-solid fa-handcuffs',
            onlySurrenderedNPC = true
        },

        dispatch = {
            enabled = true,
            cooldown = 60000,
            policeJobs = { 'police', 'sheriff', 'state' },

            -- ZGJIDH NJERIN: 'rd_mdt', 'rd_ndt', 'ps-dispatch', 'cd_dispatch',
            -- 'qs-dispatch', 'core_dispatch', 'custom_event', 'none'
            system = 'rd_mdt',

            -- Për çfarë ngjarjesh të shkojë alert në dispatch/MDT.
            events = {
                npcRobbery = true,
                hostage = true,
                deadBodyRobbery = true
            },

            alerts = {
                npcRobbery = {
                    title = 'NPC Robbery',
                    message = 'Person with weapon robbing a civilian',
                    code = '10-31',
                    sprite = 156, colour = 1, scale = 1.0, time = 60
                },
                hostage = {
                    title = 'Hostage Situation',
                    message = 'Possible hostage situation reported',
                    code = '10- hostage',
                    sprite = 480, colour = 1, scale = 1.1, time = 90
                },
                deadBodyRobbery = {
                    title = 'Body Robbery',
                    message = 'Someone is searching a downed/dead person',
                    code = '10-30',
                    sprite = 303, colour = 1, scale = 1.0, time = 60
                }
            },

            -- Nëse sistemi jot ka emër/event ndryshe, ndrysho vetëm këtu.
            custom = {
                clientEvent = '', -- p.sh. 'my_dispatch:client:alert'
                serverEvent = '', -- p.sh. 'my_dispatch:server:alert'
                exportResource = '',
                exportName = ''
            }
        },
    },


    weapons = {
        -- Guns are bought/given with 0 bullets. Ammo items are required for reload.
        startAmmo = 0,
        reloadKey = 'R',
        reloadTime = 1600,
        reloadAmount = 12,
        allowUseAmmoItem = true,
        ammoUseTime = 1400,
        attachmentUseTime = 1800,
        openAttachmentsOnWeaponClick = true, -- when inventory is open, USE/click weapon opens attachment UI

        -- Weapon toggle/unquip controls.
        toggleSameHotbarToUnquip = true, -- press 1-5/use same weapon again = holster/unquip
        unquipKeyEnabled = true,
        unquipCommand = 'rd_weapon_unquip',
        unquipKey = 'X', -- hands up / cancel weapon in hand
        unquipAnimTime = 650,

        -- Weapon draw animations by job.
        -- Jobs in whitelist draw weapon from side/holster like police.
        -- All other jobs draw from belly/front like gangster.
        holster = {
            enabled = true,
            allowInVehicle = false,
            whitelistJobs = {
                police = true,
                sheriff = true,
                state = true,
                ambulance = true
            },
            normalAnim = {
                dict = 'reaction@intimidation@cop@unarmed',
                clip = 'intro',
                duration = 850,
                drawAt = 520,
                flag = 48
            },
            gangsterAnim = {
                dict = 'reaction@intimidation@1h',
                clip = 'intro',
                duration = 1200,
                drawAt = 760,
                flag = 48
            }
        },

        ammoItems = {
            ['ammo-9'] = { 'WEAPON_PISTOL', 'WEAPON_COMBATPISTOL', 'WEAPON_MICROSMG', 'WEAPON_SMG' },
            ['ammo-45'] = { 'WEAPON_SNSPISTOL' },
            ['ammo-50'] = { 'WEAPON_PISTOL50' },
            ['ammo-rifle'] = { 'WEAPON_ASSAULTRIFLE', 'WEAPON_CARBINERIFLE' },
            ['ammo-shotgun'] = { 'WEAPON_PUMPSHOTGUN' }
        }
    },

    vehicles = {
        trunkSlots = 35,
        trunkWeight = 80000,
        gloveboxSlots = 10,
        gloveboxWeight = 15000,

        -- Press K near a vehicle to open TRUNK/BAGAZH.
        trunkKeyEnabled = true,
        trunkKeyCommand = 'rd_trunk',
        trunkKey = 'K',
        -- Player must stand behind the vehicle, not on the side/front.
        trunkSearchDistance = 4.0,
        trunkRearDistance = 1.8,
        trunkRearOffsetY = -2.65,
        trunkDistance = 1.8,

        -- false = no text UI/help text above. Press K only when you are behind the vehicle.
        showTrunkPrompt = false,

        -- If vehicle is locked, trunk will not open and player gets notify.
        checkVehicleLocked = true,
        openTrunkDoor = true,
        closeTrunkDoorOnInventoryClose = true,
        trunkAnim = true
    },

    clothes = {
        useDpClothing = true,
        dpInsideInventory = true,
        dpEvent = 'dpc:ToggleMenu',
        closeInventoryWhenOpenDp = true,
        defaults = {
            hat = 'hat_black',
            mask = 'mask_black',
            shirt = 'shirt_white',
            gloves = 'gloves_black',
            pants = 'pants_blue',
            shoes = 'shoes_black'
        }
    }
}

RD.MaxWeight = RDConfig.inventory.maxWeight
RD.MaxSlots = RDConfig.inventory.slots
RD.OpenKey = RDConfig.inventory.openKey
RD.HotbarKey = RDConfig.inventory.hotbarKey
RD.HotbarSlots = RDConfig.inventory.hotbarSlots
RD.HotbarUseKeys = RDConfig.inventory.hotbarUseKeys
RD.Command = RDConfig.inventory.command

if RDConfig.framework and RDConfig.framework ~= 'auto' then
    RD.Framework = RDConfig.framework
end

RD.Debug = RDConfig.debug == true


-- Discord webhook logs. Put your webhook URL here.
RDConfig.webhooks = RDConfig.webhooks or {
    enabled = true,
    default = 'YOUR_DISCORD_WEBHOOK_HERE',
    username = 'RD Inventory Logs',
    color = 15158332,
    events = {
        admin_giveitem = '', admin_removeitem = '', admin_clearinv = '', admin_giveweapon = '',
        give = '', drop = '', pickup = '', stash = '', trunk = '', glovebox = '', craft = ''
    }
}

return RDConfig
