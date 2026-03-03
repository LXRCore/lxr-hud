--[[
    ██╗     ██╗  ██╗██████╗        ██╗  ██╗██╗   ██╗██████╗
    ██║     ╚██╗██╔╝██╔══██╗       ██║  ██║██║   ██║██╔══██╗
    ██║      ╚███╔╝ ██████╔╝█████╗ ███████║██║   ██║██║  ██║
    ██║      ██╔██╗ ██╔══██╗╚════╝ ██╔══██║██║   ██║██║  ██║
    ███████╗██╔╝ ██╗██║  ██║       ██║  ██║╚██████╔╝██████╔╝
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚═╝  ╚═╝ ╚═════╝ ╚═════╝

    🐺 LXR HUD System - Configuration

    Controls all aspects of the player HUD: health, hunger, thirst, stamina,
    stress, temperature display, voice indicator, and alert thresholds.

    ═══════════════════════════════════════════════════════════════════════════════
    SERVER INFORMATION
    ═══════════════════════════════════════════════════════════════════════════════

    Server:      The Land of Wolves 🐺
    Developer:   iBoss21 / The Lux Empire
    Website:     https://www.wolves.land
    Discord:     https://discord.gg/CrKcWdfd3A
    Store:       https://theluxempire.tebex.io

    ═══════════════════════════════════════════════════════════════════════════════

    Version: 2.0.1
    Performance Target: Optimized for minimal server overhead and client FPS impact

    Framework Support:
    - LXR Core (Primary)
    - RSG Core (Compatible)
    - VORP Core (Compatible)
    - RedEM:RP (Compatible)
    - QBR Core (Compatible)
    - QR Core (Compatible)
    - Standalone (Compatible)

    ═══════════════════════════════════════════════════════════════════════════════

    © 2026 iBoss21 / The Lux Empire | wolves.land | All Rights Reserved
]]

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🐺 RESOURCE NAME PROTECTION - RUNTIME CHECK
-- ═══════════════════════════════════════════════════════════════════════════════

local REQUIRED_RESOURCE_NAME = "lxr-hud"
local currentResourceName = GetCurrentResourceName()

if currentResourceName ~= REQUIRED_RESOURCE_NAME then
    error(string.format([[

        ═══════════════════════════════════════════════════════════════════════════════
        ❌ CRITICAL ERROR: RESOURCE NAME MISMATCH ❌
        ═══════════════════════════════════════════════════════════════════════════════

        Expected: %s
        Got: %s

        This resource is branded and must maintain the correct name.
        Rename the folder to "%s" to continue.

        🐺 wolves.land - The Land of Wolves

        ═══════════════════════════════════════════════════════════════════════════════

    ]], REQUIRED_RESOURCE_NAME, currentResourceName, REQUIRED_RESOURCE_NAME))
end

Config = {}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ SERVER BRANDING & INFO ████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.ServerInfo = {
    name      = 'The Land of Wolves 🐺',
    developer = 'iBoss21 / The Lux Empire',
    website   = 'https://www.wolves.land',
    discord   = 'https://discord.gg/CrKcWdfd3A',
    store     = 'https://theluxempire.tebex.io',
    github    = 'https://github.com/iBoss21',
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ FRAMEWORK CONFIGURATION ███████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

--[[
    Framework Priority (in order):
    1. LXR-Core  (Primary)
    2. RSG-Core  (Primary)
    3. VORP Core (Supported)
    4. RedEM:RP  (Optional - if detected)
    5. QBR-Core  (Optional - if detected)
    6. QR-Core   (Optional - if detected)
    7. Standalone (Fallback)
]]

Config.Framework = 'auto' -- 'auto' | 'lxr-core' | 'rsg-core' | 'vorp_core' | 'redem_roleplay' | 'qbr-core' | 'qr-core' | 'standalone'

Config.FrameworkSettings = {
    ['lxr-core'] = {
        resource = 'lxr-core',
        notifications = 'ox_lib',
        inventory = 'lxr-inventory',
        events = {
            server = 'lxr-core:server:%s',
            client = 'lxr-core:client:%s',
            callback = 'lxr-core:callback:%s',
        }
    },
    ['rsg-core'] = {
        resource = 'rsg-core',
        notifications = 'ox_lib',
        inventory = 'rsg-inventory',
        events = {
            server = 'RSGCore:Server:%s',
            client = 'RSGCore:Client:%s',
            callback = 'RSGCore:Callback:%s',
        }
    },
    ['vorp_core'] = {
        resource = 'vorp_core',
        notifications = 'vorp',
        inventory = 'vorp_inventory',
        events = {
            server = 'vorp:server:%s',
            client = 'vorp:client:%s',
        }
    },
    ['redem_roleplay'] = {
        resource = 'redem_roleplay',
        notifications = 'redem',
        inventory = 'redem_inventory',
        events = {
            server = 'redem:%s:server',
            client = 'redem:%s:client',
        }
    },
    ['qbr-core'] = {
        resource = 'qbr-core',
        notifications = 'ox_lib',
        inventory = 'qbr-inventory',
        events = {
            server = 'QBR:Server:%s',
            client = 'QBR:Client:%s',
        }
    },
    ['qr-core'] = {
        resource = 'qr-core',
        notifications = 'ox_lib',
        inventory = 'qr-inventory',
        events = {
            server = 'QR:Server:%s',
            client = 'QR:Client:%s',
        }
    },
    ['standalone'] = {
        notifications = 'print',
        inventory = 'none',
    }
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ GENERAL SETTINGS ██████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.MinimumStress  = 50   -- Minimum stress level before screen-shake triggers
Config.UpdateInterval = 10   -- Food/water decay interval in minutes

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ STRESS CONFIGURATION ██████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.Stress = {
    -- Camera shake intensity per stress bracket
    intensityLevels = {
        [1] = {min = 50,  max = 60,  intensity = 0.12},
        [2] = {min = 60,  max = 70,  intensity = 0.17},
        [3] = {min = 70,  max = 80,  intensity = 0.22},
        [4] = {min = 80,  max = 90,  intensity = 0.28},
        [5] = {min = 90,  max = 100, intensity = 0.32},
    },
    -- Milliseconds between stress effects per bracket
    effectIntervals = {
        [1] = {min = 50,  max = 60,  timeout = math.random(50000, 60000)},
        [2] = {min = 60,  max = 70,  timeout = math.random(40000, 50000)},
        [3] = {min = 70,  max = 80,  timeout = math.random(30000, 40000)},
        [4] = {min = 80,  max = 90,  timeout = math.random(20000, 30000)},
        [5] = {min = 90,  max = 100, timeout = math.random(15000, 20000)},
    }
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ HUD DISPLAY SETTINGS ██████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.HUD = {
    health = {
        visible  = true,                          -- Health bar visibility
        color    = {r = 255, g = 0,   b = 0},     -- Color of the health bar
        position = "top-left",                    -- Position of the health bar
    },
    stamina = {
        visible  = true,                          -- Stamina bar visibility
        color    = {r = 0,   g = 255, b = 0},     -- Color of the stamina bar
        position = "top-left",                    -- Position of the stamina bar
    },
    hunger = {
        visible  = true,                          -- Hunger bar visibility
        color    = {r = 255, g = 165, b = 0},     -- Color of the hunger bar
        position = "top-left",                    -- Position of the hunger bar
    },
    thirst = {
        visible  = true,                          -- Thirst bar visibility
        color    = {r = 0,   g = 0,   b = 255},   -- Color of the thirst bar
        position = "top-left",                    -- Position of the thirst bar
    },
    vehicle = {
        visible      = true,                      -- Vehicle HUD visibility
        speedometer  = true,                      -- Speedometer visibility
        fuel         = true,                      -- Fuel gauge visibility
        position     = "bottom-right",            -- Position of the vehicle HUD
    }
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ ALERTS CONFIGURATION ██████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.Alerts = {
    thresholds = {
        health = 20,  -- Health %  for low-health alert
        hunger = 15,  -- Hunger %  for low-hunger alert
        thirst = 15,  -- Thirst %  for low-thirst alert
    },
    alertSound   = true,   -- Enable/Disable alert sound
    alertVisual  = true,   -- Enable/Disable visual alert
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ VEHICLE SETTINGS ██████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.Vehicle = {
    speedUnit            = "mph",  -- Speed unit: "mph" | "kph"
    fuelConsumptionRate  = 1.5,    -- Fuel consumption rate modifier
}

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ ADVANCED HUD SETTINGS █████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

Config.Advanced = {
    customHUD = {
        health  = {position = "top-left",     color = {255, 0,   0  }},
        stamina = {position = "top-right",    color = {0,   255, 0  }},
        hunger  = {position = "bottom-left",  color = {255, 165, 0  }},
        thirst  = {position = "bottom-right", color = {0,   0,   255}},
    },
    customVehicleHUD = {
        speedometer = {position = "bottom-right", color = {255, 255, 255}},
        fuel        = {position = "bottom-left",  color = {255, 255, 0  }},
    }
}
