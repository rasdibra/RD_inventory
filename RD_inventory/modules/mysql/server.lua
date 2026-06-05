RDMySQL = {}

function RDMySQL.ensureTables()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS rd_inventory (
            owner VARCHAR(100) NOT NULL,
            inventory LONGTEXT NULL,
            PRIMARY KEY (owner)
        )
    ]])
    
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS rd_inventory_ui (
            owner VARCHAR(100) NOT NULL,
            settings LONGTEXT NULL,
            PRIMARY KEY (owner)
        )
    ]])
    RD.Print('Database ready')
end

function RDMySQL.load(owner)
    local row = MySQL.single.await('SELECT inventory FROM rd_inventory WHERE owner = ?', { owner })
    if row and row.inventory then
        local ok, decoded = pcall(json.decode, row.inventory)
        if ok and decoded then return decoded end
    end
    return nil
end

function RDMySQL.save(owner, inventory)
    MySQL.update.await(
        'INSERT INTO rd_inventory (owner, inventory) VALUES (?, ?) ON DUPLICATE KEY UPDATE inventory = VALUES(inventory)',
        { owner, json.encode(inventory or {}) }
    )
end


function RDMySQL.loadUI(owner)
    local row = MySQL.single.await('SELECT settings FROM rd_inventory_ui WHERE owner = ?', { owner })
    if row and row.settings then
        local ok, decoded = pcall(json.decode, row.settings)
        if ok and decoded then return decoded end
    end
    return nil
end

function RDMySQL.saveUI(owner, settings)
    MySQL.update.await(
        'INSERT INTO rd_inventory_ui (owner, settings) VALUES (?, ?) ON DUPLICATE KEY UPDATE settings = VALUES(settings)',
        { owner, json.encode(settings or {}) }
    )
end
