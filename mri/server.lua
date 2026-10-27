-- MRI: UI design settings edited in game (/uiconfig and the mri_Qadmin plugin), see mri/README.md.

local CONFIG_FILE = 'mri/data/config.json'
local PRESETS_FILE = 'mri/data/presets.json'

-- Fallback for a missing or broken file and for keys added later.
local DEFAULTS = {
    theme = 'glass',
    accentColor = '',
    backgroundColor = '',
    radius = 8,
    opacity = 0.8,
    notifyPosition = 'center-left',
    notifyDuration = 5000,
    fontFamily = 'Saira',
    successColor = '#10b981',
    warningColor = '#eab308',
    errorColor = '#ef4444',
    progressStyle = 'default',
    progressTheme = 'hud',
    circleTheme = 'follow',
    switchStyle = 'follow',
    notifyWidth = 320,
    progressBarWidth = 380,
    progressBarHeight = 18,
    progressCircleSize = 110,
    menuWidth = 400,
    contextWidth = 360,
    radialMode = 'toggle',
    radialTheme = 'ring',
    radialSize = 166,
    notifyLayout = 'card',
    textUiLayout = 'box',
    contextLayout = 'cards',
    menuLayout = 'cards',
    dialogLayout = 'center',
    textUiPosition = 'script',
    textUiOffset = 16,
    textUiScale = 100,
    textUiKeyStyle = 'theme',
    textUiCase = 'normal',
    textUiIcon = 'show',
    menuPosition = 'script',
    menuOffset = 5,
    menuScale = 100,
    menuIcons = 'show',
    menuCounter = 'show',
    menuTitleCase = 'normal',
    contextPosition = 'right',
    contextScale = 100,
    contextIcons = 'show',
    contextDescriptions = 'show',
    radialPageSize = 6,
    radialLabels = 'show',
    radialBackdrop = 'none',
    dialogSize = 'script',
    dialogBackdrop = 'none',
    itemNotifyLayout = 'slot',
    inventoryScale = 100,
    inventoryColumns = 5,
    inventorySlotStyle = 'card',
    inventoryLabels = 'always',
    inventoryWeight = 'ring',
    inventoryDurability = 'show',
    inventoryFilters = 'show',
    inventoryHints = 'show',
    inventoryHotbar = 'center',
    inventoryBackdrop = 'full',
    inventoryBackdropColor = 'theme',
    inventoryBackdropOpacity = 'theme',
    inventorySlotOpacity = 'theme',
    itemNotifyPosition = 'bottom-center',
    itemNotifyOffset = 15,
    itemNotifyScale = 100,
}

local config = {}

local NOTIFY_POSITIONS = {
    ['top-left'] = true, ['top-center'] = true, ['top-right'] = true,
    ['center-left'] = true, ['center-right'] = true,
    ['bottom-left'] = true, ['bottom-center'] = true, ['bottom-right'] = true,
}

-- Same lists as web/src/lib/layoutConfig.ts and progressConfig.ts.
local function oneOf(...)
    local set = {}
    for _, v in ipairs({ ... }) do set[v] = true end
    return function(v) return set[v] == true end
end

-- Invalid values fall back to the default, so a tampered payload never reaches disk or the NUI CSS.
local VALIDATORS = {
    theme = function(v) return v == 'dark' or v == 'glass' or v == 'liquid' end,
    -- '' means "follow the suite convar" (mri:color).
    accentColor = function(v)
        return type(v) == 'string' and (v == '' or v:match('^#%x%x%x%x%x%x$') ~= nil)
    end,
    -- '' means "follow the suite convar" (mri:backgroundColor).
    backgroundColor = function(v)
        return type(v) == 'string' and (v == '' or v:match('^#%x%x%x%x%x%x$') ~= nil)
    end,
    radius = function(v) return type(v) == 'number' and v >= 0 and v <= 32 end,
    opacity = function(v) return type(v) == 'number' and v >= 0.3 and v <= 1 end,
    notifyPosition = function(v) return NOTIFY_POSITIONS[v] == true end,
    notifyDuration = function(v) return type(v) == 'number' and v >= 500 and v <= 30000 end,
    fontFamily = function(v)
        return type(v) == 'string' and #v <= 64 and v:match('^[%w][%w%s%-]*$') ~= nil
    end,
    successColor = function(v) return type(v) == 'string' and v:match('^#%x%x%x%x%x%x$') ~= nil end,
    warningColor = function(v) return type(v) == 'string' and v:match('^#%x%x%x%x%x%x$') ~= nil end,
    errorColor = function(v) return type(v) == 'string' and v:match('^#%x%x%x%x%x%x$') ~= nil end,
    switchStyle = function(v) return v == 'square' or v == 'round' or v == 'follow' end,
    progressStyle = function(v) return v == 'default' or v == 'bar' or v == 'circle' end,
    progressTheme = oneOf('hud', 'tactical', 'minimal', 'segmented', 'capsule', 'split', 'slim'),
    circleTheme = oneOf('follow', 'hud', 'tactical', 'minimal', 'segmented', 'capsule', 'arc', 'pie', 'dual'),
    notifyLayout = oneOf('card', 'island', 'line', 'compact', 'block'),
    textUiLayout = oneOf('box', 'key', 'pill', 'arrow', 'minimal'),
    contextLayout = oneOf('cards', 'list', 'compact', 'grid', 'sidebar', 'numbered', 'outline'),
    menuLayout = oneOf('cards', 'list', 'compact', 'pills', 'classic', 'outline', 'minimal'),
    dialogLayout = oneOf('center', 'bottom', 'side'),
    textUiPosition = oneOf('script', 'right-center', 'left-center', 'top-center', 'bottom-center'),
    textUiOffset = function(v) return type(v) == 'number' and v >= 0 and v <= 160 end,
    textUiScale = function(v) return type(v) == 'number' and v >= 80 and v <= 150 end,
    textUiKeyStyle = oneOf('theme', 'accent', 'white', 'dark', 'outline'),
    textUiCase = oneOf('normal', 'upper'),
    textUiIcon = oneOf('show', 'hide'),
    menuPosition = oneOf('script', 'top-left', 'top-right', 'bottom-left', 'bottom-right'),
    menuOffset = function(v) return type(v) == 'number' and v >= 0 and v <= 120 end,
    menuScale = function(v) return type(v) == 'number' and v >= 80 and v <= 130 end,
    menuIcons = oneOf('show', 'hide'),
    menuCounter = oneOf('show', 'hide'),
    menuTitleCase = oneOf('normal', 'upper'),
    contextPosition = oneOf('right', 'left', 'center'),
    contextScale = function(v) return type(v) == 'number' and v >= 80 and v <= 130 end,
    contextIcons = oneOf('show', 'hide'),
    contextDescriptions = oneOf('show', 'hide'),
    radialPageSize = function(v) return type(v) == 'number' and v >= 4 and v <= 10 and v % 1 == 0 end,
    radialLabels = oneOf('show', 'center'),
    radialBackdrop = oneOf('none', 'dim'),
    dialogSize = oneOf('script', 'sm', 'md', 'lg', 'xl'),
    dialogBackdrop = oneOf('none', 'dim'),
    itemNotifyLayout = oneOf('slot', 'card', 'pill', 'icon', 'line'),
    itemNotifyPosition = function(v) return NOTIFY_POSITIONS[v] == true end,
    itemNotifyOffset = function(v) return type(v) == 'number' and v >= 0 and v <= 40 end,
    itemNotifyScale = function(v) return type(v) == 'number' and v >= 70 and v <= 150 end,
    -- ox_inventory look; same lists as web/src/lib/inventoryConfig.ts.
    inventoryScale = function(v) return v == 90 or v == 100 or v == 110 or v == 125 end,
    inventoryColumns = function(v) return type(v) == 'number' and v >= 5 and v <= 7 and v % 1 == 0 end,
    inventorySlotStyle = oneOf('card', 'outline', 'clean'),
    inventoryLabels = oneOf('always', 'hover', 'hidden'),
    inventoryWeight = oneOf('ring', 'bar', 'text'),
    inventoryDurability = oneOf('show', 'hide'),
    inventoryFilters = oneOf('show', 'hide'),
    inventoryHints = oneOf('show', 'hide'),
    inventoryHotbar = oneOf('center', 'left', 'right'),
    inventoryBackdrop = oneOf('full', 'vignette', 'bottom', 'none'),
    inventoryBackdropColor = oneOf('theme', 'black', 'accent'),
    inventoryBackdropOpacity = oneOf('theme', 100, 80, 60, 40, 20),
    inventorySlotOpacity = oneOf('theme', 100, 80, 60, 40, 20),
    notifyWidth = function(v) return type(v) == 'number' and v >= 240 and v <= 480 end,
    progressBarWidth = function(v) return type(v) == 'number' and v >= 240 and v <= 600 end,
    progressBarHeight = function(v) return type(v) == 'number' and v >= 10 and v <= 32 end,
    progressCircleSize = function(v) return type(v) == 'number' and v >= 80 and v <= 160 end,
    menuWidth = function(v) return type(v) == 'number' and v >= 300 and v <= 560 end,
    contextWidth = function(v) return type(v) == 'number' and v >= 280 and v <= 520 end,
    radialMode = function(v) return v == 'hold' or v == 'toggle' end,
    radialTheme = oneOf('ring', 'orbs', 'cards', 'minimal', 'petals', 'arc', 'dial', 'chips'),
    radialSize = function(v) return type(v) == 'number' and v >= 120 and v <= 240 end,
}

local function applyDefaults(input)
    -- Configs saved before `opacity` keep their look: glass reuses glassOpacity, dark stays opaque.
    if input.opacity == nil and input.theme ~= nil then
        input.opacity = input.theme == 'glass' and type(input.glassOpacity) == 'number'
            and math.max(0.3, math.min(1, input.glassOpacity)) or 1
    end

    local out = {}
    for k, v in pairs(DEFAULTS) do
        local incoming = input[k]
        if incoming ~= nil and VALIDATORS[k](incoming) then
            out[k] = incoming
        else
            out[k] = v
        end
    end
    return out
end

local function loadFromDisk()
    local raw = LoadResourceFile(GetCurrentResourceName(), CONFIG_FILE)
    if not raw or raw == '' then
        config = applyDefaults({})
        return
    end
    local ok, parsed = pcall(json.decode, raw)
    config = applyDefaults((ok and type(parsed) == 'table') and parsed or {})
end

local function saveToDisk()
    local ok = SaveResourceFile(GetCurrentResourceName(), CONFIG_FILE, json.encode(config, { indent = true }), -1)
    if not ok then
        print('[ox_lib/mri] ERRO: falha ao escrever ' .. CONFIG_FILE)
    end
    return ok
end

-- `ox_lib.uiconfig` is grantable in the mri_Qadmin group editor; `command.uiconfig` is legacy server.cfg.
local function isAdmin(source)
    return IsPlayerAceAllowed(source, 'ox_lib.uiconfig')
        or IsPlayerAceAllowed(source, 'command.uiconfig')
        or IsPlayerAceAllowed(source, 'command')
end

loadFromDisk()

-- ox_inventory hands its item notifications to us while this key is set (cleared on stop).
GlobalState['mri:itemNotify'] = true

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then GlobalState['mri:itemNotify'] = nil end
end)

lib.addCommand({ 'adminui', 'uiconfig' }, {
    help = 'Abre o painel de design da interface (admin)',
}, function(source)
    if source <= 0 or not isAdmin(source) then return end
    TriggerClientEvent('ox_lib:openUiConfig', source)
end)

-- Without mri_Qadmin the panel color becomes the suite convar; clearing it restores the server.cfg value read here.
local SUITE_COLORS = {
    accentColor = { convar = 'mri:color', original = GetConvar('mri:color', '#00E699') },
    backgroundColor = { convar = 'mri:backgroundColor', original = GetConvar('mri:backgroundColor', '') },
}

---@param key 'accentColor' | 'backgroundColor'
---@param previous? string color saved before the commit (nil on start)
local function syncSuiteColor(key, previous)
    local suite = SUITE_COLORS[key]
    local color = config[key]

    if color == '' then
        -- Only touch the convar when a panel color was there before.
        if not previous or previous == '' then return end
        color = suite.original
    end

    if GetConvar(suite.convar, '') ~= color then
        SetConvarReplicated(suite.convar, color)
    end
end

syncSuiteColor('accentColor')
syncSuiteColor('backgroundColor')

function GetUiConfig()
    return config
end

-- With mri_Qadmin running it owns the suite colors (database + convar); the panel color fields write through to it.
local function suiteColorsManaged()
    return GetResourceState('mri_Qadmin') == 'started'
end

lib.callback.register('ox_lib:getUiConfig', function()
    return config
end)

-- Single commit path for the panel save and applyPreset, so a preset's colors also go to mri_Qadmin.
local function commitConfig(incoming, writeEmptyBackground)
    if suiteColorsManaged() then
        -- pcall covers a mri_Qadmin without these exports; the convar keeps ruling, never two colors.
        local ok = pcall(function()
            if incoming.accentColor ~= '' then
                exports['mri_Qadmin']:SetSuiteAccent(incoming.accentColor)
            end
            if incoming.backgroundColor ~= '' or writeEmptyBackground then
                exports['mri_Qadmin']:SetSuiteBackground(incoming.backgroundColor)
            end
        end)
        if not ok then
            print('[ox_lib/mri] AVISO: mri_Qadmin sem SetSuiteAccent/SetSuiteBackground; cores nao persistidas')
        end
        incoming.accentColor = ''
        incoming.backgroundColor = ''
    end

    local previous = config
    config = incoming
    if not saveToDisk() then
        config = previous
        return false
    end

    if not suiteColorsManaged() then
        syncSuiteColor('accentColor', previous.accentColor)
        syncSuiteColor('backgroundColor', previous.backgroundColor)
    end

    -- In managed mode the colors arrive through the convar broadcast fired by mri_Qadmin.
    TriggerClientEvent('ox_lib:uiConfigChanged', -1, config)
    return true
end

---Config for the panel, with the real suite colors in managed mode.
local function panelConfig()
    if not suiteColorsManaged() then return config end
    local out = {}
    for k, v in pairs(config) do out[k] = v end
    out.accentColor = GetConvar('mri:color', '#00E699')
    out.backgroundColor = GetConvar('mri:backgroundColor', '')
    return out
end

lib.callback.register('ox_lib:saveUiConfig', function(source, payload)
    if not isAdmin(source) then return false, 'sem permissão' end
    if type(payload) ~= 'table' then return false, 'payload inválido' end

    if not commitConfig(applyDefaults(payload), true) then return false, 'falha ao salvar' end
    return true, panelConfig()
end)

-- Idempotent on purpose: no write or broadcast when already empty, which stops circular triggers.
local function clearColorOverride(key)
    if config[key] == '' then return true end
    local previous = config[key]
    config[key] = ''
    if not saveToDisk() then
        config[key] = previous
        return false
    end
    TriggerClientEvent('ox_lib:uiConfigChanged', -1, config)
    return true
end

-- Server-side exports for mri_Qadmin, which already gated its own settings page permission.
exports('ClearAccentOverride', function() return clearColorOverride('accentColor') end)
exports('ClearBackgroundOverride', function() return clearColorOverride('backgroundColor') end)

-- Presets: named themes in mri/data/presets.json; applying one copies it into the active config.

local function loadPresets()
    local raw = LoadResourceFile(GetCurrentResourceName(), PRESETS_FILE)
    if not raw or raw == '' then return {} end
    local ok, parsed = pcall(json.decode, raw)
    if ok and type(parsed) == 'table' and type(parsed.presets) == 'table' then
        return parsed.presets
    end
    return {}
end

local function savePresets(presets)
    local ok = SaveResourceFile(GetCurrentResourceName(), PRESETS_FILE, json.encode({ presets = presets }, { indent = true }), -1)
    if not ok then print('[ox_lib/mri] ERRO: falha ao escrever ' .. PRESETS_FILE) end
    return ok
end

local function validName(name)
    return type(name) == 'string' and #name >= 1 and #name <= 40 and name:match('^[%w][%w%s%-_]*$') ~= nil
end

lib.callback.register('ox_lib:listPresets', function(source)
    if not isAdmin(source) then return {} end
    local names = {}
    for _, p in ipairs(loadPresets()) do
        if type(p.name) == 'string' then names[#names + 1] = p.name end
    end
    return names
end)

lib.callback.register('ox_lib:savePreset', function(source, data)
    if not isAdmin(source) then return false, 'sem permissão' end
    if type(data) ~= 'table' or not validName(data.name) then return false, 'nome inválido' end

    local cfg = applyDefaults(type(data.config) == 'table' and data.config or {})
    local presets = loadPresets()
    local found
    for _, p in ipairs(presets) do
        if p.name == data.name then p.config = cfg; found = true; break end
    end
    if not found then presets[#presets + 1] = { name = data.name, config = cfg } end
    if not savePresets(presets) then return false, 'falha ao salvar' end
    return true
end)

lib.callback.register('ox_lib:applyPreset', function(source, name)
    if not isAdmin(source) then return false, 'sem permissão' end
    for _, p in ipairs(loadPresets()) do
        if p.name == name then
            if not commitConfig(applyDefaults(type(p.config) == 'table' and p.config or {})) then
                return false, 'falha ao salvar'
            end
            return true, panelConfig()
        end
    end
    return false, 'preset não encontrado'
end)

lib.callback.register('ox_lib:deletePreset', function(source, name)
    if not isAdmin(source) then return false, 'sem permissão' end
    local presets = loadPresets()
    for i, p in ipairs(presets) do
        if p.name == name then
            table.remove(presets, i)
            if not savePresets(presets) then return false, 'falha ao salvar' end
            return true
        end
    end
    return true
end)

-- Manifest shape mirrors web/src/plugin/types.ts.
local function doRegister()
    if GetResourceState('mri_Qadmin') ~= 'started' then return end

    -- Colors saved here before mri_Qadmin was installed would override its suite colors forever.
    clearColorOverride('accentColor')
    clearColorOverride('backgroundColor')

    exports['mri_Qadmin']:RegisterPlugin({
        id = 'uiconfig',
        label = 'Interface (UI)',
        icon = 'palette',
        resource = GetCurrentResourceName(),
        htmlPath = 'web/build/index.html',
        requiredPerms = { 'ox_lib.uiconfig', 'command' },
        description = 'Editar estilos de design do ox_lib (tema, cores, etc)',
    })
end

-- RegisterPlugin is idempotent by id, so the three paths below can overlap.
AddEventHandler('mri_Qadmin:server:pluginsReady', doRegister)

AddEventHandler('onServerResourceStart', function(resourceName)
    if resourceName == 'mri_Qadmin' then doRegister() end
end)

CreateThread(function()
    Wait(0)
    doRegister()
end)

-- Suite color convars changed at runtime (mri_Qadmin or `setr`); mri/client.lua forwards to the NUI.
AddConvarChangeListener('mri:color', function(name)
    if name ~= 'mri:color' then return end
    local color = GetConvar('mri:color', '#00E699')
    if not color:match('^#%x%x%x%x%x%x$') then return end
    TriggerClientEvent('ox_lib:accentColorChanged', -1, color)
end)

-- Unlike the accent, '' is valid here: no custom background.
AddConvarChangeListener('mri:backgroundColor', function(name)
    if name ~= 'mri:backgroundColor' then return end
    local color = GetConvar('mri:backgroundColor', '')
    if color ~= '' and not color:match('^#%x%x%x%x%x%x$') then return end
    TriggerClientEvent('ox_lib:backgroundColorChanged', -1, color)
end)
