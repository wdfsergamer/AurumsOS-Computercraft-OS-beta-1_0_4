# Tiny Market Server

Run `server.lua` on a ComputerCraft computer with a modem.

Clients can open `Tiny Market` in AurumOS and either use broadcast discovery or set
the server computer ID in `Settings`.

For AurumOS auto-update, create:

```text
packages/AurumOS/files.lst
```

Each line maps target path to server source path:

```text
/x32/boot.lua packages/AurumOS/boot.lua
/x32/system/activation.lua packages/AurumOS/activation.lua
```
