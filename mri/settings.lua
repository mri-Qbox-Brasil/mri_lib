--[[
    /ox_lib da MRI: configuracoes pessoais do jogador.

    Substitui o comando registrado pelo resource/settings.lua do upstream (este
    arquivo carrega depois, no mesmo resource). Usa a MESMA tabela de settings
    (require cacheado), entao notify/locale do upstream continuam lendo daqui.

    Diferencas do upstream: sem a posicao das notificacoes, que na MRI vem do
    /uiconfig (ver mri/client.lua), e com o tema pessoal da interface. Pra
    adicionar uma opcao por jogador, e so incluir uma entrada em `options`.
]]

local settings = require 'resource.settings'
local userLocales = GetConvarInt('ox:userLocales', 1) == 1

-- Idioma da MRI. O KVP de client e isolado so pelo nome do resource, nao pelo
-- servidor: o `locale` do upstream e o mesmo em todo servidor com ox_lib, entao
-- quem escolheu English em outro servidor chegava aqui em ingles. A MRI nunca le
-- nem grava esse KVP compartilhado; usa uma chave propria (compartilhada so entre
-- servidores MRI). Sem escolha nela, vale o `ox:locale` do servidor.
local LOCALE_KVP = 'mri_locale'

local function getSavedLocale()
    local value = GetResourceKvpString(LOCALE_KVP)
    if value and value ~= '' then return value end
end

-- O upstream ja carregou o idioma do KVP compartilhado (resource/locale/client.lua);
-- corrige aqui, no load do ox_lib, antes dos outros resources pedirem o idioma.
if userLocales then
    local wanted = getSavedLocale() or settings.default_locale

    if settings.locale ~= wanted then
        settings.locale = wanted
        lib.setLocale(wanted)
    end
end

-- Mesma persistencia do `set` do upstream (local la, por isso repetida aqui).
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

-- Tema pessoal: por cima do tema do /uiconfig, so pra este jogador. O admin
-- desliga com `setr mri_ui_allow_theme_choice "false"` (vale so o /uiconfig).
local THEME_KVP = 'mri_ui_theme'

local function allowThemeChoice()
    return GetConvar('mri_ui_allow_theme_choice', 'true') ~= 'false'
end

---@return 'dark' | 'glass' | nil
local function getThemeChoice()
    if not allowThemeChoice() then return end
    local theme = GetResourceKvpString(THEME_KVP)
    if theme == 'dark' or theme == 'glass' then return theme end
end

-- A NUI pede no mount (nao depende de timing de push no boot).
RegisterNUICallback('mri:getThemeChoice', function(_, cb)
    cb({ theme = getThemeChoice() })
end)

---@class MriSettingOption
---@field enabled? fun(): boolean
---@field input fun(): table campo do lib.inputDialog
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
                label = 'Tema da interface',
                options = {
                    { label = 'Padrão do servidor', value = 'server' },
                    { label = 'Dark Premium', value = 'dark' },
                    { label = 'Glassmorph', value = 'glass' },
                },
                default = getThemeChoice() or 'server',
                required = true,
                icon = 'palette',
            }
        end,
        apply = function(value)
            if value == 'dark' or value == 'glass' then
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
