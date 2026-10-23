-- MRI: client side of the UI design panel, suite colors, notify position and context menu extras.

local uiConfig = nil

local function getConfig()
    if uiConfig then return uiConfig end
    -- Not cached on failure, so the next call retries instead of keeping an empty config.
    uiConfig = lib.callback.await('ox_lib:getUiConfig', false)
    return uiConfig or {}
end

exports('getUiConfig', getConfig)

-- Computed here, not sent with the config: the uiConfigChanged broadcast would drop it on the first save.
local function withMeta(cfg)
    local out = {}
    for k, v in pairs(cfg) do out[k] = v end
    out.playerThemeChoice = GetConvar('mri_ui_allow_theme_choice', 'true') ~= 'false'
    out.suiteColorsManaged = GetResourceState('mri_Qadmin') == 'started'
    if out.suiteColorsManaged then
        out.accentColor = GetConvar('mri:color', '#00E699')
        out.backgroundColor = GetConvar('mri:backgroundColor', '')
    end
    return out
end

RegisterNetEvent('ox_lib:uiConfigChanged', function(newConfig)
    if type(newConfig) ~= 'table' then return end
    uiConfig = newConfig
    SendNUIMessage({ action = 'applyUiConfig', data = newConfig })
end)

RegisterNetEvent('ox_lib:openUiConfig', function()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openUiConfig', data = withMeta(getConfig()) })
end)

-- Also the NUI boot pull (App.tsx), standalone or embedded in mri_Qadmin.
RegisterNUICallback('adminGetUiConfig', function(_, cb)
    cb(withMeta(getConfig()))
end)

RegisterNUICallback('adminSaveUiConfig', function(payload, cb)
    local ok, result = lib.callback.await('ox_lib:saveUiConfig', false, payload)
    cb({ success = ok == true, config = ok and result or nil })
end)

RegisterNUICallback('closeUiConfig', function(_, cb)
    SetNuiFocus(false, false)
    cb({ ok = true })
end)

RegisterNUICallback('adminListPresets', function(_, cb)
    cb(lib.callback.await('ox_lib:listPresets', false) or {})
end)

RegisterNUICallback('adminSavePreset', function(data, cb)
    local ok = lib.callback.await('ox_lib:savePreset', false, data)
    cb({ success = ok == true })
end)

RegisterNUICallback('adminApplyPreset', function(data, cb)
    local ok, result = lib.callback.await('ox_lib:applyPreset', false, data and data.name)
    cb({ success = ok == true, config = ok and result or nil })
end)

RegisterNUICallback('adminDeletePreset', function(data, cb)
    local ok = lib.callback.await('ox_lib:deletePreset', false, data and data.name)
    cb({ success = ok == true })
end)

-- Live mode: real components via SendNUIMessage, only the ones that never take focus.
RegisterNUICallback('uiConfigPreview', function(data, cb)
    local kind = data and data.kind
    if kind == 'notify' then
        SendNUIMessage({ action = 'notify', data = {
            title = 'Notificação de teste',
            description = 'Prévia ao vivo do editor de interface.',
            type = data.notifyType or 'success',
            duration = data.duration or 4000,
            position = data.position,
        } })
    elseif kind == 'progressBar' then
        -- preview=true skips the progressStyle routing, so the editor always shows the bar.
        SendNUIMessage({ action = 'progress', data = { label = 'Progresso de teste', duration = data.duration or 4000, preview = true } })
    elseif kind == 'progressCircle' then
        SendNUIMessage({ action = 'circleProgress', data = { label = 'Progresso', duration = data.duration or 4000, preview = true } })
    elseif kind == 'textui' then
        SendNUIMessage({ action = 'textUi', data = { text = '[E]  Prévia do TextUI', position = 'right-center' } })
        SetTimeout(3500, function() SendNUIMessage({ action = 'textUiHide' }) end)
    end
    cb({ ok = true })
end)

-- Suite colors (mri:color / mri:backgroundColor); own callback so resource/client.lua stays untouched.
RegisterNUICallback('mri:getConfig', function(_, cb)
    cb({
        accentColor = GetConvar('mri:color', '#00E699'),
        backgroundColor = GetConvar('mri:backgroundColor', ''),
    })
end)

RegisterNetEvent('ox_lib:accentColorChanged', function(newColor)
    SendNUIMessage({ action = 'updateAccentColor', data = { accentColor = newColor } })
end)

RegisterNetEvent('ox_lib:backgroundColorChanged', function(newColor)
    SendNUIMessage({ action = 'updateBackgroundColor', data = { backgroundColor = newColor or '' } })
end)

-- Notify position comes from /uiconfig: drop the player setting from the shared table and keep it out.
local settings = require 'resource.settings'
settings.notification_position = nil

setmetatable(settings, {
    __newindex = function(t, key, value)
        if key == 'notification_position' then return end
        rawset(t, key, value)
    end,
})

-- Context menu extras (description, background, backgroundColor) sent right before showContext.
local contextExtras = {}
local registerContext = lib.registerContext
local showContext = lib.showContext

local function saveContextExtras(menu)
    contextExtras[menu.id] = {
        description = menu.description,
        background = menu.background,
        backgroundColor = menu.backgroundColor,
    }
end

local function mriRegisterContext(context)
    for k, v in pairs(context) do
        if type(k) == 'number' then
            saveContextExtras(v)
        else
            saveContextExtras(context)
            break
        end
    end

    return registerContext(context)
end

local function mriShowContext(id)
    local extras = contextExtras[id]

    if extras then
        local background = extras.background
        if background == nil then background = GetConvarInt('ox:menuBackground', 0) == 1 end

        SendNUIMessage({
            action = 'mri:contextExtras',
            data = {
                description = extras.description,
                background = background,
                backgroundColor = extras.backgroundColor,
            }
        })
    end

    return showContext(id)
end

-- The export registered last wins, so other resources get the wrapped versions too.
rawset(lib, 'registerContext', mriRegisterContext)
rawset(lib, 'showContext', mriShowContext)
exports('registerContext', mriRegisterContext)
exports('showContext', mriShowContext)
