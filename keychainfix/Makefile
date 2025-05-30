TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = Messenger


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = keychainfix

keychainfix_FILES = Tweak.x
keychainfix_FRAMEWORKS = UIKit Foundation Security
keychainfix_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
