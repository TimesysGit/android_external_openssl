local_c_flags :=

local_c_includes := $(log_c_includes)

local_additional_dependencies := $(LOCAL_PATH)/android-config.mk $(LOCAL_PATH)/Crypto.mk

include $(LOCAL_PATH)/Crypto-config.mk

#######################################
# target static library
include $(CLEAR_VARS)
include $(LOCAL_PATH)/android-config.mk

LOCAL_SHARED_LIBRARIES := $(log_shared_libraries)

# If we're building an unbundled build, don't try to use clang since it's not
# in the NDK yet. This can be removed when a clang version that is fast enough
# in the NDK.
ifeq (,$(TARGET_BUILD_APPS))
LOCAL_CLANG := true
else
LOCAL_SDK_VERSION := 9
endif

LOCAL_SRC_FILES += $(target_src_files)
LOCAL_CFLAGS += $(target_c_flags)
LOCAL_C_INCLUDES += $(target_c_includes)
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE:= libcrypto_static
LOCAL_ADDITIONAL_DEPENDENCIES := $(local_additional_dependencies)
include $(BUILD_STATIC_LIBRARY)

#######################################
# target shared library
include $(CLEAR_VARS)
include $(LOCAL_PATH)/android-config.mk

LOCAL_SHARED_LIBRARIES := $(log_shared_libraries)

# If we're building an unbundled build, don't try to use clang since it's not
# in the NDK yet. This can be removed when a clang version that is fast enough
# in the NDK.
ifeq (,$(TARGET_BUILD_APPS))
LOCAL_CLANG := true
else
LOCAL_SDK_VERSION := 9
endif
LOCAL_LDFLAGS += -ldl

# OpenSSL has a strange script called 'fipsld' which is meant to sneakily intercept compiler calls and do magic to the resulting libcrypto.so (insert signature and such)
# 'fipsld' requires some environment variables exported, so we wrap it with 'fipscc' to take care of those variables.
LOCAL_CC := $(LOCAL_PATH)/fipscc android-14-fips-2.0 $(CLANG)
# Normally this would be $(CLANG_CXX), but we have to use $(CLANG) (just C compiler) here
# LOCAL_CXX is being used for the link step, for which LDFLAGS is relevant.
# Normally it wouldn't be a problem as it only gets passed object files, but fipscc/fipsld intercept the call and toss in fips_premain.c
# Therefore the 'link' step also needs to compile, so it needs all the compile options,
# plus it needs to not have name-mangling madness from C++ that results in undefined references to the fips_container object
LOCAL_CXX := $(LOCAL_PATH)/fipscc android-14-fips-2.0 $(CLANG)

# fipsld can and will find the fipscanister.o object on its own and link it in whether you asked or no
#LOCAL_PREBUILT_OBJ_FILES := android-14-fips-2.0/lib/fipscanister.o

# This is so fipsld can compile fips_premain.c using arguments passed to the linker
# Basically take the flags given for standard object compilation, rid '-c' and one of the '-isystem's that is specific to the target (lotus_revB), and dump it here
# Not exactly an elegant solution, and should be replaced if an easier/better method is discovered.
LOCAL_LDFLAGS += \
-isystem system/core/include \
-isystem hardware/libhardware/include \
-isystem hardware/libhardware_legacy/include \
-isystem hardware/ril/include \
-isystem libnativehelper/include \
-isystem frameworks/native/include \
-isystem frameworks/native/opengl/include \
-isystem frameworks/av/include \
-isystem frameworks/base/include \
-isystem external/skia/include \
-isystem bionic/libc/arch-arm/include \
-isystem bionic/libc/include \
-isystem bionic/libstdc++/include \
-isystem bionic/libc/kernel/common \
-isystem bionic/libc/kernel/arch-arm \
-isystem bionic/libm/include \
-isystem bionic/libm/include/arm \
-isystem bionic/libthread_db/include \
-isystem external/clang/lib/include \
-fno-exceptions -Wno-multichar -msoft-float -fpic -fPIE -ffunction-sections -fdata-sections -funwind-tables -fstack-protector \
-Werror=format-security -D_FORTIFY_SOURCE=2 -fno-short-enums -march=armv7-a -mfloat-abi=softfp -mfpu=neon \
-include build/core/combo/include/arch/linux-arm/AndroidConfig.h -I build/core/combo/include/arch/linux-arm/ \
-DANDROID -fmessage-length=0 -W -Wall -Wno-unused -Winit-self -Wpointer-arith -DUSES_TI_MAC80211 -DANDROID_P2P_STUB \
-Werror=return-type -Werror=non-virtual-dtor -Werror=address -Werror=sequence-point -DNDEBUG -g -Wstrict-aliasing=2 -DNDEBUG \
-UDEBUG -mthumb -Os -fomit-frame-pointer -fno-strict-aliasing -DOPENSSL_PIC -DOPENSSL_THREADS -D_REENTRANT -DDSO_DLFCN -DHAVE_DLFCN_H \
-DL_ENDIAN -DOPENSSL_NO_CAMELLIA -DOPENSSL_NO_CAPIENG -DOPENSSL_NO_CAST -DOPENSSL_NO_CMS -DOPENSSL_NO_DTLS1 -DOPENSSL_NO_EC_NISTP_64_GCC_128 \
-DOPENSSL_NO_GMP -DOPENSSL_NO_GOST -DOPENSSL_NO_HEARTBEATS -DOPENSSL_NO_IDEA -DOPENSSL_NO_JPAKE -DOPENSSL_NO_MD2 -DOPENSSL_NO_MDC2 -DOPENSSL_NO_RC5 \
-DOPENSSL_NO_RDRAND -DOPENSSL_NO_RFC3779 -DOPENSSL_NO_RSAX -DOPENSSL_NO_SCTP -DOPENSSL_NO_SEED -DOPENSSL_NO_SHA0 -DOPENSSL_NO_SSL2 -DOPENSSL_NO_SSL3 \
-DOPENSSL_NO_STATIC_ENGINE -DOPENSSL_NO_STORE -DOPENSSL_NO_WHIRLPOOL -DOPENSSLDIR="/system/lib/ssl" -DENGINESDIR="/system/lib/ssl/engines" \
-DNO_WINDOWS_BRAINDEATH -DAES_ASM -DGHASH_ASM -DOPENSSL_BN_ASM_GF2m -DOPENSSL_BN_ASM_MONT -DSHA1_ASM -DSHA256_ASM -DSHA512_ASM \
-D__compiler_offsetof=__builtin_offsetof -target arm-linux-androideabi -nostdlibinc \
-Bprebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.7/arm-linux-androideabi/bin -mllvm -arm-enable-ehabi

LOCAL_SRC_FILES += $(target_src_files)
LOCAL_CFLAGS += $(target_c_flags)
LOCAL_C_INCLUDES += $(target_c_includes)
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE:= libcrypto
LOCAL_ADDITIONAL_DEPENDENCIES := $(local_additional_dependencies)
include $(BUILD_SHARED_LIBRARY)

#######################################
# host shared library
include $(CLEAR_VARS)
include $(LOCAL_PATH)/android-config.mk
LOCAL_SHARED_LIBRARIES := $(log_shared_libraries)

LOCAL_CC := $(LOCAL_PATH)/fipscc x86-fips-2.0 $(HOST_CC)
#LOCAL_CXX := $(LOCAL_PATH)/fipscc x86-fips-2.0 $(HOST_CXX)
LOCAL_PREBUILT_OBJ_FILES := x86-fips-2.0/lib/fipscanister.o

LOCAL_SRC_FILES += $(host_src_files)
LOCAL_CFLAGS += $(host_c_flags) -DPURIFY
LOCAL_C_INCLUDES += $(host_c_includes)
LOCAL_LDLIBS += -ldl
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE:= libcrypto-host
LOCAL_ADDITIONAL_DEPENDENCIES := $(local_additional_dependencies)
include $(BUILD_HOST_SHARED_LIBRARY)

########################################
# host static library, which is used by some SDK tools.

include $(CLEAR_VARS)
include $(LOCAL_PATH)/android-config.mk
LOCAL_SHARED_LIBRARIES := $(log_shared_libraries)

LOCAL_CC := $(LOCAL_PATH)/fipscc x86-fips-2.0 $(HOST_CC)
#LOCAL_CXX := $(LOCAL_PATH)/fipscc x86-fips-2.0 $(HOST_CXX)
LOCAL_PREBUILT_OBJ_FILES := x86-fips-2.0/lib/fipscanister.o

LOCAL_SRC_FILES += $(host_src_files)
LOCAL_CFLAGS += $(host_c_flags) -DPURIFY
LOCAL_C_INCLUDES += $(host_c_includes)
LOCAL_LDLIBS += -ldl
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE:= libcrypto_static
LOCAL_ADDITIONAL_DEPENDENCIES := $(local_additional_dependencies)
include $(BUILD_HOST_STATIC_LIBRARY)
