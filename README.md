# LXR-HUD

LXR-HUD is a modern, customizable, and highly optimized heads-up display (HUD) designed for the LXRCore framework. It provides players with a clean and functional UI to monitor essential stats like health, stamina, hunger, thirst, and more in a visually appealing manner. Built specifically for RedM servers, LXR-HUD integrates seamlessly with LXRCore, ensuring smooth performance and easy customization.

## Features

- **Fully Customizable**: Tailor the HUD layout, design, and elements to your server's theme and player needs.
- **Status Tracking**: Displays real-time data for health, stamina, hunger, thirst, and other vital stats.
- **Optimized Performance**: Designed with performance in mind, LXR-HUD minimizes resource usage while providing detailed stat monitoring.
- **Configurable Alerts**: Set custom thresholds for low health, hunger, or thirst, providing players with visual and audio cues.
- **Vehicle Integration**: Shows key vehicle stats like speed, fuel level, and damage when driving, creating a more immersive experience.
- **Cross-Framework Compatibility**: While optimized for LXRCore, LXR-HUD can be adapted for other frameworks with minor adjustments.
- **Drag and Drop**: Easily install and configure LXR-HUD without requiring complex setups.

## Installation

1. **Download the resource**:
   - Clone or download the `lxr-hud` repository from [GitHub](https://github.com/LXRCore/lxr-hud).

   ```bash
   git clone https://github.com/LXRCore/lxr-hud.git
   ```

2. **Add to your server configuration**:
   - Add `lxr-hud` to your `server.cfg` to ensure it starts when your server launches.

   ```bash
   ensure lxr-hud
   ```

3. **Configuration**:
   - Open the `config.lua` file in the resource folder to customize HUD elements to your liking.

4. **Restart your server**:
   - After configuring the HUD, restart your server to apply the changes.

## Configuration

LXR-HUD comes with a fully customizable `config.lua` file that allows you to adjust the following:

- **HUD Positioning**: Define where each element of the HUD appears on the screen.
- **Color Themes**: Change the colors of health, stamina, hunger, and thirst bars to fit your server's theme.
- **Visibility Settings**: Enable or disable specific HUD elements based on your needs (e.g., disable hunger/thirst for specific jobs).
- **Vehicle HUD**: Customize the vehicle speedometer, fuel gauge, and damage indicators.
- **Thresholds**: Adjust the alert thresholds for low health, hunger, thirst, etc.

Example Configuration:

```lua
Config = {}
Config.HUD = {
    health = { visible = true, color = { r = 255, g = 0, b = 0 }, position = "top-left" },
    stamina = { visible = true, color = { r = 0, g = 255, b = 0 }, position = "top-left" },
    hunger = { visible = true, color = { r = 255, g = 165, b = 0 }, position = "top-left" },
    thirst = { visible = true, color = { r = 0, g = 0, b = 255 }, position = "top-left" },
    vehicle = { visible = true, speedometer = true, fuel = true, position = "bottom-right" }
}
```

## Keybindings

The HUD is designed to be simple and intuitive, but you can configure additional keybindings for toggling certain elements like the vehicle HUD or stats display. All keybinding changes can be made within the `config.lua` file.

## Requirements

- **LXRCore**: LXR-HUD is developed for the LXRCore framework but can be adapted for other frameworks with slight modifications.
- **RedM**: This HUD is intended for RedM servers running a roleplay environment.

## Future Updates

- **Modular HUD**: Upcoming features include a modular design where players can toggle different elements on or off according to personal preferences.
- **Additional Stats**: Future updates will support more in-depth stats like fatigue, temperature, and sleep.
- **Animations**: Adding smooth transitions and animations for health, stamina, and vehicle-related stats for enhanced UX.

## Support

For any questions, support, or feature requests, feel free to open an issue or a pull request on the [GitHub repository](https://github.com/LXRCore/lxr-hud).

Join our [Discord community](https://discord.gg/5DGEv4kK7Q) for further assistance and discussions on LXRCore and LXR-HUD development.
