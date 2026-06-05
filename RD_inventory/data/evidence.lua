-- Coords format: vector4(x, y, z, heading)
return {
    bags = {
        evidence_bag = { label = 'Evidence Bag', weight = 50, stack = false, close = false, image = 'evidence_bag.png' },
        filled_evidence_bag = { label = 'Filled Evidence Bag', weight = 100, stack = false, close = false, image = 'evidence_bag.png' }
    },

    policeJobs = {
        police = true,
        sheriff = true,
        state = true
    },

    lockers = {
        {
            label = 'Mission Row Evidence',
            coords = vector4(475.74, -994.65, 26.27, 90.0),
            radius = 2.0,
            slots = 80,
            weight = 200000,
            jobs = { police = 0 }
        },
        {
            label = 'Sandy Evidence',
            coords = vector4(1852.56, 3688.23, 34.26, 210.0),
            radius = 2.0,
            slots = 80,
            weight = 200000,
            jobs = { sheriff = 0, police = 0 }
        }
    }
}
