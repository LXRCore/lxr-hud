--[[
    ██╗     ██╗  ██╗██████╗        ██╗  ██╗██╗   ██╗██████╗
    ██║     ╚██╗██╔╝██╔══██╗       ██║  ██║██║   ██║██╔══██╗
    ██║      ╚███╔╝ ██████╔╝█████╗ ███████║██║   ██║██║  ██║
    ██║      ██╔██╗ ██╔══██╗╚════╝ ██╔══██║██║   ██║██║  ██║
    ███████╗██╔╝ ██╗██║  ██║       ██║  ██║╚██████╔╝██████╔╝
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚═╝  ╚═╝ ╚═════╝ ╚═════╝

    🐺 LXR HUD System - German Locale (Deutsch)

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
        getstress     = "Du wirkst gestresst",
        thirsty       = "Du wirkst ein wenig durstig",
        relaxing      = "Du beruhigst dich",
        cash_balance  = "Barguthaben: %{amount}",
        bank_balance  = "Bankguthaben: %{amount}",
    }
}

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
