--[[
    ██╗     ██╗  ██╗██████╗        ██╗  ██╗██╗   ██╗██████╗
    ██║     ╚██╗██╔╝██╔══██╗       ██║  ██║██║   ██║██╔══██╗
    ██║      ╚███╔╝ ██████╔╝█████╗ ███████║██║   ██║██║  ██║
    ██║      ██╔██╗ ██╔══██╗╚════╝ ██╔══██║██║   ██║██║  ██║
    ███████╗██╔╝ ██╗██║  ██║       ██║  ██║╚██████╔╝██████╔╝
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚═╝  ╚═╝ ╚═════╝ ╚═════╝

    🐺 LXR HUD System - FiveM Resource Manifest

    ═══════════════════════════════════════════════════════════════════════════════
    RESOURCE INFORMATION
    ═══════════════════════════════════════════════════════════════════════════════

    Resource Name:  lxr-hud
    Version:        2.0.1
    Author:         iBoss21 / The Lux Empire
    Description:    Multi-framework player HUD system for RedM displaying health,
                    hunger, thirst, stamina, stress, temperature, and voice.

    Server:         The Land of Wolves 🐺
    Website:        https://www.wolves.land
    Discord:        https://discord.gg/CrKcWdfd3A
    Store:          https://theluxempire.tebex.io

    ═══════════════════════════════════════════════════════════════════════════════
    FRAMEWORK SUPPORT
    ═══════════════════════════════════════════════════════════════════════════════

    Primary:
    - LXR Core (lxr-core)
    - RSG Core (rsg-core)

    Supported:
    - VORP Core (vorp_core)

    Optional (if detected):
    - RedEM:RP (redem_roleplay)
    - QBR Core (qbr-core)
    - QR Core (qr-core)
    - Standalone (no framework)

    ═══════════════════════════════════════════════════════════════════════════════

    © 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved
]]

fx_version 'cerulean'
game 'rdr3'

rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

-- Resource Metadata
name        'LXR HUD System'
author      'iBoss21 / The Lux Empire'
description 'Multi-framework player HUD system for RedM'
version     '2.0.1'

-- Lua 5.4
lua54 'yes'

-- Shared Scripts (loaded on both client and server)
shared_scripts {
    '@lxr-core/shared/locale.lua',
    'locales/en.lua',
    'config.lua'
}

-- Client Scripts
client_script 'client/main.lua'

-- Server Scripts
server_script 'server/main.lua'

-- NUI / UI Page
ui_page 'html/index.html'

files {
    'html/index.html',
    'html/styles.css',
    'html/app.js'
}