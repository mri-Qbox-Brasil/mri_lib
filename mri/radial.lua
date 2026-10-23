-- MRI: loads before resource/** to swap the radial keybind (F1, new name so the old Z bind is not reused).

local addKeybind = lib.addKeybind

-- 'hold' closes on release; 'toggle' (default) keeps the upstream press to open and close.
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

-- ESC acts on key release; block the pause menu until that frame passes or GTA opens it on the same press.
RegisterNUICallback('mriRadialEscape', function(_, cb)
    cb(1)

    repeat
        DisableControlAction(0, 199, true)
        DisableControlAction(0, 200, true)
        Wait(0)
    until not IsDisabledControlPressed(0, 200) and not IsDisabledControlJustReleased(0, 200)
end)
