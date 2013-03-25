KERNEL_VERSION=2.6.37.6+
# define target directory for modules tarball, zImage and initramfs.
OPENAOS_TARGET=openaos/target
# define your image directory
UBUNTU_IMAGE=image
clean:
	rm -rf $(OPENAOS_TARGET)/zImage* $(OPENAOS_TARGET)/initramfs-debug.cpio.gz* $(OPENAOS_TARGET)/initramfs.cpio.gz* $(OPENAOS_TARGET)/modules $(OPENAOS_TARGET)/modules-$(KERNEL_VERSION)*

dist: clean build modules zImage


build:
	@cd kernel; make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j16
	@cd ../

openaos_dirs:
	mkdir -p $(OPENAOS_TARGET)



zImage: openaos_dirs
	if [ -f kernel/arch/arm/boot/zImage ]; then \
		cp -f kernel/arch/arm/boot/zImage $(OPENAOS_TARGET)/zImage; \
		cd $(OPENAOS_TARGET); md5sum zImage >zImage.md5sum; \
		touch initramfs.cpio.gz; \
	fi

install:
	@if [ "x$$INSTALL_DEST" = "x" ]; then \
		INSTALL_DEST="/media/$$(ls -1 --color=no /media/|grep A*_REC)"; \
	fi; \
	cp -f $(OPENAOS_TARGET)/zImage $(OPENAOS_TARGET)/initramfs.cpio.gz $$INSTALL_DEST; \
	sync; \
	umount $$INSTALL_DEST


modules: openaos_dirs
	@rm -rf tmp/modules
	@mkdir -p tmp/modules
	@cd kernel; make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- INSTALL_MOD_PATH=../tmp/modules modules_install
	@cd tmp/modules/lib/modules; tar cjf ../../../../$(OPENAOS_TARGET)/modules-$(KERNEL_VERSION).tar.bz2 $(KERNEL_VERSION)
	@cd $(OPENAOS_TARGET); md5sum modules-$(KERNEL_VERSION).tar.bz2 >modules-$(KERNEL_VERSION).tar.bz2.md5sum
	@rm -rf tmp/modules

image_install: 
	@rm -rf $(UBUNTU_IMAGE)/lib/modules # Note this will remove all modules in your image dir
	@mkdir -p $(UBUNTU_IMAGE)/lib/modules
	@cd kernel; make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- INSTALL_MOD_PATH=../$(UBUNTU_IMAGE) modules_install
	@cd ../
	@rm $(UBUNTU_IMAGE)/lib/modules/2.6.37.6+/build
	@rm $(UBUNTU_IMAGE)/lib/modules/2.6.37.6+/source
	@rm -rf $(UBUNTU_IMAGE)/lib/modules/2.6.37.6+/kernel/drivers/gpu # remove gpu drivers, because we will use the ones from TI graphic SDK. For Meego you will need these.
	@mkdir -p $(UBUNTU_IMAGE)/boot
	@cp openaos/target/zImage $(UBUNTU_IMAGE)/boot #not needed, but for good order copy kernel and initramfs to boot dir of the image.
	@touch $(UBUNTU_IMAGE)/boot/initramfs.cpio.gz
	@rsync -av ./rootfs_changes/ $(UBUNTU_IMAGE) --exclude=*~
	@chmod +x $(UBUNTU_IMAGE)/etc/rc.local
