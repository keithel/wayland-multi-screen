/****************************************************************************
**
** Copyright (C) 2017 The Qt Company Ltd.
** Copyright (C) 2017 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
** Contact: http://www.qt-project.org/legal
**
** This file is part of the examples of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** BSD License Usage
** Alternatively, you may use this file under the terms of the BSD license
** as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of The Qt Company Ltd nor the names of its
**     contributors may be used to endorse or promote products derived
**     from this software without specific prior written permission.
**
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
** $QT_END_LICENSE$
**
****************************************************************************/

import QtQml 2.2
import QtQuick 2.0
import QtQuick.Window 2.3 as Window
import QtWayland.Compositor 1.3
import QtQml.Models 2.1

WaylandCompositor {
    id: comp

    property var waylandScreens: []
    property var shellSurfaces: []
    property bool headless: false
    property var headlessScreen: null

    Component {
        id: waylandScreenComponent
        Screen {}
    }

    Component {
        id: chromeComponent
        Chrome {}
    }

    Component {
        id: moveItemComponent
        Item {}
    }

    Item {
        id: rootItem
    }

    WlShell {
        onWlShellSurfaceCreated: handleShellSurfaceCreated(shellSurface)
    }

    XdgShellV6 {
        onToplevelCreated: handleShellSurfaceCreated(xdgSurface)
    }

    XdgShell {
        onToplevelCreated: {
            console.log("XdgShell onToplevelCreated", xdgSurface)
            handleShellSurfaceCreated(xdgSurface)
        }
    }

    function createShellSurfaceItem(shellSurface, moveItem, output) {
        var parentSurfaceItem = output.viewsBySurface[shellSurface.parentSurface];
        var parent = parentSurfaceItem || output.surfaceArea;
        var item = chromeComponent.createObject(parent, {
            "shellSurface": shellSurface,
            "moveItem": moveItem,
            "output": output
        });
        if (parentSurfaceItem) {
            item.x += output.position.x;
            item.y += output.position.y;
        }
        output.viewsBySurface[shellSurface.surface] = item;
        if (comp.shellSurfaces.indexOf(shellSurface) === -1) {
            console.log("storing shellsurface", shellSurface)
            comp.shellSurfaces.push(shellSurface)
        }
    }

    function createShellSurfaceItemForScreen(shellSurface, screen) {
        if (!shellSurface) {
            console.log("createShellSurfaceItemForScreen: undefined shellsurface. Exit")
            return
        }
        console.log("createShellSurfaceItemForScreen:", shellSurface, !!screen ? screen.text : "no screen")
        if (!screen) {
            return
        }
        console.log("create shellsurface item on screen", screen.text)
        var moveItem = moveItemComponent.createObject(rootItem, {
            "x": screen.position.x,
            "y": screen.position.y,
            "width": Qt.binding(function() { return shellSurface.surface.width; }),
            "height": Qt.binding(function() { return shellSurface.surface.height; })
        });
        createShellSurfaceItem(shellSurface, moveItem, screen);
    }

    function handleShellSurfaceCreated(shellSurface) {
        // when there are multiple physical screens,
        // create shellsurfaceitem for screen 0 by default
        var screen = comp.headless ? comp.headlessScreen : comp.waylandScreens[0]
        createShellSurfaceItemForScreen(shellSurface, screen)
    }

    function createWaylandScreen(screen) {
        let waylandScreen = null
        if (!!screen)
        {
            waylandScreen = waylandScreenComponent.createObject(comp,
                                                         {
                                                            "surfaceArea.color": "lightsteelblue",
                                                            "text": screen.name,
                                                             "compositor": comp,
                                                             "screen": screen,
                                                             position: Qt.point(screen.virtualX, screen.virtualY),
                                                         });
            if (waylandScreen !== null) {
                console.log("wayland screen", waylandScreen.text,
                            "created. geometry.x", waylandScreen.geometry.x,
                            "y", waylandScreen.geometry.y)
            } else {
                console.log("error creating waylandScreen for screen", screen.name);
            }
        }
        return waylandScreen
    }

    function createHeadlessWaylandScreen(screen) {
        if (!!screen && screen.name === "qt_Headless") {
            let waylandScreen = createWaylandScreen(screen)
            if (!!waylandScreen) {
                comp.headlessScreen = waylandScreen
                comp.headless = true
                //delay shellsurface item creation
                shellSurfaceItemTimer.delayCreation(true)
            }
        }
    }

    function closeHeadlessWaylandScreen(screens) {
        if (!comp.headlessScreen) {
            return
        }

        let found = false
        for (let i = 0; i < screens.length; i++) {
            if (screens[i].name === "qt_Headless") {
                found = true
                break
            }
        }
        console.log("close screen", comp.headlessScreen.text, !found)
        if (!found) {
            comp.headlessScreen.window.close()
            comp.headlessScreen.window.screen = null
            comp.headless = false
        }
    }

    function createWaylandScreens(screens) {
        // check if there is a non-headless screen
        let headlessScreen = null
        for (let i = 0; i < screens.length; i++) {
            if (screens[i].name === "qt_Headless") {
               headlessScreen = screens[i]
                break
            }
        }

        if (!comp.headless && !!headlessScreen) {
            if (!comp.headlessScreen) {
                // create a wayland screen for headless screen
                createHeadlessWaylandScreen(headlessScreen)
            } else {
                // show the window on headless screen
                comp.headlessScreen.window.screen = headlessScreen
                comp.headlessScreen.window.show()
            }

            // After the wayland screen is created, set compositor's
            // defaultOutput to headlessScreen
            if (!!comp.headlessScreen) {
                // set compositor's defaultOutput to headlessScreen
                comp.defaultOutput = comp.headlessScreen
                comp.headless = true
            }
        }
        // do nothing if it is already on a headless screen
        else if (comp.headless && screens.length === 1 && !!headlessScreen) {
            console.log("headless screen already, ignore...")
        }
        else {
            // create wayland screens for physical screens
            for (let i = 0; i < screens.length; i++) {
                if (screens[i].name === "qt_Headless") {
                    continue
                }
                let found = false
                for (let j = 0; j < waylandScreens.length; j++) {
                    if (screens[i].name === waylandScreens[j].text) {
                        found = true
                        // set the screen and open the window
                        waylandScreens[j].window.screen = screens[i]
                        waylandScreens[j].window.show()
                        break
                    }
                }
                console.log("screen", screens[i].name, "found", found)
                if (!found) {
                    let waylandScreen = comp.createWaylandScreen(screens[i])
                    if (!!waylandScreen) {
                        comp.waylandScreens.push(waylandScreen)

                        //delay shellsurface item creation
                        shellSurfaceItemTimer.delayCreation(false)
                    }
                }
            }
            // set compositor's defaultoutput
            comp.defaultOutput = waylandScreens[0]
        }
    }

    function closeWaylandScreens(screens) {
        //find screens to removed
        let waylandScreensToRemove = []

        for (let wIndex = 0; wIndex < comp.waylandScreens.length; wIndex++) {
            let waylandScreenName = comp.waylandScreens[wIndex].text
            let found = false
            for (let qIndex = 0; qIndex < screens.length; qIndex++) {
                if (waylandScreenName === screens[qIndex].name) {
                    found = true
                    break
                }
            }
            console.log("close screen", waylandScreens[wIndex].text, !found)
            if (!found) {
                waylandScreens[wIndex].window.close()
                waylandScreens[wIndex].window.screen = null
            }
        }

        closeHeadlessWaylandScreen(screens)
    }

    function updateWaylandScreens(screens) {
        comp.createWaylandScreens(screens)
        comp.closeWaylandScreens(screens)
        console.log("wayland screens:", waylandScreens.length, "headless wayland screen:", headless ? 1 : 0)
    }

    function handleScreensChanged() {
        let qscreens = Qt.application.screens
        console.log("handle screensChanged:")
        for (let i = 0; i < qscreens.length; i++) {
            console.log("     screen", qscreens[i].name)
        }
        comp.updateWaylandScreens(qscreens)
    }

    Component.onCompleted: {
        Qt.application.screensChanged.connect(comp.handleScreensChanged)
        comp.updateWaylandScreens(Qt.application.screens)
    }

    Timer {
        id: shellSurfaceItemTimer
        property bool headless: false
        function delayCreation(headless) {
            shellSurfaceItemTimer.headless = headless
            shellSurfaceItemTimer.start()
        }

        interval: 500
        repeat: false
        running: false
        onTriggered: {
            console.log("shellsurfaces:", comp.shellSurfaces.length)
            let waylandScreen = shellSurfaceItemTimer.headless ?  comp.headlessScreen : comp.waylandScreens[comp.waylandScreens.length-1]
            for (let i = 0; i < comp.shellSurfaces.length; i++) {
                comp.createShellSurfaceItemForScreen(comp.shellSurfaces[i], waylandScreen)
            }
        }
    }
}
