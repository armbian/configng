
#
# Copyright (c) Authors: http://www.armbian.com/authors, info@armbian.com
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.
#
#  	utility_confiig_blockdevice.sh related functions. See
#	http://linux-mtd.infradead.org/doc/general.html  for more info.
#   https://en.wikipedia.org/wiki/MultiMediaCard#eMMC

# @description Set up a simulated MTD spi flash for testing.
#
# @example
#   set_spi_vflash
#   echo $?
#   #Output
#   /dev/mtd0
#	/dev/mtd0ro
#	/dev/mtdblock0
#
# @exitcode 0  If successful.
blockdevice::set_vflash(){

	# Load the nandsim and mtdblock modules to create a virtual MTD device

	modprobe mtdblock
    #modprobe nandsim
	# Find the newly created MTD device
	if [[ ! -e /dev/mtdblock0 ]]; then
  		modprobe nandsim
		irtual_mtd=$(grep -l "NAND simulator" /sys/class/mtd/mtd*/name | sed -r 's/.*mtd([0-9]+).*/mtd\1/')
	else
		echo "$( ls /dev/mtdblock0 )"
	fi

	# Create a symlink to the virtual MTD device with the name "spi0.0"
	# This is necessary because the erase_spi_bootloader function looks for an MTD device with this name
	if [[ ! -e /dev/mtdblock0 ]]; then
		ln -s /dev/$virtual_mtd /dev/mtdblock0
	fi

    # Create the mount point if it doesn't exist
    mkdir -p /tmp/boot

    # Mount the virtual MTD device to the mount point
    mount -t jffs2 /dev/mtdblock0 /tmp/boot

	# write a file to remove
	touch /tmp/boot/Mounted_MTD.txt

	echo "$( ls /dev/mtd* )"

}

# @description Remove tsting simulated MTD spi flash.
#
# @example
#   rem_spi_vflash
#   echo $?
#   #Output
#   0
#
# @exitcode 0  If successful.
blockdevice::rem_vflash(){

    # Unmount the virtual MTD device from the mount point
    umount $(mount | grep /dev/mtdblock0 | awk '{print $3}')

    # Remove the symlink to the virtual MTD device
    rm /dev/mtdblock0

    # Unload the nandsim and mtdblock modules to remove the virtual MTD device
    modprobe -r mtdblock
    modprobe -r nandsim

	echo "0"
}
