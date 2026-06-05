const app = document.getElementById('app');
const playerGrid = document.getElementById('playerGrid');
const otherGrid = document.getElementById('otherGrid');
const contextMenu = document.getElementById('contextMenu');
const contextButtons = contextMenu ? contextMenu.querySelectorAll('button') : [];
const amount = document.getElementById('amount');
const weightText = document.getElementById('weightText');
const weightFill = document.getElementById('weightFill');
const rightWeightText = document.getElementById('rightWeightText');
const rightWeightFill = document.getElementById('rightWeightFill');
const rightTitle = document.getElementById('rightTitle');
const rightSub = document.getElementById('rightSub');
const settingsPanel = document.getElementById('settingsPanel');
const clothesPanel = document.getElementById('clothesPanel');
const hotbar = document.getElementById('hotbar');
const attachModal = document.getElementById('attachModal');
const attachList = document.getElementById('attachList');
const attachWeapon = document.getElementById('attachWeapon');
const attachClose = document.getElementById('attachClose');
const giveModal = document.getElementById('giveModal');
const giveTargetId = document.getElementById('giveTargetId');
const giveConfirm = document.getElementById('giveConfirm');
const giveCancel = document.getElementById('giveCancel');
const shopPayModal = document.getElementById('shopPayModal');
const shopPayText = document.getElementById('shopPayText');
const shopPayItem = document.getElementById('shopPayItem');
const shopPayCash = document.getElementById('shopPayCash');
const shopPayBank = document.getElementById('shopPayBank');
const shopPayCancel = document.getElementById('shopPayCancel');
let pendingShopBuy = null;


const rdProgress = document.getElementById('rdProgress');
const rdProgressLabel = document.getElementById('rdProgressLabel');
const rdProgressPercent = document.getElementById('rdProgressPercent');
const rdProgressFill = document.getElementById('rdProgressFill');
let rdProgressTimer = null;
let rdInventoryClosing = false;
let rdLastCloseAt = 0;

function setInventoryOpenState(open) {
    document.body.classList.toggle('rd-inventory-open', !!open);
}

function hideRdProgress() {
    if (rdProgressTimer) clearInterval(rdProgressTimer);
    rdProgressTimer = null;
    if (rdProgress) rdProgress.classList.add('hidden');
    if (rdProgressFill) rdProgressFill.style.width = '0%';
    if (rdProgressPercent) rdProgressPercent.innerText = '0%';
}

function showRdProgress(data = {}) {
    const duration = Math.max(250, Number(data.duration || data.time || 2500));
    const label = String(data.label || data.text || 'WORKING');
    const started = Date.now();
    if (!rdProgress || !rdProgressFill) return;
    if (rdProgressTimer) clearInterval(rdProgressTimer);
    rdProgressLabel.innerText = label;
    rdProgressFill.style.width = '0%';
    rdProgressPercent.innerText = '0%';
    rdProgress.classList.remove('hidden');
    rdProgressTimer = setInterval(() => {
        const pct = Math.min(100, Math.floor(((Date.now() - started) / duration) * 100));
        rdProgressFill.style.width = pct + '%';
        rdProgressPercent.innerText = pct + '%';
        if (pct >= 100) {
            clearInterval(rdProgressTimer);
            rdProgressTimer = null;
            setTimeout(hideRdProgress, 180);
        }
    }, 50);
}


let selected = null;
let mode = 'inventory';
let currentShop = null;
let lastItems = [];
let currentOther = null;
let currentHotbar = {};
let currentMaxWeight = 50000;
let currentSlots = 50;
let wornClothes = {};
let dragGhost = null;
let pendingGiveItem = null;

// RD rule: storage secondary inventories use right-click quick move.
// Left-click drag stays ENABLED so player can drag items to middle USE/GIVE/DROP zones like ox_inventory.
function isStorageSecondaryOpen() {
    const t = currentOther && currentOther.type ? String(currentOther.type).toLowerCase() : '';
    return !!t && !['ground', 'drop', 'drops', 'shop'].includes(t);
}

function canStartDrag(side) {
    // Keep drag enabled for mouse-hold action zones (USE/GIVE/DROP) and slot re-ordering.
    return true;
}



// RD DEEP FIX: custom mouse-hold drag for FiveM NUI.
// HTML5 drag/drop is unreliable in some CEF/NUI builds, so this keeps UI same
// but moves items with normal mouse down -> move -> mouse up.
let rdMouseDrag = null;
let rdLastHover = null;

function rdClearHover() {
    if (rdLastHover) rdLastHover.classList.remove('drop-target');
    rdLastHover = null;
}

function rdAmount(defaultCount = 1) {
    const n = Number(amount?.value);
    return n > 0 ? n : defaultCount;
}

function rdSelectDragged(data) {
    if (!data || !data.item) return false;
    selected = Object.assign({}, data.item, { side: data.source, slot: data.fromSlot || data.item.slot });
    return true;
}

function performSlotMove(data, targetSide, targetSlot) {
    if (!data || !data.item || !targetSide || !targetSlot) return;
    const source = data.source;
    const fromSlot = data.fromSlot || data.item.slot;
    const item = data.item;

    // Same exact slot = no action.
    if (String(source) === String(targetSide) && Number(fromSlot) === Number(targetSlot)) return;

    // Clothes -> player slot
    if (source === 'clothes' && targetSide === 'player') {
        if (item && item.name) nui('unequipClothingToInventory', { type: data.clothType, name: item.name, toSlot: targetSlot });
        const wornSlot = document.querySelector(`.wear-slot[data-cloth="${data.clothType}"]`);
        if (wornSlot) resetWearSlot(wornSlot, data.clothType);
        delete wornClothes[data.clothType];
        return;
    }

    // Player inventory internal move/swap.
    if (targetSide === 'player' && source === 'player') {
        nui('moveItem', { fromSlot, toSlot: targetSlot, name: item.name, count: rdAmount(item.count || 1) });
        if (targetSlot >= 1 && targetSlot <= 5) nui('setHotbar', { hotbarSlot: targetSlot, itemSlot: targetSlot });
        return;
    }

    // Other -> player (stash/trunk/glovebox/ground/shop)
    if (targetSide === 'player' && source !== 'player') {
        if (source === 'shop' || currentOther?.type === 'shop') {
            rdOpenShopPay(item, targetSlot);
        } else if (currentOther?.type === 'ground') {
            nui('pickupDrop', { dropId: currentOther.dropId, slot: fromSlot, toSlot: targetSlot, count: Number(amount?.value) || 0 });
        } else {
            nui('moveBetweenInventories', { fromType: currentOther?.type || source, toType: 'player', fromSlot, toSlot: targetSlot, name: item.name, count: rdAmount(1), stashId: currentOther?.stashId, plate: currentOther?.plate, vehicleType: currentOther?.vehicleType || currentOther?.type });
        }
        return;
    }

    // Player -> other (stash/trunk/glovebox/ground). Shop blocked.
    if (targetSide !== 'player' && source === 'player') {
        if (currentOther?.type === 'ground') {
            nui('dropItem', { name: item.name, count: rdAmount(1), slot: fromSlot, dropId: currentOther.dropId, toSlot: targetSlot });
        } else if (currentOther?.type && currentOther.type !== 'shop') {
            nui('moveBetweenInventories', { fromType: 'player', toType: currentOther.type, fromSlot, toSlot: targetSlot, name: item.name, count: rdAmount(1), stashId: currentOther.stashId, plate: currentOther.plate, vehicleType: currentOther.vehicleType || currentOther.type });
        }
        return;
    }

    // Other internal move/swap (stash/trunk/glovebox/ground).
    if (targetSide !== 'player' && source === targetSide && currentOther?.type !== 'shop') {
        if (currentOther?.type === 'ground') {
            nui('moveGroundItem', { dropId: currentOther.dropId, fromSlot, toSlot: targetSlot });
        } else {
            nui('moveOtherItem', { invType: currentOther?.type || targetSide, fromSlot, toSlot: targetSlot, plate: currentOther?.plate, vehicleType: currentOther?.vehicleType || currentOther?.type, stashId: currentOther?.stashId });
        }
    }
}

function performActionDrop(data, actionId) {
    if (!rdSelectDragged(data)) return;
    if (actionId === 'useBtn') useSelected();
    if (actionId === 'giveBtn') giveSelected();
    if (actionId === 'dropBtn') dropSelected();
}

function rdFindDropTarget(x, y) {
    const el = document.elementFromPoint(x, y);
    if (!el) return null;
    const action = el.closest && el.closest('#useBtn,#giveBtn,#dropBtn');
    if (action) return { type: 'action', el: action, actionId: action.id };
    const slot = el.closest && el.closest('.slot');
    if (slot) return { type: 'slot', el: slot, side: slot.dataset.side, slot: Number(slot.dataset.slot) };
    const wear = el.closest && el.closest('.wear-slot');
    if (wear) return { type: 'wear', el: wear, cloth: wear.dataset.cloth };
    return null;
}

function rdMoveGhost(e) {
    if (!rdMouseDrag) return;
    rdMouseDrag.moved = true;
    rdMouseDrag.ghost.style.left = `${e.clientX - rdMouseDrag.offsetX}px`;
    rdMouseDrag.ghost.style.top = `${e.clientY - rdMouseDrag.offsetY}px`;
    const target = rdFindDropTarget(e.clientX, e.clientY);
    rdClearHover();
    if (target && target.el && target.el !== rdMouseDrag.sourceEl) {
        target.el.classList.add('drop-target');
        rdLastHover = target.el;
    }
}

function rdEndMouseDrag(e) {
    if (!rdMouseDrag) return;
    document.removeEventListener('mousemove', rdMoveGhost, true);
    document.removeEventListener('mouseup', rdEndMouseDrag, true);
    const drag = rdMouseDrag;
    rdMouseDrag = null;
    rdClearHover();
    if (drag.ghost && drag.ghost.parentNode) drag.ghost.parentNode.removeChild(drag.ghost);
    drag.sourceEl.classList.remove('dragging');

    const target = rdFindDropTarget(e.clientX, e.clientY);
    if (!drag.moved || !target) return;

    if (target.type === 'slot') {
        performSlotMove(drag.data, target.side, target.slot);
    } else if (target.type === 'action') {
        performActionDrop(drag.data, target.actionId);
    } else if (target.type === 'wear') {
        const data = drag.data;
        if (data.source === 'player' && !isStorageSecondaryOpen()) {
            const type = clothingType(data.item);
            if (type && type === target.cloth) putClothOnBody(data.item, true, data.fromSlot);
        }
    }
}

function startRDMouseDrag(e, item, slot, side, el) {
    if (e.button !== 0 || !item) return;
    if (e.target && ['INPUT','BUTTON','TEXTAREA'].includes(e.target.tagName)) return;
    e.preventDefault();
    e.stopPropagation();

    selectItem(item, el, side);
    const rect = el.getBoundingClientRect();
    const ghost = el.cloneNode(true);
    ghost.classList.add('rd-drag-ghost');
    ghost.classList.remove('selected');
    ghost.style.position = 'fixed';
    ghost.style.width = `${rect.width}px`;
    ghost.style.height = `${rect.height}px`;
    ghost.style.left = `${e.clientX - rect.width / 2}px`;
    ghost.style.top = `${e.clientY - rect.height / 2}px`;
    ghost.style.zIndex = '999999';
    ghost.style.pointerEvents = 'none';
    ghost.style.opacity = '0.95';
    ghost.style.transform = 'scale(1.03)';
    ghost.style.boxShadow = '0 0 22px rgba(255,48,48,.45)';
    document.body.appendChild(ghost);

    el.classList.add('dragging');
    rdMouseDrag = {
        item,
        sourceEl: el,
        ghost,
        moved: false,
        offsetX: rect.width / 2,
        offsetY: rect.height / 2,
        data: { item, fromSlot: item.slot || slot, source: side }
    };
    document.addEventListener('mousemove', rdMoveGhost, true);
    document.addEventListener('mouseup', rdEndMouseDrag, true);
}

function nui(name, data = {}) {
    return fetch(`https://${GetParentResourceName()}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data)
    }).catch(() => {});
}

function cleanImageName(item) {
    let imageName = (item && (item.image || item.icon || item.name)) ? String(item.image || item.icon || item.name) : 'unknown';
    imageName = imageName.replace(/^.*[\\/]/, '');
    if (!/\.(png|jpg|jpeg|webp|gif|svg)$/i.test(imageName)) imageName += '.png';
    return imageName;
}

function img(item) { return `nui://${GetParentResourceName()}/web/images/${cleanImageName(item)}?rdv=3`; }

function fallbackIcon(item) {
    const type = clothingType(item || {});
    const name = String((item && item.name) || '').toLowerCase();
    if (type) return `./assets/${type}.svg`;
    if (name.includes('bag')) return './assets/bag.svg';
    if (name.includes('drop')) return './assets/drop.svg';
    if (name.includes('weapon') || name.includes('ammo')) return './assets/use.svg';
    return './assets/use.svg';
}

function clothingType(item) {
    const n = (item.name || '').toLowerCase();
    if (item.type) return item.type;
    if (n.includes('hat')) return 'hat';
    if (n.includes('mask')) return 'mask';
    if (n.includes('shirt') || n.includes('jacket') || n.includes('torso')) return 'shirt';
    if (n.includes('glove')) return 'gloves';
    if (n.includes('pant') || n.includes('leg')) return 'pants';
    if (n.includes('shoe') || n.includes('boot')) return 'shoes';
    return null;
}

function applyServerSettings(settings = {}) {
    const local = JSON.parse(localStorage.getItem('rd_inventory_ui') || '{}');
    settings = Object.assign({}, settings || {}, local || {});
    document.getElementById('bgOpacity').value = settings.backgroundOpacity ?? settings.bg ?? 68;
    document.getElementById('slotSize').value = settings.slotSize ?? 92;
    document.getElementById('slotGap').value = settings.slotGap ?? 8;
    document.getElementById('slotRadius').value = settings.slotRadius ?? 7;
    document.getElementById('redIntensity').value = settings.redIntensity ?? settings.red ?? 255;
    if (document.getElementById('bagOpacity')) document.getElementById('bagOpacity').value = settings.bagOpacity ?? 92;
    if (document.getElementById('slotDark')) document.getElementById('slotDark').value = settings.slotDark ?? 96;
    applySettings(false);
}

function currentSettings() {
    return {
        backgroundOpacity: Number(document.getElementById('bgOpacity').value),
        slotSize: Number(document.getElementById('slotSize').value),
        slotGap: Number(document.getElementById('slotGap').value),
        slotRadius: Number(document.getElementById('slotRadius').value),
        redIntensity: Number(document.getElementById('redIntensity').value),
        bagOpacity: Number(document.getElementById('bagOpacity')?.value || 92),
        slotDark: Number(document.getElementById('slotDark')?.value || 96)
    };
}

function applySettings(save = true) {
    const s = currentSettings();
    document.documentElement.style.setProperty('--bg-opacity', s.backgroundOpacity / 100);
    document.documentElement.style.setProperty('--slot-size', `${s.slotSize}px`);
    document.documentElement.style.setProperty('--slot-gap', `${s.slotGap}px`);
    document.documentElement.style.setProperty('--slot-radius', `${s.slotRadius}px`);
    document.documentElement.style.setProperty('--rd-red', `rgb(${s.redIntensity}, 48, 48)`);
    document.documentElement.style.setProperty('--bag-opacity', `${s.bagOpacity / 100}`);
    document.documentElement.style.setProperty('--slot-dark', `${s.slotDark / 100}`);
    localStorage.setItem('rd_inventory_ui', JSON.stringify(s));
    if (save) nui('saveUISettings', s);
}

function createSlot(item, slot, side) {
    const el = document.createElement('div');
    el.className = 'slot' + (side === 'player' && slot >= 1 && slot <= 5 ? ' hotbar-slot' : '') + (side !== 'player' ? ' other-slot' : '');
    el.dataset.slot = slot;
    el.dataset.side = side;

    if (side === 'player' && slot >= 1 && slot <= 5) {
        const badge = document.createElement('span');
        badge.className = 'hot-num';
        badge.innerText = slot;
        el.appendChild(badge);
    }

    if (item) {
        el.draggable = false; // RD deep fix uses custom mouse drag, not native HTML5 drag
        el.innerHTML = `
            ${side === 'player' && slot >= 1 && slot <= 5 ? `<span class="hot-num">${slot}</span>` : ''}
            ${item.price ? `<span class="item-price">$${item.price}</span>` : ''}
            <span class="item-count">${item.count || 1}</span>
            <img src="${img(item)}" onerror="this.onerror=null;this.src='${fallbackIcon(item)}'">
            <span class="item-name">${item.label || item.name}</span>
        `;
        el.onclick = () => selectItem(item, el, side);
        el.onmousedown = (e) => startRDMouseDrag(e, item, slot, side, el);
        el.oncontextmenu = (e) => {
            e.preventDefault();
            selectItem(item, el, side);
            if (contextMenu) contextMenu.classList.add('hidden');

            const secondaryOpen = isStorageSecondaryOpen();

            // RD OX-STYLE RULE:
            // Stash / trunk / glovebox open: right-click quick-moves to the other side.
            // No context menu is ever opened.
            if (secondaryOpen) {
                const otherType = currentOther.type;
                const count = Number(amount?.value) > 0 ? Number(amount.value) : (item.count || 1);

                if (side === 'player') {
                    nui('moveBetweenInventories', {
                        fromType: 'player',
                        toType: otherType,
                        fromSlot: item.slot || slot,
                        toSlot: null,
                        name: item.name,
                        count,
                        stashId: currentOther.stashId,
                        plate: currentOther.plate,
                        vehicleType: currentOther.vehicleType || otherType
                    });
                } else {
                    nui('moveBetweenInventories', {
                        fromType: otherType,
                        toType: 'player',
                        fromSlot: item.slot || slot,
                        toSlot: null,
                        name: item.name,
                        count,
                        stashId: currentOther.stashId,
                        plate: currentOther.plate,
                        vehicleType: currentOther.vehicleType || otherType
                    });
                }
                return false;
            }

            // Player inventory only: right-click menu is disabled.
            // Use = double click item OR drag item to the center USE button.
            // Give = drag item to the center GIVE button and enter server ID.
            // Drop = drag item to the center DROP button/zone.
            return false;
        };
        el.ondblclick = (e) => {
            e.preventDefault();
            selectItem(item, el, side);
            if (!isStorageSecondaryOpen() && side === 'player') {
                useSelected();
            }
        };
        el.ondragstart = (e) => {
            if (!canStartDrag(side)) {
                e.preventDefault();
                return false;
            }
            e.dataTransfer.effectAllowed = 'move';
            e.dataTransfer.setData('text/plain', JSON.stringify({ item, fromSlot: item.slot || slot, source: side }));
            setTimeout(() => el.classList.add('dragging'), 0);
        };
        el.ondragend = () => {
            el.classList.remove('dragging');
            document.querySelectorAll('.drop-target').forEach(x => x.classList.remove('drop-target'));
        };
    }

    el.ondragover = (e) => {
        // Drag is enabled even when storage is open; right-click handles quick move.
        e.preventDefault();
        el.classList.add('drop-target');
    };
    el.ondragleave = () => el.classList.remove('drop-target');
    el.ondrop = (e) => {
        e.preventDefault();
        el.classList.remove('drop-target');
        const raw = e.dataTransfer.getData('text/plain');
        if (!raw) return;
        const data = JSON.parse(raw);

        // Clothes panel -> player inventory: remove clothes from body and add back to inventory.
        if (data.source === 'clothes' && side === 'player') {
            if (data.item && data.item.name) nui('unequipClothingToInventory', { type: data.clothType, name: data.item.name, toSlot: slot });
            const wornSlot = document.querySelector(`.wear-slot[data-cloth="${data.clothType}"]`);
            if (wornSlot) resetWearSlot(wornSlot, data.clothType);
            delete wornClothes[data.clothType];
            return;
        }

        // Player inventory reorder / hotbar slots 1-5.
        if (side === 'player' && data.source === 'player') {
            nui('moveItem', { fromSlot: data.fromSlot, toSlot: slot, name: data.item.name, count: Number(amount.value) || 1 });
            if (slot >= 1 && slot <= 5) nui('setHotbar', { hotbarSlot: slot, itemSlot: slot });
            return;
        }

        // Right side -> player: buy/take from shop, stash, trunk, glovebox, drops.
        if (side === 'player' && data.source !== 'player') {
            if (data.source === 'shop' || currentOther?.type === 'shop') {
                rdOpenShopPay(data.item, slot);
            } else if (currentOther?.type === 'ground') {
                nui('pickupDrop', { dropId: currentOther.dropId, slot: data.fromSlot, toSlot: slot, count: Number(amount.value) || 0 });
            } else {
                nui('moveBetweenInventories', { fromType: currentOther.type, toType: 'player', fromSlot: data.fromSlot, toSlot: slot, name: data.item.name, count: Number(amount.value) || 1, shopId: currentShop || currentOther.shopId, stashId: currentOther.stashId });
            }
            return;
        }

        // Player -> right side: store/drop. Shop blocks selling here.
        if (side !== 'player' && data.source === 'player') {
            if (currentOther?.type === 'ground') {
                nui('dropItem', { name: data.item.name, count: Number(amount.value) || 1, slot: data.fromSlot, dropId: currentOther.dropId, toSlot: slot });
            } else if (currentOther?.type !== 'shop') {
                nui('moveBetweenInventories', { fromType: 'player', toType: currentOther.type, fromSlot: data.fromSlot, toSlot: slot, name: data.item.name, count: Number(amount.value) || 1, shopId: currentShop || currentOther.shopId, stashId: currentOther.stashId });
            }
            return;
        }

        // Reorder inside stash/trunk/glovebox/ground drop. Dropping on an occupied slot swaps items.
        if (side !== 'player' && data.source === side && currentOther?.type !== 'shop') {
            if (currentOther?.type === 'ground') {
                nui('moveGroundItem', { dropId: currentOther.dropId, fromSlot: data.fromSlot, toSlot: slot });
            } else {
                nui('moveOtherItem', { invType: currentOther.type, fromSlot: data.fromSlot, toSlot: slot, plate: currentOther.plate, vehicleType: currentOther.vehicleType, stashId: currentOther.stashId });
            }
        }
    };

    return el;
}

function updateContextMenuForSide(side) {
    contextButtons.forEach(btn => {
        const action = btn.dataset.action;
        if (side === 'shop') {
            btn.style.display = action === 'buy' ? 'block' : 'none';
        } else if (side === 'player') {
            btn.style.display = action === 'buy' ? 'none' : 'block';
        } else {
            btn.style.display = action === 'use' ? 'block' : 'none';
            if (action === 'use') btn.innerText = 'Take';
        }
        if (side !== 'shop' && action === 'use') btn.innerText = side === 'player' ? 'Use' : 'Take';
        if (action === 'buy') btn.innerText = 'Buy';
    });
}

function selectItem(item, el, side) {
    document.querySelectorAll('.slot').forEach(s => s.classList.remove('selected'));
    el.classList.add('selected');
    selected = { ...item, side, slot: item.slot || Number(el.dataset.slot) };
    updateContextMenuForSide(side);
}


function getDragItemFromEvent(e) {
    const raw = e.dataTransfer.getData('text/plain');
    if (!raw) return null;
    try { return JSON.parse(raw); } catch (_) { return null; }
}

function selectDraggedItem(data) {
    if (!data || !data.item) return false;
    if (data.source !== 'player') return false;
    selected = Object.assign({}, data.item, { side: 'player', slot: data.fromSlot || data.item.slot });
    return true;
}

function setupMiddleActionDropZones() {
    const bind = (id, fn) => {
        const btn = document.getElementById(id);
        if (!btn) return;
        btn.ondragover = (e) => {
            e.preventDefault();
            btn.classList.add('drop-target');
        };
        btn.ondragleave = () => btn.classList.remove('drop-target');
        btn.ondrop = (e) => {
            e.preventDefault();
            btn.classList.remove('drop-target');
            const data = getDragItemFromEvent(e);
            if (!selectDraggedItem(data)) return;
            fn();
        };
    };
    bind('useBtn', useSelected);
    bind('giveBtn', giveSelected);
    bind('dropBtn', dropSelected);
}

function renderGrid(grid, items, side, totalSlots = 50) {
    grid.innerHTML = '';
    const bySlot = {};
    (items || []).forEach(i => bySlot[i.slot || 1] = i);
    for (let i = 1; i <= totalSlots; i++) {
        grid.appendChild(createSlot(bySlot[i], i, side));
    }
}

function renderHotbar(items, hot) {
    currentHotbar = hot || {};
    const bySlot = {};
    (items || []).forEach(i => bySlot[i.slot] = i);

    document.querySelectorAll('.hot-slot').forEach(hs => {
        const h = Number(hs.dataset.hotbar);
        const item = bySlot[h];
        hs.innerHTML = `<span>${h}</span>${item ? `<img src="${img(item)}" onerror="this.onerror=null;this.src='${fallbackIcon(item)}'"><b>${item.label || item.name}</b>` : ''}`;
        hs.ondragover = e => { if (!isStorageSecondaryOpen()) e.preventDefault(); };
        hs.ondrop = e => {
            if (isStorageSecondaryOpen()) { e.preventDefault(); return; }
            e.preventDefault();
            const raw = e.dataTransfer.getData('text/plain');
            if (!raw) return;
            const data = JSON.parse(raw);
            if (data.source === 'player') {
                nui('moveItem', { fromSlot: data.fromSlot, toSlot: h, name: data.item.name, count: Number(amount.value) || 1 });
                nui('setHotbar', { hotbarSlot: h, itemSlot: h });
            }
        };
    });
}

function calcWeight(items) {
    return (items || []).reduce((a, i) => a + ((i.weight || 0) * (i.count || 1)), 0);
}

function updateRightWeight(other) {
    if (!rightWeightText || !rightWeightFill) return;
    const o = other || {};
    const max = Number(o.maxWeight || o.weight || 0);
    const used = calcWeight(o.items || []);
    if (max > 0) {
        rightWeightText.innerText = `${(used / 1000).toFixed(1)} / ${(max / 1000).toFixed(0)} KG`;
        rightWeightFill.style.width = `${Math.max(0, Math.min(100, (used / max) * 100))}%`;
    } else {
        rightWeightText.innerText = used > 0 ? `${(used / 1000).toFixed(1)} KG` : `0.0 / 0 KG`;
        rightWeightFill.style.width = used > 0 ? '8%' : '0%';
    }
}

function openInventory(data) {
    mode = 'inventory';
    currentShop = null;
    app.classList.remove('hidden');
    setInventoryOpenState(true);
    applyServerSettings(data.uiSettings || {});

    const items = data.items || [];
    lastItems = items;
    currentOther = data.other || { type: 'ground', label: 'GROUND DROPS', items: [] };

    const max = data.maxWeight || 50000;
    currentMaxWeight = max;
    currentSlots = data.slots || 50;
    const weight = calcWeight(items);
    weightText.innerText = `${(weight/1000).toFixed(1)} / ${(max/1000).toFixed(0)} KG`;
    weightFill.style.width = `${Math.min(100, (weight / max) * 100)}%`;

    rightTitle.innerText = currentOther.label || 'GROUND DROPS';
    rightSub.innerText = currentOther.subtitle || (currentOther.type === 'ground' ? 'Drop / pickup items' : currentOther.type === 'shop' ? 'Drag item to buy' : currentOther.type === 'stash' ? 'Stash storage' : 'Vehicle storage');
    updateRightWeight(currentOther);

    renderGrid(playerGrid, items, 'player', currentSlots);
    renderGrid(otherGrid, currentOther.items || [], currentOther.type || 'ground', currentOther.slots || 25);
    renderHotbar(items, data.hotbar || {});
}

function openShop(data) {
    mode = 'shop';
    currentShop = data.shopId;
    app.classList.remove('hidden');
    setInventoryOpenState(true);
    applyServerSettings(data.uiSettings || {});

    const items = data.playerItems || data.items || [];
    lastItems = items;
    const max = data.maxWeight || 50000;
    currentMaxWeight = max;
    currentSlots = data.slots || 50;
    const weight = calcWeight(items);
    weightText.innerText = `${(weight/1000).toFixed(1)} / ${(max/1000).toFixed(0)} KG`;
    weightFill.style.width = `${Math.min(100, (weight / max) * 100)}%`;

    rightTitle.innerText = data.shopLabel || 'SHOP';
    rightSub.innerText = 'Drag item to your inventory to buy';
    currentOther = { type: 'shop', label: data.shopLabel, subtitle: 'Drag item to buy', shopId: data.shopId, items: data.shopItems || [], slots: data.shopSlots || 25, maxWeight: 0 };
    updateRightWeight(currentOther);
    renderGrid(playerGrid, items, 'player', currentSlots);
    renderGrid(otherGrid, data.shopItems || [], 'shop', data.shopSlots || 25);
    renderHotbar(items, data.hotbar || {});
}

function closeInventory() {
    const now = Date.now();
    if (rdInventoryClosing || (now - rdLastCloseAt) < 250) return;
    rdInventoryClosing = true;
    rdLastCloseAt = now;
    app.classList.add('hidden');
    contextMenu.classList.add('hidden');
    settingsPanel.classList.add('hidden');
    closeClothesUi();
    closeAttachmentModal();
    hotbar.classList.add('hidden');
    selected = null;
    setInventoryOpenState(false);
    nui('close');
    setTimeout(() => { rdInventoryClosing = false; }, 300);
}

function putClothOnBody(item, send = true, equipSlot = null) {
    const type = clothingType(item);
    if (!type) return false;
    const slot = document.querySelector(`.wear-slot[data-cloth="${type}"]`);
    if (!slot) return false;
    wornClothes[type] = item;
    slot.classList.add('filled');
    slot.draggable = true;
    const icon = slot.querySelector('.rd-hex img') || slot.querySelector('img');
    if (icon) {
        icon.src = img(item);
        icon.onerror = function(){ this.onerror=null; this.src=fallbackIcon(item); };
    }
    const label = slot.querySelector('.rd-label span') || slot.querySelector('.wear-label');
    if (label && item.label) label.textContent = item.label;
    slot.ondragstart = (e) => {
        if (isStorageSecondaryOpen()) { e.preventDefault(); return false; }
        e.dataTransfer.effectAllowed = 'move';
        e.dataTransfer.setData('text/plain', JSON.stringify({ source: 'clothes', clothType: type, item }));
    };
    if (send) nui('equipClothing', { name: item.name, type, slot: equipSlot || item.slot || selected?.slot });
    return true;
}


function isWeaponItem(item) {
    const n = String(item?.name || '').toLowerCase();
    return n.startsWith('weapon_') || n.startsWith('weapon-') || n.includes('pistol') || n.includes('rifle') || n.includes('shotgun') || n.includes('smg');
}

let rdAttachDrag = null;
let rdAttachWeaponData = null;
let rdAttachedNow = [];

function attachmentCategory(name = '') {
    const n = String(name).toLowerCase();
    if (n.includes('scope')) return 'scope';
    if (n.includes('suppressor') || n.includes('supp') || n.includes('muzzle')) return 'muzzle';
    if (n.includes('flash')) return 'flash';
    if (n.includes('clip') || n.includes('mag') || n.includes('drum')) return 'clip';
    if (n.includes('grip')) return 'grip';
    if (n.includes('barrel')) return 'barrel';
    if (n.includes('skin') || n.includes('tint') || n.includes('luxary') || n.includes('finish') || n.includes('color') || n.includes('colour')) return 'skin';
    return 'misc';
}

function rdAttachImage(a) {
    return `nui://${GetParentResourceName()}/web/images/${a.image || (a.name + '.png')}`;
}

function rdWeaponImage(weapon) {
    if (weapon?.image) return `nui://${GetParentResourceName()}/web/images/${weapon.image}`;
    const raw = String(weapon?.weapon || weapon?.name || '').toUpperCase();
    const file = raw.startsWith('WEAPON_') ? raw : raw.replace(/^WEAPON-/, 'WEAPON_');
    return `nui://${GetParentResourceName()}/web/images/${file}.png`;
}

function rdMountedForCategory(cat) {
    return (rdAttachedNow || []).find(a => attachmentCategory(a.name || '') === cat || attachmentCategory(a.component || '') === cat);
}

function rdMountedHtml(cat, label) {
    const a = rdMountedForCategory(cat);
    if (!a) return `<span>${label}</span><small class="slot-empty">EMPTY</small>`;
    return `<img class="rd-slot-img" src="${rdAttachImage(a)}" onerror="this.onerror=null;this.src='./assets/use.svg'"><span>${a.label || a.name}</span><small class="slot-on">VENDOSUR</small>`;
}

function rdBindMountedSlotDrag() {
    document.querySelectorAll('.rd-weapon-slot').forEach(slot => {
        const mounted = rdMountedForCategory(slot.dataset.category);
        if (!mounted) return;
        slot.setAttribute('draggable', 'true');
        slot.ondragstart = (e) => {
            e.dataTransfer.effectAllowed = 'move';
            e.dataTransfer.setData('text/plain', JSON.stringify({ source:'weapon-mounted', name:mounted.name, component:mounted.component, category:slot.dataset.category, label:mounted.label || mounted.name, image: mounted.image || (mounted.name + '.png') }));
        };
        slot.onmousedown = (e) => {
            if (e.button !== 0) return;
            rdStartMouseAttachmentDrag(e, { source:'weapon-mounted', name:mounted.name, component:mounted.component, category:slot.dataset.category, label:mounted.label || mounted.name, image: mounted.image || (mounted.name + '.png') }, slot.querySelector('img')?.src);
        };
        slot.oncontextmenu = (e) => {
            e.preventDefault();
            nui('removeWeaponAttachment', { name: mounted.name, component: mounted.component, weapon: rdAttachWeaponData?.weapon || rdAttachWeaponData?.name });
            rdAttachedNow = rdAttachedNow.filter(x => x.component !== mounted.component && x.name !== mounted.name);
            if (window.rdRenderAttachmentSlots) window.rdRenderAttachmentSlots();
            return false;
        };
    });
}

function rdRenderAttachedList() {
    const box = document.getElementById('rdAttachedList');
    if (!box) return;
    if (!rdAttachedNow.length) {
        box.innerHTML = '<div class="rd-attach-empty small">Asnje attachment i vendosur.</div>';
        return;
    }
    box.innerHTML = rdAttachedNow.map(a => `
        <div class="rd-attached-chip" draggable="true" data-name="${a.name}" data-component="${a.component}" data-category="${attachmentCategory(a.name)}">
            <img src="${rdAttachImage(a)}" onerror="this.onerror=null;this.src='./assets/use.svg'">
            <span>${a.label || a.name}</span>
        </div>
    `).join('');
    box.querySelectorAll('.rd-attached-chip').forEach(chip => {
        chip.ondragstart = (e) => {
            e.dataTransfer.effectAllowed = 'move';
            e.dataTransfer.setData('text/plain', JSON.stringify({ source:'weapon-mounted', name:chip.dataset.name, component:chip.dataset.component, category:chip.dataset.category, label:chip.querySelector('span')?.innerText || chip.dataset.name }));
        };
        chip.onmousedown = (e) => rdStartMouseAttachmentDrag(e, { source:'weapon-mounted', name:chip.dataset.name, component:chip.dataset.component, category:chip.dataset.category, label:chip.querySelector('span')?.innerText || chip.dataset.name }, chip.querySelector('img')?.src);
    });
}

function rdSetupAttachmentDrops() {
    const clearTargets = () => document.querySelectorAll('.rd-drop-hover,.drop-target').forEach(x => x.classList.remove('rd-drop-hover','drop-target'));
    const useAttachmentOnSlot = (data, slot) => {
        if (!data || !slot) return;
        const need = slot.dataset.category;
        if (need !== 'any' && data.category !== need) {
            nui('notify', { message: 'Ky attachment nuk shkon ne kete slot', type: 'error' });
            return;
        }
        nui('useAttachmentItem', { name: data.name, slot: Number(data.slot) || null, component: data.component, weapon: rdAttachWeaponData?.weapon || rdAttachWeaponData?.name, weaponSlot: rdAttachWeaponData?.slot || null });
        rdAttachedNow = rdAttachedNow.filter(x => x.component !== data.component);
        rdAttachedNow.push(data);
        rdRenderAttachedList();
        if (window.rdRenderAttachmentSlots) window.rdRenderAttachmentSlots();
    };
    const removeMountedAttachment = (data) => {
        if (!data) return;
        nui('removeWeaponAttachment', { name: data.name, component: data.component, weapon: rdAttachWeaponData?.weapon || rdAttachWeaponData?.name });
        rdAttachedNow = rdAttachedNow.filter(x => x.component !== data.component && x.name !== data.name);
        rdRenderAttachedList();
        if (window.rdRenderAttachmentSlots) window.rdRenderAttachmentSlots();
    };

    document.querySelectorAll('.rd-weapon-slot').forEach(slot => {
        slot.ondragover = (e) => { e.preventDefault(); slot.classList.add('drop-target'); };
        slot.ondragleave = () => slot.classList.remove('drop-target');
        slot.ondrop = (e) => {
            e.preventDefault(); slot.classList.remove('drop-target');
            let data = null;
            try { data = JSON.parse(e.dataTransfer.getData('text/plain') || '{}'); } catch(_) {}
            if (!data || data.source !== 'inventory-attachment') return;
            useAttachmentOnSlot(data, slot);
        };
        slot.onclick = () => {
            if (window.rdSelectedAttach && window.rdSelectedAttach.source === 'inventory-attachment') {
                useAttachmentOnSlot(window.rdSelectedAttach, slot);
                window.rdSelectedAttach = null;
                clearTargets();
            }
        };
    });

    const trash = document.getElementById('rdAttachTrash');
    if (trash) {
        trash.ondragover = (e) => { e.preventDefault(); trash.classList.add('drop-target'); };
        trash.ondragleave = () => trash.classList.remove('drop-target');
        trash.ondrop = (e) => {
            e.preventDefault(); trash.classList.remove('drop-target');
            let data = null;
            try { data = JSON.parse(e.dataTransfer.getData('text/plain') || '{}'); } catch(_) {}
            if (data && data.source === 'weapon-mounted') removeMountedAttachment(data);
        };
        trash.onclick = () => {
            if (window.rdSelectedAttach && window.rdSelectedAttach.source === 'weapon-mounted') {
                removeMountedAttachment(window.rdSelectedAttach);
                window.rdSelectedAttach = null;
                clearTargets();
            }
        };
    }
}

function rdStartMouseAttachmentDrag(e, data, imgSrc) {
    if (!data) return;
    e.preventDefault();
    e.stopPropagation();
    window.rdSelectedAttach = data;

    const ghost = document.createElement('div');
    ghost.className = 'rd-attach-ghost';
    ghost.innerHTML = `<img src="${imgSrc || './assets/use.svg'}"><span>${data.label || data.name || ''}</span>`;
    document.body.appendChild(ghost);

    const move = (ev) => {
        ghost.style.left = (ev.clientX + 10) + 'px';
        ghost.style.top = (ev.clientY + 10) + 'px';
        document.querySelectorAll('.rd-weapon-slot,#rdAttachTrash').forEach(x => x.classList.remove('rd-drop-hover'));
        ghost.style.display = 'none';
        const under = document.elementFromPoint(ev.clientX, ev.clientY);
        ghost.style.display = '';
        const target = under?.closest?.('.rd-weapon-slot,#rdAttachTrash');
        if (target) target.classList.add('rd-drop-hover');
    };
    const up = (ev) => {
        document.removeEventListener('mousemove', move, true);
        document.removeEventListener('mouseup', up, true);
        document.querySelectorAll('.rd-weapon-slot,#rdAttachTrash').forEach(x => x.classList.remove('rd-drop-hover'));
        ghost.remove();
        const under = document.elementFromPoint(ev.clientX, ev.clientY);
        const target = under?.closest?.('.rd-weapon-slot,#rdAttachTrash');
        if (target) {
            if (target.id === 'rdAttachTrash' && data.source === 'weapon-mounted') {
                nui('removeWeaponAttachment', { name: data.name, component: data.component, weapon: rdAttachWeaponData?.weapon || rdAttachWeaponData?.name });
                rdAttachedNow = rdAttachedNow.filter(x => x.component !== data.component && x.name !== data.name);
                rdRenderAttachedList();
                if (window.rdRenderAttachmentSlots) window.rdRenderAttachmentSlots();
            } else if (target.classList.contains('rd-weapon-slot') && data.source === 'inventory-attachment') {
                const need = target.dataset.category;
                if (need !== 'any' && data.category !== need) {
                    nui('notify', { message: 'Ky attachment nuk shkon ne kete slot', type: 'error' });
                } else {
                    nui('useAttachmentItem', { name: data.name, slot: Number(data.slot) || null, component: data.component, weapon: rdAttachWeaponData?.weapon || rdAttachWeaponData?.name, weaponSlot: rdAttachWeaponData?.slot || null });
                    rdAttachedNow = rdAttachedNow.filter(x => x.component !== data.component);
                    rdAttachedNow.push(data);
                    rdRenderAttachedList();
                    if (window.rdRenderAttachmentSlots) window.rdRenderAttachmentSlots();
                }
            }
            window.rdSelectedAttach = null;
        }
    };
    document.addEventListener('mousemove', move, true);
    document.addEventListener('mouseup', up, true);
    move(e);
}
function openAttachmentModal(data) {
    if (!attachModal || !attachList) return;
    const weapon = data.weapon || {};
    rdAttachWeaponData = weapon;
    rdAttachedNow = data.equipped || [];
    attachWeapon.innerText = weapon.label || weapon.name || 'Weapon';
    const list = data.attachments || [];

    const renderSlots = () => {
        const stage = document.querySelector('.rd-gun-stage');
        if (!stage) return;
        const slots = [
            ['scope', 'SCOPE'], ['muzzle', 'SUPPRESSOR'], ['flash', 'FLASH'], ['clip', 'CLIP'], ['grip', 'GRIP'], ['barrel', 'BARREL'], ['skin', 'COLOR']
        ];
        slots.forEach(([cat, label]) => {
            const el = stage.querySelector(`.rd-weapon-slot[data-category="${cat}"]`);
            if (el) {
                el.removeAttribute('draggable');
                el.innerHTML = rdMountedHtml(cat, label);
            }
        });
        setTimeout(rdBindMountedSlotDrag, 0);
    };
    window.rdRenderAttachmentSlots = renderSlots;

    attachList.innerHTML = `
        <div class="rd-attach-pro">
            <div id="rdAttachTrash" class="rd-attach-trash" title="Hiq attachment nga arma">🗑</div>
            <div class="rd-gun-stage">
                <div class="rd-gun-line line-scope"></div>
                <div class="rd-gun-line line-muzzle"></div>
                <div class="rd-gun-line line-flash"></div>
                <div class="rd-gun-line line-clip"></div>
                <div class="rd-gun-line line-grip"></div>
                <div class="rd-gun-line line-barrel"></div>
                <div class="rd-gun-line line-skin"></div>
                <img class="rd-real-weapon-img" src="${rdWeaponImage(weapon)}" onerror="this.onerror=null;this.classList.add('hidden');this.parentElement.querySelector('.rd-gun-shape').classList.remove('hidden')">
                <div class="rd-gun-shape hidden"><div class="rd-gun-barrel"></div><div class="rd-gun-body"></div><div class="rd-gun-grip"></div></div>
                <div class="rd-weapon-slot slot-scope" data-category="scope">${rdMountedHtml('scope','SCOPE')}</div>
                <div class="rd-weapon-slot slot-muzzle" data-category="muzzle">${rdMountedHtml('muzzle','SUPPRESSOR')}</div>
                <div class="rd-weapon-slot slot-flash" data-category="flash">${rdMountedHtml('flash','FLASH')}</div>
                <div class="rd-weapon-slot slot-clip" data-category="clip">${rdMountedHtml('clip','CLIP')}</div>
                <div class="rd-weapon-slot slot-grip" data-category="grip">${rdMountedHtml('grip','GRIP')}</div>
                <div class="rd-weapon-slot slot-barrel" data-category="barrel">${rdMountedHtml('barrel','BARREL')}</div>
                <div class="rd-weapon-slot slot-skin" data-category="skin">${rdMountedHtml('skin','COLOR')}</div>
                <div class="rd-weapon-info">
                    <b>${weapon.label || weapon.name || 'Weapon'}</b>
                    <small>${weapon.weapon || weapon.name || ''}</small>
                    <em>DURABILITY: 100%</em>
                </div>
            </div>
            <div id="rdAttachedList" class="rd-attached-list rd-hidden-mounted-list"></div>
            <div class="rd-attach-title-row">ATTACHMENTS NE INVENTORY - kapi me mouse dhe vendosi te sloti i armes</div>
            <div class="rd-inv-attachments">
                ${list.length ? list.map(a => `
                    <div class="rd-attach-card" draggable="true" data-name="${a.name}" data-slot="${a.slot || ''}" data-component="${a.component || ''}" data-category="${attachmentCategory(a.name)}">
                        <img src="${rdAttachImage(a)}" onerror="this.onerror=null;this.src='./assets/use.svg'">
                        <span>${a.label || a.name}</span>
                        <b>x${a.count || 1}</b>
                    </div>
                `).join('') : '<div class="rd-attach-empty">Nuk ke attachments per kete arme.</div>'}
            </div>
        </div>`;

    attachList.querySelectorAll('.rd-attach-card').forEach(card => {
        card.ondragstart = (e) => {
            e.dataTransfer.effectAllowed = 'move';
            e.dataTransfer.setData('text/plain', JSON.stringify({
                source:'inventory-attachment',
                name:card.dataset.name,
                slot:card.dataset.slot,
                component:card.dataset.component,
                category:card.dataset.category,
                label:card.querySelector('span')?.innerText || card.dataset.name,
                image:(card.dataset.name || '') + '.png'
            }));
        };
        card.onmousedown = (e) => rdStartMouseAttachmentDrag(e, {
            source:'inventory-attachment',
            name:card.dataset.name,
            slot:card.dataset.slot,
            component:card.dataset.component,
            category:card.dataset.category,
            label:card.querySelector('span')?.innerText || card.dataset.name,
            image:(card.dataset.name || '') + '.png'
        }, card.querySelector('img')?.src);
        card.onclick = () => {
            window.rdSelectedAttach = {
                source:'inventory-attachment',
                name:card.dataset.name,
                slot:card.dataset.slot,
                component:card.dataset.component,
                category:card.dataset.category,
                label:card.querySelector('span')?.innerText || card.dataset.name,
                image:(card.dataset.name || '') + '.png'
            };
            document.querySelectorAll('.rd-attach-card').forEach(x => x.classList.remove('selected'));
            card.classList.add('selected');
            nui('notify', { message: 'Zgjidh slotin ku do ta vendosesh attachment', type: 'info' });
        };
    });
    rdRenderAttachedList();
    renderSlots();
    rdSetupAttachmentDrops();
    attachModal.classList.remove('hidden');
}

function closeAttachmentModal() {
    if (attachModal) attachModal.classList.add('hidden');
}

function useSelected() {
    if (!selected) return;
    if (selected.side === 'shop') return buySelected();
    if (selected.side !== 'player') {
        if (currentOther?.type === 'ground') nui('pickupDrop', { dropId: currentOther.dropId, slot: selected.slot, count: Number(amount.value) || 0 });
        return;
    }

    const type = clothingType(selected);
    if (type) {
        clothesPanel.classList.remove('hidden');
        putClothOnBody(selected, true, selected.slot);
        return;
    }

    nui('useItem', { name: selected.name, slot: selected.slot });
}

function dropSelected() {
    if (!selected || selected.side !== 'player') return;
    nui('dropItem', { name: selected.name, count: Number(amount.value) || 1, slot: selected.slot, dropId: currentOther?.type === 'ground' ? currentOther.dropId : null });
}

function openGiveModal(item) {
    if (!item || item.side !== 'player') return;
    pendingGiveItem = Object.assign({}, item);
    if (giveTargetId) giveTargetId.value = '';
    if (giveModal) giveModal.classList.remove('hidden');
    setTimeout(() => giveTargetId && giveTargetId.focus(), 30);
}

function closeGiveModal() {
    pendingGiveItem = null;
    if (giveModal) giveModal.classList.add('hidden');
}

function confirmGiveModal() {
    if (!pendingGiveItem) return closeGiveModal();
    const targetId = Number(giveTargetId?.value);
    if (!targetId || targetId < 1) return;
    nui('giveItem', { name: pendingGiveItem.name, count: rdAmount(1), slot: pendingGiveItem.slot, targetId });
    closeGiveModal();
}

function giveSelected() {
    if (!selected || selected.side !== 'player') return;
    openGiveModal(selected);
}

function rdOpenShopPay(item, targetSlot) {
    if (!item) return;
    const count = Number(amount?.value) || 1;
    const total = (Number(item.price) || 0) * count;
    pendingShopBuy = {
        shopId: currentShop || currentOther?.shopId,
        name: item.name,
        label: item.label || item.name,
        count,
        slot: targetSlot || item.slot,
        fromSlot: item.slot,
        toSlot: targetSlot || item.slot,
        total
    };
    if (shopPayText) shopPayText.innerText = `Total: $${total}`;
    if (shopPayItem) shopPayItem.innerText = `${pendingShopBuy.label} x${count}`;
    if (shopPayModal) shopPayModal.classList.remove('hidden');
}

function rdConfirmShopPay(method) {
    if (!pendingShopBuy) return;
    const data = Object.assign({}, pendingShopBuy, { payMethod: method || 'cash' });
    if (shopPayModal) shopPayModal.classList.add('hidden');
    pendingShopBuy = null;
    nui('closeForShopPayment', {});
    closeInventory();
    nui('buyItem', data);
}

function buySelected() {
    if (!selected || selected.side !== 'shop') return;
    rdOpenShopPay(selected);
}

function initClothesDrops() {
    document.querySelectorAll('.wear-slot').forEach(slot => {
        slot.ondragover = e => { if (!isStorageSecondaryOpen()) e.preventDefault(); };
        slot.ondrop = e => {
            if (isStorageSecondaryOpen()) { e.preventDefault(); return; }
            e.preventDefault();
            const raw = e.dataTransfer.getData('text/plain');
            if (!raw) return;
            const data = JSON.parse(raw);
            const item = data.item;
            const type = clothingType(item);
            if (type !== slot.dataset.cloth) return;
            putClothOnBody(item, true, data.fromSlot);
        };
        slot.ondblclick = () => {
            const type = slot.dataset.cloth;
            const item = wornClothes[type];
            if (!item || !item.name) return;
            nui('unequipClothingToInventory', { type, name: item.name });
        };
    });
}

function resetWearSlot(slot, type) {
    slot.classList.remove('filled');
    slot.draggable = false;
    const pretty = String(type || '').toUpperCase();
    slot.innerHTML = `<b>${pretty}</b><img src="nui://${GetParentResourceName()}/web/images/${type}.png" onerror="this.onerror=null;this.style.display='none'"><span class="wear-empty">+</span>`;
}

function openClothesUi() {
    settingsPanel.classList.add('hidden');
    contextMenu.classList.add('hidden');
    document.body.classList.add('clothes-mode');
    const shell = document.querySelector('.inventory-shell');
    if (shell) shell.classList.add('hidden');
    clothesPanel.classList.remove('hidden');
    initClothesDrops();
    nui('openClothesUI', {});
}

function closeClothesUi() {
    document.body.classList.remove('clothes-mode');
    const shell = document.querySelector('.inventory-shell');
    if (shell) shell.classList.remove('hidden');
    clothesPanel.classList.add('hidden');
    nui('closeClothesUI', { keepFocus: true });
}


// RD FIX: Clothes button must NOT open inventory clothes panel.
// It closes RD inventory and opens the real merged dpclothing native GUI only.
function openRealDpClothingOnly(ev){
    if (ev) { ev.preventDefault(); ev.stopPropagation(); }
    try {
        if (typeof closeClothesUi === 'function') closeClothesUi(true);
        if (clothesPanel) clothesPanel.classList.add('hidden');
        if (settingsPanel) settingsPanel.classList.add('hidden');
        document.body.classList.remove('clothes-mode');
        const shell = document.querySelector('.inventory-shell');
        if (shell) shell.classList.remove('hidden');
    } catch(e) {}
    try { nui('openDpClothingAndCloseInventory', {}); }
    catch(e) {
        fetch(`https://${GetParentResourceName()}/openDpClothingAndCloseInventory`, {
            method:'POST', headers:{'Content-Type':'application/json'}, body:'{}'
        });
    }
}

function toggleClothes() {
    if (clothesPanel.classList.contains('hidden')) openClothesUi();
    else closeClothesUi();
}


if (attachClose) attachClose.onclick = closeAttachmentModal;
if (giveConfirm) giveConfirm.onclick = confirmGiveModal;
if (giveCancel) giveCancel.onclick = closeGiveModal;
if (shopPayCash) shopPayCash.onclick = () => rdConfirmShopPay('cash');
if (shopPayBank) shopPayBank.onclick = () => rdConfirmShopPay('bank');
if (shopPayCancel) shopPayCancel.onclick = () => { pendingShopBuy = null; if (shopPayModal) shopPayModal.classList.add('hidden'); };

if (giveTargetId) giveTargetId.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') confirmGiveModal();
    if (e.key === 'Escape') closeGiveModal();
});

window.addEventListener('message', (event) => {
    const d = event.data || {};
    if (d.action === 'forceClose') { closeInventory(); return; }
    if (d.action === 'open') { rdInventoryClosing = false; openInventory(d); }
    if (d.action === 'refresh') {
        lastItems = d.items || [];
        const rw = calcWeight(lastItems);
        weightText.innerText = `${(rw/1000).toFixed(1)} / ${(currentMaxWeight/1000).toFixed(0)} KG`;
        weightFill.style.width = `${Math.min(100, (rw / currentMaxWeight) * 100)}%`;
        if (d.other) currentOther = d.other;
        updateRightWeight(currentOther);
        currentSlots = d.slots || currentSlots || 50;
        renderGrid(playerGrid, d.items || [], 'player', currentSlots);
        // Mos e ndrysho panelin e djathtë kur jemi në shop/stash/trunk/glovebox.
        // Kjo e ndalon bug-un ku pas blerjes shop-i boshatiset ose kthehet në drops.
        if (currentOther) {
            renderGrid(otherGrid, currentOther.items || [], currentOther.type || 'ground', currentOther.slots || 25);
        }
        renderHotbar(d.items || [], d.hotbar || currentHotbar);
    }
    if (d.action === 'refreshOther') {
        currentOther = d.other || currentOther;
        rightTitle.innerText = currentOther.label || 'GROUND DROPS';
        rightSub.innerText = currentOther.subtitle || (currentOther.type === 'ground' ? 'Drop / pickup items' : currentOther.type === 'shop' ? 'Drag item to buy' : currentOther.type === 'stash' ? 'Stash storage' : 'Vehicle storage');
        updateRightWeight(currentOther);
        renderGrid(otherGrid, currentOther.items || [], currentOther.type || 'ground', currentOther.slots || 25);
    }
    if (d.action === 'openShop') openShop(d);
    if (d.action === 'clothEquipped' && d.item) {
        putClothOnBody(d.item, false);
    }
    if (d.action === 'clothSync') {
        document.querySelectorAll('.wear-slot').forEach(slot => resetWearSlot(slot, slot.dataset.cloth));
        wornClothes = {};
        (d.items || []).forEach(item => putClothOnBody(item, false));
    }
    if (d.action === 'hotbar') {
        renderHotbar(d.items || [], d.hotbar || {});
        hotbar.classList.remove('hidden');
        setTimeout(() => hotbar.classList.add('hidden'), 3000);
    }
    if (d.action === 'attachments') openAttachmentModal(d);
    if (d.action === 'progress') showRdProgress(d);
    if (d.action === 'progressHide') hideRdProgress();
    if (d.action === 'close') { app.classList.add('hidden'); setInventoryOpenState(false); rdInventoryClosing = false; }
});

setupMiddleActionDropZones();
document.getElementById('useBtn').onclick = useSelected;
document.getElementById('dropBtn').onclick = dropSelected;
document.getElementById('giveBtn').onclick = giveSelected;
document.getElementById('settingsBtn').onclick = () => {
    clothesPanel.classList.add('hidden');
    settingsPanel.classList.toggle('hidden');
};
document.getElementById('clothesBtn').onclick = openRealDpClothingOnly;
document.getElementById('closeClothes').onclick = closeClothesUi;

['bgOpacity','slotSize','slotGap','slotRadius','redIntensity','bagOpacity','slotDark'].forEach(id => {
    document.getElementById(id).addEventListener('input', () => applySettings(false));
});

document.getElementById('saveUi').onclick = () => applySettings(true);
document.getElementById('resetUi').onclick = () => {
    const def = { backgroundOpacity: 68, slotSize: 92, slotGap: 8, slotRadius: 7, redIntensity: 255, bagOpacity: 92, slotDark: 96 };
    try {
        localStorage.removeItem('rdInventoryUi');
        localStorage.removeItem('rd_inventory_ui');
    } catch(e) {}
    document.getElementById('bgOpacity').value = def.backgroundOpacity;
    document.getElementById('slotSize').value = def.slotSize;
    document.getElementById('slotGap').value = def.slotGap;
    document.getElementById('slotRadius').value = def.slotRadius;
    document.getElementById('redIntensity').value = def.redIntensity;
    if (document.getElementById('bagOpacity')) document.getElementById('bagOpacity').value = def.bagOpacity;
    if (document.getElementById('slotDark')) document.getElementById('slotDark').value = def.slotDark;
    applySettings(false);
    nui('saveUISettings', def);
};

contextMenu.onclick = (e) => {
    const action = e.target.dataset.action;
    if (action === 'use') useSelected();
    if (action === 'drop') dropSelected();
    if (action === 'give') giveSelected();
    if (action === 'buy') buySelected();
    contextMenu.classList.add('hidden');
};

document.addEventListener('click', (e) => {
    if (!contextMenu.contains(e.target)) contextMenu.classList.add('hidden');
});
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' || e.key === 'Tab') {
        e.preventDefault();
        closeInventory();
    }
});

initClothesDrops();

if (typeof GetParentResourceName === 'undefined') {
    window.GetParentResourceName = () => 'RD_inventory';
    openInventory({
        items:[
            {slot:1,name:'water',label:'Water',count:3,weight:500,image:'water.png'},
            {slot:2,name:'bread',label:'Bread',count:2,weight:300,image:'bread.png'},
            {slot:3,name:'hat_black',label:'Black Hat',count:1,weight:250,image:'hat.png'}
        ],
        other:{type:'ground', label:'GROUND DROPS', items:[{slot:1,name:'phone',label:'Phone',count:1,image:'phone.png'}], slots:25},
        hotbar:{1:1,2:2},
        maxWeight:50000,
        slots:40,
        uiSettings:{backgroundOpacity:68,slotSize:92,slotGap:8,slotRadius:7,redIntensity:255}
    });
}

// rd-clothes-esc-fix
window.addEventListener('keydown', (e) => {
    if ((e.key === 'Escape' || String(e.key).toLowerCase() === 'x') && clothesPanel && !clothesPanel.classList.contains('hidden')) {
        closeClothesUi();
        e.preventDefault();
    }
});


// RD FINAL: clear clothes icons + safe TAB/ESC/X close, prevents stuck NUI when spam pressing keys.
(function(){
    const iconMap = {
        hat:'hat.svg', mask:'mask.svg', glasses:'glasses.svg', earrings:'earrings.svg', chain:'chain.svg', watch:'watch.svg',
        jacket:'jacket.svg', shirt:'shirt.svg', gloves:'gloves.svg', bag:'bag.svg', pants:'pants.svg', shoes:'shoes.svg'
    };
    window.rdClothIcon = function(type){ return `./assets/${iconMap[type] || 'clothes.svg'}`; };

    const _oldReset = resetWearSlot;
    resetWearSlot = function(slot, type){
        if (!slot) return _oldReset(slot, type);
        slot.classList.remove('filled');
        slot.draggable = false;
        const img = slot.querySelector('.rd-hex img') || slot.querySelector('img');
        if (img) img.src = window.rdClothIcon(type);
    };

    const _oldFallback = fallbackIcon;
    fallbackIcon = function(item){
        const t = clothingType(item || {});
        if (t) return window.rdClothIcon(t);
        return _oldFallback(item);
    };

    let keyLock = false;
    let clothesLock = false;
    let closeLock = false;

    function unlockSoon(){ setTimeout(() => { keyLock=false; clothesLock=false; closeLock=false; rdInventoryClosing=false; }, 420); }

    openClothesUi = function(){
        if (clothesLock) return;
        clothesLock = true;
        rdInventoryClosing = false;
        if (settingsPanel) settingsPanel.classList.add('hidden');
        if (contextMenu) contextMenu.classList.add('hidden');
        document.body.classList.add('clothes-mode');
        const shell = document.querySelector('.inventory-shell');
        if (shell) shell.classList.add('hidden');
        if (clothesPanel) clothesPanel.classList.remove('hidden');
        initClothesDrops();
        nui('openClothesUI', {});
        setTimeout(() => { clothesLock=false; }, 350);
    };

    closeClothesUi = function(silent){
        if (!clothesPanel || clothesPanel.classList.contains('hidden')) return;
        if (clothesLock && !silent) return;
        clothesLock = true;
        document.body.classList.remove('clothes-mode');
        const shell = document.querySelector('.inventory-shell');
        if (shell && app && !app.classList.contains('hidden')) shell.classList.remove('hidden');
        clothesPanel.classList.add('hidden');
        if (!silent) nui('closeClothesUI', { keepFocus: true });
        setTimeout(() => { clothesLock=false; }, 300);
    };

    closeInventory = function(){
        if (closeLock || rdInventoryClosing) return;
        closeLock = true;
        rdInventoryClosing = true;
        rdLastCloseAt = Date.now();
        document.body.classList.remove('clothes-mode');
        const shell = document.querySelector('.inventory-shell');
        if (shell) shell.classList.remove('hidden');
        if (app) app.classList.add('hidden');
        if (contextMenu) contextMenu.classList.add('hidden');
        if (settingsPanel) settingsPanel.classList.add('hidden');
        if (clothesPanel) clothesPanel.classList.add('hidden');
        if (attachModal) attachModal.classList.add('hidden');
        if (hotbar) hotbar.classList.add('hidden');
        selected = null;
        setInventoryOpenState(false);
        nui('closeClothesUI', { keepFocus: false });
        nui('close', {});
        unlockSoon();
    };

    toggleClothes = function(){
        if (!clothesPanel) return;
        if (clothesPanel.classList.contains('hidden')) openClothesUi();
        else closeClothesUi(false);
    };

    const cb = document.getElementById('clothesBtn');
    if (cb) cb.onclick = openRealDpClothingOnly;
    const cx = document.getElementById('closeClothes');
    if (cx) cx.onclick = () => closeClothesUi(false);

    window.addEventListener('keydown', function(e){
        const k = String(e.key || '').toLowerCase();
        if (k !== 'escape' && k !== 'tab' && k !== 'x') return;
        if (keyLock) { e.preventDefault(); e.stopImmediatePropagation(); return; }
        keyLock = true;
        e.preventDefault();
        e.stopImmediatePropagation();
        if (clothesPanel && !clothesPanel.classList.contains('hidden')) closeClothesUi(false);
        else if (app && !app.classList.contains('hidden')) closeInventory();
        unlockSoon();
    }, true);

    window.addEventListener('message', function(ev){
        const d = ev.data || {};
        if (d.action === 'open' || d.action === 'openShop') { keyLock=false; closeLock=false; clothesLock=false; rdInventoryClosing=false; }
        if (d.action === 'close' || d.action === 'forceClose') { keyLock=false; closeLock=false; clothesLock=false; rdInventoryClosing=false; }
    }, true);
})();

// RD FIX 2026: settings save button + NUI anti-glitch + UI feedback notifications.
(function(){
    let rdSaveLock = false;
    let rdHardCloseLock = false;

    function toast(message, type){
        let wrap = document.querySelector('.rd-toast-wrap');
        if (!wrap) {
            wrap = document.createElement('div');
            wrap.className = 'rd-toast-wrap';
            document.body.appendChild(wrap);
        }
        const el = document.createElement('div');
        el.className = 'rd-toast ' + (type || 'info');
        el.innerHTML = `<b>RD Inventory</b><span>${String(message || 'Done')}</span>`;
        wrap.appendChild(el);
        setTimeout(() => el.classList.add('out'), 2600);
        setTimeout(() => el.remove(), 2850);
    }
    window.rdInventoryToast = toast;


    function rdEscapeHtml(v){
        return String(v == null ? '' : v).replace(/[&<>'"]/g, function(ch){
            return ({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'})[ch];
        });
    }

    function rdCleanNotifyImage(data){
        const name = String((data && (data.image || data.name)) || 'item.png').replace(/^.*[\\/]/, '');
        return name.toLowerCase().endsWith('.png') ? name : (name + '.png');
    }

    function rdItemNotify(data){
        data = data || {};
        let wrap = document.querySelector('.rd-item-notify-wrap');
        if (!wrap) {
            wrap = document.createElement('div');
            wrap.className = 'rd-item-notify-wrap';
            document.body.appendChild(wrap);
        }
        const count = Number(data.count || 1);
        const label = data.label || data.name || 'Item';
        const image = rdCleanNotifyImage(data);
        const el = document.createElement('div');
        el.className = 'rd-item-notify ' + (data.type || 'add');
        el.innerHTML = `
            <div class="rd-item-glow"></div>
            <div class="rd-item-imgbox"><img src="nui://${GetParentResourceName()}/web/images/${image}" onerror="this.onerror=null;this.src='nui://${GetParentResourceName()}/web/images/box.png';this.style.display='none';"></div>
            <div class="rd-item-info">
                <b>TI MORRE</b>
                <span>${rdEscapeHtml(label)}</span>
            </div>
            <div class="rd-item-count">x${count}</div>
        `;
        wrap.appendChild(el);
        setTimeout(() => el.classList.add('show'), 20);
        setTimeout(() => el.classList.add('out'), 2450);
        setTimeout(() => el.remove(), 2850);
    }
    window.rdItemNotify = rdItemNotify;

    function safeSettings(){
        try { return currentSettings(); }
        catch(e) { return { backgroundOpacity:68, slotSize:92, slotGap:8, slotRadius:7, redIntensity:255, bagOpacity:92, slotDark:96 }; }
    }

    async function saveSettingsNow(btn, customSettings, reset){
        if (rdSaveLock) return;
        rdSaveLock = true;
        if (btn) btn.classList.add('rd-saving');
        const s = customSettings || safeSettings();
        try {
            localStorage.setItem('rd_inventory_ui', JSON.stringify(s));
            applySettings(false);
            await nui('saveUISettings', s);
            toast(reset ? 'UI settings u resetuan dhe u ruajten.' : 'UI settings u ruajten me sukses.', 'success');
            if (settingsPanel) settingsPanel.classList.add('hidden');
        } catch(e) {
            toast('Settings u ruajten lokalisht, por server save deshtoi.', 'error');
        }
        setTimeout(() => {
            rdSaveLock = false;
            if (btn) btn.classList.remove('rd-saving');
        }, 450);
    }

    const saveBtn = document.getElementById('saveUi');
    if (saveBtn) saveBtn.onclick = function(e){
        if (e) { e.preventDefault(); e.stopPropagation(); }
        saveSettingsNow(saveBtn, null, false);
    };

    const resetBtn = document.getElementById('resetUi');
    if (resetBtn) resetBtn.onclick = function(e){
        if (e) { e.preventDefault(); e.stopPropagation(); }
        const def = { backgroundOpacity: 68, slotSize: 92, slotGap: 8, slotRadius: 7, redIntensity: 255, bagOpacity: 92, slotDark: 96 };
        try { localStorage.removeItem('rdInventoryUi'); localStorage.removeItem('rd_inventory_ui'); } catch(err) {}
        ['bgOpacity','slotSize','slotGap','slotRadius','redIntensity','bagOpacity','slotDark'].forEach(id => {
            const el = document.getElementById(id);
            if (!el) return;
            const key = id === 'bgOpacity' ? 'backgroundOpacity' : id;
            el.value = def[key];
        });
        saveSettingsNow(resetBtn, def, true);
    };

    const oldCloseInventory = closeInventory;
    closeInventory = function(){
        if (rdHardCloseLock) return;
        rdHardCloseLock = true;
        document.body.classList.add('rd-hard-closing');
        try { hideRdProgress(); } catch(e) {}
        try { if (rdMouseDrag && rdMouseDrag.ghost) rdMouseDrag.ghost.remove(); rdMouseDrag = null; } catch(e) {}
        try { document.querySelectorAll('.drop-target,.dragging').forEach(x => x.classList.remove('drop-target','dragging')); } catch(e) {}
        try { oldCloseInventory(); } catch(e) { nui('close', {}); }
        setTimeout(() => {
            rdHardCloseLock = false;
            rdInventoryClosing = false;
            document.body.classList.remove('rd-hard-closing');
        }, 520);
    };

    window.addEventListener('message', function(ev){
        const d = ev.data || {};
        if (d.action === 'notify') toast(d.message || d.description || 'Inventory', d.type || 'info');
        if (d.action === 'itemNotify') rdItemNotify(d);
        if (d.action === 'open' || d.action === 'openShop') {
            rdHardCloseLock = false;
            rdInventoryClosing = false;
            document.body.classList.remove('rd-hard-closing');
        }
    }, true);
})();

// RD CLOTHES DOUBLE CLICK REMOVE + CLEAN UI SYNC FIX 2026-05-26
(function(){
    function rdDefaultClothIcon(type){
        if (window.rdClothIcon) return window.rdClothIcon(type);
        return `./assets/${String(type || 'clothes')}.svg`;
    }
    window.rdResetClothSlot = function(type){
        const slot = document.querySelector(`.wear-slot[data-cloth="${type}"]`);
        if (!slot) return;
        slot.classList.remove('filled');
        slot.draggable = false;
        if (window.wornClothes) delete window.wornClothes[type];
        try { delete wornClothes[type]; } catch(e) {}
        const imgEl = slot.querySelector('.rd-hex img') || slot.querySelector('img');
        if (imgEl) imgEl.src = rdDefaultClothIcon(type);
    };
    function rdRemoveCloth(type, item){
        if (!type) return;
        const worn = item || (typeof wornClothes !== 'undefined' ? wornClothes[type] : null);
        if (worn && worn.name) nui('unequipClothingToInventory', { type:type, name:worn.name });
        else nui('removeClothing', { type:type });
        // Visual reset immediately; server still validates and sends notify.
        window.rdResetClothSlot(type);
        if (window.rdInventoryToast) window.rdInventoryToast('Rroba u hoq nga trupi.', 'success');
    }
    function bindClothesDoubleClick(){
        document.querySelectorAll('.wear-slot').forEach(slot => {
            slot.addEventListener('dblclick', function(e){
                e.preventDefault();
                e.stopPropagation();
                const type = slot.dataset.cloth;
                const item = (typeof wornClothes !== 'undefined') ? wornClothes[type] : null;
                rdRemoveCloth(type, item);
            }, true);
        });
    }
    bindClothesDoubleClick();
    window.addEventListener('message', function(ev){
        const d = ev.data || {};
        if (d.action === 'removeClothing' || d.action === 'clothRemoved') window.rdResetClothSlot(d.type || d.clothType);
        if (d.action === 'open' || d.action === 'clothSync') setTimeout(bindClothesDoubleClick, 50);
    }, true);
})();

// ================= RD CRAFTING PRO UI =================
const craftApp = document.getElementById('craftApp');
const craftRecipeList = document.getElementById('craftRecipeList');
const craftAttachmentList = document.getElementById('craftAttachmentList');
const craftBenchTitle = document.getElementById('craftBenchTitle');
const craftMainImage = document.getElementById('craftMainImage');
const craftIngredients = document.getElementById('craftIngredients');
const craftInventoryList = document.getElementById('craftInventoryList');
const craftButton = document.getElementById('craftButton');
const craftCloseBtn = document.getElementById('craftClose');
const craftLevelEl = document.getElementById('craftLevel');
const craftXpText = document.getElementById('craftXpText');
const craftXpFill = document.getElementById('craftXpFill');
const craftProgress = document.getElementById('craftProgress');
const craftProgressLabel = document.getElementById('craftProgressLabel');
const craftProgressFill = document.getElementById('craftProgressFill');
let rdCraftState = { recipes: [], inventory: [], selected: null, level: 1, xp: 0, nextXp: 100, filter: 'all', busy: false, placed: {} };
let rdCraftDrag = null;
let rdCraftTimer = null;

function rdCraftImg(nameOrItem){
    const item = typeof nameOrItem === 'string' ? { image: nameOrItem, name: nameOrItem } : (nameOrItem || {});
    return img(item);
}
function rdCraftClose(){
    if (!craftApp) return;
    craftApp.classList.add('hidden');
    rdCraftState.busy = false;
    nui('craftClose', {});
}
function rdCraftHideOnly(){
    if (!craftApp) return;
    craftApp.classList.add('hidden');
    rdCraftState.busy = false;
}
function rdCraftInventoryCount(name){
    let c = 0;
    (rdCraftState.inventory || []).forEach(it => { if (it.name === name) c += Number(it.count || 0); });
    return c;
}

function rdCraftNeedKey(recipe){ return recipe ? String(recipe.id || recipe.item || recipe.label || '') : ''; }
function rdCraftPlacedFor(recipe){ return rdCraftState.placed[rdCraftNeedKey(recipe)] || {}; }
function rdCraftPlacedOk(recipe){
    // Comfortable mode: materials can be dragged into slots OR crafted directly if you have them.
    // Dragging is only a visual confirmation; server still validates real inventory items.
    const ing = recipe && recipe.ingredients ? recipe.ingredients : {};
    for (const [name, need] of Object.entries(ing)) {
        if (rdCraftInventoryCount(name) < Number(need || 0)) return false;
    }
    return true;
}
function rdCraftStartDrag(e, item){
    if (e.button !== 0 || !item) return;
    e.preventDefault();
    const ghost = document.createElement('div');
    ghost.className = 'craft-drag-ghost';
    ghost.innerHTML = `<img src="${rdCraftImg(item.image || item.name)}"><b>${item.label || item.name}</b>`;
    document.body.appendChild(ghost);
    rdCraftDrag = { item, ghost };
    rdCraftMoveDrag(e);
    document.addEventListener('mousemove', rdCraftMoveDrag, true);
    document.addEventListener('mouseup', rdCraftEndDrag, true);
}
function rdCraftMoveDrag(e){
    if (!rdCraftDrag) return;
    rdCraftDrag.ghost.style.left = (e.clientX + 12) + 'px';
    rdCraftDrag.ghost.style.top = (e.clientY + 12) + 'px';
    document.querySelectorAll('.craft-ing').forEach(el => el.classList.remove('hover'));
    const el = document.elementFromPoint(e.clientX, e.clientY);
    const slot = el && el.closest ? el.closest('.craft-ing') : null;
    if (slot) slot.classList.add('hover');
}
function rdCraftEndDrag(e){
    if (!rdCraftDrag) return;
    document.removeEventListener('mousemove', rdCraftMoveDrag, true);
    document.removeEventListener('mouseup', rdCraftEndDrag, true);
    const drag = rdCraftDrag; rdCraftDrag = null;
    if (drag.ghost && drag.ghost.parentNode) drag.ghost.parentNode.removeChild(drag.ghost);
    document.querySelectorAll('.craft-ing').forEach(el => el.classList.remove('hover'));
    const el = document.elementFromPoint(e.clientX, e.clientY);
    const slot = el && el.closest ? el.closest('.craft-ing') : null;
    if (!slot || !rdCraftState.selected) return;
    const needName = slot.dataset.need;
    if (!needName) return;
    const itemName = String(drag.item.name || '').toLowerCase();
    if (itemName !== String(needName).toLowerCase()) {
        slot.classList.add('wrong'); setTimeout(()=>slot.classList.remove('wrong'), 450); return;
    }
    const key = rdCraftNeedKey(rdCraftState.selected);
    rdCraftState.placed[key] = rdCraftState.placed[key] || {};
    rdCraftState.placed[key][needName] = drag.item.name;
    rdCraftRender();
}
function rdCraftRenderInventory(){
    if (!craftInventoryList) return;
    craftInventoryList.innerHTML = '';
    const needed = new Set();
    if (rdCraftState.selected && rdCraftState.selected.ingredients) Object.keys(rdCraftState.selected.ingredients).forEach(n => needed.add(String(n).toLowerCase()));
    (rdCraftState.inventory || []).filter(it => it && it.name && Number(it.count || 0) > 0).sort((a,b)=> (needed.has(String(b.name).toLowerCase())?1:0)-(needed.has(String(a.name).toLowerCase())?1:0)).forEach(it => {
        const row = document.createElement('div');
        row.className = 'craft-inv-item' + (needed.has(String(it.name).toLowerCase()) ? ' needed' : '');
        row.innerHTML = `<img src="${rdCraftImg(it.image || it.name)}" onerror="this.src='./assets/use.svg'"><div><b>${it.label || it.name}</b><span>x${it.count || 0}</span></div>`;
        row.onmousedown = (e) => rdCraftStartDrag(e, it);
        craftInventoryList.appendChild(row);
    });
}

function rdCraftCanMake(recipe){
    if (!recipe) return false;
    if (rdCraftState.level < Number(recipe.level || 1)) return false;
    if (!rdCraftPlacedOk(recipe)) return false;
    for (const [name, need] of Object.entries(recipe.ingredients || {})) {
        if (rdCraftInventoryCount(name) < Number(need || 0)) return false;
    }
    return true;
}
function rdCraftRender(){
    if (!craftRecipeList) return;
    craftLevelEl.innerText = rdCraftState.level || 1;
    craftXpText.innerText = `${rdCraftState.xp || 0} / ${rdCraftState.nextXp || 100} XP`;
    craftXpFill.style.width = `${Math.min(100, ((rdCraftState.xp || 0) / (rdCraftState.nextXp || 100)) * 100)}%`;
    craftRecipeList.innerHTML = '';
    rdCraftRenderInventory();
    const filtered = (rdCraftState.recipes || []).filter(r => rdCraftState.filter === 'all' || r.category === rdCraftState.filter);
    filtered.forEach(r => {
        const card = document.createElement('div');
        card.className = 'craft-card' + (rdCraftState.selected && rdCraftState.selected.id === r.id ? ' active' : '') + (!rdCraftCanMake(r) ? ' locked' : '');
        card.innerHTML = `<img src="${rdCraftImg(r.image || r.item)}" onerror="this.src='./assets/use.svg'"><div><h4>${r.label}</h4><p>${(r.category || 'item').toUpperCase()} • LVL ${r.level || 1} • +${r.xp || 0} XP</p></div><b>x${r.count || 1}</b>`;
        card.onclick = () => { rdCraftState.selected = r; rdCraftRender(); };
        craftRecipeList.appendChild(card);
    });
    craftAttachmentList.innerHTML = '';
    (rdCraftState.recipes || []).filter(r => ['attachments','tints'].includes(r.category)).forEach(r => {
        const card = document.createElement('div');
        card.className = 'craft-card' + (!rdCraftCanMake(r) ? ' locked' : '');
        card.innerHTML = `<img src="${rdCraftImg(r.image || r.item)}" onerror="this.src='./assets/use.svg'"><div><h4>${r.label}</h4><p>LVL ${r.level || 1} • ${rdCraftCanMake(r) ? 'READY' : 'MISSING'}</p></div>`;
        card.onclick = () => { rdCraftState.selected = r; rdCraftRender(); };
        craftAttachmentList.appendChild(card);
    });
    const sel = rdCraftState.selected || filtered[0] || (rdCraftState.recipes || [])[0];
    rdCraftState.selected = sel;
    if (!sel) return;
    craftMainImage.src = rdCraftImg(sel.image || sel.item);
    craftIngredients.innerHTML = '';
    for (const [name, need] of Object.entries(sel.ingredients || {})) {
        const have = rdCraftInventoryCount(name);
        const ing = document.createElement('div');
        const placed = rdCraftPlacedFor(sel)[name];
        ing.className = 'craft-ing' + (have < need ? ' missing' : '') + (placed ? ' placed' : '');
        ing.dataset.need = name;
        ing.innerHTML = `<img src="${rdCraftImg(name)}" onerror="this.src='./assets/use.svg'"><div><b>${name}</b><span>${placed ? 'PLACED' : (have + ' / ' + need)}</span></div>`;
        ing.onclick = () => {
            if (have >= need) {
                const key = rdCraftNeedKey(sel);
                rdCraftState.placed[key] = rdCraftState.placed[key] || {};
                rdCraftState.placed[key][name] = name;
                rdCraftRender();
            }
        };
        craftIngredients.appendChild(ing);
    }
    craftButton.disabled = rdCraftState.busy || !rdCraftCanMake(sel);
    craftButton.innerText = rdCraftState.level < (sel.level || 1) ? `NEED LEVEL ${sel.level}` : (rdCraftCanMake(sel) ? 'CRAFT' : 'MISSING ITEMS');
}
function rdCraftProgress(label, duration){
    if (!craftProgress) return;
    duration = Math.max(500, Number(duration || 3000));
    rdCraftState.busy = true;
    rdCraftRender();
    craftProgressLabel.innerText = label || 'CRAFTING';
    craftProgressFill.style.width = '0%';
    craftProgress.classList.remove('hidden');
    const start = Date.now();
    if (rdCraftTimer) clearInterval(rdCraftTimer);
    rdCraftTimer = setInterval(() => {
        const pct = Math.min(100, ((Date.now() - start) / duration) * 100);
        craftProgressFill.style.width = pct + '%';
        if (pct >= 100) {
            clearInterval(rdCraftTimer); rdCraftTimer = null;
            setTimeout(() => { craftProgress.classList.add('hidden'); rdCraftState.busy = false; rdCraftRender(); }, 250);
        }
    }, 40);
}
function rdCraftMiniGame(done){
    const wrap = document.createElement('div');
    wrap.style.cssText = 'position:fixed;inset:0;z-index:99999;background:rgba(0,0,0,.72);display:flex;align-items:center;justify-content:center;font-family:Arial;color:#fff';
    wrap.innerHTML = `<div style="width:560px;border:2px solid #ff1f2d;background:linear-gradient(135deg,#120000,#050505);border-radius:18px;padding:24px;text-align:center;box-shadow:0 0 35px #ff1f2d66">
        <h2 style="margin:0 0 8px;color:#ff2636;letter-spacing:2px">CRAFT SKILLCHECK</h2>
        <p style="opacity:.9;margin:0 0 16px">Shtyp <b>SPACE</b> kur vija eshte brenda zones se kuqe. Zona ndryshon vend pas cdo hit.</p>
        <div style="position:relative;height:38px;background:#151515;border:1px solid #555;border-radius:10px;overflow:hidden">
            <div id="rdMiniZone" style="position:absolute;left:40%;top:0;width:22%;height:100%;background:#ff263670;box-shadow:0 0 18px #ff263655 inset"></div>
            <div id="rdMiniNeedle" style="position:absolute;left:0;top:0;width:6px;height:100%;background:#fff;box-shadow:0 0 14px #fff"></div>
        </div>
        <div id="rdMiniText" style="margin-top:13px;font-weight:900">0 / 3</div>
        <div style="margin-top:8px;font-size:12px;opacity:.75">Eshte bere me avash + ke 2 gabime pa ta prishur craftin.</div>
    </div>`;
    document.body.appendChild(wrap);

    let x = 0;
    let dir = 1;
    let hits = 0;
    let misses = 0;
    let raf = null;
    let last = performance.now();

    const speedPerSecond = 28; // old speed was very fast; this is slow and smooth.
    const zoneWidth = 22;      // bigger red zone = easier SPACE timing.
    let zoneLeft = 40;

    const zone = wrap.querySelector('#rdMiniZone');
    const needle = wrap.querySelector('#rdMiniNeedle');
    const text = wrap.querySelector('#rdMiniText');

    function randomZone(){
        zoneLeft = 8 + Math.random() * (84 - zoneWidth);
        zone.style.left = zoneLeft + '%';
        zone.style.width = zoneWidth + '%';
    }

    function tick(now){
        const delta = Math.min(50, now - last) / 1000;
        last = now;
        x += dir * speedPerSecond * delta;
        if (x >= 99) { x = 99; dir = -1; }
        if (x <= 0) { x = 0; dir = 1; }
        needle.style.left = x + '%';
        raf = requestAnimationFrame(tick);
    }

    function cleanup(ok){
        cancelAnimationFrame(raf);
        window.removeEventListener('keydown', key, true);
        wrap.remove();
        done(!!ok);
    }

    function setText(msg, color){
        text.innerText = msg;
        text.style.color = color || '#fff';
    }

    function key(e){
        if (e.code !== 'Space') return;
        e.preventDefault();
        e.stopPropagation();

        if (x >= zoneLeft && x <= zoneLeft + zoneWidth) {
            hits++;
            setText(hits + ' / 3', '#34ff74');
            if (hits >= 3) return cleanup(true);
            randomZone();
            return;
        }

        misses++;
        if (misses >= 3) {
            setText('FAILED', '#ff2636');
            return setTimeout(() => cleanup(false), 650);
        }
        setText('MISS ' + misses + ' / 2', '#ffb02e');
    }

    randomZone();
    window.addEventListener('keydown', key, true);
    raf = requestAnimationFrame(tick);
}
if (craftButton) craftButton.onclick = () => {
    if (!rdCraftState.selected || rdCraftState.busy || !rdCraftCanMake(rdCraftState.selected)) return;
    rdCraftState.busy = true;
    rdCraftRender();
    rdCraftMiniGame((ok) => {
        if (!ok) { rdCraftState.busy = false; rdCraftRender(); return; }
        nui('craftStart', { recipeId: rdCraftState.selected.id });
        rdCraftHideOnly();
    });
};
if (craftCloseBtn) craftCloseBtn.onclick = rdCraftClose;
document.querySelectorAll('.craft-filter button').forEach(btn => btn.addEventListener('click', () => {
    document.querySelectorAll('.craft-filter button').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    rdCraftState.filter = btn.dataset.cat || 'all';
    rdCraftRender();
}));
window.addEventListener('message', (event) => {
    const d = event.data || {};
    if (d.action === 'openCraft') {
        if (app) app.classList.add('hidden');
        craftApp.classList.remove('hidden');
        craftBenchTitle.innerText = (d.bench && d.bench.label) || 'CRAFTING TABLE';
        rdCraftState = { recipes: d.recipes || [], inventory: d.inventory || [], selected: null, level: d.level || 1, xp: d.xp || 0, nextXp: d.nextXp || 100, filter: 'all', busy: false, placed: {} };
        document.querySelectorAll('.craft-filter button').forEach(b => b.classList.toggle('active', b.dataset.cat === 'all'));
        rdCraftRender();
    }
    if (d.action === 'craftUpdate') {
        rdCraftState.inventory = d.inventory || rdCraftState.inventory || [];
        rdCraftState.level = d.level || rdCraftState.level;
        rdCraftState.xp = d.xp || rdCraftState.xp;
        rdCraftState.nextXp = d.nextXp || rdCraftState.nextXp;
        rdCraftState.busy = false;
        if (craftProgress) craftProgress.classList.add('hidden');
        rdCraftRender();
    }
    if (d.action === 'craftProgress') rdCraftProgress(d.label, d.duration);
    if (d.action === 'forceCloseCraft') rdCraftHideOnly();
});
window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && craftApp && !craftApp.classList.contains('hidden')) rdCraftClose();
});

// RD UPDATE: Clothes button opens merged dpclothing UI and closes inventory first.
(function(){
  const btn = document.getElementById('clothesBtn');
  if (!btn) return;
  btn.onclick = openRealDpClothingOnly;
})();

// RD FINAL HARD FIX: Inventory CLOTHES button opens REAL dpclothing wheel only.
// This disables the old inventory clothes panel from every path.
(function(){
  function rdOpenDpFromInventory(ev){
    if (ev) { ev.preventDefault(); ev.stopPropagation(); if (ev.stopImmediatePropagation) ev.stopImmediatePropagation(); }
    try {
      document.body.classList.remove('clothes-mode');
      const cp = document.getElementById('clothesPanel'); if (cp) cp.classList.add('hidden');
      const sp = document.getElementById('settingsPanel'); if (sp) sp.classList.add('hidden');
      const cm = document.getElementById('contextMenu'); if (cm) cm.classList.add('hidden');
      const sh = document.querySelector('.inventory-shell'); if (sh) sh.classList.remove('hidden');
    } catch(e) {}
    try {
      fetch(`https://${GetParentResourceName()}/openDpClothingAndCloseInventory`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: '{}'
      });
    } catch(e) {}
    return false;
  }

  // Any old call to openClothesUi/toggleClothes now opens dpclothing instead of RD clothes panel.
  window.openClothesUi = rdOpenDpFromInventory;
  window.toggleClothes = rdOpenDpFromInventory;
  window.openRealDpClothingOnly = rdOpenDpFromInventory;

  function bindClothesBtn(){
    const btn = document.getElementById('clothesBtn');
    if (!btn || btn.dataset.rdDpBound === '1') return;
    btn.dataset.rdDpBound = '1';
    btn.onclick = rdOpenDpFromInventory;
    btn.addEventListener('click', rdOpenDpFromInventory, true);
    btn.addEventListener('mousedown', function(e){ e.stopPropagation(); }, true);
  }
  bindClothesBtn();
  window.addEventListener('load', bindClothesBtn);
  window.addEventListener('message', bindClothesBtn, true);
})();
