# Back Up the Windows Driver Store from Ubuntu

If Windows is offline but the partition is still readable, copy:

```text
C:\Windows\System32\DriverStore\FileRepository
```

This is not as clean as `DISM /Export-Driver`, but it preserves the INF-based driver packages available on the offline Windows install.

## Find the Windows Partition

```bash
lsblk -o NAME,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINTS
```

Choose the large NTFS Windows partition, not EFI or recovery.

## Mount Read-Only

```bash
sudo apt update
sudo apt install -y rsync ntfs-3g zip

WINDEV=/dev/nvme0n1p4
sudo mkdir -p /mnt/win
sudo umount /mnt/win 2>/dev/null || true
sudo mount -t ntfs-3g -o ro "$WINDEV" /mnt/win
```

Verify:

```bash
ls /mnt/win/Windows/System32/DriverStore/FileRepository
```

## Copy Driver Packages

```bash
DEST="$HOME/windows-driver-backup-$(date +%Y%m%d-%H%M)"
mkdir -p "$DEST"

sudo rsync -rt --info=progress2 \
  /mnt/win/Windows/System32/DriverStore/FileRepository/ \
  "$DEST/FileRepository/"

sudo rsync -rt --info=progress2 \
  /mnt/win/Windows/INF/ \
  "$DEST/INF/"

sudo rsync -rt --info=progress2 \
  /mnt/win/Windows/System32/drivers/ \
  "$DEST/System32-drivers/"
```

## Inventory

```bash
find "$DEST/FileRepository" -iname "*.inf" | sort > "$DEST/all-driver-inf-files.txt"
find "$DEST/FileRepository" -maxdepth 1 -type d | sort > "$DEST/driverstore-folders.txt"
du -sh "$DEST" > "$DEST/backup-size.txt"
```

## Windows Restore Script

```bash
cat > "$DEST/RESTORE-ON-WINDOWS.cmd" <<'EOF'
@echo off
echo Installing drivers from FileRepository...
pnputil /add-driver "%~dp0FileRepository\*.inf" /subdirs /install

echo.
echo Installing drivers from INF folder...
pnputil /add-driver "%~dp0INF\*.inf" /subdirs /install

echo.
echo Done. Reboot Windows after this.
pause
EOF
```

If the backup is on a Linux filesystem, zip it:

```bash
cd "$(dirname "$DEST")"
zip -r "$(basename "$DEST").zip" "$(basename "$DEST")"
```

## BitLocker

If the Windows partition is BitLocker encrypted:

```bash
sudo apt install -y dislocker
sudo mkdir -p /mnt/bitlocker /mnt/win
sudo dislocker -V /dev/nvme0n1p4 -u -- /mnt/bitlocker
sudo mount -o loop,ro /mnt/bitlocker/dislocker-file /mnt/win
```

Then continue from the copy step.

