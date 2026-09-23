<div align="center">

# ox_lib MRI Qbox

Versão do [ox_lib](https://github.com/overextended/ox_lib) usada pela MRI Qbox Brasil, com interface redesenhada, painel de design para o admin e configurações por jogador.

[![](https://img.shields.io/github/v/release/mri-Qbox-Brasil/mri_lib?style=for-the-badge&logo=github)](https://github.com/mri-Qbox-Brasil/mri_lib/releases/latest)
[![](https://img.shields.io/github/downloads/mri-Qbox-Brasil/mri_lib/total?style=for-the-badge&logo=github)](https://github.com/mri-Qbox-Brasil/mri_lib/releases/latest/download/ox_lib.zip)

</div>

## 💾 Download

https://github.com/mri-Qbox-Brasil/mri_lib/releases/latest/download/ox_lib.zip

O resource continua se chamando `ox_lib`: é só substituir a pasta e manter o `ensure ox_lib` no `server.cfg`. A API é a mesma do upstream, então qualquer script feito para o ox_lib funciona.

## ✨ O que a versão MRI adiciona

### Interface redesenhada
Menus, notificações, barras de progresso, diálogos, radial e skillcheck com o visual da MRI, em dois temas: **Dark Premium** e **Glassmorph** (sem blur, para não pesar no FPS).

### `/uiconfig`: painel de design do admin
Painel para configurar a interface ingame, para todos os jogadores e sem restart: tema, cor de destaque, cor de fundo, cantos arredondados, opacidade do glass, fonte, cores de status, posição e duração das notificações, estilo e tamanho das barras de progresso e largura dos menus.

- Permissão: ACE `command.uiconfig`.
- Salva temas completos como **presets** para reaplicar depois.
- Tem modo **ao vivo**, que mostra notificações e barras reais na tela enquanto você edita.
- Com o mri_Qadmin rodando, o painel também aparece como plugin dentro dele.

### `/ox_lib`: configurações do jogador
Cada jogador escolhe, só para ele:

- **Som das notificações**
- **Idioma**: salvo no KVP `mri_locale`. O `ox_lib` original usa o KVP `locale`, que é o mesmo em todo servidor com ox_lib; por isso um jogador que escolheu English em outro servidor entrava em inglês. A versão MRI ignora essa chave: sem escolha própria, vale o `ox:locale` do servidor.
- **Tema da interface**: Padrão do servidor, Dark Premium ou Glassmorph. Pode ser desligado com `mri_ui_allow_theme_choice`.

A posição das notificações não aparece aqui porque vem do `/uiconfig`.

### Menu radial
Abre com **F1** segurando e fecha ao soltar (no ox_lib original é Z, clicando). O jogador pode trocar a tecla nas configurações de atalhos do FiveM.

### Context menu com descrição e fundo
`lib.registerContext` aceita três campos a mais:

```lua
lib.registerContext({
    id = 'exemplo',
    title = 'Título do menu',
    description = 'Descrição abaixo do título', -- novo
    background = true,                          -- novo: fundo neste menu
    backgroundColor = '#1f2937',                -- novo: cor do fundo
    options = {
        { title = 'Opção 1' },
    },
})
```

Para ligar o fundo em todos os context menus: `setr ox:menuBackground 1`.

### Cores da suite MRI
A cor de destaque e a cor de fundo são compartilhadas com os outros scripts da MRI (mri_Qmultichar, mri_Qspawn, mri_Qadmin, mri_Qloadscreen, mri_Qchat) e podem ser trocadas com o servidor ligado, via convar ou pelo mri_Qadmin.

### Logs no mri_Qadmin
Com `setr ox:logger "mri_Qadmin"`, os logs de `lib.logger` de todos os scripts vão para o painel de logs do mri_Qadmin.

## ⚙️ Convars

| Convar | Padrão | O que faz |
|---|---|---|
| `setr mri:color "#00E699"` | `#00E699` | Cor de destaque da suite MRI (muda ao vivo) |
| `setr mri:backgroundColor ""` | vazio | Cor de fundo da suite. Vazio = cor do tema |
| `setr mri_ui_allow_theme_choice "true"` | `true` | `false` tira a escolha de tema do `/ox_lib`; vale só o tema do `/uiconfig` |
| `setr ox:menuBackground 1` | `0` | Liga o fundo em todos os context menus |
| `setr ox:logger "mri_Qadmin"` | `datadog` | Envia os logs de `lib.logger` para o mri_Qadmin |
| `setr ox:locale "pt-br"` | `en` | Idioma padrão do servidor (do ox_lib original) |
| `setr ox:userLocales 1` | `1` | `0` impede o jogador de escolher o idioma (do ox_lib original) |

## 🧩 Modificações em relação ao ox_lib

As modificações da MRI ficam na pasta [`mri/`](./mri/README.md), que explica cada arquivo. Fora dela, só mudam:

- `fxmanifest.lua`: carrega a pasta `mri/` e usa a versão do sistema de releases da MRI;
- `imports/logger/server.lua`: provider de log do mri_Qadmin;
- `web/`: a interface redesenhada.

Todo o resto é idêntico ao [overextended/ox_lib](https://github.com/overextended/ox_lib), que é sincronizado periodicamente.

## ⚖️ Licença e créditos

O ox_lib é desenvolvido pela [Overextended](https://github.com/overextended) e licenciado sob a LGPL-3.0; as modificações da MRI seguem a mesma licença. Veja [LICENSE](./LICENSE) e [NOTICE.md](./NOTICE.md).

Para contribuir com o ox_lib original, veja o [CONTRIBUTING.md](./CONTRIBUTING.md).

## 📚 Documentação do ox_lib

https://overextended.dev/ox_lib

## 📦 Pacote npm

https://www.npmjs.com/package/@overextended/ox_lib

## 🖥️ Lua Language Server

- Instale o [Lua Language Server](https://luals.github.io/#install) para ter anotações, checagem de tipos e diagnósticos.
- Baixe o [fivem-lls-addon](https://github.com/overextended/fivem-lls-addon) para ter as declarações de natives e do runtime do FiveM.
