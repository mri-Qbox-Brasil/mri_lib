--[[
    Carregado ANTES de resource/** (ver fxmanifest): o radial do ox_lib registra
    o keybind no load do arquivo, entao interceptamos o lib.addKeybind pra trocar
    so o do radial. Qualquer outro keybind passa direto.

    MRI: tecla F1. O modo vem do /adminui (radialMode): 'toggle' (padrao) aperta pra abrir
    e de novo pra fechar, como o ox_lib original; 'hold' segura pra abrir e
    solta pra fechar. O nome muda pra que o bind antigo do jogador (Z) nao seja
    reaproveitado.
]]

local addKeybind = lib.addKeybind

local function holdToOpen()
    local ok, cfg = pcall(function() return exports[GetCurrentResourceName()]:getUiConfig() end)
    return ok and type(cfg) == 'table' and cfg.radialMode == 'hold'
end

rawset(lib, 'addKeybind', function(data)
    if data.name == 'ox_lib-radial' then
        data.name = 'mri_ox_lib-radial'
        data.defaultKey = 'F1'
        data.onReleased = function()
            if holdToOpen() then lib.hideRadial() end
        end
    end

    return addKeybind(data)
end)

RegisterNUICallback('mriRadialEscape', function(_, cb)
    cb(1)

    repeat
        DisableControlAction(0, 199, true)
        DisableControlAction(0, 200, true)
        Wait(0)
    until not IsDisabledControlPressed(0, 200) and not IsDisabledControlJustReleased(0, 200)
end)
