RDHooks = RDHooks or {}
RDHooks.registered = {}

function RDHooks.register(name, cb)
    RDHooks.registered[name] = RDHooks.registered[name] or {}
    RDHooks.registered[name][#RDHooks.registered[name] + 1] = cb
end

function RDHooks.trigger(name, ...)
    for _, cb in ipairs(RDHooks.registered[name] or {}) do
        local ok, result = pcall(cb, ...)
        if ok and result == false then return false end
    end
    return true
end
