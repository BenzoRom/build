#
# Copyright (C) 2013 The Android Open Source Project
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

# Provides a functioning ART environment without Android frameworks

ifeq ($(TARGET_CORE_JARS),)
$(error TARGET_CORE_JARS is empty; cannot update PRODUCT_PACKAGES variable)
endif

# Minimal boot classpath. This should be a subset of PRODUCT_BOOT_JARS, and equivalent to
# TARGET_CORE_JARS.
PRODUCT_PACKAGES += \
    $(TARGET_CORE_JARS)

# Additional mixins to the boot classpath.
PRODUCT_PACKAGES += \
    android.test.base \

# Why are we pulling in ext, which is frameworks/base, depending on tagsoup and nist-sip?
PRODUCT_PACKAGES += \
    ext \

# Android Runtime APEX module.
PRODUCT_PACKAGES += com.android.runtime
PRODUCT_HOST_PACKAGES += com.android.runtime

# Certificates.
PRODUCT_PACKAGES += \
    cacerts \

PRODUCT_PACKAGES += \
    hiddenapi-package-whitelist.xml \

PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    dalvik.vm.image-dex2oat-Xms=64m \
    dalvik.vm.image-dex2oat-Xmx=64m \
    dalvik.vm.dex2oat-Xms=64m \
    dalvik.vm.dex2oat-Xmx=512m \
    dalvik.vm.usejit=true \
    dalvik.vm.usejitprofiles=true \
    dalvik.vm.dexopt.secondary=true \
    dalvik.vm.appimageformat=lz4

PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.dalvik.vm.native.bridge=0

# Enable resolution of startup const strings.
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    dalvik.vm.dex2oat-resolve-startup-strings=true

# Specify default block size of 512K to enable parallel image decompression.
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    dalvik.vm.dex2oat-max-image-block-size=524288

# Enable minidebuginfo generation unless overridden.
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    dalvik.vm.minidebuginfo=true \
    dalvik.vm.dex2oat-minidebuginfo=true

# Disable iorapd by default
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.iorapd.enable=false

PRODUCT_USES_ART := true
