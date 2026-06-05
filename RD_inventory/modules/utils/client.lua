RDUtils = RDUtils or {}

function RDUtils.notify(msg, typ)
    msg = tostring(msg or 'Inventory')
    typ = typ or 'info'

    -- ONE notify system for the full inventory.
    -- Everything is forced to top-center so you do not get two different notify styles.
    if lib and lib.notify then
        lib.notify({
            id = ('rd_inventory_%s'):format(msg:sub(1, 40)), -- ox_lib replaces same id instead of stacking duplicate spam
            title = 'RD Inventory',
            description = msg,
            type = typ,
            position = 'top-center',
            duration = 3200,
            icon = 'box',
            iconColor = '#ff3030',
            style = {
                backgroundColor = '#080203',
                color = '#ffffff',
                border = '1px solid rgba(255, 35, 35, .85)',
                borderRadius = '12px',
                boxShadow = '0 0 24px rgba(255, 0, 0, .30)',
                fontSize = '14px',
                fontWeight = '600'
            }
        })
        return
    end

    -- Fallback only if ox_lib notify does not exist.
    SetNotificationTextEntry('STRING')
    AddTextComponentString(('~r~RD Inventory~s~\n%s'):format(msg))
    DrawNotification(false, false)
end

function RDUtils.playAnim(anim)
    local a = nil
    if type(anim) == 'string' then
        a = (RDAnimations and RDAnimations[anim]) or nil
    elseif type(anim) == 'table' then
        a = anim
    end
    if not a or not a.dict or not a.clip then return end

    local ped = PlayerPedId()
    local propObj = nil
    if a.prop and a.prop.model then
        local model = type(a.prop.model) == 'number' and a.prop.model or joaat(a.prop.model)
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(10) end
        propObj = CreateObject(model, 0.0, 0.0, 0.0, true, true, false)
        local pos = a.prop.pos or vec3(0.0, 0.0, 0.0)
        local rot = a.prop.rot or vec3(0.0, 0.0, 0.0)
        AttachEntityToEntity(propObj, ped, GetPedBoneIndex(ped, 57005), pos.x or 0.0, pos.y or 0.0, pos.z or 0.0, rot.x or 0.0, rot.y or 0.0, rot.z or 0.0, true, true, false, true, 1, true)
    end

    RequestAnimDict(a.dict)
    while not HasAnimDictLoaded(a.dict) do Wait(10) end
    TaskPlayAnim(ped, a.dict, a.clip, 8.0, -8.0, a.duration or a.usetime or 2000, a.flag or 49, 0, false, false, false)
    Wait(a.duration or a.usetime or 2000)
    ClearPedTasks(ped)
    if propObj and DoesEntityExist(propObj) then DeleteEntity(propObj) end
end
