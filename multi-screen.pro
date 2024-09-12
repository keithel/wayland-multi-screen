QT += gui qml

SOURCES += \
    main.cpp

OTHER_FILES = \
    qml/main.qml \

RESOURCES += multi-screen.qrc

kmsconfig.files = kmsconfig.json
kmsconfig.path = .

# target.path = $$[QT_INSTALL_EXAMPLES]/wayland/multi-screen
target.path = /home/root/multi-screen
sources.files = $$SOURCES $$HEADERS $$RESOURCES $$FORMS multi-screen.pro
# sources.path = $$[QT_INSTALL_EXAMPLES]/wayland/multi-screen
sources.path = multi-screen
#INSTALLS += target sources
INSTALLS += target kmsconfig


DISTFILES += \
    kmsconfig.json \
    qml/HeadlessScreen.qml \
    qml/Screen.qml \
    qml/Chrome.qml
