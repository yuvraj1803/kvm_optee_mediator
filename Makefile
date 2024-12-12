DEBUG ?= 1
NPROC ?= $(shell nproc)
ROOT  ?= $(shell pwd)
QEMU ?= qemu-system-aarch64

all: buildroot u-boot linux tfa optee 

clean: clean_tfa clean_linux clean_u-boot clean_optee clean_buildroot 

# OPTEE

OPTEE_FLAGS ?= CFG_ASLR=n \
			CROSS_COMPILE=aarch64-linux-gnu- \
			CROSS_COMPILE_core=aarch64-linux-gnu- \
			CROSS_COMPILE_ta_arm64=aarch64-linux-gnu- \
			PLATFORM=vexpress-qemu_armv8a \
			O=out/arm/ \
			CFG_USER_TA_TARGETS=ta_arm64 \
			CFG_ARM64_core=y \
			CFG_TEE_CORE_LOG_LEVEL=3 \
			CFG_ARM_GICV3=y \
			CFG_NS_VIRTUALIZATION=y \
			DEBUG=1	
.PHONY: optee
optee:
	cd optee_os/ && make $(OPTEE_FLAGS)

clean_optee:
	cd optee_os/ && make clean

# U-Boot
.PHONY: u-boot
u-boot:
	cd u-boot && make qemu_arm64_defconfig && make -j$(NPROC)

clean_u-boot:
	cd u-boot && make clean

# ARM Trusted Firmware

TFA_FLAGS ?= \
	     CROSS_COMPILE=aarch64-linux-gnu- \
	     PLAT=qemu \
	     BL33=$(ROOT)/u-boot/u-boot.bin \
	     DEBUG=$(DEBUG) \
	     LOG_LEVEL=40 \
	     ARM_LINUX_KERNEL_AS_BL33=0 \
	     QEMU_USE_GIC_DRIVER=QEMU_GICV3 \
	     BL32_RAM_LOCATION=tdram \
	     BL32=$(ROOT)/optee_os/out/arm/core/tee-raw.bin \
		 BL32_EXTRA1=$(ROOT)/optee_os/out/arm/core/tee-pager_v2.bin \
		 BL32_EXTRA2=$(ROOT)/optee_os/out/arm/core/tee-pageable_v2.bin \
	     -j$(NPROC) \
	     SPD=opteed

ifeq ($(DEBUG),1)
TFA_BUILD_PATH=arm-trusted-firmware/build/qemu/debug/
else
TFA_BUILD_PATH=arm-trusted-firmware/build/qemu/release/
endif

tfa: linux u-boot optee
	cd arm-trusted-firmware && make $(TFA_FLAGS) all fip
	cp $(TFA_BUILD_PATH)/qemu_fw.bios $(TFA_BUILD_PATH)/../
clean_tfa:
	rm -f $(TFA_BUILD_PATH)/../qemu_fw.bios
	cd arm-trusted-firmware && make clean

# Buildroot
.PHONY: buildroot
buildroot:
	cp configs/br_config buildroot/.config
	cd buildroot/ && make -j$(NPROC)
clean_buildroot:
	cd buildroot/ && make clean

# Linux Kernel

LINUX_FLAGS ?= \
               ARCH=arm64 \
               CROSS_COMPILE=aarch64-linux-gnu- \
	       -j$(NPROC)

.PHONY: linux
linux: buildroot
	cd linux && make $(LINUX_FLAGS) defconfig && make $(LINUX_FLAGS) Image
	cp buildroot/output/images/rootfs.ext4 linux/
	cp linux/arch/arm64/boot/Image shared/Image
clean_linux:
	cd linux && make clean
	rm -f linux/rootfs.ext4
	rm -f shared/Image
# Run
QEMU_ARGS ?= \
	     -nographic \
	     -kernel linux/arch/arm64/boot/Image \
	     -cpu cortex-a72 \
	     -smp 2 \
	     -machine virt,secure=on,gic-version=3,virtualization=on \
	     -bios $(TFA_BUILD_PATH)/../qemu_fw.bios \
	     -drive file=linux/rootfs.ext4,if=none,format=raw,id=hd0 -device virtio-blk-device,drive=hd0 \
	     -m 8G \
	     -append "rootwait nokaslr root=/dev/vda rw init=/sbin/init console=ttyAMA0 kvm-arm.mode=protected" \
	     -serial mon:stdio \
	     -serial tcp:localhost:12345 \
		 -netdev user,id=vmnic -device virtio-net-device,netdev=vmnic

run:
	sudo sh mount_shared.sh
	$(QEMU) $(QEMU_ARGS)

debug:
	$(QEMU) $(QEMU_ARGS) -s -S

GDB_ARGS ?= \
	    -ex "set confirm off" \
	    -ex "add-symbol-file arm-trusted-firmware/build/qemu/debug/bl1/bl1.elf" \
	    -ex "add-symbol-file arm-trusted-firmware/build/qemu/debug/bl2/bl2.elf" \
	    -ex "add-symbol-file arm-trusted-firmware/build/qemu/debug/bl31/bl31.elf" \
	    -ex "add-symbol-file linux/vmlinux" \
	    -ex "add-symbol-file optee_os/out/arm/core/tee.elf" \
	    -ex "target remote localhost:1234" \
	    -ex "source gdb_scripts/aarch64.gdb" #aarch64.gdb helps in breaking into nvhe symbols. this uses vabits_actual as 62. if this values changes, the breakpoints might not get hit. change this var accordingly. check https://elixir.bootlin.com/linux/v6.9.12/source/arch/arm64/include/asm/memory.h#L233 on how this is calculated when CONFIG_ARM64_VA_BITS is 52.



gdb:
	gdb-multiarch $(GDB_ARGS)

nc:
	nc -l 12345 -k
