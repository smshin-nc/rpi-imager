ARCH        := arm64
SUITE       := jammy
MIRROR      := http://ports.ubuntu.com/
ROOTFS_VER  := 1.1.0
ROOTFS_DIR  := rootfs-$(ARCH)-$(ROOTFS_VER)
SQUASH_IMG  := rootfs-$(ARCH)-$(ROOTFS_VER).squashfs
OTA_SLOT_B  := ./slot_b
INITRAMFS   := initramfs-$(ARCH).cpio.gz
KERNEL_IMG  := ./files/Image
DTB_FILE    := ./files/apache6.dtb
INCLUDE_APT := apt,busybox-static,net-tools
DEPLOY_DIR  := deploy

all: clean rootfs overlayfs squashfs deploy

rootfs:
	sudo debootstrap --arch=$(ARCH) --variant=minbase --include=$(INCLUDE_APT) --foreign $(SUITE) $(ROOTFS_DIR) $(MIRROR)
	sudo cp /usr/bin/qemu-aarch64-static $(ROOTFS_DIR)/usr/bin/
	sudo mkdir -p $(ROOTFS_DIR)/mnt /dev /proc /sys
	sudo mount -o bind /dev  $(ROOTFS_DIR)/dev
	sudo mount -o bind /proc $(ROOTFS_DIR)/proc
	sudo mount -o bind /sys  $(ROOTFS_DIR)/sys
	sudo chroot $(ROOTFS_DIR) /debootstrap/debootstrap --second-stage 
	sudo chroot $(ROOTFS_DIR) /bin/sh -c "\
		apt-get update && \
		apt-get install -y --no-install-recommends busybox-static && \
		ln -sf /bin/busybox /bin/sh && \
		rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/locale/* /var/lib/apt/lists/* /var/cache/apt/*"
	sudo umount $(ROOTFS_DIR)/dev || true
	sudo umount $(ROOTFS_DIR)/proc || true
	sudo umount $(ROOTFS_DIR)/sys || true

overlayfs:
	sudo mkdir -p $(OTA_SLOT_B)
	sudo cp -a $(ROOTFS_DIR)/* $(OTA_SLOT_B)/
	sudo touch $(OTA_SLOT_B)/.version-$(ROOTFS_VER)

squashfs:
	sudo mksquashfs $(OTA_SLOT_B) $(SQUASH_IMG) -comp xz -noappend

initramfs:
	mkdir -p initramfs/bin initramfs/sbin initramfs/etc initramfs/proc initramfs/sys initramfs/newroot
	cp /bin/busybox initramfs/bin/
	cd initramfs/bin && for i in `./busybox --list`; do ln -sf busybox $$i; done
	echo "#!/bin/sh \
	mount -t proc none /proc \
	mount -t sysfs none /sys \
	mount -t devtmpfs none /dev \
	mount /dev/mmcblk1p3 /mnt/lower \
	mount /dev/mmcblk1p4 /mnt/upper \
	mkdir /mnt/upper/work /mnt/upper/upper \
	mount -t overlay overlay -o lowerdir=/mnt/lower,upperdir=/mnt/upper/upper,workdir=/mnt/upper/work /mnt/newroot \
	exec switch_root /mnt/newroot /sbin/init" > initramfs/init \
	chmod +x initramfs/init \
	cd initramfs && find . | cpio -H newc -o | gzip > ../$(INITRAMFS)

deploy:
	mkdir -p $(DEPLOY_DIR)
	cp $(KERNEL_IMG) $(DTB_FILE) $(SQUASH_IMG) $(INITRAMFS) $(DEPLOY_DIR)/

clean:
	sudo rm -rf rootfs-* initramfs deploy *.squashfs *.cpio.gz
