--[[
    Modificação MRI Qbox sobre o ox_lib (LGPL-3.0).

    Lado client do painel de design da UI. Hidrata o config no boot e manda
    pra NUI aplicar; expõe o comando /uiconfig (gateado por ACE) pra abrir o
    painel standalone; trata os callbacks NUI do painel admin; e reaplica
    quando o server faz broadcast de mudança.
]]

local uiConfig = nil

-- Cache lazy do config (vem do server, que le mri/data/config.json).
local function getConfig()
    if uiConfig then return uiConfig end
    uiConfig = lib.callback.await('ox_lib:getUiConfig', false) or {}
    return uiConfig
end

-- Flag de leitura pro painel: com o mri_Qadmin presente, ele e o dono das cores
-- da suite (banco + convar), entao os campos de cor do painel editam o GLOBAL
-- (write-through) em vez de override local. Ver saveUiConfig no server.
--
-- Calculada aqui e nao mandada junto do config de proposito: o broadcast de
-- `ox_lib:uiConfigChanged` sobrescreve o cache com o config cru, e uma flag
-- carregada dentro dele se perderia no primeiro save.
local function withMeta(cfg)
    local out = {}
    for k, v in pairs(cfg) do out[k] = v end
    out.suiteColorsManaged = GetResourceState('mri_Qadmin') == 'started'
    return out
end

-- Manda o config atual pra NUI aplicar (CSS vars + data-theme). O hook
-- useNuiEvent desestrutura event.data.data — payload aninhado em `data`.
local function pushConfigToNui()
    SendNUIMessage({ action = 'applyUiConfig', data = getConfig() })
end

-- Aplica no boot, depois que a NUI montou.
CreateThread(function()
    Wait(1500)
    pushConfigToNui()
end)

-- Runtime: server broadcasta quando admin salva. Atualiza cache + reaplica.
RegisterNetEvent('ox_lib:uiConfigChanged', function(newConfig)
    if type(newConfig) ~= 'table' then return end
    uiConfig = newConfig
    SendNUIMessage({ action = 'applyUiConfig', data = newConfig })
end)

-- Comando standalone pra abrir o painel. Restrito por ACE: RegisterCommand
-- nativo com restricted = true exige o ace command.uiconfig no jogador. De
-- toda forma o save e gateado de novo no server (saveUiConfig).
RegisterCommand('uiconfig', function()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openUiConfig', data = withMeta(getConfig()) })
end, true)

-- Painel pede o config (boot do painel, standalone ou embedded no Qadmin).
RegisterNUICallback('adminGetUiConfig', function(_, cb)
    cb(withMeta(getConfig()))
end)

-- Painel salva. Repassa pro server (que gateia ACE + persiste + broadcasta).
RegisterNUICallback('adminSaveUiConfig', function(payload, cb)
    local ok, result = lib.callback.await('ox_lib:saveUiConfig', false, payload)
    if ok and result then uiConfig = result end
    cb({ success = ok == true, config = ok and result or nil })
end)

-- Painel standalone pediu pra fechar (libera foco).
RegisterNUICallback('closeUiConfig', function(_, cb)
    SetNuiFocus(false, false)
    cb({ ok = true })
end)

-- ============================================================================
-- Presets (temas nomeados). Repassam pro server, que gateia ACE + persiste.
-- ============================================================================

RegisterNUICallback('adminListPresets', function(_, cb)
    cb(lib.callback.await('ox_lib:listPresets', false) or {})
end)

RegisterNUICallback('adminSavePreset', function(data, cb)
    local ok = lib.callback.await('ox_lib:savePreset', false, data)
    cb({ success = ok == true })
end)

RegisterNUICallback('adminApplyPreset', function(data, cb)
    local ok, result = lib.callback.await('ox_lib:applyPreset', false, data and data.name)
    if ok and result then uiConfig = result end
    cb({ success = ok == true, config = ok and result or nil })
end)

RegisterNUICallback('adminDeletePreset', function(data, cb)
    local ok = lib.callback.await('ox_lib:deletePreset', false, data and data.name)
    cb({ success = ok == true })
end)

-- ============================================================================
-- Modo ao vivo (editor ingame): dispara os componentes REAIS do ox_lib na
-- tela pro admin ver com o tema aplicado. SendNUIMessage direto (sem lib.*),
-- pra nao bloquear a thread nem travar os controles do player. So componentes
-- que NAO capturam foco/input (notify/progress/textui) — menus ficam no
-- preview de amostra do painel pra nao roubar o foco dos inputs.
-- ============================================================================

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
        -- preview=true: bypassa o roteamento por progressStyle, pra o editor
        -- sempre mostrar a BARRA (mesmo com estilo forçado pra círculo).
        SendNUIMessage({ action = 'progress', data = { label = 'Progresso de teste', duration = data.duration or 4000, preview = true } })
    elseif kind == 'progressCircle' then
        SendNUIMessage({ action = 'circleProgress', data = { label = 'Progresso', duration = data.duration or 4000, preview = true } })
    elseif kind == 'textui' then
        SendNUIMessage({ action = 'textUi', data = { text = '[E]  Prévia do TextUI', position = 'right-center' } })
        SetTimeout(3500, function() SendNUIMessage({ action = 'textUiHide' }) end)
    end
    cb({ ok = true })
end)
