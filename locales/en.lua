--[[
    ██╗     ██╗  ██╗██████╗        ██╗  ██╗██╗   ██╗██████╗
    ██║     ╚██╗██╔╝██╔══██╗       ██║  ██║██║   ██║██╔══██╗
    ██║      ╚███╔╝ ██████╔╝█████╗ ███████║██║   ██║██║  ██║
    ██║      ██╔██╗ ██╔══██╗╚════╝ ██╔══██║██║   ██║██║  ██║
    ███████╗██╔╝ ██╗██║  ██║       ██║  ██║╚██████╔╝██████╔╝
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚═╝  ╚═╝ ╚═════╝ ╚═════╝

    🐺 LXR HUD System - English Locale

    ═══════════════════════════════════════════════════════════════════════════════
    Server:      The Land of Wolves 🐺
    Developer:   iBoss21 / The Lux Empire
    Website:     https://www.wolves.land
    Discord:     https://discord.gg/CrKcWdfd3A
    ═══════════════════════════════════════════════════════════════════════════════

    © 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved
]]

local Translations = {
    error = {

    },
    success = {

    },
    info = {
        getstress     = "You are getting stressed",
        thirsty       = "You are a bit thirsty",
        relaxing      = "You Are Relaxing",
        cash_balance  = "Cash Balance: %{amount}",
        bank_balance  = "Bank Balance: %{amount}",
    }
}

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
