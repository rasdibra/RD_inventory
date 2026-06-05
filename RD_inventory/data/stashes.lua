RD = RD or {}

-- RD_inventory stashes
-- Coords format: vector4(x, y, z, heading)
-- type = 'job'      -> shared stash for selected jobs
-- type = 'gang'     -> shared stash for selected gangs
-- type = 'personal' -> same location, but private stash for each player identifier
-- ped.enabled = true spawns an NPC with ox_target/qb-target. false uses zone/marker.
RDStashes = {
    police_armory = {
        label = 'Police Armory',
        type = 'job',
        jobs = { police = 0 },
        slots = 80,
        weight = 300000,
        coords = vector4(482.27, -995.75, 30.69, 90.0),
        radius = 2.0,
        marker = false,
        ped = {
            enabled = true,
            model = 's_m_y_cop_01',
            heading = 90.0,
            scenario = 'WORLD_HUMAN_GUARD_STAND'
        }
    },

    police_evidence = {
        label = 'Police Evidence',
        type = 'job',
        jobs = { police = 0, sheriff = 0 },
        slots = 100,
        weight = 500000,
        coords = vector4(475.74, -994.65, 26.27, 90.0),
        radius = 2.0,
        marker = false,
        ped = {
            enabled = false
        }
    },

    mechanic_storage = {
        label = 'Mechanic Storage',
        type = 'job',
        jobs = { mechanic = 0 },
        slots = 80,
        weight = 300000,
        coords = vector4(-347.63, -133.75, 39.01, 70.0),
        radius = 2.0,
        marker = false,
        ped = {
            enabled = true,
            model = 's_m_m_autoshop_01',
            heading = 70.0,
            scenario = 'WORLD_HUMAN_CLIPBOARD'
        }
    },

    ambulance_storage = {
        label = 'EMS Storage',
        type = 'job',
        jobs = { ambulance = 0 },
        slots = 80,
        weight = 250000,
        coords = vector4(306.66, -601.47, 43.28, 340.0),
        radius = 2.0,
        marker = false,
        ped = {
            enabled = true,
            model = 's_m_m_doctor_01',
            heading = 340.0,
            scenario = 'WORLD_HUMAN_CLIPBOARD'
        }
    },

    ballas_stash = {
        label = 'Ballas Stash',
        type = 'gang',
        gangs = { ballas = 0 },
        slots = 100,
        weight = 500000,
        coords = vector4(115.0, -1961.0, 21.0, 180.0),
        radius = 2.0,
        marker = false,
        ped = {
            enabled = true,
            model = 'g_m_y_ballasout_01',
            heading = 180.0,
            scenario = 'WORLD_HUMAN_SMOKING'
        }
    },

    vagos_stash = {
        label = 'Vagos Stash',
        type = 'gang',
        gangs = { vagos = 0 },
        slots = 100,
        weight = 500000,
        coords = vector4(344.0, -2022.0, 22.0, 140.0),
        radius = 2.0,
        marker = false,
        ped = {
            enabled = true,
            model = 'g_m_y_mexgoon_02',
            heading = 140.0,
            scenario = 'WORLD_HUMAN_SMOKING'
        }
    },

    personal_stash = {
        label = 'Personal Storage',
        type = 'personal',
        personal = true,
        slots = 80,
        weight = 300000,
        coords = vector4(200.0, -1000.0, 30.0, 90.0),
        radius = 2.0,
        marker = false,
        ped = {
            enabled = true,
            model = 'a_m_m_business_01',
            heading = 90.0,
            scenario = 'WORLD_HUMAN_CLIPBOARD'
        }
    },

    public_storage = {
        label = 'Public Storage',
        type = 'public',
        slots = 60,
        weight = 200000,
        coords = vector4(199.0, -1000.0, 30.0, 90.0),
        radius = 2.0,
        marker = false,
        ped = {
            enabled = false
        }
    }
}

RD.Stashes = RDStashes
return RDStashes
