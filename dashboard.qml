/******************************************************************************
 *                                                                            *
 *   RACE DASH PRO - Professional Racing Dashboard                           *
 *                                                                            *
 *   Автор:     Бухлаков Евгений                                              *
 *   Дата:      29 апреля 2026 г.                                             *
 *   Версия:    3.0                                                           *
 *   Лицензия:  MIT                                                           *
 *                                                                            *
 *   Telegram:  @race_dash_pro                                                *
 *   GitHub:    https://github.com/buhlakov/race-dash-pro                     *
 *                                                                            *
 ******************************************************************************/

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.0

ApplicationWindow {
    visible: true
    width: 800
    height: 480
    title: "RACE DASH PRO"
    color: "#0a0c10"

    // ======================== СВОЙСТВА ========================
    
    property bool controlPanelVisible: false
    property bool graphPanelVisible: false
    property bool limitsPanelVisible: false
    property bool settingsPanelVisible: false
    property bool errorPanelVisible: false
    property bool splashVisible: true
    property bool alertBlink: false
    property real dragStartX: 0
    
    // Текущая цветовая схема
    property color themePrimary: car.panel_theme === "blue" ? "#00b4d8" : (car.panel_theme === "red" ? "#e63946" : "#f4a261")
    property color themeSecondary: car.panel_theme === "blue" ? "#004d66" : (car.panel_theme === "red" ? "#662222" : "#664422")
    property color themeAlert: car.panel_theme === "blue" ? "#e63946" : (car.panel_theme === "red" ? "#ff6b6b" : "#ff5555")
    property color themeBg: "#0a0c10"

    // Таймер для мигания предупреждений
    Timer {
        id: blinkTimer
        interval: 500
        running: car.global_alert
        repeat: true
        onTriggered: alertBlink = !alertBlink
        onRunningChanged: if (!running) alertBlink = false
    }

    // ======================== ФУНКЦИИ ========================
    
    function rpmToAngle(rpm) {
        return -125 + (Math.min(rpm, 8000) / 8000) * 250
    }
    
    function closeAllPanels() {
        controlPanelVisible = false
        graphPanelVisible = false
        limitsPanelVisible = false
        settingsPanelVisible = false
        errorPanelVisible = false
        controlPanelAnimation.stop()
        graphPanelAnimation.stop()
        limitsPanelAnimation.stop()
        settingsPanelAnimation.stop()
        errorPanelAnimation.stop()
        dimOverlay.opacity = 0
        dimOverlay.visible = false
    }

    function getBluetoothIcon() {
        if (!car.bluetooth_enabled) return "🔘"
        if (car.bt_transfer_active) return "📡"
        if (car.bt_connected) return "🔷"
        return "🔍"
    }

    function getBluetoothStatusText() {
        if (!car.bluetooth_enabled) return ""
        if (car.bt_transfer_active) return car.bt_transfer_progress + "%"
        if (car.bt_connected) return "ON"
        return "SCAN"
    }

    function getBluetoothTooltip() {
        if (!car.bluetooth_enabled) return "Bluetooth выключен"
        if (car.bt_transfer_active) return "Передача данных... " + car.bt_transfer_progress + "%"
        if (car.bt_connected) return "Подключено: " + car.bt_connected_device
        return "Bluetooth вкл. Нажмите для настройки"
    }

    // ======================== ЗАСТАВКА ========================
    
    Rectangle {
        id: splashScreen
        anchors.fill: parent
        color: "#050608"
        z: 1000
        visible: splashVisible
        
        Text {
            id: motorsportText
            anchors.centerIn: parent
            text: "RACE DASH PRO"
            color: "#e63946"
            font.pixelSize: 42
            font.bold: true
            font.family: "Monospace"
            letterSpacing: 15
            opacity: 0
            
            SequentialAnimation on opacity {
                running: splashVisible
                NumberAnimation { from: 0; to: 1; duration: 600 }
                PauseAnimation { duration: 400 }
                NumberAnimation { from: 1; to: 0.2; duration: 800 }
                NumberAnimation { from: 0.2; to: 0; duration: 500 }
            }
            
            layer.enabled: true
            layer.effect: Glow {
                color: "#e63946"
                spread: 0.2
                samples: 20
                transparentBorder: true
            }
        }
        
        Text {
            anchors.top: motorsportText.bottom
            anchors.topMargin: 15
            anchors.horizontalCenter: parent.horizontalCenter
            text: "MOTORSPORT"
            color: "#8a8f99"
            font.pixelSize: 12
            font.family: "Monospace"
            letterSpacing: 8
            opacity: 0
            
            SequentialAnimation on opacity {
                running: splashVisible
                PauseAnimation { duration: 700 }
                NumberAnimation { from: 0; to: 1; duration: 500 }
                PauseAnimation { duration: 600 }
                NumberAnimation { from: 1; to: 0; duration: 400 }
            }
        }
        
        // Шестерни
        Image {
            source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><circle cx='50' cy='50' r='20' fill='none' stroke='#00b4d8' stroke-width='8'/><circle cx='50' cy='50' r='8' fill='#00b4d8'/><rect x='46' y='12' width='8' height='25' fill='#00b4d8'/><rect x='46' y='63' width='8' height='25' fill='#00b4d8'/><rect x='12' y='46' width='25' height='8' fill='#00b4d8'/><rect x='63' y='46' width='25' height='8' fill='#00b4d8'/><rect x='24' y='24' width='8' height='20' fill='#00b4d8' transform='rotate(45 28 34)'/><rect x='68' y='56' width='8' height='20' fill='#00b4d8' transform='rotate(45 72 66)'/><rect x='56' y='68' width='20' height='8' fill='#00b4d8' transform='rotate(45 66 72)'/><rect x='24' y='56' width='20' height='8' fill='#00b4d8' transform='rotate(-45 34 60)'/></svg>"
            width: 85; height: 85
            x: parent.width * 0.12; y: parent.height * 0.25
            opacity: 0.9
            RotationAnimator { target: parent; from: 0; to: 360; duration: 4200; loops: Animation.Infinite; running: splashVisible }
        }
        
        Image {
            source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><circle cx='50' cy='50' r='18' fill='none' stroke='#e63946' stroke-width='7'/><circle cx='50' cy='50' r='7' fill='#e63946'/><rect x='47' y='15' width='6' height='22' fill='#e63946'/><rect x='47' y='63' width='6' height='22' fill='#e63946'/><rect x='15' y='47' width='22' height='6' fill='#e63946'/><rect x='63' y='47' width='22' height='6' fill='#e63946'/><rect x='26' y='26' width='6' height='18' fill='#e63946' transform='rotate(45 29 35)'/><rect x='68' y='56' width='6' height='18' fill='#e63946' transform='rotate(45 71 65)'/></svg>"
            width: 70; height: 70
            x: parent.width * 0.78; y: parent.height * 0.2
            opacity: 0.9
            RotationAnimator { target: parent; from: 360; to: 0; duration: 3600; loops: Animation.Infinite; running: splashVisible }
        }
        
        Image {
            source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><circle cx='50' cy='50' r='14' fill='none' stroke='#4CAF50' stroke-width='6'/><circle cx='50' cy='50' r='5' fill='#4CAF50'/><rect x='47' y='20' width='6' height='18' fill='#4CAF50'/><rect x='47' y='62' width='6' height='18' fill='#4CAF50'/><rect x='20' y='47' width='18' height='6' fill='#4CAF50'/><rect x='62' y='47' width='18' height='6' fill='#4CAF50'/></svg>"
            width: 55; height: 55
            x: parent.width * 0.65; y: parent.height * 0.58
            opacity: 0.8
            RotationAnimator { target: parent; from: 0; to: 360; duration: 2800; loops: Animation.Infinite; running: splashVisible }
        }
        
        Image {
            source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><circle cx='50' cy='50' r='16' fill='none' stroke='#f4a261' stroke-width='6'/><circle cx='50' cy='50' r='6' fill='#f4a261'/><rect x='47' y='17' width='6' height='20' fill='#f4a261'/><rect x='47' y='63' width='6' height='20' fill='#f4a261'/><rect x='17' y='47' width='20' height='6' fill='#f4a261'/><rect x='63' y='47' width='20' height='6' fill='#f4a261'/><rect x='28' y='28' width='6' height='16' fill='#f4a261' transform='rotate(45 31 36)'/><rect x='66' y='56' width='6' height='16' fill='#f4a261' transform='rotate(45 69 64)'/></svg>"
            width: 60; height: 60
            x: parent.width * 0.18; y: parent.height * 0.65
            opacity: 0.85
            RotationAnimator { target: parent; from: 360; to: 0; duration: 3300; loops: Animation.Infinite; running: splashVisible }
        }
        
        // Прогресс-бар
        Rectangle {
            anchors.top: motorsportText.bottom
            anchors.topMargin: 55
            anchors.horizontalCenter: parent.horizontalCenter
            width: 200
            height: 3
            color: "#2a2e35"
            radius: 1.5
            
            Rectangle {
                width: 0
                height: 3
                color: "#e63946"
                radius: 1.5
                SequentialAnimation {
                    running: splashVisible
                    NumberAnimation { target: parent; property: "width"; from: 0; to: 200; duration: 2200 }
                }
            }
        }
        
        // Автоматическое закрытие заставки
        SequentialAnimation {
            id: splashFadeOut
            NumberAnimation { target: splashScreen; property: "opacity"; to: 0; duration: 500 }
            ScriptAction { script: {
                splashScreen.visible = false
                splashScreen.opacity = 1
            } }
        }
        
        Timer {
            interval: 2800
            running: splashVisible
            onTriggered: splashFadeOut.start()
        }
    }

    // ======================== ОСНОВНОЙ КОНТЕНТ ========================
    
    Item {
        id: mainContent
        anchors.fill: parent
        visible: false
        opacity: 0
        enabled: visible
        
        Timer {
            running: true
            interval: 2850
            onTriggered: {
                mainContent.visible = true
                mainContent.opacity = 1
            }
        }

        // ======================== ОБРАБОТКА СВАЙПОВ ========================
        
        DragHandler {
            id: swipeHandler
            target: null
            acceptedDevices: PointerDevice.TouchScreen
            onActiveChanged: {
                if (active) {
                    dragStartX = centroid.pressPosition.x
                } else if (centroid.pressPosition.x !== undefined) {
                    var deltaX = centroid.position.x - dragStartX
                    if (deltaX > 80 && !controlPanelVisible && !graphPanelVisible && !limitsPanelVisible && !settingsPanelVisible && !errorPanelVisible) {
                        controlPanelVisible = true
                        controlPanelAnimation.start()
                    } else if (deltaX < -80 && !controlPanelVisible && !graphPanelVisible && !limitsPanelVisible && !settingsPanelVisible && !errorPanelVisible) {
                        graphPanelVisible = true
                        graphPanelAnimation.start()
                    }
                }
            }
        }

        // ======================== ЗАТЕМНЕНИЕ ========================
        
        Rectangle {
            id: dimOverlay
            anchors.fill: parent
            color: "#80000000"
            opacity: 0
            visible: false
            MouseArea { anchors.fill: parent; onClicked: closeAllPanels() }
        }

        // ======================== ГЛОБАЛЬНАЯ ТРЕВОГА ========================
        
        Rectangle {
            id: globalAlertOverlay
            anchors.fill: parent
            color: "transparent"
            border.color: alertBlink ? "#e63946" : "transparent"
            border.width: 4
            z: 50
            visible: car.global_alert
        }
        
        Rectangle {
            id: alertBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 32
            color: alertBlink ? "#e63946" : "#1a1c22"
            z: 51
            visible: car.global_alert
            
            Row {
                anchors.centerIn: parent
                spacing: 20
                Text { text: "⚠️ ПРЕВЫШЕНИЕ ЛИМИТОВ:"; color: "white"; font.bold: true; font.pixelSize: 12 }
                Repeater {
                    model: ["rpm","boost","coolant_temp","oil_temp","oil_pressure","fuel_pressure","voltage","lambda","egt","knock","ign_angle","tps"]
                    Text {
                        text: {
                            var alerts = JSON.parse(car.alerts_json)
                            if (alerts[modelData]) {
                                var paramName = {
                                    "rpm": "RPM", "boost": "Наддув", "coolant_temp": "ОЖ",
                                    "oil_temp": "Масло°C", "oil_pressure": "Давл.масла",
                                    "fuel_pressure": "Давл.топл.", "voltage": "Напряжение",
                                    "lambda": "Лямбда", "egt": "EGT", "knock": "Детонация",
                                    "ign_angle": "УОЗ", "tps": "Дроссель"
                                }[modelData] || modelData
                                return paramName + "!"
                            }
                            return ""
                        }
                        color: "white"
                        font.pixelSize: 11
                        font.bold: true
                    }
                }
            }
        }

        // ======================== ВЕРХНЯЯ ПАНЕЛЬ (TOP BAR) ========================
        
        Rectangle {
            id: topBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 45
            color: "#0d1117"
            border.color: "#1f242c"
            z: 20
            
            Row {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 15
                
                // Кнопка настроек
                Button {
                    id: settingsButton
                    width: 36; height: 30
                    text: "⚙️"
                    background: Rectangle {
                        color: settingsPanelVisible ? "#00b4d8" : "#1f242c"
                        radius: 6
                        border.color: "#2a2e35"
                        border.width: 1
                    }
                    contentItem: Text {
                        text: parent.text
                        color: settingsPanelVisible ? "white" : "#00b4d8"
                        font.pixelSize: 16
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        if (!settingsPanelVisible) {
                            settingsPanelVisible = true
                            settingsPanelAnimation.start()
                        } else {
                            closeAllPanels()
                        }
                    }
                }
                
                // Кнопка ошибок
                Button {
                    id: errorMenuButton
                    width: car.has_critical_errors ? 50 : 40
                    height: 30
                    background: Rectangle {
                        color: car.has_critical_errors ? "#e63946" : (car.error_count > 0 ? "#f4a261" : "#1f242c")
                        radius: 15
                        border.color: "#2a2e35"
                        border.width: 1
                    }
                    contentItem: Row {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: "⚠️"
                            color: "white"
                            font.pixelSize: 14
                        }
                        Text {
                            text: car.error_count > 0 ? car.error_count.toString() : ""
                            color: "white"
                            font.pixelSize: 10
                            font.bold: true
                            visible: car.error_count > 0
                        }
                    }
                    onClicked: {
                        if (!errorPanelVisible) {
                            errorPanelVisible = true
                            errorPanelAnimation.start()
                        } else {
                            closeAllPanels()
                        }
                    }
                }
                
                Text {
                    text: "🌍 " + car.latitude.toFixed(5) + " / " + car.longitude.toFixed(5)
                    color: "#8a8f99"
                    font.pixelSize: 11
                    verticalAlignment: Text.AlignVCenter
                }
                
                Rectangle {
                    width: 45; height: 25
                    color: "#1f242c"; radius: 4
                    Text {
                        anchors.centerIn: parent
                        text: car.gear
                        color: car.gear > 1 ? "#00b4d8" : "#e0e0e0"
                        font.bold: true
                        font.pixelSize: 14
                    }
                }
                
                Text {
                    text: car.boost_mode
                    color: car.boost_mode === "Race" ? "#e63946" : (car.boost_mode === "Sport" ? "#f4a261" : "#00b4d8")
                    font.bold: true
                    font.pixelSize: 13
                }
                
                Item { width: 20 }
                
                // Индикатор Wi-Fi (если подключён)
                Text {
                    text: car.wifi_connected_ssid ? "📶" : ""
                    color: "#00b4d8"
                    font.pixelSize: 12
                }
                
                // Индикатор Bluetooth
                Rectangle {
                    id: btCompactIndicator
                    width: 28
                    height: 28
                    radius: 14
                    color: car.bluetooth_enabled ? (car.bt_connected ? "#1a3a1a" : (car.bt_transfer_active ? "#3a2a1a" : "#1a2a3a")) : "#1a1a1a"
                    border.color: car.bluetooth_enabled ? (car.bt_connected ? "#4CAF50" : (car.bt_transfer_active ? "#f4a261" : "#00b4d8")) : "#5a606b"
                    border.width: 1
                    
                    Text {
                        anchors.centerIn: parent
                        text: getBluetoothIcon()
                        color: car.bluetooth_enabled ? (car.bt_connected ? "#4CAF50" : (car.bt_transfer_active ? "#f4a261" : "#00b4d8")) : "#5a606b"
                        font.pixelSize: 14
                        SequentialAnimation on opacity {
                            running: car.bt_transfer_active
                            loops: Animation.Infinite
                            NumberAnimation { from: 0.3; to: 1; duration: 250 }
                            NumberAnimation { from: 1; to: 0.3; duration: 250 }
                        }
                    }
                    ToolTip {
                        parent: btCompactIndicator
                        visible: btCompactMouse.containsMouse
                        text: getBluetoothTooltip()
                        delay: 500
                    }
                    MouseArea {
                        id: btCompactMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (!settingsPanelVisible) {
                                settingsPanelVisible = true
                                settingsPanelAnimation.start()
                            }
                        }
                    }
                }
                
                // Индикатор CAN
                Rectangle {
                    width: 70; height: 24
                    radius: 12
                    color: car.can_initialized ? (car.can_error ? "#3a1a1a" : "#1a3a1a") : "#1a1a1a"
                    border.color: car.can_initialized ? (car.can_error ? "#e63946" : "#4CAF50") : "#5a606b"
                    border.width: 1
                    Row {
                        anchors.centerIn: parent
                        spacing: 5
                        Text { text: "🔄"; color: car.can_initialized ? (car.can_error ? "#e63946" : "#4CAF50") : "#5a606b"; font.pixelSize: 10 }
                        Text { text: car.can_initialized ? (car.can_error ? "CAN ERR" : "CAN OK") : "CAN OFF"; color: car.can_initialized ? (car.can_error ? "#e63946" : "#4CAF50") : "#5a606b"; font.pixelSize: 8; font.bold: true }
                    }
                    ToolTip {
                        parent: parent
                        visible: canMouse.containsMouse
                        text: car.can_initialized ? (car.can_error ? "Ошибка CAN шины!" : "CAN шина активна, 500 кбит/с") : "CAN не инициализирован"
                        delay: 500
                    }
                    MouseArea { id: canMouse; anchors.fill: parent; hoverEnabled: true }
                }
                
                // Кнопка питания
                Rectangle {
                    id: powerButton
                    width: 50; height: 30
                    radius: 15
                    color: "transparent"
                    border.color: car.panel_power_state ? "#e63946" : "#2a2e35"
                    border.width: 2
                    
                    SequentialAnimation on border.color {
                        running: car.panel_power_state && !car.shutdown_in_progress
                        loops: Animation.Infinite
                        ColorAnimation { from: "#e63946"; to: "#ff6b6b"; duration: 1000 }
                        ColorAnimation { from: "#ff6b6b"; to: "#e63946"; duration: 1000 }
                    }
                    
                    Rectangle {
                        anchors.centerIn: parent
                        width: 12; height: 12; radius: 6
                        color: car.panel_power_state ? "#e63946" : "#5a606b"
                        SequentialAnimation on scale {
                            running: car.panel_power_state && !car.shutdown_in_progress
                            loops: Animation.Infinite
                            NumberAnimation { from: 1; to: 1.3; duration: 500 }
                            NumberAnimation { from: 1.3; to: 1; duration: 500 }
                        }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (!car.shutdown_in_progress) {
                                car.toggle_panel_power()
                            }
                        }
                    }
                    ToolTip {
                        parent: powerButton
                        visible: powerButtonMouse.containsMouse
                        text: car.panel_power_state ? "Выключить панель" : "Включить панель"
                        delay: 500
                    }
                    MouseArea {
                        id: powerButtonMouse
                        anchors.fill: parent
                        hoverEnabled: true
                    }
                }
            }
        }
        // ======================== ЦЕНТРАЛЬНЫЙ ТАХОМЕТР ========================
        
        Item {
            id: tachoContainer
            anchors.centerIn: parent
            width: 380
            height: 380
            z: 10
            
            Canvas {
                id: tachoCanvas
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    var cx = width/2, cy = height/2
                    var r = width/2 - 15
                    var start = -Math.PI/1.5
                    var end = Math.PI/1.5
                    
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, start, end)
                    ctx.lineWidth = 18
                    ctx.strokeStyle = "#2a2e35"
                    ctx.stroke()
                    
                    var percent = Math.min(car.rpm, 8000) / 8000
                    var activeEnd = start + (percent * (end - start))
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, start, activeEnd)
                    ctx.strokeStyle = themePrimary
                    ctx.stroke()
                }
                Connections { target: car; onRpmChanged: tachoCanvas.requestPaint() }
            }
            
            Image {
                id: needle
                source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><polygon points='50,10 60,45 95,50 60,55 50,90 40,55 5,50 40,45' fill='#e0e0e0'/></svg>"
                anchors.centerIn: parent
                width: 80
                height: 80
                transformOrigin: Item.Bottom
                rotation: rpmToAngle(car.rpm)
                Behavior on rotation { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
            }
            
            Rectangle {
                anchors.centerIn: parent
                width: 60; height: 60; radius: 30
                color: "#0a0c10"
                border.color: "#2a2e35"
                Text { anchors.centerIn: parent; text: "x1000"; color: "#8a8f99"; font.pixelSize: 10 }
            }
            
            Text {
                anchors.centerIn: parent
                y: parent.height * 0.65
                text: Math.round(car.rpm)
                color: "#e0e0e0"
                font.pixelSize: 42
                font.bold: true
                font.family: "Monospace"
            }
            Text {
                anchors.centerIn: parent
                y: parent.height * 0.75
                text: "RPM"
                color: "#e63946"
                font.pixelSize: 11
                font.bold: true
            }
        }

        // ======================== ЛЕВАЯ ПАНЕЛЬ (ТЕМПЕРАТУРЫ) ========================
        
        Column {
            id: leftTempColumn
            anchors.left: parent.left
            anchors.leftMargin: 15
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12
            
            // Охлаждающая жидкость
            Rectangle {
                width: 130; height: 70
                color: car.coolant_temp > 100 ? "#3a1a1a" : "#14171c"
                radius: 6
                border.color: car.coolant_temp > 100 ? "#e63946" : "#2a2e35"
                border.width: 2
                Column {
                    anchors.centerIn: parent
                    spacing: 5
                    Text { text: "COOLANT"; color: "#8a8f99"; font.pixelSize: 9; anchors.horizontalCenter: parent.horizontalCenter }
                    Text {
                        text: car.coolant_temp.toFixed(0) + "°C"
                        color: car.coolant_temp > 100 ? "#e63946" : (car.coolant_temp > 95 ? "#f4a261" : "#e0e0e0")
                        font.pixelSize: 20; font.bold: true
                    }
                }
            }
            
            // Температура масла
            Rectangle {
                width: 130; height: 70
                color: car.oil_temp > 110 ? "#3a1a1a" : "#14171c"
                radius: 6
                border.color: car.oil_temp > 110 ? "#e63946" : "#2a2e35"
                border.width: 2
                Column {
                    anchors.centerIn: parent
                    spacing: 5
                    Text { text: "OIL TEMP"; color: "#8a8f99"; font.pixelSize: 9; anchors.horizontalCenter: parent.horizontalCenter }
                    Text {
                        text: car.oil_temp.toFixed(0) + "°C"
                        color: car.oil_temp > 110 ? "#e63946" : (car.oil_temp > 100 ? "#f4a261" : "#e0e0e0")
                        font.pixelSize: 20; font.bold: true
                    }
                }
            }
            
            // Температура воздуха
            Rectangle {
                width: 130; height: 70
                color: "#14171c"
                radius: 6
                border.color: "#2a2e35"
                border.width: 2
                Column {
                    anchors.centerIn: parent
                    spacing: 5
                    Text { text: "AIR TEMP"; color: "#8a8f99"; font.pixelSize: 9; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: car.air_temp.toFixed(0) + "°C"; color: "#e0e0e0"; font.pixelSize: 20; font.bold: true }
                }
            }
            
            // EGT (Выхлопные газы)
            Rectangle {
                width: 130; height: 70
                color: car.egt > car.egt_critical ? "#3a1a1a" : (car.egt > car.egt_warning ? "#3a2a1a" : "#14171c")
                radius: 6
                border.color: car.egt > car.egt_critical ? "#e63946" : (car.egt > car.egt_warning ? "#f4a261" : "#2a2e35")
                border.width: 2
                Column {
                    anchors.centerIn: parent
                    spacing: 5
                    Text { text: "EGT"; color: "#8a8f99"; font.pixelSize: 9; anchors.horizontalCenter: parent.horizontalCenter }
                    Text {
                        text: car.egt.toFixed(0) + "°C"
                        color: car.egt > car.egt_critical ? "#e63946" : (car.egt > car.egt_warning ? "#f4a261" : "#e0e0e0")
                        font.pixelSize: 20; font.bold: true
                    }
                }
            }
        }

        // ======================== ПРАВАЯ ПАНЕЛЬ (ДАВЛЕНИЯ) ========================
        
        Column {
            id: rightPressColumn
            anchors.right: parent.right
            anchors.rightMargin: 15
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12
            
            // Давление наддува
            Rectangle {
                width: 130; height: 70
                color: "#14171c"
                radius: 6
                border.color: "#2a2e35"
                border.width: 2
                Column {
                    anchors.centerIn: parent
                    spacing: 5
                    Text { text: "BOOST"; color: "#8a8f99"; font.pixelSize: 9; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: car.boost.toFixed(1) + " bar"; color: car.boost > 1.5 ? "#00b4d8" : "#e0e0e0"; font.pixelSize: 20; font.bold: true }
                }
            }
            
            // Давление масла
            Rectangle {
                width: 130; height: 70
                color: car.oil_pressure < 1.0 ? "#3a1a1a" : "#14171c"
                radius: 6
                border.color: car.oil_pressure < 1.0 ? "#e63946" : "#2a2e35"
                border.width: 2
                Column {
                    anchors.centerIn: parent
                    spacing: 5
                    Text { text: "OIL PRESS"; color: "#8a8f99"; font.pixelSize: 9; anchors.horizontalCenter: parent.horizontalCenter }
                    Text {
                        text: car.oil_pressure.toFixed(1) + " bar"
                        color: car.oil_pressure < 1.0 ? "#e63946" : "#e0e0e0"
                        font.pixelSize: 20; font.bold: true
                    }
                }
            }
            
            // Давление топлива
            Rectangle {
                width: 130; height: 70
                color: "#14171c"
                radius: 6
                border.color: "#2a2e35"
                border.width: 2
                Column {
                    anchors.centerIn: parent
                    spacing: 5
                    Text { text: "FUEL PRESS"; color: "#8a8f99"; font.pixelSize: 9; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: car.fuel_pressure.toFixed(1) + " bar"; color: "#e0e0e0"; font.pixelSize: 20; font.bold: true }
                }
            }
            
            // Напряжение
            Rectangle {
                width: 130; height: 70
                color: car.voltage < 12.0 ? "#3a1a1a" : "#14171c"
                radius: 6
                border.color: car.voltage < 12.0 ? "#e63946" : "#2a2e35"
                border.width: 2
                Column {
                    anchors.centerIn: parent
                    spacing: 5
                    Text { text: "BATTERY"; color: "#8a8f99"; font.pixelSize: 9; anchors.horizontalCenter: parent.horizontalCenter }
                    Text {
                        text: car.voltage.toFixed(1) + " V"
                        color: car.voltage < 12.0 ? "#e63946" : "#e0e0e0"
                        font.pixelSize: 20; font.bold: true
                    }
                }
            }
        }

        // ======================== ДОПОЛНИТЕЛЬНАЯ ПАНЕЛЬ (ДЕТОНАЦИЯ, ЛЯМБДА) ========================
        
        Column {
            id: extraColumn
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 60
            spacing: 8
            
            Row {
                spacing: 15
                
                // Детонация 1
                Rectangle {
                    width: 100; height: 50
                    color: car.knock_occurred ? "#3a1a1a" : "#14171c"
                    radius: 6
                    border.color: car.knock_occurred ? "#e63946" : "#2a2e35"
                    border.width: 2
                    Column {
                        anchors.centerIn: parent; spacing: 3
                        Text { text: "KNOCK 1"; color: "#8a8f99"; font.pixelSize: 8; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: car.knock_1.toFixed(2) + " V"; color: car.knock_occurred ? "#e63946" : "#e0e0e0"; font.pixelSize: 16; font.bold: true }
                    }
                }
                
                // Детонация 2
                Rectangle {
                    width: 100; height: 50
                    color: car.knock_1 > 0.6 ? "#3a1a1a" : "#14171c"
                    radius: 6
                    border.color: car.knock_1 > 0.6 ? "#f4a261" : "#2a2e35"
                    border.width: 2
                    Column {
                        anchors.centerIn: parent; spacing: 3
                        Text { text: "KNOCK 2"; color: "#8a8f99"; font.pixelSize: 8; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: car.knock_2.toFixed(2) + " V"; color: car.knock_1 > 0.6 ? "#f4a261" : "#e0e0e0"; font.pixelSize: 16; font.bold: true }
                    }
                }
                
                // TPS (Дроссель)
                Rectangle {
                    width: 100; height: 50
                    color: car.tps_wide ? "#1a3a1a" : "#14171c"
                    radius: 6
                    border.color: car.tps_wide ? "#4CAF50" : "#2a2e35"
                    border.width: 2
                    Column {
                        anchors.centerIn: parent; spacing: 3
                        Text { text: "TPS"; color: "#8a8f99"; font.pixelSize: 8; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: car.tps.toFixed(0) + "%"; color: car.tps_wide ? "#4CAF50" : "#e0e0e0"; font.pixelSize: 16; font.bold: true }
                    }
                }
                
                // Угол зажигания
                Rectangle {
                    width: 100; height: 50
                    color: car.ign_angle < 10 ? "#3a1a1a" : (car.ign_angle > 35 ? "#1a2a3a" : "#14171c")
                    radius: 6
                    border.color: car.ign_angle < 10 ? "#e63946" : (car.ign_angle > 35 ? "#00b4d8" : "#2a2e35")
                    border.width: 2
                    Column {
                        anchors.centerIn: parent; spacing: 3
                        Text { text: "IGN"; color: "#8a8f99"; font.pixelSize: 8; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: car.ign_angle.toFixed(1) + "°"; color: car.ign_angle < 10 ? "#e63946" : (car.ign_angle > 35 ? "#00b4d8" : "#e0e0e0"); font.pixelSize: 16; font.bold: true }
                    }
                }
                
                // Лямбда
                Rectangle {
                    width: 100; height: 50
                    color: car.lambda_lean ? "#3a1a1a" : (car.lambda_rich ? "#3a1a1a" : "#14171c")
                    radius: 6
                    border.color: car.lambda_lean ? "#e63946" : (car.lambda_rich ? "#f4a261" : "#2a2e35")
                    border.width: 2
                    Column {
                        anchors.centerIn: parent; spacing: 3
                        Text { text: "LAMBDA"; color: "#8a8f99"; font.pixelSize: 8; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: car.lambda_value.toFixed(3); color: car.lambda_lean ? "#e63946" : (car.lambda_rich ? "#f4a261" : "#00b4d8"); font.pixelSize: 16; font.bold: true }
                    }
                }
                
                // AFR
                Rectangle {
                    width: 100; height: 50
                    color: "#14171c"
                    radius: 6
                    border.color: "#2a2e35"
                    border.width: 2
                    Column {
                        anchors.centerIn: parent; spacing: 3
                        Text { text: "AFR"; color: "#8a8f99"; font.pixelSize: 8; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: car.afr_value.toFixed(1); color: "#00b4d8"; font.pixelSize: 16; font.bold: true }
                    }
                }
            }
        }

        // ======================== НИЖНЯЯ ПАНЕЛЬ (BOTTOM BAR) ========================
        
        Rectangle {
            id: bottomBar
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 45
            color: "#0d1117"
            border.color: "#1f242c"
            z: 20
            
            Row {
                anchors.centerIn: parent
                spacing: 30
                
                // Температура RPi
                Row { spacing: 8
                    Text { text: "🌡️ RPi: " + car.rpi_temp.toFixed(0) + "°C"; color: car.rpi_temp > 80 ? "#e63946" : (car.rpi_temp > 70 ? "#f4a261" : "#8bc34a"); font.pixelSize: 11; font.family: "Monospace" }
                    Rectangle { width: 50; height: 6; radius: 3; color: "#2a2e35"
                        Rectangle { width: Math.min(50, (car.rpi_temp / 85) * 50); height: 6; radius: 3; color: car.rpi_temp > 80 ? "#e63946" : (car.rpi_temp > 70 ? "#f4a261" : "#8bc34a") }
                    }
                }
                
                // ШИМ вентилятора
                Row { spacing: 8
                    Text { text: "FAN PWM: " + car.fan_pwm + "%"; color: car.fan_active ? "#00b4d8" : "#5a606b"; font.pixelSize: 11 }
                    Rectangle { width: 60; height: 6; radius: 3; color: "#2a2e35"
                        Rectangle { width: (car.fan_pwm / 100) * 60; height: 6; radius: 3; color: "#e63946" }
                    }
                }
                
                // ШИМ насоса
                Row { spacing: 8
                    Text { text: "PUMP PWM: " + car.pump_pwm + "%"; color: "#5a606b"; font.pixelSize: 11 }
                    Rectangle { width: 60; height: 6; radius: 3; color: "#2a2e35"
                        Rectangle { width: (car.pump_pwm / 100) * 60; height: 6; radius: 3; color: "#f4a261" }
                    }
                }
                
                // Launch Control
                Rectangle {
                    width: 85; height: 28
                    color: car.launch_active ? "#e63946" : "#1f242c"
                    radius: 4
                    Text { anchors.centerIn: parent; text: "LAUNCH"; color: "white"; font.bold: true; font.pixelSize: 10 }
                    visible: car.launch_active
                }
                
                // Anti-Lag
                Rectangle {
                    width: 85; height: 28
                    color: car.antilag_active ? "#f4a261" : "#1f242c"
                    radius: 4
                    Text { anchors.centerIn: parent; text: "ANTILAG"; color: "white"; font.bold: true; font.pixelSize: 10 }
                    visible: car.antilag_active
                }
            }
        }

        // ======================== ПАНЕЛЬ УПРАВЛЕНИЯ (СВАЙП ВПРАВО) ========================
        
        Rectangle {
            id: controlPanel
            width: 320
            height: parent.height
            anchors.right: parent.right
            anchors.rightMargin: -width
            color: "#14171c"
            border.color: "#2a2e35"
            border.width: 2
            z: 60
            
            Behavior on anchors.rightMargin {
                NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
            }
            
            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 20
                
                Text { text: "РУЧНОЕ УПРАВЛЕНИЕ"; color: "#00b4d8"; font.pixelSize: 18; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                Rectangle { height: 1; width: parent.width; color: "#2a2e35" }
                
                Column { width: parent.width
                    Text { text: "PUMP PWM"; color: "#e0e0e0"; font.pixelSize: 12 }
                    Row { spacing: 15
                        Slider { id: pumpSlider; from: 0; to: 100; stepSize: 1; width: parent.parent.width - 70
                            value: car.pump_pwm; onMoved: car.updatePumpPwm(value) }
                        Text { text: Math.round(pumpSlider.value) + "%"; color: "#f4a261"; font.pixelSize: 14 }
                    }
                }
                
                Column { width: parent.width
                    Text { text: "FAN PWM"; color: "#e0e0e0"; font.pixelSize: 12 }
                    Row { spacing: 15
                        Slider { id: fanSlider; from: 0; to: 100; stepSize: 1; width: parent.parent.width - 70
                            value: car.fan_pwm; onMoved: car.updateFanPwm(value) }
                        Text { text: Math.round(fanSlider.value) + "%"; color: "#e63946"; font.pixelSize: 14 }
                    }
                }
                
                Row { spacing: 20
                    Column { width: 120
                        Text { text: "FUEL PUMP"; color: "#e0e0e0"; font.pixelSize: 12 }
                        Button { width: 100; height: 40; text: car.fuel_pump_active ? "ON" : "OFF"
                            background: Rectangle { color: car.fuel_pump_active ? "#e63946" : "#2a2e35"; radius: 5 }
                            contentItem: Text { text: parent.text; color: "white"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            onClicked: car.updateFuelPump(!car.fuel_pump_active)
                        }
                    }
                    Column { width: 120
                        Text { text: "BOOST VALVE"; color: "#e0e0e0"; font.pixelSize: 12 }
                        Button { width: 100; height: 40; text: car.boost_valve_active ? "ON" : "OFF"
                            background: Rectangle { color: car.boost_valve_active ? "#00b4d8" : "#2a2e35"; radius: 5 }
                            contentItem: Text { text: parent.text; color: "white"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            onClicked: car.updateBoostValve(!car.boost_valve_active)
                        }
                    }
                }
                
                // Демо режим
                Column {
                    width: parent.width
                    spacing: 8
                    Button {
                        width: parent.width; height: 45
                        text: car.demo_mode_active ? "🎬 ДЕМО РЕЖИМ АКТИВЕН (" + car.demo_time_left + "с)" : "🎬 ДЕМО РЕЖИМ"
                        background: Rectangle { color: car.demo_mode_active ? "#e63946" : "#2a2e35"; radius: 6; border.color: car.demo_mode_active ? "#ff6b6b" : "#00b4d8"; border.width: 1 }
                        contentItem: Text { text: parent.text; color: car.demo_mode_active ? "white" : "#00b4d8"; font.bold: true; font.pixelSize: 14; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        onClicked: { if (!car.demo_mode_active) car.start_demo_mode() }
                        enabled: !car.demo_mode_active
                    }
                    Text { text: "▶ 30 секунд динамической демонстрации\n   имитация разгона, температур и графиков"; color: "#5a606b"; font.pixelSize: 9; wrapMode: Text.WordWrap; width: parent.width; horizontalAlignment: Text.AlignHCenter }
                }
                
                Rectangle { height: 1; width: parent.width; color: "#2a2e35" }
                Text { text: "← Нажмите на фон для закрытия"; color: "#8a8f99"; font.pixelSize: 10; anchors.horizontalCenter: parent.horizontalCenter }
                Text { text: "ТЕКУЩИЕ: Насос " + car.pump_pwm + "%  Вент " + car.fan_pwm + "%"; color: "#5a606b"; font.pixelSize: 10 }
            }
        }
        // ======================== ПАНЕЛЬ ГРАФИКОВ (СВАЙП ВЛЕВО) ========================
        
        Rectangle {
            id: graphPanel
            width: parent.width - 30
            height: parent.height
            anchors.left: parent.left
            anchors.leftMargin: -width
            color: "#14171c"
            border.color: "#2a2e35"
            border.width: 2
            z: 60
            
            Behavior on anchors.leftMargin {
                NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
            }
            
            Column {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8
                
                Row {
                    width: parent.width; height: 40
                    spacing: 10
                    Text { text: "📊 ГРАФИКИ В РЕАЛЬНОМ ВРЕМЕНИ"; color: "#00b4d8"; font.pixelSize: 14; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                    Item { width: 20 }
                    Button {
                        width: 100; height: 32
                        text: car.logging_active ? "⏹️ СТОП ЛОГ" : "▶️ СТАРТ ЛОГ"
                        background: Rectangle { color: car.logging_active ? "#e63946" : "#4CAF50"; radius: 4 }
                        contentItem: Text { text: parent.text; color: "white"; font.bold: true; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        onClicked: { if (car.logging_active) car.stopLogging(); else car.startLogging() }
                    }
                    Text { text: car.logging_active ? "📝 " + car.log_filename : ""; color: "#f4a261"; font.pixelSize: 9; anchors.verticalCenter: parent.verticalCenter }
                }
                
                Rectangle { height: 1; width: parent.width; color: "#2a2e35" }
                
                ScrollView {
                    width: parent.width; height: parent.height - 80
                    clip: true
                    
                    Column {
                        width: graphPanel.width - 20
                        spacing: 12
                        
                        // RPM график
                        Rectangle {
                            width: parent.width; height: 130
                            color: "#0d1117"
                            border.color: "#2a2e35"; border.width: 1; radius: 4
                            Column {
                                anchors.fill: parent; anchors.margins: 6; spacing: 4
                                Row {
                                    spacing: 10
                                    Text { text: "ОБОРОТЫ (RPM)"; color: "#00b4d8"; font.pixelSize: 10; font.bold: true }
                                    Text { text: { var d=JSON.parse(car.history_json); return d.rpm?.slice(-1)[0]?.toFixed(0)||"0" }; color: "#e0e0e0"; font.pixelSize: 10 }
                                }
                                Canvas {
                                    width: parent.width; height: 100
                                    onPaint: {
                                        var ctx = getContext("2d")
                                        ctx.clearRect(0, 0, width, height)
                                        var data = JSON.parse(car.history_json)
                                        var values = data.rpm
                                        if (!values || values.length < 2) return
                                        var w = width, h = height, step = w / (values.length - 1)
                                        var minVal = 0, maxVal = 8000, range = maxVal - minVal
                                        // Сетка
                                        ctx.strokeStyle = "#2a2e35"; ctx.lineWidth = 0.5
                                        for (var i = 0; i <= 6; i++) { var x = (w/6)*i; ctx.beginPath(); ctx.moveTo(x,0); ctx.lineTo(x,h); ctx.stroke() }
                                        for (var j = 0; j <= 5; j++) { var y = (h/5)*j; ctx.beginPath(); ctx.moveTo(0,y); ctx.lineTo(w,y); ctx.stroke() }
                                        // Линия
                                        ctx.beginPath(); ctx.strokeStyle = "#00b4d8"; ctx.lineWidth = 2
                                        var firstY = h - ((values[0]-minVal)/range)*h
                                        firstY = Math.max(0, Math.min(h, firstY))
                                        ctx.moveTo(0, firstY)
                                        for (var k = 1; k < values.length; k++) { var yVal = h - ((values[k]-minVal)/range)*h; yVal = Math.max(0, Math.min(h, yVal)); ctx.lineTo(k*step, yVal) }
                                        ctx.stroke()
                                        ctx.fillStyle = "#00b4d820"
                                        ctx.lineTo(w, h); ctx.lineTo(0, h); ctx.closePath(); ctx.fill()
                                    }
                                    Connections { target: car; onDataChanged: parent.requestPaint() }
                                }
                            }
                        }
                        
                        // Наддув график
                        Rectangle {
                            width: parent.width; height: 130
                            color: "#0d1117"
                            border.color: "#2a2e35"; border.width: 1; radius: 4
                            Column {
                                anchors.fill: parent; anchors.margins: 6; spacing: 4
                                Row {
                                    spacing: 10
                                    Text { text: "НАДДУВ (Boost)"; color: "#f4a261"; font.pixelSize: 10; font.bold: true }
                                    Text { text: { var d=JSON.parse(car.history_json); return d.boost?.slice(-1)[0]?.toFixed(1)||"0" }; color: "#e0e0e0"; font.pixelSize: 10 }
                                }
                                Canvas {
                                    width: parent.width; height: 100
                                    onPaint: {
                                        var ctx = getContext("2d")
                                        ctx.clearRect(0, 0, width, height)
                                        var data = JSON.parse(car.history_json)
                                        var values = data.boost
                                        if (!values || values.length < 2) return
                                        var w = width, h = height, step = w / (values.length - 1)
                                        var minVal = 0, maxVal = 2.5, range = maxVal - minVal
                                        ctx.strokeStyle = "#2a2e35"; ctx.lineWidth = 0.5
                                        for (var i = 0; i <= 6; i++) { var x = (w/6)*i; ctx.beginPath(); ctx.moveTo(x,0); ctx.lineTo(x,h); ctx.stroke() }
                                        for (var j = 0; j <= 5; j++) { var y = (h/5)*j; ctx.beginPath(); ctx.moveTo(0,y); ctx.lineTo(w,y); ctx.stroke() }
                                        ctx.beginPath(); ctx.strokeStyle = "#f4a261"; ctx.lineWidth = 2
                                        var firstY = h - ((values[0]-minVal)/range)*h
                                        firstY = Math.max(0, Math.min(h, firstY))
                                        ctx.moveTo(0, firstY)
                                        for (var k = 1; k < values.length; k++) { var yVal = h - ((values[k]-minVal)/range)*h; yVal = Math.max(0, Math.min(h, yVal)); ctx.lineTo(k*step, yVal) }
                                        ctx.stroke()
                                        ctx.fillStyle = "#f4a26120"
                                        ctx.lineTo(w, h); ctx.lineTo(0, h); ctx.closePath(); ctx.fill()
                                    }
                                    Connections { target: car; onDataChanged: parent.requestPaint() }
                                }
                            }
                        }
                        
                        // Температуры график
                        Rectangle {
                            width: parent.width; height: 130
                            color: "#0d1117"
                            border.color: "#2a2e35"; border.width: 1; radius: 4
                            Column {
                                anchors.fill: parent; anchors.margins: 6; spacing: 4
                                Row {
                                    spacing: 15
                                    Text { text: "ТЕМПЕРАТУРЫ (°C)"; color: "#ff6b6b"; font.pixelSize: 10; font.bold: true }
                                    Text { text: "🔴 ОЖ"; color: "#e63946"; font.pixelSize: 8 }
                                    Text { text: "🟠 Масло"; color: "#f4a261"; font.pixelSize: 8 }
                                }
                                Canvas {
                                    width: parent.width; height: 100
                                    onPaint: {
                                        var ctx = getContext("2d")
                                        ctx.clearRect(0, 0, width, height)
                                        var data = JSON.parse(car.history_json)
                                        var coolant = data.coolant_temp
                                        var oil = data.oil_temp
                                        if (!coolant || coolant.length < 2) return
                                        var w = width, h = height, step = w / (coolant.length - 1)
                                        var minVal = 60, maxVal = 130, range = maxVal - minVal
                                        ctx.strokeStyle = "#2a2e35"; ctx.lineWidth = 0.5
                                        for (var i = 0; i <= 6; i++) { var x = (w/6)*i; ctx.beginPath(); ctx.moveTo(x,0); ctx.lineTo(x,h); ctx.stroke() }
                                        for (var j = 0; j <= 5; j++) { var y = (h/5)*j; ctx.beginPath(); ctx.moveTo(0,y); ctx.lineTo(w,y); ctx.stroke() }
                                        // ОЖ
                                        ctx.beginPath(); ctx.strokeStyle = "#e63946"; ctx.lineWidth = 2
                                        var firstY = h - ((coolant[0]-minVal)/range)*h
                                        firstY = Math.max(0, Math.min(h, firstY))
                                        ctx.moveTo(0, firstY)
                                        for (var k = 1; k < coolant.length; k++) { var yVal = h - ((coolant[k]-minVal)/range)*h; yVal = Math.max(0, Math.min(h, yVal)); ctx.lineTo(k*step, yVal) }
                                        ctx.stroke()
                                        // Масло
                                        if (oil && oil.length > 0) {
                                            ctx.beginPath(); ctx.strokeStyle = "#f4a261"; ctx.lineWidth = 2
                                            var firstY2 = h - ((oil[0]-minVal)/range)*h
                                            firstY2 = Math.max(0, Math.min(h, firstY2))
                                            ctx.moveTo(0, firstY2)
                                            for (var k = 1; k < oil.length; k++) { var yVal = h - ((oil[k]-minVal)/range)*h; yVal = Math.max(0, Math.min(h, yVal)); ctx.lineTo(k*step, yVal) }
                                            ctx.stroke()
                                        }
                                    }
                                    Connections { target: car; onDataChanged: parent.requestPaint() }
                                }
                            }
                        }
                        
                        // Давления график
                        Rectangle {
                            width: parent.width; height: 130
                            color: "#0d1117"
                            border.color: "#2a2e35"; border.width: 1; radius: 4
                            Column {
                                anchors.fill: parent; anchors.margins: 6; spacing: 4
                                Row {
                                    spacing: 15
                                    Text { text: "ДАВЛЕНИЯ (bar)"; color: "#6aa84f"; font.pixelSize: 10; font.bold: true }
                                    Text { text: "🟢 Масло"; color: "#6aa84f"; font.pixelSize: 8 }
                                    Text { text: "🟣 Топливо"; color: "#9c27b0"; font.pixelSize: 8 }
                                }
                                Canvas {
                                    width: parent.width; height: 100
                                    onPaint: {
                                        var ctx = getContext("2d")
                                        ctx.clearRect(0, 0, width, height)
                                        var data = JSON.parse(car.history_json)
                                        var oil = data.oil_pressure
                                        var fuel = data.fuel_pressure
                                        if (!oil || oil.length < 2) return
                                        var w = width, h = height, step = w / (oil.length - 1)
                                        var minVal = 0, maxVal = 8, range = maxVal - minVal
                                        ctx.strokeStyle = "#2a2e35"; ctx.lineWidth = 0.5
                                        for (var i = 0; i <= 6; i++) { var x = (w/6)*i; ctx.beginPath(); ctx.moveTo(x,0); ctx.lineTo(x,h); ctx.stroke() }
                                        for (var j = 0; j <= 5; j++) { var y = (h/5)*j; ctx.beginPath(); ctx.moveTo(0,y); ctx.lineTo(w,y); ctx.stroke() }
                                        // Масло
                                        ctx.beginPath(); ctx.strokeStyle = "#6aa84f"; ctx.lineWidth = 2
                                        var firstY = h - ((oil[0]-minVal)/range)*h
                                        firstY = Math.max(0, Math.min(h, firstY))
                                        ctx.moveTo(0, firstY)
                                        for (var k = 1; k < oil.length; k++) { var yVal = h - ((oil[k]-minVal)/range)*h; yVal = Math.max(0, Math.min(h, yVal)); ctx.lineTo(k*step, yVal) }
                                        ctx.stroke()
                                        // Топливо
                                        if (fuel && fuel.length > 0) {
                                            ctx.beginPath(); ctx.strokeStyle = "#9c27b0"; ctx.lineWidth = 2
                                            var firstY2 = h - ((fuel[0]-minVal)/range)*h
                                            firstY2 = Math.max(0, Math.min(h, firstY2))
                                            ctx.moveTo(0, firstY2)
                                            for (var k = 1; k < fuel.length; k++) { var yVal = h - ((fuel[k]-minVal)/range)*h; yVal = Math.max(0, Math.min(h, yVal)); ctx.lineTo(k*step, yVal) }
                                            ctx.stroke()
                                        }
                                    }
                                    Connections { target: car; onDataChanged: parent.requestPaint() }
                                }
                            }
                        }
                        
                        // Детонация график
                        Rectangle {
                            width: parent.width; height: 130
                            color: "#0d1117"
                            border.color: "#2a2e35"; border.width: 1; radius: 4
                            Column {
                                anchors.fill: parent; anchors.margins: 6; spacing: 4
                                Row {
                                    spacing: 15
                                    Text { text: "ДЕТОНАЦИЯ (V)"; color: "#e63946"; font.pixelSize: 10; font.bold: true }
                                    Text { text: "🔴 Knock 1"; color: "#e63946"; font.pixelSize: 8 }
                                    Text { text: "🟠 Knock 2"; color: "#f4a261"; font.pixelSize: 8 }
                                }
                                Canvas {
                                    width: parent.width; height: 100
                                    onPaint: {
                                        var ctx = getContext("2d")
                                        ctx.clearRect(0, 0, width, height)
                                        var data = JSON.parse(car.history_json)
                                        var knock1 = data.knock_1
                                        var knock2 = data.knock_2
                                        if (!knock1 || knock1.length < 2) return
                                        var w = width, h = height, step = w / (knock1.length - 1)
                                        var minVal = 0, maxVal = 1.0, range = maxVal - minVal
                                        ctx.strokeStyle = "#2a2e35"; ctx.lineWidth = 0.5
                                        for (var i = 0; i <= 6; i++) { var x = (w/6)*i; ctx.beginPath(); ctx.moveTo(x,0); ctx.lineTo(x,h); ctx.stroke() }
                                        for (var j = 0; j <= 5; j++) { var y = (h/5)*j; ctx.beginPath(); ctx.moveTo(0,y); ctx.lineTo(w,y); ctx.stroke() }
                                        // Порог детонации
                                        var thresholdY = h - ((0.7 - minVal)/range)*h
                                        ctx.beginPath(); ctx.strokeStyle = "#e63946"; ctx.lineWidth = 1; ctx.setLineDash([5,5])
                                        ctx.moveTo(0, thresholdY); ctx.lineTo(w, thresholdY); ctx.stroke()
                                        ctx.setLineDash([])
                                        // Knock 1
                                        ctx.beginPath(); ctx.strokeStyle = "#e63946"; ctx.lineWidth = 2
                                        var firstY = h - ((knock1[0]-minVal)/range)*h
                                        firstY = Math.max(0, Math.min(h, firstY))
                                        ctx.moveTo(0, firstY)
                                        for (var k = 1; k < knock1.length; k++) { var yVal = h - ((knock1[k]-minVal)/range)*h; yVal = Math.max(0, Math.min(h, yVal)); ctx.lineTo(k*step, yVal) }
                                        ctx.stroke()
                                        // Knock 2
                                        if (knock2 && knock2.length > 0) {
                                            ctx.beginPath(); ctx.strokeStyle = "#f4a261"; ctx.lineWidth = 2
                                            var firstY2 = h - ((knock2[0]-minVal)/range)*h
                                            firstY2 = Math.max(0, Math.min(h, firstY2))
                                            ctx.moveTo(0, firstY2)
                                            for (var k = 1; k < knock2.length; k++) { var yVal = h - ((knock2[k]-minVal)/range)*h; yVal = Math.max(0, Math.min(h, yVal)); ctx.lineTo(k*step, yVal) }
                                            ctx.stroke()
                                        }
                                    }
                                    Connections { target: car; onDataChanged: parent.requestPaint() }
                                }
                            }
                        }
                        
                        // TPS и УОЗ график
                        Rectangle {
                            width: parent.width; height: 130
                            color: "#0d1117"
                            border.color: "#2a2e35"; border.width: 1; radius: 4
                            Column {
                                anchors.fill: parent; anchors.margins: 6; spacing: 4
                                Row {
                                    spacing: 15
                                    Text { text: "TPS (%) / IGN (°)"; color: "#8bc34a"; font.pixelSize: 10; font.bold: true }
                                    Text { text: "🟢 TPS"; color: "#8bc34a"; font.pixelSize: 8 }
                                    Text { text: "🔵 IGN"; color: "#00b4d8"; font.pixelSize: 8 }
                                }
                                Canvas {
                                    width: parent.width; height: 100
                                    onPaint: {
                                        var ctx = getContext("2d")
                                        ctx.clearRect(0, 0, width, height)
                                        var data = JSON.parse(car.history_json)
                                        var tps = data.tps
                                        var ign = data.ign_angle
                                        if (!tps || tps.length < 2) return
                                        var w = width, h = height, step = w / (tps.length - 1)
                                        // TPS (0-100)
                                        var minValTPS = 0, maxValTPS = 100, rangeTPS = maxValTPS - minValTPS
                                        // IGN (0-45)
                                        var minValIGN = 0, maxValIGN = 45, rangeIGN = maxValIGN - minValIGN
                                        ctx.strokeStyle = "#2a2e35"; ctx.lineWidth = 0.5
                                        for (var i = 0; i <= 6; i++) { var x = (w/6)*i; ctx.beginPath(); ctx.moveTo(x,0); ctx.lineTo(x,h); ctx.stroke() }
                                        for (var j = 0; j <= 5; j++) { var y = (h/5)*j; ctx.beginPath(); ctx.moveTo(0,y); ctx.lineTo(w,y); ctx.stroke() }
                                        // TPS
                                        ctx.beginPath(); ctx.strokeStyle = "#8bc34a"; ctx.lineWidth = 2
                                        var firstY = h - ((tps[0]-minValTPS)/rangeTPS)*h
                                        firstY = Math.max(0, Math.min(h, firstY))
                                        ctx.moveTo(0, firstY)
                                        for (var k = 1; k < tps.length; k++) { var yVal = h - ((tps[k]-minValTPS)/rangeTPS)*h; yVal = Math.max(0, Math.min(h, yVal)); ctx.lineTo(k*step, yVal) }
                                        ctx.stroke()
                                        // IGN
                                        if (ign && ign.length > 0) {
                                            ctx.beginPath(); ctx.strokeStyle = "#00b4d8"; ctx.lineWidth = 2
                                            var firstY2 = h - ((ign[0]-minValIGN)/rangeIGN)*h
                                            firstY2 = Math.max(0, Math.min(h, firstY2))
                                            ctx.moveTo(0, firstY2)
                                            for (var k = 1; k < ign.length; k++) { var yVal = h - ((ign[k]-minValIGN)/rangeIGN)*h; yVal = Math.max(0, Math.min(h, yVal)); ctx.lineTo(k*step, yVal) }
                                            ctx.stroke()
                                        }
                                    }
                                    Connections { target: car; onDataChanged: parent.requestPaint() }
                                }
                            }
                        }
                    }
                }
                
                Rectangle { height: 1; width: parent.width; color: "#2a2e35" }
                Row { spacing: 15
                    Text { text: "← Нажмите на фон для закрытия"; color: "#8a8f99"; font.pixelSize: 10 }
                    Text { text: "📁 Логи: ./logs/"; color: "#5a606b"; font.pixelSize: 10 }
                }
            }
        }

        // ======================== АНИМАЦИИ ПАНЕЛЕЙ ========================
        
        SequentialAnimation {
            id: controlPanelAnimation
            ScriptAction { script: { dimOverlay.visible = true; dimOverlay.opacity = 0 } }
            ParallelAnimation {
                NumberAnimation { target: dimOverlay; property: "opacity"; to: 1; duration: 200 }
                NumberAnimation { target: controlPanel; property: "anchors.rightMargin"; to: 0; duration: 300 }
            }
        }
        
        SequentialAnimation {
            id: graphPanelAnimation
            ScriptAction { script: { dimOverlay.visible = true; dimOverlay.opacity = 0 } }
            ParallelAnimation {
                NumberAnimation { target: dimOverlay; property: "opacity"; to: 1; duration: 200 }
                NumberAnimation { target: graphPanel; property: "anchors.leftMargin"; to: 0; duration: 300 }
            }
        }
        
        SequentialAnimation {
            id: settingsPanelAnimation
            ScriptAction { script: { dimOverlay.visible = true; dimOverlay.opacity = 0 } }
            ParallelAnimation {
                NumberAnimation { target: dimOverlay; property: "opacity"; to: 1; duration: 200 }
                NumberAnimation { target: settingsPanel; property: "anchors.topMargin"; to: 60; duration: 300; easing.type: Easing.OutCubic }
            }
        }
        
        SequentialAnimation {
            id: errorPanelAnimation
            ScriptAction { script: { dimOverlay.visible = true; dimOverlay.opacity = 0 } }
            ParallelAnimation {
                NumberAnimation { target: dimOverlay; property: "opacity"; to: 1; duration: 200 }
                NumberAnimation { target: errorPanel; property: "anchors.topMargin"; to: 60; duration: 300; easing.type: Easing.OutCubic }
            }
        }
        
        SequentialAnimation {
            id: limitsPanelAnimation
            ScriptAction { script: { dimOverlay.visible = true; dimOverlay.opacity = 0 } }
            ParallelAnimation {
                NumberAnimation { target: dimOverlay; property: "opacity"; to: 1; duration: 200 }
                NumberAnimation { target: limitsPanel; property: "anchors.leftMargin"; to: 0; duration: 300 }
            }
        }

        // ======================== ПОДСКАЗКА ДЛЯ ПОЛЬЗОВАТЕЛЯ ========================
        
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: 15
            width: 220
            height: 30
            color: "#14171c"
            radius: 15
            opacity: 0.7
            z: 100
            Text {
                anchors.centerIn: parent
                text: "👉 Свайп вправо | 👈 Свайп влево"
                color: "#8a8f99"
                font.pixelSize: 9
            }
            Timer { running: true; interval: 5000; onTriggered: parent.opacity = 0 }
        }
    }
}