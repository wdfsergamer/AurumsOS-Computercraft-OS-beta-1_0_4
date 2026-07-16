# AurumOS 1.0.5 Floppy Disk Boot Guide

This guide explains how to create a bootable floppy disk with AurumOS 1.0.5 and use it to boot the operating system.

## Overview

AurumOS 1.0.5 can now be installed and booted entirely from a floppy disk, making it portable and easy to share. The disk boot system includes:

- **Portable Boot Loader** - Lightweight boot code that runs from disk
- **Complete OS Files** - All AurumOS system files on the disk
- **Auto-Boot Support** - Optional auto-boot on computer startup
- **Launcher** - Easy launcher to run AurumOS from the disk

## Creating a Boot Disk

### Prerequisites

- A computer with a disk drive attached
- A blank or expendable floppy disk
- Access to the `create_boot_disk.lua` script
- AurumOS 1.0.5 source files

### Step-by-Step Instructions

1. **Attach a disk drive**
   - Connect a disk drive peripheral to your computer (top, bottom, left, right, front, or back)

2. **Insert a blank disk**
   - Place a blank floppy disk into the drive

3. **Run the boot disk creator**
   ```
   run create_boot_disk.lua
   ```

4. **Follow the prompts**
   - Review the warning message
   - Type `y` to confirm and proceed
   - Wait for files to be copied
   - Keep the disk in the drive during the process

5. **Verify creation**
   - The script will show checkmarks (✓) for successfully copied files
   - Look for messages confirming:
     - Directory structure created
     - Boot files copied
     - Launcher created
     - Boot info file created

## Using the Boot Disk

### Manual Launch

Once you have a boot disk, you can launch AurumOS from any computer:

```
run disk:AurumOS/launcher.lua
```

Or directly:

```
run disk:startup.lua
```

### Auto-Boot (On Reboot)

To make AurumOS auto-boot from the disk on computer startup:

1. Create the boot disk using the instructions above
2. The disk will automatically contain the necessary startup file
3. On next reboot, the computer will automatically load AurumOS from the disk

### Using on Different Computers

The boot disk can be used on any ComputerCraft computer:

1. Insert the disk into a drive on the target computer
2. Type: `run disk:startup.lua`
3. Or reboot to auto-boot

## Disk Structure

When successfully created, your boot disk will have this structure:

```
disk:/
├── startup.lua                 # Auto-boot on reboot
├── BOOT_INFO.txt              # Information file
└── AurumOS/
    ├── boot.lua               # Main kernel
    ├── launcher.lua           # Easy launcher
    ├── Desktop/               # User desktop items
    ├── Programs/              # User programs
    ├── modules/               # System modules
    └── system/
        ├── activation.lua      # Activation system
        ├── terminal.lua        # Terminal application
        ├── games.lua           # Game implementations
        ├── gosdoom.lua         # DOOM easter egg
        └── graphs_integration.lua  # Graphs module
```

## Troubleshooting

### "No disk drive found"

**Problem**: The script cannot find a disk drive

**Solution**:
- Check that a disk drive is attached to the computer
- Verify it's attached to one of these sides: top, bottom, left, right, front, back
- Try a different side if available

### "No disk in drive"

**Problem**: The drive is detected but no disk is inserted

**Solution**:
- Insert a blank floppy disk into the drive
- Wait for the drive to recognize the disk
- Re-run the script

### File copy failures

**Problem**: Some files show "✗ Failed" during creation

**Solution**:
- Ensure all AurumOS source files are in the correct location
- The source path should be `aurumsOS/AurumOS/`
- Check that the disk has enough free space
- Try with a different disk

### Boot disk won't start

**Problem**: Inserting the disk and running startup.lua doesn't work

**Solution**:
- Verify the disk was created successfully (check for ✓ marks)
- Check that `disk:AurumOS/boot.lua` exists using: `ls disk:AurumOS/`
- Try re-creating the boot disk with a different floppy
- Ensure the disk drive is properly connected

## Advanced Usage

### Portable Installation

Create boot disks to distribute AurumOS to others:

1. Create a boot disk using this guide
2. Share the disk with other users
3. They can insert it and run: `run disk:startup.lua`

### Multi-System Setup

Use the same boot disk on multiple computers:

1. Create the boot disk once
2. Move it between computers
3. Insert and run from any computer
4. Each computer gets its own activation key

### Backup

Make backup copies of important systems:

1. Create a boot disk
2. Copy the disk using ComputerCraft's disk copying features
3. Keep backups safe for emergency boot

## Technical Details

### Boot Process

1. Computer startup
2. `startup.lua` runs from the disk
3. Boot loader initializes
4. System checks and mounts disk
5. `boot.lua` loads and executes
6. AurumOS interface initializes
7. User login/desktop appears

### File Sizes

Approximate sizes (varies by version):

- `boot.lua`: ~50-60 KB
- `system/` folder: ~30-40 KB
- Total disk usage: ~100-150 KB
- Available on standard floppy: ~1500 KB

## Notes

- Boot disks preserve their data between uses
- Settings and user files can be saved to the disk
- Multiple AurumOS installations can exist on different disks
- The disk boot system is read/write compatible

## Support

For issues or questions about disk booting:

1. Check this guide's troubleshooting section
2. Verify all files were copied successfully
3. Try with a different disk drive or floppy disk
4. Review system logs if available

---

**Happy booting!** 🚀
