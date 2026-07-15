# AurumOS 1.0.4 for ComputerCraft

AurumOS is a small ComputerCraft desktop OS with draggable windows, compact desktop
items, a tabbed Start menu, optional login password, activation during install,
Tiny Market, auto-update, Turtle Remote, RedNet Share, display settings, Calculator,
Paint, Sheets, Code Studio, BIOS tools, games, sound/mixer support, and a built-in
file manager.

## Files

- `install.lua` - creates `/x32`, copies the OS there, asks for activation, and writes `/startup` plus `/startup.lua`.
- `activation_server.lua` - generates activation keys for one ComputerCraft computer ID and one OS version.
- `/x32/boot.lua` after install - desktop, window manager, taskbar, launcher, file manager, and terminal.
- `/x32/Desktop` after install - desktop items. Move or copy programs here to show them on the desktop.
- `/x32/Programs` after install - optional place for installed programs.
- `/x32/Shared` after install - received RedNet files from the Share app.
- `/x32/system/settings.dat` after install - saved display settings.
- `Tiny market/server.lua` - RedNet market/update server.
- `/x32/Programs/turtle_client.lua` after install - run this on turtles for remote control.

## Install

1. Copy this folder to a ComputerCraft computer or disk.
2. Run `activation_server.lua` on another computer if you want a computer-specific key.
3. On the target computer, run `install.lua`.
4. Enter the generated key. If both computers have modems, press Enter and the installer will ask the server over `rednet`.
5. Reboot. After activation, the OS boots straight to the desktop.

The generated key depends on the target `Computer ID` and AurumOS version, so a
normal key is not valid for another computer or another OS version.

## Desktop Programs

To add a program to the desktop, move or copy it into:

```text
/x32/Desktop
```

No extra lines need to be added inside the program. Double-click the desktop item
to run it in a window.

Optional `.link` files can point to built-in tools:

```text
title=Files
icon=F
target=builtin:files
```

## Controls

- Drag a window by its top title bar.
- Click `-` in the title bar to minimize.
- Click `X` in the title bar to close.
- Click a taskbar button to focus or restore.
- Click the `X` at the end of a taskbar button to close the window from the taskbar.
- Double-click desktop items to open them.
- Use `Share` to send text/files over RedNet.
- Use `CC Shell` to leave the desktop and work in the native ComputerCraft shell.
- Use `Settings` to change gradient, icon size, and monitor text scale when supported.
- In `Settings`, leave `Password` empty for no login prompt, or set your own password.
- In `Files`, drag a row onto a folder to move it there.
- Use `Calculator` for simple arithmetic and `Paint` for basic mouse drawing.
- Use `Sheets` for a small spreadsheet; `Print` sends it to an attached printer.
- Use `Code Studio` for Lua editing with colored syntax and Tab autocomplete.
- Press `B` during startup, or open `BIOS`, for reinstall and alternate boot tools.
- Use `Tiny Market` with `Tiny market/server.lua` for apps and auto-updates.
- Use `Turtle Remote` with `turtle_client.lua` running on a turtle.
- Use `Ballistics` for an approximate Create Big Cannons aiming calculation.
- Drag desktop icons to `[Trash]` near the bottom to remove them.
- Type `DOOM` in Terminal to open the hidden mini game.
