# Copyright (C) 2018-2020 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#
# Kernel build configuration variables
# ====================================
#
# These config vars are usually set in BoardConfig.mk:
#
#   TARGET_KERNEL_SOURCE               = Kernel source dir, optional, defaults
#                                          to kernel/$(TARGET_DEVICE_DIR)
#
#   TARGET_KERNEL_ADDITIONAL_FLAGS     = Additional make flags, optional
#
#   TARGET_KERNEL_ARCH                 = Kernel Arch
#
#   TARGET_KERNEL_CROSS_COMPILE_PREFIX = Compiler prefix (e.g. arm-eabi-)
#                                          defaults to arm-linux-androidkernel- for arm
#                                                      aarch64-linux-android- for arm64
#                                                      x86_64-linux-android- for x86
#
#   TARGET_KERNEL_CLANG_COMPILE        = Compile kernel with clang, defaults to true
#
#   TARGET_KERNEL_CLANG_VERSION        = Clang prebuilts version, optional, defaults to clang-stable
#
#   TARGET_KERNEL_CLANG_PATH           = Clang prebuilts path, optional
#
#   KERNEL_CLANG_TRIPLE                = Target triple for clang (e.g. aarch64-linux-gnu-)
#                                          defaults to arm-linux-gnu- for arm
#                                                      aarch64-linux-gnu- for arm64
#                                                      x86_64-linux-gnu- for x86
#
#   KERNEL_TOOLCHAIN_PREFIX            = Overrides TARGET_KERNEL_CROSS_COMPILE_PREFIX,
#                                          Set this var in shell to override
#                                          toolchain specified in BoardConfig.mk
#
#   KERNEL_TOOLCHAIN                   = Path to toolchain, if unset, assumes
#                                          TARGET_KERNEL_CROSS_COMPILE_PREFIX
#                                          is in PATH
#
#   USE_CCACHE                         = Enable ccache (global Android flag)
#
#   TARGET_KERNEL_USE_LLVM_1           = Pass LLVM=1 when building the kernel to use LLVM
#                                          binutils only for kernels that support it, except
#                                          for the integrated assembler.
#
#   TARGET_KERNEL_USE_LLVM_AS          = Same as above except it does use the integrated
#                                          assembler and passes LLVM_IAS=1 as well.
#
#   TARGET_KERNEL_CLANG_USE_GAS        = Use Google's gas binutil prebuilts instead of GCC
#                                          (prebuilts/gas). Also changes CROSS_COMPILE.

BUILD_TOP := $(shell pwd)

TARGET_AUTO_KDIR := $(shell echo $(TARGET_DEVICE_DIR) | sed -e 's/^device/kernel/g')
TARGET_KERNEL_SOURCE ?= $(TARGET_AUTO_KDIR)
ifneq ($(TARGET_PREBUILT_KERNEL),)
  TARGET_KERNEL_SOURCE :=
endif

TARGET_KERNEL_ARCH := $(strip $(TARGET_KERNEL_ARCH))
ifeq ($(TARGET_KERNEL_ARCH),)
  KERNEL_ARCH := $(TARGET_ARCH)
else
  KERNEL_ARCH := $(TARGET_KERNEL_ARCH)
endif

# Clang toolchain
ifneq ($(TARGET_KERNEL_CLANG_COMPILE),false)
  ifneq ($(TARGET_KERNEL_CLANG_VERSION),)
    KERNEL_CLANG_VERSION := $(TARGET_KERNEL_CLANG_VERSION)
  else
    # Use the default version of clang if TARGET_KERNEL_CLANG_VERSION
    # hasn't been set by the device's BoardConfig
    KERNEL_CLANG_VERSION := $(LLVM_PREBUILTS_VERSION)
  endif
  TARGET_KERNEL_CLANG_PATH ?= $(BUILD_TOP)/prebuilts/clang/host/$(HOST_PREBUILT_TAG)/$(KERNEL_CLANG_VERSION)
  CLANG_PREBUILTS := $(TARGET_KERNEL_CLANG_PATH)/bin
endif

# GAS prebuilt path
GAS_PREBUILTS := $(BUILD_TOP)/prebuilts/gas/$(HOST_PREBUILT_TAG)

# GCC toolchain path
GCC_PREBUILTS := $(BUILD_TOP)/prebuilts/gcc/$(HOST_PREBUILT_TAG)

# arm64 GCC toolchain
KERNEL_TOOLCHAIN_arm64 := $(GCC_PREBUILTS)/aarch64/aarch64-linux-android-4.9/bin
KERNEL_TOOLCHAIN_PREFIX_arm64 := aarch64-linux-android-

# arm GCC toolchain
KERNEL_TOOLCHAIN_arm := $(GCC_PREBUILTS)/arm/arm-linux-androideabi-4.9/bin
KERNEL_TOOLCHAIN_PREFIX_arm := arm-linux-androidkernel-

# x86 GCC toolchain
KERNEL_TOOLCHAIN_x86 := $(GCC_PREBUILTS)/x86/x86_64-linux-android-4.9/bin
KERNEL_TOOLCHAIN_PREFIX_x86 := x86_64-linux-android-

# Toolchain prefix (Ex: aarch64-linux-android-)
TARGET_KERNEL_CROSS_COMPILE_PREFIX := $(strip $(TARGET_KERNEL_CROSS_COMPILE_PREFIX))
ifneq ($(TARGET_KERNEL_CROSS_COMPILE_PREFIX),)
  KERNEL_TOOLCHAIN_PREFIX ?= $(TARGET_KERNEL_CROSS_COMPILE_PREFIX)
else
  KERNEL_TOOLCHAIN ?= $(KERNEL_TOOLCHAIN_$(KERNEL_ARCH))
  KERNEL_TOOLCHAIN_PREFIX ?= $(KERNEL_TOOLCHAIN_PREFIX_$(KERNEL_ARCH))
endif

# Toolchain to use if passed
ifeq ($(KERNEL_TOOLCHAIN),)
  KERNEL_TOOLCHAIN_PATH := $(KERNEL_TOOLCHAIN_PREFIX)
else
  KERNEL_TOOLCHAIN_PATH := $(KERNEL_TOOLCHAIN)/$(KERNEL_TOOLCHAIN_PREFIX)
endif

# We need to add GCC toolchain to the path no matter what for tools like `as`
KERNEL_TOOLCHAIN_PATH_gcc := $(KERNEL_TOOLCHAIN_$(KERNEL_ARCH))/$(KERNEL_TOOLCHAIN_PREFIX_$(KERNEL_ARCH))

# Setup ccache
ifneq ($(USE_CCACHE),)
  ifneq ($(CCACHE_EXEC),)
    CCACHE_BIN := $(CCACHE_EXEC)
  endif
endif

# Cross-compile toolchain (GCC used as secondary if Clang is used)
ifneq ($(TARGET_KERNEL_CLANG_COMPILE),false)
  ifeq ($(TARGET_KERNEL_CLANG_USE_GAS),true)
    KERNEL_CROSS_COMPILE := CROSS_COMPILE=aarch64-linux-gnu-
  else
    KERNEL_CROSS_COMPILE := CROSS_COMPILE="$(KERNEL_TOOLCHAIN_PATH)"
  endif
else
  KERNEL_CROSS_COMPILE := CROSS_COMPILE="$(CCACHE_BIN) $(KERNEL_TOOLCHAIN_PATH)"
endif

# Needed for CONFIG_COMPAT_VDSO, safe to set for all arm64 builds
ifeq ($(KERNEL_ARCH),arm64)
  ifeq ($(TARGET_KERNEL_CLANG_USE_GAS),true)
    CC_ARM32_PATH=arm-linux-gnueabi-
  else
    CC_ARM32_PATH=$(KERNEL_TOOLCHAIN_arm)/$(KERNEL_TOOLCHAIN_PREFIX_arm)
  endif
  KERNEL_CROSS_COMPILE += CROSS_COMPILE_ARM32=$(CC_ARM32_PATH)
  KERNEL_CROSS_COMPILE += CROSS_COMPILE_COMPAT=$(CC_ARM32_PATH)
endif

# Clear this first to prevent accidental poisoning from env
KERNEL_MAKE_FLAGS :=

# Setup passing LLVM=1
ifeq ($(TARGET_KERNEL_USE_LLVM_IAS),true)
  KERNEL_MAKE_FLAGS += LLVM_IAS=1
  TARGET_KERNEL_USE_LLVM_1=true
endif
ifeq ($(TARGET_KERNEL_USE_LLVM_1),true)
  KERNEL_MAKE_FLAGS += LLVM=1
endif

# Setup clang triple early in case LLVM=1 is used
ifeq ($(KERNEL_ARCH),arm64)
  # Avoid "unsupported RELA relocation: 311" errors (R_AARCH64_ADR_GOT_PAGE)
  KERNEL_MAKE_FLAGS += CFLAGS_MODULE="-fno-pic"
  # Set arm64 Clang Triple
  KERNEL_CLANG_TRIPLE ?= CLANG_TRIPLE=aarch64-linux-gnu-
else ifeq ($(KERNEL_ARCH),arm)
  # Avoid "Unknown symbol _GLOBAL_OFFSET_TABLE_" errors
  KERNEL_MAKE_FLAGS += CFLAGS_MODULE="-fno-pic"
  # Set arm Clang Triple
  KERNEL_CLANG_TRIPLE ?= CLANG_TRIPLE=arm-linux-gnu-
else ifeq ($(KERNEL_ARCH),x86)
  # Set x86 Clang Triple
  KERNEL_CLANG_TRIPLE ?= CLANG_TRIPLE=x86_64-linux-gnu-
endif
ifneq ($(TARGET_KERNEL_CLANG_COMPILE),false)
  ifneq ($(TARGET_KERNEL_CLANG_USE_GAS),true)
    KERNEL_MAKE_FLAGS += $(KERNEL_CLANG_TRIPLE)
  endif
endif

# build-tools path
prebuilt_build_tools_path := $(BUILD_TOP)/prebuilts/build-tools
prebuilt_build_tools_bin_path := $(prebuilt_build_tools_path)/$(HOST_PREBUILT_TAG)/bin
prebuilt_build_tools_common_path := $(prebuilt_build_tools_path)/common

# Add back threads, ninja cuts this to $(nproc)/2
KERNEL_MAKE_FLAGS += -j$(shell $(prebuilt_build_tools_bin_path)/nproc --all)

# Host cflags and ldflags
ifeq ($(HOST_OS),darwin)
  KERNEL_MAKE_FLAGS += HOSTCFLAGS="-I$(BUILD_TOP)/external/elfutils/libelf -I/usr/local/opt/openssl/include" HOSTLDFLAGS="-L/usr/local/opt/openssl/lib -fuse-ld=lld"
else
  KERNEL_MAKE_FLAGS += CPATH="/usr/include:/usr/include/x86_64-linux-gnu" HOSTLDFLAGS="-L/usr/lib/x86_64-linux-gnu -L/usr/lib64 -fuse-ld=lld --rtlib=compiler-rt"
endif

# Add additional flags from BoardConfig
ifneq ($(TARGET_KERNEL_ADDITIONAL_FLAGS),)
  KERNEL_MAKE_FLAGS += $(TARGET_KERNEL_ADDITIONAL_FLAGS)
endif

# Setup tools
KERNEL_BUILD_TOOLS := $(BUILD_TOP)/prebuilts/kernel-build-tools/$(HOST_PREBUILT_TAG)/bin

TOOLS_PATH_OVERRIDE := \
  PATH=$(CLANG_PREBUILTS):$(KERNEL_BUILD_TOOLS):$(GAS_PREBUILTS):$(prebuilt_build_tools_bin_path):$$PATH \
  LD_LIBRARY_PATH=$(prebuilt_build_tools_path)/$(HOST_PREBUILT_TAG)/lib:$$LD_LIBRARY_PATH \
  PERL5LIB=$(prebuilt_build_tools_common_path)/perl-base

# Set DTBO image locations so the build system knows to build them
ifeq (true,$(filter true, $(TARGET_NEEDS_DTBOIMAGE) $(BOARD_KERNEL_SEPARATED_DTBO)))
  BOARD_PREBUILT_DTBOIMAGE ?= $(TARGET_OUT_INTERMEDIATES)/DTBO_OBJ/arch/$(KERNEL_ARCH)/boot/dtbo.img
endif

# Set use the full path to the make command
KERNEL_MAKE_CMD := $(prebuilt_build_tools_bin_path)/make

# Set the full path to the clang command for host only if LLVM=1 isn't going to be used
ifneq ($(TARGET_KERNEL_USE_LLVM_1),true)
  KERNEL_MAKE_FLAGS += HOSTCC=clang
  KERNEL_MAKE_FLAGS += HOSTCXX=clang++
  KERNEL_MAKE_FLAGS += HOSTLD=ld.lld
  KERNEL_MAKE_FLAGS += HOSTAR=llvm-ar
endif

# Since Linux 4.16, flex and bison are required
KERNEL_MAKE_FLAGS += LEX=$(prebuilt_build_tools_bin_path)/flex
KERNEL_MAKE_FLAGS += YACC=$(prebuilt_build_tools_bin_path)/bison
KERNEL_MAKE_FLAGS += M4=$(prebuilt_build_tools_bin_path)/m4
TOOLS_PATH_OVERRIDE += BISON_PKGDATADIR=$(prebuilt_build_tools_common_path)/bison

# Set the out dir for the kernel's O= arg
# This needs to be an absolute path, so only set this if the standard out dir isn't used
OUT_DIR_PREFIX := $(shell echo $(OUT_DIR) | sed -e 's|/target/.*$$||g')
KERNEL_BUILD_OUT_PREFIX :=
ifeq ($(OUT_DIR_PREFIX),out)
  KERNEL_BUILD_OUT_PREFIX := $(BUILD_TOP)/
endif

include build/make/core/BoardConfigSoong.mk
