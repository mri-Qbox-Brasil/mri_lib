-- MRI: replaces the upstream /ox_lib command (same cached settings table), without notify position and with the personal theme.

local settings = require 'resource.settings'
local userLocales = GetConvarInt('ox:userLocales', 1) == 1

-- Own KVP: the upstream `locale` one is shared by every ox_lib server the player joins.
local LOCALE_KVP = 'mri_locale'

local function getSavedLocale()
    local value = GetResourceKvpString(LOCALE_KVP)
    if value and value ~= '' then return value end
end

-- Upstream already loaded the shared KVP; fix it here before other resources ask for the locale.
if userLocales then
    local wanted = getSavedLocale() or settings.default_locale

    if settings.locale ~= wanted then
        settings.locale = wanted
        lib.setLocale(wanted)
    end
end

-- Same persistence as the upstream `set`, which is local there.
local function set(key, value)
    if settings[key] == value then return false end

    settings[key] = value
    local valueType = type(value)

    if valueType == 'nil' then
        DeleteResourceKvp(key)
    elseif valueType == 'string' then
        SetResourceKvp(key, value)
    elseif valueType == 'table' then
        SetResourceKvp(key, json.encode(value))
    elseif valueType == 'number' then
        SetResourceKvpInt(key, value)
    elseif valueType == 'boolean' then
        SetResourceKvpInt(key, value and 1 or 0)
    else
        return false
    end

    return true
end

-- Personal theme over the /uiconfig one; `setr mri_ui_allow_theme_choice "false"` turns it off.
local THEME_KVP = 'mri_ui_theme'

local function allowThemeChoice()
    return GetConvar('mri_ui_allow_theme_choice', 'true') ~= 'false'
end

---@return 'dark' | 'glass' | 'liquid' | nil
local function getThemeChoice()
    if not allowThemeChoice() then return end
    local theme = GetResourceKvpString(THEME_KVP)
    if theme == 'dark' or theme == 'glass' or theme == 'liquid' then return theme end
end

RegisterNUICallback('mri:getThemeChoice', function(_, cb)
    cb({ theme = getThemeChoice() })
end)

---@class MriSettingOption
---@field enabled? fun(): boolean
---@field input fun(): table lib.inputDialog field
---@field apply fun(value: any)

---@type MriSettingOption[]
local options = {
    {
        input = function()
            return {
                type = 'checkbox',
                label = locale('ui.settings.notification_audio'),
                checked = settings.notification_audio,
            }
        end,
        apply = function(value) set('notification_audio', value) end,
    },
    {
        enabled = function() return userLocales end,
        input = function()
            return {
                type = 'select',
                label = locale('ui.settings.locale'),
                searchable = true,
                description = locale('ui.settings.locale_description', settings.locale),
                options = GlobalState['ox_lib:locales'],
                default = settings.locale,
                required = true,
                icon = 'book',
            }
        end,
        apply = function(value)
            if not value or value == settings.locale then return end

            SetResourceKvp(LOCALE_KVP, value)
            settings.locale = value
            lib.setLocale(value)
        end,
    },
    {
        enabled = allowThemeChoice,
        input = function()
            return {
                type = 'select',
                label = locale('ui.settings.theme'),
                options = {
                    { label = locale('ui.settings.theme_server'), value = 'server' },
                    { label = locale('ui.settings.theme_dark'), value = 'dark' },
                    { label = locale('ui.settings.theme_glass'), value = 'glass' },
                    { label = locale('ui.settings.theme_liquid'), value = 'liquid' },
                },
                default = getThemeChoice() or 'server',
                required = true,
                icon = 'palette',
            }
        end,
        apply = function(value)
            if value == 'dark' or value == 'glass' or value == 'liquid' then
                SetResourceKvp(THEME_KVP, value)
            else
                DeleteResourceKvp(THEME_KVP)
            end

            SendNUIMessage({ action = 'mri:setThemeChoice', data = { theme = getThemeChoice() } })
        end,
    },
}

RegisterCommand('ox_lib', function()
    local active, fields = {}, {}

    for i = 1, #options do
        local option = options[i]

        if not option.enabled or option.enabled() then
            active[#active + 1] = option
            fields[#fields + 1] = option.input()
        end
    end

    local input = lib.inputDialog(locale('settings'), fields) --[[@as table?]]
    if not input then return end

    for i = 1, #active do
        active[i].apply(input[i])
    end
end)
