ARCHS = arm64
TARGET := iphone:clang:latest:17.0
PACKAGE_VERSION = 1.1.0

# Rootless 越狱路径（Bootstrap/Dopamine/Palera1n）
THEOS_PACKAGE_SCHEME = rootless

# 本地测试时可以设置
# THEOS_DEVICE_IP = localhost
# THEOS_DEVICE_PORT = 2222

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PowercutsClone

PowercutsClone_FILES = Tweak.x
PowercutsClone_CFLAGS = -fobjc-arc
PowercutsClone_FRAMEWORKS = UIKit Foundation Intents UserNotifications AVFoundation

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall Shortcuts"
