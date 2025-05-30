INSTALL_TARGET_PROCESSES = Messenger
PACKAGE_VERSION = 1.1.0
ARCHS = arm64

TARGET = iphone:clang:latest:15.0

include $(THEOS)/makefiles/common.mk

SUBPROJECTS += keychainfix

TWEAK_NAME = SNMessenger
$(TWEAK_NAME)_FRAMEWORKS = UIKit Foundation AVFoundation AVKit CoreMotion GameController VideoToolbox Accelerate CoreMedia CoreImage CoreGraphics ImageIO Photos CoreServices SystemConfiguration SafariServices Security QuartzCore WebKit SceneKit
$(TWEAK_NAME)_FILES = $(wildcard *.xm Settings/*.mm)
$(TWEAK_NAME)_CCFLAGS = -std=c++17
$(TWEAK_NAME)_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
