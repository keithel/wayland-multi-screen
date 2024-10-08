/****************************************************************************
**
** Copyright (C) 2017 The Qt Company Ltd.
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

import QtQuick 2.8
import QtWayland.Compositor 1.0
import QtQuick.Window 2.3

WaylandOutput {
    id: screen
    property variant viewsBySurface: ({})
    property alias surfaceArea: background
    property alias text: t.text
    property alias screen: win.screen
    sizeFollowsWindow: true

    property bool windowed: false

    window: Window {
        id: win
        x: Screen.virtualX
        y: Screen.virtualY
        width: 800
        height: 800
        visibility: windowed ? Window.Windowed : Window.FullScreen
        visible: true

        WaylandMouseTracker {
            id: mouseTracker
            anchors.fill: parent
            windowSystemCursorEnabled: !clientCursor.visible

            Rectangle {
                anchors.fill: parent
                id: background

                Text {
                    id: t
                    anchors.centerIn: parent
                    font.pointSize: 72
                }
            }

            WaylandCursorItem {
                id: clientCursor
                inputEventsEnabled: false
                x: mouseTracker.mouseX
                y: mouseTracker.mouseY
                seat: comp.defaultSeat
                visible: surface !== null && mouseTracker.containsMouse
            }
        }
        Shortcut {
            sequence: "Ctrl+Alt+Backspace"
            onActivated: Qt.quit()
        }

        onScreenChanged: {
            console.log(win, "screen changed", !!win.screen ? win.screen.name : "no screen")
        }

        Component.onCompleted: console.log(win, "on screen", screen.text, "created. visible:",win.visible)
        Component.onDestruction: console.log(win, "on screen", screen.text, "destroyed")
    }
    Component.onCompleted: console.log(screen, screen.text, "created.")
    Component.onDestruction: console.log(screen, screen.text, "destroyed")
}
