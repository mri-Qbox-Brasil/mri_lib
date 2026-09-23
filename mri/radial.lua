--[[
    Carregado ANTES de resource/** (ver fxmanifest): o radial do ox_lib registra
    o keybind no load do arquivo, entao interceptamos o lib.addKeybind pra trocar
    so o do radial. Qualquer outro keybind passa direto.

    MRI: tecla F1, segurar pra abrir e soltar pra fechar. O nome muda pra que o
    bind antigo do jogador (Z) nao seja reaproveitado.
]]

local addKeybind = lib.addKeybind

rawset(lib, 'addKeybind', function(data)
    if data.name == 'ox_lib-radial' then
        data.name = 'mri_ox_lib-radial'
        data.defaultKey = 'F1'
        data.onReleased = function() lib.hideRadial() end
    end

    return addKeybind(data)
end)
