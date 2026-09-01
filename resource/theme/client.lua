-- mri_ui_theme/client.lua

-- Escolha PESSOAL de tema do jogador. Persiste no KVP e vira override na NUI
-- (persist = true). O tema server-wide e o do /uiconfig (mri/); a escolha
-- pessoal tem precedencia sobre ele (resolvido em web/src/lib/theme.ts).
local function SetUiTheme(theme)
    local allowChoice = GetConvar("mri_ui_allow_theme_choice", "true") == "true"

    if not allowChoice then
        -- Escolha desabilitada: limpa qualquer override pessoal e deixa o
        -- tema do /uiconfig valer.
        DeleteResourceKvp("mri_ui_theme")
        SendNUIMessage({ action = "setTheme", data = { clear = true } })
        return
    end

    if theme ~= "dark" and theme ~= "glass" then
        theme = GetConvar("mri_ui_default_theme", "dark")
    end

    SetResourceKvp("mri_ui_theme", theme)
    SendNUIMessage({
        action = "setTheme",
        data = { theme = theme, persist = true }
    })

    -- Se for chamado pelo menu, dar a notificação
    if GetInvokingResource() == nil or GetInvokingResource() == GetCurrentResourceName() then
        lib.notify({
            title = "Interface UI",
            description = "Tema alterado com sucesso para: " .. theme,
            type = "success"
        })
    end
end

-- Export para outros scripts usarem se quiserem
exports('SetUiTheme', SetUiTheme)

-- Boot: re-hidrata a escolha pessoal na NUI, SO se o jogador realmente
-- escolheu (KVP setado). Sem escolha, nao empurra nada — o tema server-wide
-- do /uiconfig (aplicado via applyUiConfig) e quem manda.
CreateThread(function()
    Wait(1500)

    local allowChoice = GetConvar("mri_ui_allow_theme_choice", "true") == "true"

    if not allowChoice then
        SendNUIMessage({ action = "setTheme", data = { clear = true } })
        return
    end

    local savedTheme = GetResourceKvpString("mri_ui_theme")
    if savedTheme == "dark" or savedTheme == "glass" then
        SendNUIMessage({
            action = "setTheme",
            data = { theme = savedTheme, persist = true }
        })
    end
end)

-- Comando para abrir o menu de troca
RegisterCommand("uitheme", function()
    local allowChoice = GetConvar("mri_ui_allow_theme_choice", "true") == "true"
    
    if not allowChoice then
        lib.notify({
            title = "Aviso",
            description = "A escolha de temas está desabilitada no servidor.",
            type = "error"
        })
        return
    end

    lib.registerContext({
        id = "mri_ui_theme_menu",
        title = "Escolha o Tema da Interface",
        options = {
            {
                title = "Dark Premium",
                description = "Tema escuro, sólido e limpo",
                icon = "moon",
                event = "mri_ui_theme:setTheme",
                args = "dark"
            },
            {
                title = "Glassmorph",
                description = "Tema translúcido",
                icon = "gem",
                event = "mri_ui_theme:setTheme",
                args = "glass"
            }
        }
    })

    lib.showContext("mri_ui_theme_menu")
end)

RegisterCommand("temaui", function()
    ExecuteCommand("uitheme")
end)

AddEventHandler("mri_ui_theme:setTheme", function(theme)
    SetUiTheme(theme)
end)
