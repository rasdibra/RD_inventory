--[[
    RD_inventory - Ox style usable cards for EVERY item.
    This file is loaded after data/items.lua.
    Goal: every item in RDItems can be clicked/double-clicked/dragged to USE.

    Important:
    - Items that already have a custom client config keep their real prop/animation/status.
    - Weapons/ammo/attachments keep their special weapon logic from modules/weapon/client.lua.
    - Generic/craft/material items do NOT get consumed unless their item has consume = 1.
    - This gives every item a clean ox_inventory style use action/card instead of doing nothing.
]]

RDUsableDefaults = RDUsableDefaults or {}

local function rdLower(value)
    return string.lower(tostring(value or ''))
end

local function rdHasAny(text, words)
    text = rdLower(text)
    for _, word in ipairs(words) do
        if text:find(word, 1, true) then return true end
    end
    return false
end

RDUsableDefaults.generic = {
    usetime = 1800,
    progressLabel = 'USING ITEM',
    cancel = true,
    notification = 'Item used',
    anim = { dict = 'missheistdockssetup1clipboard@base', clip = 'base', flag = 49 },
    prop = { model = 'prop_cs_tablet', bone = 60309, pos = vec3(0.03, 0.02, -0.02), rot = vec3(10.0, 0.0, 0.0) }
}

RDUsableDefaults.material = {
    usetime = 1300,
    progressLabel = 'CHECKING MATERIAL',
    cancel = true,
    notification = 'Material checked',
    anim = { dict = 'anim@heists@box_carry@', clip = 'idle', flag = 49 },
    prop = { model = 'prop_cs_cardbox_01', bone = 28422, pos = vec3(0.02, 0.0, -0.10), rot = vec3(0.0, 0.0, 0.0) }
}

RDUsableDefaults.document = {
    usetime = 2200,
    progressLabel = 'READING DOCUMENT',
    cancel = true,
    notification = 'Document checked',
    anim = { dict = 'missheistdockssetup1clipboard@base', clip = 'base', flag = 49 },
    prop = { model = 'prop_notepad_01', bone = 18905, pos = vec3(0.10, 0.02, 0.05), rot = vec3(10.0, 0.0, 0.0) }
}

RDUsableDefaults.tool = {
    usetime = 2400,
    progressLabel = 'USING TOOL',
    cancel = true,
    notification = 'Tool used',
    anim = { dict = 'amb@world_human_hammering@male@base', clip = 'base', flag = 49 },
    prop = { model = 'prop_tool_hammer', bone = 57005, pos = vec3(0.10, 0.02, -0.02), rot = vec3(90.0, 0.0, 0.0) }
}

RDUsableDefaults.medical = {
    usetime = 4500,
    progressLabel = 'USING MEDICAL ITEM',
    cancel = true,
    notification = 'Medical item used',
    anim = { dict = 'missheistdockssetup1clipboard@base', clip = 'base', flag = 49 },
    prop = { model = 'prop_ld_health_pack', bone = 57005, pos = vec3(0.12, 0.02, 0.02), rot = vec3(0.0, 90.0, 0.0) }
}

RDUsableDefaults.smoke = {
    usetime = 5000,
    progressLabel = 'USING SMOKE ITEM',
    cancel = true,
    notification = 'Smoke item used',
    anim = { dict = 'amb@world_human_smoking@male@male_a@enter', clip = 'enter', flag = 49 },
    prop = { model = 'prop_cs_ciggy_01', bone = 28422, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) }
}

RDUsableDefaults.drink = {
    usetime = 4200,
    progressLabel = 'DRINKING',
    cancel = true,
    notification = 'You drank it',
    status = { thirst = 120000 },
    anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle', flag = 49 },
    prop = { model = 'prop_ld_flow_bottle', bone = 57005, pos = vec3(0.03, 0.03, 0.02), rot = vec3(0.0, 0.0, -1.5) }
}

RDUsableDefaults.food = {
    usetime = 4500,
    progressLabel = 'EATING',
    cancel = true,
    notification = 'You ate it',
    status = { hunger = 120000 },
    anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp', flag = 49 },
    prop = { model = 'prop_cs_burger_01', bone = 57005, pos = vec3(0.12, 0.03, 0.02), rot = vec3(-70.0, 20.0, 10.0) }
}

local function rdCopy(tbl)
    if type(tbl) ~= 'table' then return tbl end
    local out = {}
    for k, v in pairs(tbl) do out[k] = rdCopy(v) end
    return out
end

local function rdPickDefault(name, item)
    local search = rdLower((name or '') .. ' ' .. (item.label or '') .. ' ' .. (item.description or '') .. ' ' .. (item.category or '') .. ' ' .. (item.type or ''))

    if rdHasAny(search, { 'water', 'drink', 'cola', 'sprunk', 'coffee', 'tea', 'milk', 'juice', 'beer', 'whiskey', 'wine', 'vodka', 'soda' }) then
        return 'drink'
    end

    if rdHasAny(search, { 'bread', 'burger', 'food', 'sandwich', 'taco', 'pizza', 'donut', 'soup', 'steak', 'chicken', 'meat', 'fish', 'apple', 'banana' }) then
        return 'food'
    end

    if rdHasAny(search, { 'bandage', 'medkit', 'firstaid', 'painkiller', 'medical', 'armor', 'armour' }) then
        return 'medical'
    end

    if rdHasAny(search, { 'license', 'licence', 'id_card', 'idcard', 'document', 'paper', 'receipt', 'contract', 'permit' }) then
        return 'document'
    end

    if rdHasAny(search, { 'hammer', 'wrench', 'tool', 'drill', 'lockpick', 'repair', 'screwdriver', 'cutter' }) then
        return 'tool'
    end

    if rdHasAny(search, { 'scrap', 'metal', 'steel', 'rubber', 'cloth', 'plastic', 'wood', 'glass', 'brass', 'gunpowder', 'parts', 'body', 'spring', 'barrel', 'trigger', 'electronics' }) then
        return 'material'
    end

    if rdHasAny(search, { 'cigarette', 'cigar', 'joint', 'smoke', 'lighter' }) then
        return 'smoke'
    end

    return 'generic'
end

local function rdMakeEveryItemUsable()
    if type(RDItems) ~= 'table' then return end

    for name, item in pairs(RDItems) do
        if type(item) == 'table' then
            item.label = item.label or name
            item.image = item.image or (name .. '.png')
            item.close = item.close ~= false
            item.stack = item.stack ~= false
            item.description = item.description or ('Use ' .. tostring(item.label or name))

            item.client = item.client or {}
            local client = item.client
            local defaultName = rdPickDefault(name, item)
            local default = RDUsableDefaults[defaultName] or RDUsableDefaults.generic

            -- Keep custom values, only fill missing fields.
            for key, value in pairs(default) do
                if client[key] == nil then client[key] = rdCopy(value) end
            end

            client.progressLabel = client.progressLabel or ('USING ' .. string.upper(tostring(item.label or name)))
            client.notification = client.notification or ('Used: ' .. tostring(item.label or name))
            client.image = client.image or item.image
        end
    end
end

rdMakeEveryItemUsable()
