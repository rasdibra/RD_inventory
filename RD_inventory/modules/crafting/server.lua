RDCraftingServer = RDCraftingServer or {}
local xpCache = {}
local xpFile = 'craft_xp.json'
local craftBusy = {}

local function loadXp()
    local raw = LoadResourceFile(GetCurrentResourceName(), xpFile)
    if raw and raw ~= '' then xpCache = json.decode(raw) or {} end
end
local function saveXp() SaveResourceFile(GetCurrentResourceName(), xpFile, json.encode(xpCache), -1) end
loadXp()

local function ident(src)
    if RDUtils and RDUtils.identifier then return RDUtils.identifier(src) end
    return tostring(src)
end
local function levelFromXp(xp)
    xp = tonumber(xp) or 0
    local level = math.floor(math.sqrt(xp / 100)) + 1
    if level < 1 then level = 1 end
    if level > 50 then level = 50 end
    local nextXp = ((level) * (level)) * 100
    return level, nextXp
end
local function itemCount(inv, name)
    local c = 0
    for _, it in ipairs((inv and inv.items) or {}) do if it.name == name then c = c + (tonumber(it.count) or 0) end end
    return c
end
local function recipeOut(id, r, inv)
    local have, missing = {}, false
    for name, count in pairs(r.ingredients or r.items or {}) do
        have[name] = itemCount(inv, name)
        if have[name] < count then missing = true end
    end
    return {
        id = id, label = r.label or id, category = r.category or 'items', item = r.item or (r.result and r.result.name) or id,
        count = r.count or (r.result and r.result.count) or 1, image = r.image, level = r.level or 1, xp = r.xp or 5,
        duration = r.duration or 3000, ingredients = r.ingredients or r.items or {}, have = have, missing = missing
    }
end

lib.callback.register('rd_inventory:crafting:getBenchData', function(src, benchId)
    local bench = RDCrafting and RDCrafting[benchId]
    if not bench then return nil end
    local key = ident(src)
    local xp = tonumber(xpCache[key] or 0) or 0
    local lvl, nextXp = levelFromXp(xp)
    local inv = RDInv.get(src)
    local recipes = {}
    for _, rid in ipairs(bench.recipes or {}) do
        local r = RDRecipes and RDRecipes[rid]
        if r then recipes[#recipes+1] = recipeOut(rid, r, inv) end
    end
    return { bench = { id = benchId, label = bench.label or 'Crafting Table' }, recipes = recipes, inventory = inv.items or {}, level = lvl, xp = xp, nextXp = nextXp }
end)

RegisterNetEvent('rd_inventory:crafting:craftRecipe', function(benchId, recipeId)
    local src = source
    if craftBusy[src] then return end
    craftBusy[src] = true
    local bench = RDCrafting and RDCrafting[benchId]
    local function done() craftBusy[src] = nil end
    if not bench or not recipeId then done(); return end
    local allowed = false
    for _, rid in ipairs(bench.recipes or {}) do if rid == recipeId then allowed = true break end end
    if not allowed then done(); return end
    local r = RDRecipes and RDRecipes[recipeId]
    if not r then done(); return end
    local key = ident(src)
    local xp = tonumber(xpCache[key] or 0) or 0
    local lvl = levelFromXp(xp)
    if lvl < (r.level or 1) then
        TriggerClientEvent('rd_inventory:notify', src, ('Need crafting level %s'):format(r.level or 1), 'error')
        done(); return
    end
    local inv = RDInv.get(src)
    for name, count in pairs(r.ingredients or r.items or {}) do
        if itemCount(inv, name) < count then
            TriggerClientEvent('rd_inventory:notify', src, 'Missing materials for this craft', 'error')
            done(); return
        end
    end
    local craftDuration = 30000
    TriggerClientEvent('rd_inventory:crafting:progress', src, r.label or 'Crafting', craftDuration)
    Wait(craftDuration)
    -- validate again after progress
    inv = RDInv.get(src)
    for name, count in pairs(r.ingredients or r.items or {}) do if itemCount(inv, name) < count then done(); return end end
    for name, count in pairs(r.ingredients or r.items or {}) do RDInv.removeItem(src, name, count) end
    local item = r.item or (r.result and r.result.name)
    local count = r.count or (r.result and r.result.count) or 1
    if item then RDInv.addItem(src, item, count, r.metadata or {}) end
    if RDLog and RDLog.send then RDLog.send('craft', src, { bench = tostring(benchId), recipe = tostring(recipeId), item = tostring(item), count = count }) end
    xpCache[key] = xp + (tonumber(r.xp) or 5)
    saveXp()
    local lvl2, nextXp = levelFromXp(xpCache[key])
    inv = RDInv.get(src)
    local recipes = {}
    for _, rid in ipairs(bench.recipes or {}) do local rr = RDRecipes and RDRecipes[rid]; if rr then recipes[#recipes+1] = recipeOut(rid, rr, inv) end end
    TriggerClientEvent('rd_inventory:crafting:update', src, { inventory = inv.items or {}, recipes = recipes, level = lvl2, xp = xpCache[key], nextXp = nextXp, recipeId = recipeId })
    TriggerClientEvent('rd_inventory:notify', src, ('Crafted %s +%s XP'):format(r.label or item, r.xp or 5), 'success')
    done()
end)

-- Backward compatibility old event
RegisterNetEvent('rd_inventory:craftItem', function(recipeId)
    TriggerEvent('rd_inventory:crafting:craftRecipe', 'public', recipeId)
end)
