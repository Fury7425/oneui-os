# Creates a Hyper-V VM that boots the Fedora KDE 44 live ISO, plus a small "ONEUIOS" disk holding this repo,
# so you can try the OneUI OS look on real Plasma without building the image.
# Run from an admin PowerShell:  powershell -ExecutionPolicy Bypass -File .\vm.ps1
# Edited the theme? Shut the VM down and run this again; it refreshes the ONEUIOS disk.
param([string]$Name = "oneui-os-test")
$ErrorActionPreference = "Stop"

$os  = Split-Path $PSScriptRoot
$dir = (Split-Path -Qualifier $os) + "\oneui-os-vm"
$iso = "$dir\Fedora-KDE-Desktop-Live-44-1.7.x86_64.iso"
$vhd = "$dir\oneui-os-files.vhdx"
New-Item -ItemType Directory -Force $dir | Out-Null

if (-not (Test-Path $iso)) {
    curl.exe -L --fail -o $iso "https://download.fedoraproject.org/pub/fedora/linux/releases/44/KDE/x86_64/iso/Fedora-KDE-Desktop-Live-44-1.7.x86_64.iso"
    if ((Get-FileHash $iso -Algorithm SHA256).Hash -ne "C8295961D4C41ADBF785A31A17C21A971D3B7415FDA72DCAD0C11C49577BF03A") {
        Remove-Item $iso
        throw "ISO checksum mismatch, deleted it. Run again."
    }
}

$vm = Get-VM $Name -ErrorAction SilentlyContinue
if ($vm -and $vm.State -ne "Off") { throw "Shut down '$Name' first." }

# Files disk: FAT32 so the live session mounts it with no extra drivers. mok.key stays on Windows.
if (Test-Path $vhd) { Remove-Item $vhd }
$vol = New-VHD -Path $vhd -SizeBytes 512MB -Dynamic | Mount-VHD -Passthru | Initialize-Disk -PartitionStyle MBR -Passthru |
    New-Partition -UseMaximumSize -AssignDriveLetter | Format-Volume -FileSystem FAT32 -NewFileSystemLabel ONEUIOS -Confirm:$false
Get-ChildItem $os -Exclude mok.key | Copy-Item -Destination "$($vol.DriveLetter):\" -Recurse
Dismount-VHD $vhd

if (-not $vm) {
    New-VM -Name $Name -Generation 2 -MemoryStartupBytes 6GB -SwitchName "Default Switch" -Path $dir -NoVHD | Out-Null
    Set-VMMemory $Name -DynamicMemoryEnabled $false
    Set-VMProcessor $Name -Count 4
    Set-VMFirmware $Name -SecureBootTemplate MicrosoftUEFICertificateAuthority
    Set-VMVideo $Name -ResolutionType Single -HorizontalResolution 1920 -VerticalResolution 1200 # the mockup's canvas
    Add-VMDvdDrive $Name -Path $iso
    Add-VMHardDiskDrive $Name -Path $vhd
    Set-VMFirmware $Name -FirstBootDevice (Get-VMDvdDrive $Name)
}

vmconnect.exe localhost $Name
Start-VM $Name
