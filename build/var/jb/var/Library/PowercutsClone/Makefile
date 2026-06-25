ARCHS = arm64
TARGET := iphone:clang:latest:17.0
THEOS_DEVICE_IP = localhost
THEOS_DEVICE_PORT = 2222
PACKAGE_VERSION = 1.0.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PowercutsClone

PowercutsClone_FILES = Tweak.x
PowercutsClone_CFLAGS = -fobjc-arc
PowercutsClone_FRAMEWORKS = UIKit Foundation Intents UserNotifications AVFoundation

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall Shortcuts"
