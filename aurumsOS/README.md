# AurumOS 1.0.5 for ComputerCraft

A modern, feature-rich desktop operating system for ComputerCraft with an intuitive interface, powerful applications, and extensive customization options.

## What's New in 1.0.5

### 🎨 **Modern Interface**
- Completely redesigned UI with improved visuals
- Better window management and layout
- Support for the `graphs` addon for data visualization
- Enhanced color scheme and theme system

### 🎮 **Full Game Suite**
- **GOSDOOM**: Simplified DOOM game easter egg (type `GOSDOOM` in terminal)
- **Pong**: Classic two-player game
- **Snake**: Retro snake game with scoring
- All games fully functional with no placeholders

### 🔧 **Process Manager**
- F1 key opens the process manager
- View active windows and processes
- Better task management and multitasking

### 📡 **Remote Installation**
- New network installer server
- Install AurumOS from any active computer on the network
- Automatic activation key generation
- Simple installation without manual key entry

### 📊 **Graphs Integration**
- Built-in graphs module for data visualization
- Bar chart support
- Line chart support
- Easy integration into custom applications

### ⚙️ **Improved Mechanics**
- Better file management
- Enhanced terminal with command support
- Improved error handling
- Modular architecture for easier development

## Features

- ✅ Draggable windows with minimize/close buttons
- ✅ Desktop icons and file manager
- ✅ Full terminal with command support
- ✅ Process manager (F1)
- ✅ RedNet support for file sharing
- ✅ Password protection
- ✅ Customizable themes and settings
- ✅ Speaker support with sound effects
- ✅ Multi-monitor support
- ✅ Network-based installation

## Installation

### Quick Install (Local)

```bash
# Run the installer
run install.lua

# Enter your computer ID and activation key
# Reboot and enjoy!
```

### Network Install (Remote)

#### On Server Computer:
```bash
# Start the installation server
run network_installer_server.lua
```

#### On Client Computer:
```bash
# Start boot and press B for BIOS
# Select option 5: Download from network
# The installer will find the server automatically
```

## Terminal Commands

- `HELP` - Show available commands
- `GOSDOOM` - Launch the DOOM mini-game
- `CLEAR` - Clear the screen
- `DISK` - Show disk usage
- `TIME` - Show current time
- `VERSION` - Show OS version

## Hotkeys

- `F1` - Open Process Manager
- `Q` - Quit applications (in games)
- `WASD` - Movement in DOOM
- `Arrow Keys` - Shoot in DOOM

## Games

### GOSDOOM
A simplified action game inspired by DOOM. Fight enemies, collect ammo, and advance through levels.
- **Controls**: WASD to move, Arrow Keys to shoot, Q to quit
- **Objective**: Defeat all enemies and advance to the next level

### Pong
Classic two-player paddle game.
- **Player 1**: W/S keys
- **Player 2**: Up/Down arrow keys

### Snake
Retro snake game with food collection.
- **Controls**: Arrow keys to move
- **Objective**: Eat food and grow without hitting walls or yourself

## Settings

Access settings to customize:
- Theme (modern color schemes)
- Icon size
- Text scale for monitors
- Password protection
- Sound volume
- Monitor and speaker assignment
- Graphs integration toggle

## System Requirements

- ComputerCraft 1.80+
- At least 512KB free disk space
- (Optional) Modem for network features
- (Optional) Speaker for audio
- (Optional) Monitor for multi-display

## Files Structure

```
aurumsOS/
├── install.lua              # Main installer
├── network_installer_server.lua  # Network server
├── README.md                # This file
├── AurumOS/
│   ├── boot.lua            # Main OS kernel
│   ├── Desktop/            # Desktop items
│   ├── Programs/           # User programs
│   └── system/
│       ├── activation.lua   # Activation system
│       ├── gosdoom.lua      # DOOM easter egg
│       ├── terminal.lua     # Terminal app
│       ├── games.lua        # Game implementations
│       └── graphs_integration.lua  # Charting module
└── Tiny market/            # MarketPlace server
    └── server.lua
```

## Tips

1. **Network Installation**: Set up `network_installer_server.lua` on one computer to allow others to join the network and install automatically.

2. **Games**: Try typing `GOSDOOM` in the terminal for a fun easter egg!

3. **Customization**: Edit settings to set up your preferred theme and peripherals.

4. **Performance**: Modular design means only loaded modules consume memory.

## Troubleshooting

### OS won't activate
- Ensure you have the correct activation key
- Check that `/x32/system/activation.key` exists
- Try reinstalling via network server

### Games don't work
- Verify the game files exist in `/x32/system/`
- Check your terminal size (minimum 50x20 recommended)

### Network features unavailable
- Ensure a modem is attached to the computer
- Check that the modem is on a valid side (top, bottom, left, right, front, back)

## License

AurumOS 1.0.5 - Made for ComputerCraft
Based on community feedback and modern OS design principles.

---

**Enjoy your new operating system!** 🚀
