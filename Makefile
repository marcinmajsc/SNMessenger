ARCHS = arm64
PACKAGE_VERSION = 1.0.0
TARGET = iphone:clang:latest:12.4
INSTALL_TARGET_PROCESSES = Messenger

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SNMessenger
$(TWEAK_NAME)_FILES = $(wildcard *.xm Settings/*.m)
$(TWEAK_NAME)_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
