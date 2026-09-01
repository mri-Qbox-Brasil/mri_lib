--[[
    Modificação MRI Qbox sobre o ox_lib (LGPL-3.0).

    Gerencia os settings de DESIGN da UI (tema, accent, radius, etc) editáveis
    ingame pelo painel admin. data/config.json e a fonte de verdade; este
    script le/escreve + faz broadcast pra todos os clients reaplicarem sem
    restart, e registra o painel como plugin do mri_Qadmin.
]]

local CONFIG_FILE = 'mri/data/config.json'
local PRESETS_FILE = 'mri/data/presets.json'

-- Defaults: fallback se o JSON sumir/corromper OU se faltar chave (forward
-- compat). Devem bater com mri/data/config.json.
local DEFAULTS = {
    theme = 'dark',
    accentColor = '',
    backgroundColor = '',
    radius = 8,
    glassOpacity = 0.65,
    notifyPosition = 'top-right',
    notifyDuration = 5000,
    fontFamily = 'Inter',
    successColor = '#10b981',
    warningColor = '#eab308',
    errorColor = '#ef4444',
    progressStyle = 'default',
    switchStyle = 'follow',
    notifyWidth = 320,
    progressBarWidth = 380,
    progressBarHeight = 18,
    progressCircleSize = 110,
    menuWidth = 400,
    contextWidth = 360,
}

local config = {}

local NOTIFY_POSITIONS = {
    ['top-left'] = true, ['top-center'] = true, ['top-right'] = true,
    ['center-left'] = true, ['center-right'] = true,
    ['bottom-left'] = true, ['bottom-center'] = true, ['bottom-right'] = true,
}

-- Valor invalido (tipo errado, fora do range, fora da whitelist) cai no
-- default — o JSON persistido e o broadcast nunca carregam lixo, mesmo que
-- o payload venha adulterado (fontFamily entra em CSS var na NUI).
local VALIDATORS = {
    theme = function(v) return v == 'dark' or v == 'glass' end,
    accentColor = function(v)
        return type(v) == 'string' and (v == '' or v:match('^#%x%x%x%x%x%x$') ~= nil)
    end,
    -- Mesma regra do accent: '' e valido e significa "seguir a convar global"
    -- (aqui, mri:backgroundColor).
    backgroundColor = function(v)
        return type(v) == 'string' and (v == '' or v:match('^#%x%x%x%x%x%x$') ~= nil)
    end,
    radius = function(v) return type(v) == 'number' and v >= 0 and v <= 32 end,
    glassOpacity = function(v) return type(v) == 'number' and v >= 0 and v <= 1 end,
    notifyPosition = function(v) return NOTIFY_POSITIONS[v] == true end,
    notifyDuration = function(v) return type(v) == 'number' and v >= 500 and v <= 30000 end,
    fontFamily = function(v)
        return type(v) == 'string' and #v <= 64 and v:match('^[%w][%w%s%-]*$') ~= nil
    end,
    successColor = function(v) return type(v) == 'string' and v:match('^#%x%x%x%x%x%x$') ~= nil end,
    warningColor = function(v) return type(v) == 'string' and v:match('^#%x%x%x%x%x%x$') ~= nil end,
    errorColor = function(v) return type(v) == 'string' and v:match('^#%x%x%x%x%x%x$') ~= nil end,
    -- Shape dos toggles on/off; 'follow' deriva do radius (default).
    switchStyle = function(v) return v == 'square' or v == 'round' or v == 'follow' end,
    progressStyle = function(v) return v == 'default' or v == 'bar' or v == 'circle' end,
    notifyWidth = function(v) return type(v) == 'number' and v >= 240 and v <= 480 end,
    progressBarWidth = function(v) return type(v) == 'number' and v >= 240 and v <= 600 end,
    progressBarHeight = function(v) return type(v) == 'number' and v >= 10 and v <= 32 end,
    progressCircleSize = function(v) return type(v) == 'number' and v >= 80 and v <= 160 end,
    menuWidth = function(v) return type(v) == 'number' and v >= 300 and v <= 560 end,
    contextWidth = function(v) return type(v) == 'number' and v >= 280 and v <= 520 end,
}

local function applyDefaults(input)
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

-- Gate de admin: usa o sistema de ACE do proprio ox_lib. `command.uiconfig`
-- ou `command` (god/console) liberam. Mesma semantica OR da suite.
local function isAdmin(source)
    return IsPlayerAceAllowed(source, 'command.uiconfig')
        or IsPlayerAceAllowed(source, 'command')
end

loadFromDisk()

-- Getter Lua pra outros scripts/comandos (broadcast usa pra mandar a versao
-- corrente sem reler do disco).
function GetUiConfig()
    return config
end

-- Com o mri_Qadmin presente ele e o dono das cores da suite: guarda no banco e
-- replica via convar (`mri:color` / `mri:backgroundColor`), que e o que os
-- outros resources leem. Nesse modo os campos de cor DESTE painel deixam de ser
-- override e viram edicao do global — write-through pro Qadmin, e o config.json
-- fica com '' porque o valor nao mora aqui.
--
-- Sem o Qadmin nao ha onde persistir a convar, entao os campos voltam a ser
-- override local (comportamento antigo, valendo so pra UI do ox_lib).
local function suiteColorsManaged()
    return GetResourceState('mri_Qadmin') == 'started'
end

lib.callback.register('ox_lib:getUiConfig', function()
    return config
end)

-- Caminho unico de commit: write-through das cores (se managed), grava e
-- broadcasta. Usado pelo save do painel E pelo applyPreset — um preset carrega
-- cores tambem, e sem passar por aqui ele reintroduziria override pelas costas.
local function commitConfig(incoming)
    if suiteColorsManaged() then
        -- Repassa pro Qadmin e zera local. O `pcall` cobre versao do Qadmin sem
        -- os exports; se falhar, o campo fica '' e a convar manda — degradado,
        -- mas nunca com duas cores concorrentes.
        local ok = pcall(function()
            if incoming.accentColor ~= '' then
                exports['mri_Qadmin']:SetSuiteAccent(incoming.accentColor)
            end
            if incoming.backgroundColor ~= '' then
                exports['mri_Qadmin']:SetSuiteBackground(incoming.backgroundColor)
            end
        end)
        if not ok then
            print('[ox_lib/mri] AVISO: mri_Qadmin sem SetSuiteAccent/SetSuiteBackground; cores nao persistidas')
        end
        incoming.accentColor = ''
        incoming.backgroundColor = ''
    end

    config = incoming
    if not saveToDisk() then return false end

    -- Broadcast pra todos reaplicarem sem restart. As cores nao vem por aqui no
    -- modo managed — chegam pelo broadcast da convar, disparado pelo Qadmin.
    TriggerClientEvent('ox_lib:uiConfigChanged', -1, config)
    return true
end

lib.callback.register('ox_lib:saveUiConfig', function(source, payload)
    if not isAdmin(source) then return false, 'sem permissão' end
    if type(payload) ~= 'table' then return false, 'payload inválido' end

    if not commitConfig(applyDefaults(payload)) then return false, 'falha ao salvar' end
    return true, config
end)

-- Limpa um override de cor, voltando pra convar global da suite (`mri:color`
-- ou `mri:backgroundColor`).
--
-- Export (nao RegisterNetEvent) de proposito: e uma chamada server->server, sem
-- source de player, entao nao passa pelo gate de ACE. Quem chama e o
-- mri_Qadmin quando o admin aplica uma cor global pelo painel de Settings dele
-- — ali o gate ja rodou (`qadmin.page.settings`), que e outra perm, e exigir
-- `command.uiconfig` por cima faria o picker do Qadmin falhar em silencio.
--
-- Idempotente: se ja esta vazio nao reescreve o disco nem broadcasta. Isso e o
-- que impede disparo circular — o broadcast so sai quando algo mudou de fato.
local function clearColorOverride(key)
    if config[key] == '' then return true end
    config[key] = ''
    if not saveToDisk() then return false end
    TriggerClientEvent('ox_lib:uiConfigChanged', -1, config)
    return true
end

exports('ClearAccentOverride', function() return clearColorOverride('accentColor') end)
exports('ClearBackgroundOverride', function() return clearColorOverride('backgroundColor') end)

-- ============================================================================
-- Presets: temas nomeados salvos em mri/data/presets.json. O config.json
-- continua sendo o ativo/aplicado; aplicar um preset copia ele pro ativo e
-- broadcasta. Cada preset guarda um config completo (passa por applyDefaults
-- na leitura/escrita, entao nunca carrega chave invalida ou faltante).
-- ============================================================================

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

-- Lista os nomes dos presets (pro dropdown do painel).
lib.callback.register('ox_lib:listPresets', function(source)
    if not isAdmin(source) then return {} end
    local names = {}
    for _, p in ipairs(loadPresets()) do
        if type(p.name) == 'string' then names[#names + 1] = p.name end
    end
    return names
end)

-- Salva/atualiza (upsert) um preset com o config recebido (o draft do painel).
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

-- Aplica um preset: vira o config ativo, persiste e broadcasta pra todos.
lib.callback.register('ox_lib:applyPreset', function(source, name)
    if not isAdmin(source) then return false, 'sem permissão' end
    for _, p in ipairs(loadPresets()) do
        if p.name == name then
            -- Via commitConfig: um preset carrega cores, e no modo managed elas
            -- precisam ir pro banco do Qadmin em vez de virar override local.
            if not commitConfig(applyDefaults(type(p.config) == 'table' and p.config or {})) then
                return false, 'falha ao salvar'
            end
            return true, config
        end
    end
    return false, 'preset não encontrado'
end)

lib.callback.register('ox_lib:deletePreset', function(source, name)
    if not isAdmin(source) then return false, 'sem permissão' end
    local presets = loadPresets()
    for i, p in ipairs(presets) do
        if p.name == name then table.remove(presets, i); break end
    end
    if not savePresets(presets) then return false, 'falha ao salvar' end
    return true
end)

-- Registra o painel como plugin do mri_Qadmin (se presente). Fail-silent —
-- ox_lib funciona normalmente sem o Qadmin; o /uiconfig standalone cobre.
-- Manifest shape espelha web/src/plugin/types.ts (drift control manual).
local function doRegister()
    if GetResourceState('mri_Qadmin') ~= 'started' then return end
    exports['mri_Qadmin']:RegisterPlugin({
        id = 'uiconfig',
        label = 'Interface (UI)',
        icon = 'palette',
        resource = GetCurrentResourceName(),
        htmlPath = 'web/build/index.html',
        requiredPerms = { 'command.uiconfig', 'command' },
        description = 'Editar estilos de design do ox_lib (tema, cores, etc)',
    })
end

-- Qadmin inicia/reinicia → re-registra automaticamente
AddEventHandler('onServerResourceStart', function(resourceName)
    if resourceName == 'mri_Qadmin' then doRegister() end
end)

-- Plugin inicia com Qadmin já rodando → registra imediatamente
CreateThread(function()
    Wait(0)
    doRegister()
end)
