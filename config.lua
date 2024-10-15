
Config = {}

-- General Settings
Config.MinimumStress = 50        -- Minimum Stress Level for Screen Shaking
Config.UpdateInterval = 10       -- Update Interval for Food and Water (minutes)

-- Stress Configuration
Config.Stress = {
    intensityLevels = {
        [1] = {min = 50, max = 60, intensity = 0.12},
        [2] = {min = 60, max = 70, intensity = 0.17},
        [3] = {min = 70, max = 80, intensity = 0.22},
        [4] = {min = 80, max = 90, intensity = 0.28},
        [5] = {min = 90, max = 100, intensity = 0.32},
    },
    effectIntervals = {
        [1] = {min = 50, max = 60, timeout = math.random(50000, 60000)},
        [2] = {min = 60, max = 70, timeout = math.random(40000, 50000)},
        [3] = {min = 70, max = 80, timeout = math.random(30000, 40000)},
        [4] = {min = 80, max = 90, timeout = math.random(20000, 30000)},
        [5] = {min = 90, max = 100, timeout = math.random(15000, 20000)},
    }
}

-- HUD Display Settings
Config.HUD = {
    health = {
        visible = true,                   -- Health bar visibility
        color = {r = 255, g = 0, b = 0},  -- Color of the health bar
        position = "top-left"             -- Position of the health bar
    },
    stamina = {
        visible = true,                   -- Stamina bar visibility
        color = {r = 0, g = 255, b = 0},  -- Color of the stamina bar
        position = "top-left"             -- Position of the stamina bar
    },
    hunger = {
        visible = true,                   -- Hunger bar visibility
        color = {r = 255, g = 165, b = 0},-- Color of the hunger bar
        position = "top-left"             -- Position of the hunger bar
    },
    thirst = {
        visible = true,                   -- Thirst bar visibility
        color = {r = 0, g = 0, b = 255},  -- Color of the thirst bar
        position = "top-left"             -- Position of the thirst bar
    },
    vehicle = {
        visible = true,                   -- Vehicle HUD visibility
        speedometer = true,               -- Speedometer visibility
        fuel = true,                      -- Fuel gauge visibility
        position = "bottom-right"         -- Position of the vehicle HUD
    }
}

-- Alerts Configuration
Config.Alerts = {
    thresholds = {
        health = 20,      -- Health threshold for low health alert
        hunger = 15,      -- Hunger threshold for low hunger alert
        thirst = 15,      -- Thirst threshold for low thirst alert
    },
    alertSound = true,     -- Enable/Disable alert sound
    alertVisual = true     -- Enable/Disable visual alert
}

-- Vehicle Settings
Config.Vehicle = {
    speedUnit = "mph",      -- Speed unit (mph/kph)
    fuelConsumptionRate = 1.5, -- Fuel consumption rate modifier
}

-- Advanced HUD Settings (Custom positions, custom colors, etc.)
Config.Advanced = {
    customHUD = {
        health = { position = "top-left", color = {255, 0, 0} },
        stamina = { position = "top-right", color = {0, 255, 0} },
        hunger = { position = "bottom-left", color = {255, 165, 0} },
        thirst = { position = "bottom-right", color = {0, 0, 255} }
    },
    customVehicleHUD = {
        speedometer = { position = "bottom-right", color = {255, 255, 255} },
        fuel = { position = "bottom-left", color = {255, 255, 0} }
    }
}
