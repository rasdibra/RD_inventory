RDTarget = RDTarget or {}

function RDTarget.addCraftTargets()
    -- Crafting/client.lua now spawns real workbench props and attaches ox_target to the prop.
    -- This avoids double target options on the same table.
    if RD and RD.CraftPropsRegistered then return true end
    if GetResourceState('ox_target') ~= 'started' then return false end

    for id, craft in pairs(RDCrafting or {}) do
        if craft.coords and craft.target then
            exports.ox_target:addSphereZone({
                coords = craft.coords,
                radius = craft.radius or 2.0,
                debug = false,
                options = {
                    {
                        name = 'rd_inventory_craft_' .. id,
                        icon = 'fa-solid fa-screwdriver-wrench',
                        label = 'Craft ' .. (craft.label or id),
                        distance = 2.5,
                        onSelect = function()
                            TriggerEvent('rd_inventory:client:openCrafting', id)
                        end
                    }
                }
            })
        end
    end

    return true
end

CreateThread(function()
    Wait(3000)
    RDTarget.addCraftTargets()
end)

function RDTarget.addStashTargets()
    if RDStashesClient and RDStashesClient.init then
        return true
    end
    return false
end

CreateThread(function()
    Wait(3500)
    RDTarget.addStashTargets()
end)
