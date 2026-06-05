RDUI = {
    saveOnServer = true,

    default = {
        backgroundOpacity = 68,
        slotSize = 92,
        slotGap = 8,
        slotRadius = 7,
        redIntensity = 255,
        clothesPanelScale = 85
    },

    clothes = {
        panelSide = 'right',
        iconsOnly = true,
        compact = true,
        slots = {
            hat = { icon = 'hat.png', component = 'prop_0' },
            mask = { icon = 'mask.png', component = 'mask' },
            shirt = { icon = 'shirt.png', component = 'torso' },
            gloves = { icon = 'gloves.png', component = 'arms' },
            pants = { icon = 'pants.png', component = 'legs' },
            shoes = { icon = 'shoes.png', component = 'shoes' }
        }
    }
}

return RDUI
