#!/bin/bash

# Wipe the disk clean (this deletes all partitions on /dev/sda)
echo "Wiping the disk clean..."
dd if=/dev/zero of=/dev/nvme0n1 bs=512 count=1 status=progress

# Partitioning the disk (non-interactive, modify as needed)
echo "Creating new partitions..."
echo -e "g\nn\n\n\n+100M\nt\n1\nn\n\n+8G\nn\n\n+367G\nn\n\nw" | fdisk /dev/nvme0n1

# Formatting partitions
mkfs.fat -F 32 /dev/nvme0n1p1      # EFI partition
mkfs.ext4 /dev/nvme0n1p3          # Root partition
mkswap /dev/nvme0n1p2             # Swap partition

# Mount partitions
mount /dev/nvme0n1p3 /mnt         # Mount root
mkdir -p /mnt/boot/efi
mount /dev/nvme0n1p1 /mnt/boot/efi    # Mount EFI
swapon /dev/nvme0n1p2             # Enable swap

# Installing the base system
pacstrap /mnt base linux linux-firmware sof-firmware base-devel grub efibootmgr nano networkmanager

# Generate fstab
genfstab /mnt > /mnt/etc/fstab

# Chroot into the new system
arch-chroot /mnt << EOF
# Set timezone and localization
ln -sf /usr/share/zoneinfo/Australia/Sydney /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf
echo "Arch" > /etc/hostname

# Set root password automatically
echo "root:J-hack1.18" | chpasswd

# Install GRUB bootloader
grub-install /dev/nvme0n1
grub-mkconfig -o /boot/grub/grub.cfg

# Create user (optional, set username and password)
useradd -m -G wheel -s /bin/bash justin_sus1
echo "justin_sus1:J-hack1.18" | chpasswd
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

systemctl enable NetworkManager

pacman -S plasma sddm konsole kate firefox

systemctl enable sddm

EOF

# Unmount and reboot
umount -R /mnt
reboot
