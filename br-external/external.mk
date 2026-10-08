include $(sort $(wildcard $(BR2_EXTERNAL_FPVOS_PATH)/package/*/*.mk))

# Mesa for Panfrost, without LLVM. Buildroot's recipe enables LLVM (and, via
# the shader precompiler, OpenCL with Clang and libclc) whenever Panfrost is
# selected, but Panfrost's compiler is Mesa's own, and the OpenCL-C shaders are
# compiled on the build host by host-mesa3d (-Dmesa-clc=system). Built this
# way libgallium does not link libLLVM, so post-build.sh can drop the ~220 MB
# of LLVM, Clang, libclc and SPIR-V tools Buildroot installs into the target.
ifeq ($(BR2_PACKAGE_MESA3D_GALLIUM_DRIVER_PANFROST),y)
MESA3D_CONF_OPTS += -Dllvm=disabled
endif

# The kernel against its board's linux.hash (board/vrxpro for the goggle,
# board/ascent-lite for the air unit: the folder of the build's kernel config
# fragment): its tarball, and its licence files for legal-info. Buildroot's own
# linux.hash only knows upstream's licence files, which Rockchip's tree does not
# match (legal-info fails), and Buildroot skips the tarball's check for any
# kernel but its own latest. A pin moved without a new hash fails the download.
ifeq ($(BR2_LINUX_KERNEL_CUSTOM_TARBALL),y)
LINUX_HASH_FILES = $(dir $(firstword $(call qstrip,$(BR2_LINUX_KERNEL_CONFIG_FRAGMENT_FILES))))linux.hash
BR_NO_CHECK_HASH_FOR := $(filter-out $(LINUX_SOURCE),$(BR_NO_CHECK_HASH_FOR))
# Headers built from the same tarball (the air unit's Buildroot toolchain) are
# the same file, so they are checked against the same hash file.
ifeq ($(BR2_KERNEL_HEADERS_AS_KERNEL),y)
LINUX_HEADERS_HASH_FILES = $(LINUX_HASH_FILES)
endif
endif
