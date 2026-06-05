# RD_inventory FULL READY

This is a working base inventory for FiveM ESX/QB/QBX with:
- TAB inventory
- red/black ox-style NUI
- item save/load with oxmysql
- add/remove/use/drop/move
- ESX/QB/QBX bridge money support
- 24/7 shop markers
- usable water/bread animations
- exports: AddItem, RemoveItem, GetInventory

Install:
1. Put folder as resources/[rd]/RD_inventory
2. ensure ox_lib
3. ensure oxmysql
4. ensure RD_inventory
5. Add item images to web/images


## Shops
Coords, peds, blips and items are configured in data/shops.lua.


## UI update
- Use item closes inventory automatically.
- Middle menu is icon based: use/give/amount/drop/settings.
- Bottom icon menu added: clothes/bag/settings.
- UI settings can customize background opacity, slot size, slot gap, and slot roundness.
- Replace icons in web/images: use.png, give.png, drop.png, settings.png, clothes.png, bag.png.


## Clothes Drag Update
- Middle menu now has Use, Give, Amount, Drop, Settings, Clothes.
- Settings opens separate customization UI.
- Clothes opens character/clothes UI like qs-inventory style.
- Drag clothing icons to character slots, double-click a body slot to remove/naked that clothing slot.


## Latest fixes
- Clothes UI is now small on far right, not covering inventory.
- Clothes UI uses icons only, no ugly text cards.
- Use clothing item sends it straight to the clothes panel slot.
- UI settings save to database permanently per player.
- ox_target zones added for shops and crafting when ox_target is started.


## Drop / Trunk / Glovebox / Hotbar Update
- Right side now shows ground drops when on foot.
- When inside vehicle, right side shows GLOVEBOX.
- When outside near vehicle, right side shows TRUNK.
- Drag player item to right side to drop/store.
- Drag right side item to player inventory to pickup/take.
- Move items anywhere in player inventory by drag/drop slot swap.
- Press Z to show 1-5 hotbar.
- Drag player items to hotbar slots to save them.

## RD Inventory admin commands + logs
Set Discord webhook in `data/config.lua`:
```lua
RDConfig.webhooks.default = 'YOUR_WEBHOOK_URL'
```

Commands:
- `/inventory` open inventory
- `/rd_trunk` open nearest trunk behind vehicle
- `/rd_openstash [stashId] [label]` open stash
- `/rd_opentrunk` helper trunk command
- `/rd_openglovebox` helper glovebox command while inside vehicle
- `/giveitem [id] item count` admin give item
- `/giveme item count` self test give
- `/givecraftitems [id]` give full craft material pack
- `/rd_giveitem [id] item count` admin give item with webhook log
- `/rd_removeitem [id] item count` admin remove item with webhook log
- `/rd_clearinv [id]` clear inventory with webhook log
- `/rd_giveweapon [id] WEAPON_PISTOL ammo` give weapon item with metadata
- `/rd_invhelp` show command help

Webhook logs included for give, drop, pickup, stash, trunk, glovebox, craft, admin give/remove/clear/giveweapon.

## RD Crafting Workbench Props Update
- Gun crafting bench now spawns real props at every crafting coordinate.
- Weapon bench model: `gr_prop_gr_bench_02a`.
- Public/mechanic bench model: `prop_tool_bench02_ld`.
- ox_target is attached directly on the prop, so players target the actual workbench.
- Fallback marker + E key still works if ox_target is not started.

Edit `data/crafting.lua` per bench:
```lua
prop = {
  enabled = true,
  model = 'gr_prop_gr_bench_02a',
  placeOnGround = true,
  freeze = true,
  offset = vec3(0.0, 0.0, -1.0)
}
```


## Update: Clean Craft Items + Lua Format

- Every item produced by `data/crafting.lua` is now also registered inside `data/items.lua`.
- Added missing normal weapon items, `repairkit`, and `bandage`, so craft rewards do not fail because of missing item definitions.
- Cleaned the crafting recipe layout: every recipe now has separate readable fields for label, category, item, level, XP, duration, image, and ingredients.
- Cleaned crafting materials in `data/items.lua` so they are easier to edit.

Main files to edit:

```lua
data/items.lua      -- all usable/weapon/craft item definitions
data/crafting.lua   -- benches, coords, recipe list, levels and ingredients
```


## RD Food/Drink Real Props Update
- Food and drinks now spawn real hand props while using items.
- Added soup with bowl + spoon animation.
- Added steak/plate item with fork + knife style eating.
- Added coffee, cola, sandwich, donut and fries with props.
- Use items normally from inventory: effects apply only after the progressbar finishes.

## RD_STORES / Owned Stores link
- `general_store_license` is usable. Use it at a location to create an owned General Store.
- Store creates ped + blip automatically.
- Owner menu: target ped -> Owner Stock/Menu or press `G` near store.
- Stock opens with RD_inventory: left = player inventory, right = store stock. Drag items from player to stock.
- Set sale price: Owner Stock/Menu -> Set Item Price -> enter stock slot + price.
- Customers: target ped -> Open Store or press `E`; drag item to player inventory and choose cash/bank.
- No qs-inventory/qb-inventory/ox_inventory dependency is required. RD_inventory provides `CreateUsableItem`, `RegisterUsableItem`, `AddItem`, `RemoveItem`, `GetItemCount`, `HasItem`, `GetStashItems`, and `SetStashItems` compatibility exports.
