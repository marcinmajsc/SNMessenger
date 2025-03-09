INSTALL_TARGET_PROCESSES = Messenger
PACKAGE_VERSION = 1.1.0
ARCHS = arm64

ifeq ($(ROOTLESS), 1)
    THEOS_PACKAGE_SCHEME = rootless
    TARGET = iphone:clang:latest:15.0
else
    TARGET = iphone:clang:latest:12.4
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SNMessenger
$(TWEAK_NAME)_FILES = $(wildcard *.xm Settings/*.m)
$(TWEAK_NAME)_CCFLAGS = -std=c++17
$(TWEAK_NAME)_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
