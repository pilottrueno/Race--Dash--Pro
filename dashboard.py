#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║    ██████╗  █████╗  ██████╗███████╗    ██████╗  █████╗ ███████╗██╗  ██╗       ║
║    ██╔══██╗██╔══██╗██╔════╝██╔════╝    ██╔══██╗██╔══██╗██╔════╝██║  ██║       ║
║    ██████╔╝███████║██║     █████╗      ██║  ██║███████║███████╗███████║       ║
║    ██╔══██╗██╔══██║██║     ██╔══╝      ██║  ██║██╔══██║╚════██║██╔══██║       ║
║    ██║  ██║██║  ██║╚██████╗███████╗    ██████╔╝██║  ██║███████║██║  ██║       ║
║    ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚══════╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝       ║
║                                                                               ║
║    ██████╗ ██████╗  ██████╗                                                     ║
║    ██╔══██╗██╔══██╗██╔═══██╗                                                    ║
║    ██████╔╝██████╔╝██║   ██║                                                    ║
║    ██╔═══╝ ██╔══██╗██║   ██║                                                    ║
║    ██║     ██║  ██║╚██████╔╝                                                    ║
║    ╚═╝     ╚═╝  ╚═╝ ╚═════╝                                                     ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝

================================================================================
    RACE DASH PRO - Профессиональная гоночная приборная панель
================================================================================

Автор:          Бухлаков Евгений
Дата создания:  29 апреля 2026 г.
Версия:         3.0
Лицензия:       MIT

================================================================================
    Контакты:
================================================================================
    Telegram:   @race_dash_pro
    GitHub:     https://github.com/buhlakov/race-dash-pro
    Email:      buhlakov@race-dash.ru

================================================================================
"""

import sys
import os
import math
import datetime
import json
import time
import random
import queue
import threading
import subprocess
import struct
import glob
import shutil
import signal
from enum import Enum
from dataclasses import dataclass, field
from typing import List, Dict, Optional, Tuple

from PyQt5.QtCore import QObject, QUrl, QTimer, pyqtProperty, pyqtSignal, pyqtSlot, QDateTime, QCoreApplication
from PyQt5.QtGui import QGuiApplication, QColor
from PyQt5.QtQml import QQmlApplicationEngine

# ======================== ИНФОРМАЦИЯ О ПРОЕКТЕ ========================

PROJECT_NAME = "RACE DASH PRO"
PROJECT_VERSION = "3.0"
PROJECT_AUTHOR = "Бухлаков Евгений"
PROJECT_CREATED = "29.04.2026"
PROJECT_LICENSE = "MIT"
PROJECT_GITHUB = "https://github.com/buhlakov/race-dash-pro"
PROJECT_TELEGRAM = "@race_dash_pro"
PROJECT_EMAIL = "buhlakov@race-dash.ru"

# ======================== ОПРЕДЕЛЕНИЕ ПЛАТФОРМЫ ========================

IS_RASPBERRY_PI = False
try:
    with open('/sys/firmware/devicetree/base/model', 'r') as f:
        if 'Raspberry Pi' in f.read():
            IS_RASPBERRY_PI = True
except FileNotFoundError:
    pass

print(f"[{PROJECT_NAME}] v{PROJECT_VERSION}")
print(f"[{PROJECT_NAME}] Автор: {PROJECT_AUTHOR}")
print(f"[{PROJECT_NAME}] Дата создания: {PROJECT_CREATED}")
print(f"[{PROJECT_NAME}] Платформа: {'Raspberry Pi' if IS_RASPBERRY_PI else 'ПК (режим симуляции)'}")
print(f"[{PROJECT_NAME}] GitHub: {PROJECT_GITHUB}")

# ======================== КОНСТАНТЫ ========================

LOG_DIR = "logs"
TRACK_DIR = os.path.join(LOG_DIR, "tracks")
DBC_DIR = os.path.join(LOG_DIR, "dbc")
CONFIG_DIR = os.path.join(LOG_DIR, "config")

for d in [LOG_DIR, TRACK_DIR, DBC_DIR, CONFIG_DIR]:
    if not os.path.exists(d):
        os.makedirs(d)

# ======================== КЛАССЫ ДЛЯ ДИАГНОСТИКИ ========================

class ErrorSeverity(Enum):
    INFO = 0
    WARNING = 1
    ERROR = 2
    CRITICAL = 3


@dataclass
class SystemError:
    id: str
    name: str
    description: str
    severity: ErrorSeverity
    timestamp: float = field(default_factory=time.time)
    resolved: bool = False
    solution: str = ""
    source: str = "system"


class DiagnosticEngine:
    """Двигатель диагностики на основе анализа реальных проблем сообщества"""

    ERROR_DATABASE = {
        'can_no_termination': {
            'name': 'Отсутствует терминация CAN шины',
            'description': 'На CAN шине нет необходимых терминирующих резисторов 120 Ом.',
            'causes': ['Отсутствуют резисторы', 'Переключатель 120R в OFF', 'Обрыв кабеля'],
            'solution': 'Установите ДВА резистора по 120 Ом на КОНЦАХ CAN шины.',
            'severity': ErrorSeverity.CRITICAL,
            'source': 'can'
        },
        'temp_critical': {
            'name': 'КРИТИЧЕСКАЯ ТЕМПЕРАТУРА!',
            'description': 'Температура процессора достигла 85°C. Включён троттлинг.',
            'causes': ['Нет охлаждения', 'Долгая работа на солнце', 'Запылённость'],
            'solution': 'НЕМЕДЛЕННО выключите панель для охлаждения! Установите вентилятор.',
            'severity': ErrorSeverity.CRITICAL,
            'source': 'temp'
        },
        'undervoltage': {
            'name': 'Пониженное напряжение питания!',
            'description': 'Напряжение ниже 4.8V. Самая частая проблема в автомобилях!',
            'causes': ['Плохой USB кабель', 'Скачки в бортовой сети', 'Ослабление контактов'],
            'solution': 'Используйте DC-DC преобразователь и качественный кабель.',
            'severity': ErrorSeverity.CRITICAL,
            'source': 'power'
        },
        'storage_full': {
            'name': 'Недостаточно места на SD карте',
            'description': 'Свободное место заканчивается. Логи могут не записываться!',
            'causes': ['Долгая работа без очистки', 'Много логов', 'Маленькая SD карта'],
            'solution': 'Удалите старые логи или замените SD карту на 32-64 ГБ.',
            'severity': ErrorSeverity.CRITICAL,
            'source': 'system'
        },
        'temp_warning': {
            'name': 'Повышенная температура процессора',
            'description': 'Температура превысила 70°C. Может начаться троттлинг.',
            'causes': ['Недостаточное охлаждение', 'Высокая нагрузка', 'Жарко в салоне'],
            'solution': 'Установите радиатор и вентилятор на процессор.',
            'severity': ErrorSeverity.WARNING,
            'source': 'temp'
        },
        'can_crc_error': {
            'name': 'Ошибка CRC на CAN шине',
            'description': 'Обнаружены ошибки контрольной суммы. Данные могут быть повреждены.',
            'causes': ['Помехи от зажигания', 'Плохой контакт', 'Длинный кабель'],
            'solution': 'Используйте экранированную витую пару и уменьшите длину кабеля.',
            'severity': ErrorSeverity.ERROR,
            'source': 'can'
        },
        'i2c_error': {
            'name': 'Ошибка I2C интерфейса',
            'description': 'I2C шина не работает. Датчики не будут работать.',
            'causes': ['I2C отключён', 'Нет подтягивающих резисторов', 'Конфликт адресов'],
            'solution': 'Включите I2C в raspi-config: Interface Options → I2C → Enable',
            'severity': ErrorSeverity.ERROR,
            'source': 'system'
        },
        'spi_error': {
            'name': 'Ошибка SPI интерфейса',
            'description': 'SPI шина не работает. CAN модуль не будет работать.',
            'causes': ['SPI отключён', 'Конфликт пинов', 'Повреждение драйвера'],
            'solution': 'Включите SPI в raspi-config: Interface Options → SPI → Enable',
            'severity': ErrorSeverity.ERROR,
            'source': 'system'
        },
        'bt_no_controller': {
            'name': 'Bluetooth адаптер не обнаружен',
            'description': 'Система не видит Bluetooth контроллер.',
            'causes': ['Bluetooth отключён', 'Нет драйверов', 'Конфликт с UART'],
            'solution': 'Установите pi-bluetooth и включите Bluetooth в настройках.',
            'severity': ErrorSeverity.ERROR,
            'source': 'bt'
        },
        'gps_no_fix': {
            'name': 'GPS не может определить местоположение',
            'description': 'Недостаточно спутников для определения координат.',
            'causes': ['Антенна под металлом', 'Долгий старт', 'Плохая погода'],
            'solution': 'Вынесите антенну под лобовое стекло или на крышу.',
            'severity': ErrorSeverity.WARNING,
            'source': 'gps'
        },
        'gy521_not_found': {
            'name': 'Датчик GY-521 не обнаружен',
            'description': 'Акселерометр и гироскоп не видны на I2C шине.',
            'causes': ['GY-521 на 5V (надо 3.3V)', 'I2C отключён', 'Плохой контакт'],
            'solution': 'Подключайте GY-521 ТОЛЬКО к 3.3V! Проверьте I2C: i2cdetect -y 1',
            'severity': ErrorSeverity.ERROR,
            'source': 'sensor'
        },
        'qml_loading_error': {
            'name': 'Ошибка загрузки QML интерфейса',
            'description': 'Не удалось загрузить QML компоненты. Интерфейс может отображаться некорректно.',
            'causes': ['Отсутствует файл dashboard.qml', 'Ошибка синтаксиса в QML', 'Несовместимость версий Qt'],
            'solution': 'Проверьте наличие файла dashboard.qml в той же папке. Убедитесь в корректности QML синтаксиса.',
            'severity': ErrorSeverity.CRITICAL,
            'source': 'system'
        }
    }

    def __init__(self):
        self.errors: List[SystemError] = []
        self._temperature = 0
        self._throttle_status = 0
        self._gps_satellites = 0
        self._gps_fix = False
        self._error_check_functions = {
            'temp_warning': lambda: 70 <= self._temperature < 85,
            'temp_critical': lambda: self._temperature >= 85,
            'undervoltage': lambda: (self._throttle_status & 0x1) or (self._throttle_status & 0x10000),
            'storage_full': self._check_storage,
            'i2c_error': self._check_i2c,
            'spi_error': self._check_spi,
            'bt_no_controller': self._check_bt_controller,
            'gps_no_fix': lambda: self._gps_satellites < 4 if self._gps_satellites else False,
            'gy521_not_found': self._check_gy521,
        }

    def _check_storage(self):
        try:
            statvfs = os.statvfs('/')
            free = statvfs.f_frsize * statvfs.f_bfree
            total = statvfs.f_frsize * statvfs.f_blocks
            free_percent = (free / total) * 100
            return free_percent < 10
        except:
            return False

    def _check_i2c(self):
        if not IS_RASPBERRY_PI:
            return False
        try:
            result = subprocess.run(['i2cdetect', '-y', '1'], capture_output=True, text=True, timeout=5)
            return '68' not in result.stdout
        except:
            return False

    def _check_spi(self):
        if not IS_RASPBERRY_PI:
            return False
        return not glob.glob('/dev/spi*')

    def _check_bt_controller(self):
        if not IS_RASPBERRY_PI:
            return False
        try:
            result = subprocess.run(['bluetoothctl', 'list'], capture_output=True, text=True, timeout=5)
            return not result.stdout.strip() or 'No default controller' in result.stdout
        except:
            return False

    def _check_gy521(self):
        if not IS_RASPBERRY_PI:
            return False
        try:
            result = subprocess.run(['i2cdetect', '-y', '1'], capture_output=True, text=True, timeout=5)
            return '68' not in result.stdout
        except:
            return False

    def run_diagnostics(self, temperature=0, throttle_status=0, gps_satellites=0, gps_fix=False):
        self._temperature = temperature
        self._throttle_status = throttle_status
        self._gps_satellites = gps_satellites
        self._gps_fix = gps_fix

        for error_id, check_func in self._error_check_functions.items():
            if error_id in self.ERROR_DATABASE:
                try:
                    if check_func():
                        self.add_error_from_code(error_id)
                except Exception as e:
                    print(f"[DIAG] Ошибка проверки {error_id}: {e}")

    def add_error_from_code(self, error_code: str):
        if error_code not in self.ERROR_DATABASE:
            return
        for err in self.errors:
            if err.id == error_code and not err.resolved:
                return

        info = self.ERROR_DATABASE[error_code]
        causes = "\n".join([f"   • {c}" for c in info['causes']])
        full_desc = f"{info['description']}\n\n📋 ВОЗМОЖНЫЕ ПРИЧИНЫ:\n{causes}"

        error = SystemError(
            id=error_code,
            name=info['name'],
            description=full_desc,
            severity=info['severity'],
            solution=info['solution'],
            source=info['source']
        )
        self.errors.append(error)
        self.errors.sort(key=lambda x: x.severity.value, reverse=True)

    def resolve_error(self, error_id: str):
        for err in self.errors:
            if err.id == error_id:
                err.resolved = True
                break

    def clear_all_errors(self):
        self.errors = []

    def get_active_errors(self):
        return [e for e in self.errors if not e.resolved]

    def get_error_count(self):
        return len(self.get_active_errors())

    def get_critical_count(self):
        return sum(1 for e in self.errors if not e.resolved and e.severity == ErrorSeverity.CRITICAL)

    def has_critical_errors(self):
        return self.get_critical_count() > 0


# ======================== RGB LED КОНТРОЛЛЕР ========================

class RGBController:
    COLOR_ZONES = {
        'cold': (0, 0, 255),
        'warm': (0, 100, 255),
        'normal': (0, 255, 0),
        'sport': (100, 255, 0),
        'hot': (255, 100, 0),
        'redline': (255, 0, 0),
        'flash': (255, 255, 255)
    }

    def __init__(self, led_count=1, gpio_pin=18):
        self.led_count = led_count
        self.gpio_pin = gpio_pin
        self.pixels = None
        self.current_rgb = (0, 0, 0)
        self.flash_state = False
        self._simulation_color_logged = False

        if IS_RASPBERRY_PI:
            try:
                import board
                import neopixel
                pin = getattr(board, f'D{gpio_pin}')
                self.pixels = neopixel.NeoPixel(pin, led_count, brightness=0.5, auto_write=False)
                print("[RGB LED] Реальный режим")
            except ImportError:
                print("[RGB LED] Библиотека neopixel не установлена. Установка: pip install adafruit-circuitpython-neopixel")
                self.pixels = None
            except Exception as e:
                print(f"[RGB LED] Ошибка: {e}")
                self.pixels = None
        else:
            print("[RGB LED] Режим симуляции (ПК)")

    def rpm_to_color(self, rpm, max_rpm=8000, is_over_limit=False):
        if is_over_limit:
            return (255, 0, 0) if self.flash_state else (255, 255, 255)
        rpm_norm = min(1.0, rpm / max_rpm)
        if rpm_norm < 0.2:
            return self.COLOR_ZONES['cold']
        elif rpm_norm < 0.35:
            return self.COLOR_ZONES['warm']
        elif rpm_norm < 0.5:
            return self.COLOR_ZONES['normal']
        elif rpm_norm < 0.65:
            return self.COLOR_ZONES['sport']
        elif rpm_norm < 0.85:
            return self.COLOR_ZONES['hot']
        else:
            return self.COLOR_ZONES['redline']

    def update(self, rpm, is_over_limit=False, max_rpm=8000):
        if self.pixels is None:
            if not self._simulation_color_logged:
                self._simulation_color_logged = True
                print("[RGB LED] Симуляция: светодиод меняет цвет в зависимости от оборотов")
            return
        new_color = self.rpm_to_color(rpm, max_rpm, is_over_limit)
        if new_color != self.current_rgb:
            self.current_rgb = new_color
            r, g, b = new_color
            color_int = (r << 16) | (g << 8) | b
            for i in range(self.led_count):
                self.pixels[i] = color_int
            self.pixels.show()

    def update_flash_state(self, is_flashing):
        self.flash_state = is_flashing

    def cleanup(self):
        if self.pixels is not None:
            for i in range(self.led_count):
                self.pixels[i] = 0
            self.pixels.show()
            self.pixels.deinit()


# ======================== ОСНОВНОЙ КЛАСС ========================

class CarData(QObject):
    dataChanged = pyqtSignal()
    diagnostics_updated = pyqtSignal()
    panel_shutdown_started = pyqtSignal()
    panel_power_on = pyqtSignal()
    panel_power_off = pyqtSignal()
    qml_loaded = pyqtSignal()

    def __init__(self):
        super().__init__()

        self._init_engine_data()
        self._init_storage()
        self._init_diagnostics()
        self._init_rgb()

        self._timer = QTimer()
        self._timer.timeout.connect(self.update_data)
        self._timer.start(20)

        self._sim_time = 0.0
        self._last_speed = 0.0
        print("[СИСТЕМА] Приборная панель запущена")

    def _init_engine_data(self):
        self._rpm = 800.0
        self._boost = 0.0
        self._oil_pressure = 2.5
        self._oil_temp = 90.0
        self._coolant_temp = 85.0
        self._fuel_pressure = 3.8
        self._voltage = 14.2
        self._lambda = 1.0
        self._afr = 14.7
        self._egt = 400.0
        self._gear = 1
        self._boost_mode = "Eco"
        self._latitude = 55.751244
        self._longitude = 37.618423
        self._gps_speed = 0.0
        self._gps_satellites = 12
        self._gps_fix = True
        self._accel_x = 0.0
        self._accel_y = 0.0
        self._accel_z = 9.81
        self._rpi_temp = 45.0
        self._track_recording = False
        self._track_visualization = []
        self._log_files = []
        self._log_files_json = "[]"
        self._storage_total = 0
        self._storage_used = 0
        self._storage_free = 0
        self._logs_size = 0
        self._system_size = 0
        self._storage_used_percent = 0
        self._logs_count = 0

        # ===== НОВЫЕ ПАРАМЕТРЫ =====
        self._knock_1 = 0.0
        self._knock_2 = 0.0
        self._tps = 0.0
        self._ign_angle = 0.0
        self._knock_occurred = False
        self._tps_closed = True
        self._tps_wide = False

    def _init_storage(self):
        self._update_storage_info()
        self._update_log_files_list()

    def _init_diagnostics(self):
        self._diagnostic_engine = DiagnosticEngine()
        self._auto_diagnostics_enabled = True
        self._diagnostics_timer = QTimer()
        self._diagnostics_timer.timeout.connect(self.run_diagnostics)
        self._diagnostics_timer.start(60000)
        self.run_diagnostics()

    def _init_rgb(self):
        self._rgb_controller = RGBController(led_count=1, gpio_pin=18)
        self._flash_toggle = False
        self._flash_timer = QTimer()
        self._flash_timer.timeout.connect(self._toggle_flash)
        self._flash_timer.start(150)

    def _update_storage_info(self):
        try:
            statvfs = os.statvfs('/')
            self._storage_total = statvfs.f_frsize * statvfs.f_blocks
            self._storage_free = statvfs.f_frsize * statvfs.f_bfree
            self._storage_used = self._storage_total - self._storage_free
            self._storage_used_percent = int((self._storage_used / self._storage_total) * 100) if self._storage_total else 0

            self._logs_size = self._get_folder_size(LOG_DIR)
            self._system_size = self._storage_used - self._logs_size
            self.dataChanged.emit()
        except Exception as e:
            print(f"[STORAGE] Ошибка: {e}")

    def _get_folder_size(self, folder_path):
        total = 0
        if not os.path.exists(folder_path):
            return 0
        try:
            for entry in os.scandir(folder_path):
                if entry.is_file():
                    total += entry.stat().st_size
                elif entry.is_dir():
                    total += self._get_folder_size(entry.path)
        except PermissionError:
            pass
        return total

    def _update_log_files_list(self):
        self._log_files = []
        if not os.path.exists(LOG_DIR):
            self._log_files_json = "[]"
            self.dataChanged.emit()
            return

        try:
            for filename in os.listdir(LOG_DIR):
                filepath = os.path.join(LOG_DIR, filename)
                if os.path.isfile(filepath) and (filename.endswith('.txt') or filename.endswith('.csv') or filename.endswith('.geojson')):
                    stat = os.stat(filepath)
                    self._log_files.append({
                        'name': filename,
                        'size_mb': round(stat.st_size / (1024 * 1024), 2),
                        'modified': datetime.datetime.fromtimestamp(stat.st_mtime).strftime('%Y-%m-%d %H:%M:%S'),
                        'type': 'track' if filename.endswith('.geojson') else ('data' if filename.endswith('.csv') else 'log')
                    })
            self._log_files.sort(key=lambda x: x['modified'], reverse=True)
            self._logs_count = len(self._log_files)
            self._log_files_json = json.dumps(self._log_files)
        except Exception as e:
            print(f"[FILES] Ошибка: {e}")
            self._log_files_json = "[]"
        self.dataChanged.emit()

    def _format_bytes(self, bytes_value):
        for unit in ['Б', 'КБ', 'МБ', 'ГБ']:
            if bytes_value < 1024.0:
                return f"{bytes_value:.1f} {unit}"
            bytes_value /= 1024.0
        return f"{bytes_value:.1f} ТБ"

    def _toggle_flash(self):
        self._flash_toggle = not self._flash_toggle
        self._rgb_controller.update_flash_state(self._flash_toggle)
        self._rgb_controller.update(self._rpm, False, 8000)

    def run_diagnostics(self):
        if not self._auto_diagnostics_enabled:
            return
        self._diagnostic_engine.run_diagnostics(
            temperature=self._rpi_temp,
            throttle_status=0,
            gps_satellites=self._gps_satellites,
            gps_fix=self._gps_fix
        )
        self.diagnostics_updated.emit()
        self.dataChanged.emit()

    @pyqtSlot()
    def clear_all_errors(self):
        self._diagnostic_engine.clear_all_errors()
        self.diagnostics_updated.emit()
        self.dataChanged.emit()

    @pyqtSlot(str)
    def delete_log_file(self, filename):
        filepath = os.path.join(LOG_DIR, filename)
        if os.path.exists(filepath):
            try:
                os.remove(filepath)
                self._update_log_files_list()
                self._update_storage_info()
                return True
            except Exception as e:
                print(f"[DELETE] Ошибка: {e}")
                return False
        return False

    @pyqtSlot()
    def delete_all_logs(self):
        try:
            for filename in os.listdir(LOG_DIR):
                filepath = os.path.join(LOG_DIR, filename)
                if os.path.isfile(filepath):
                    try:
                        os.remove(filepath)
                    except:
                        pass
            self._update_log_files_list()
            self._update_storage_info()
        except Exception as e:
            print(f"[DELETE ALL] Ошибка: {e}")

    @pyqtSlot()
    def refresh_log_files(self):
        self._update_log_files_list()
        self._update_storage_info()

    @pyqtSlot()
    def open_log_folder(self):
        try:
            if sys.platform == 'win32':
                os.startfile(LOG_DIR)
            else:
                subprocess.run(['xdg-open', LOG_DIR])
        except Exception as e:
            print(f"[FOLDER] Ошибка: {e}")

    @pyqtSlot(bool)
    def set_auto_diagnostics(self, enabled):
        self._auto_diagnostics_enabled = enabled
        self.dataChanged.emit()

    @pyqtSlot()
    def toggle_panel_power(self):
        print("[ПИТАНИЕ] Панель выключается...")
        self.panel_shutdown_started.emit()
        QTimer.singleShot(3000, self._perform_shutdown)

    def _perform_shutdown(self):
        print("[ПИТАНИЕ] Панель выключена")
        self.panel_power_off.emit()
        if IS_RASPBERRY_PI:
            QCoreApplication.quit()
    @pyqtProperty(float, notify=dataChanged)
    def rpm(self): return self._rpm

    @rpm.setter
    def rpm(self, value):
        if abs(self._rpm - value) > 1:
            self._rpm = value
            self._rgb_controller.update(value, False, 8000)
            self.dataChanged.emit()

    @pyqtProperty(float, notify=dataChanged)
    def boost(self): return self._boost

    @pyqtProperty(float, notify=dataChanged)
    def oil_pressure(self): return self._oil_pressure

    @pyqtProperty(float, notify=dataChanged)
    def oil_temp(self): return self._oil_temp

    @pyqtProperty(float, notify=dataChanged)
    def coolant_temp(self): return self._coolant_temp

    @pyqtProperty(float, notify=dataChanged)
    def fuel_pressure(self): return self._fuel_pressure

    @pyqtProperty(float, notify=dataChanged)
    def voltage(self): return self._voltage

    @pyqtProperty(float, notify=dataChanged)
    def lambda_value(self): return self._lambda

    @pyqtProperty(float, notify=dataChanged)
    def afr_value(self): return self._afr

    @pyqtProperty(float, notify=dataChanged)
    def egt(self): return self._egt

    @pyqtProperty(int, notify=dataChanged)
    def gear(self): return self._gear

    @pyqtProperty(str, notify=dataChanged)
    def boost_mode(self): return self._boost_mode

    @pyqtProperty(float, notify=dataChanged)
    def latitude(self): return self._latitude

    @pyqtProperty(float, notify=dataChanged)
    def longitude(self): return self._longitude

    @pyqtProperty(float, notify=dataChanged)
    def gps_speed(self): return self._gps_speed

    @pyqtProperty(int, notify=dataChanged)
    def gps_satellites(self): return self._gps_satellites

    @pyqtProperty(bool, notify=dataChanged)
    def gps_fix(self): return self._gps_fix

    @pyqtProperty(float, notify=dataChanged)
    def accel_x(self): return self._accel_x

    @pyqtProperty(float, notify=dataChanged)
    def accel_y(self): return self._accel_y

    @pyqtProperty(float, notify=dataChanged)
    def accel_z(self): return self._accel_z

    @pyqtProperty(float, notify=dataChanged)
    def rpi_temp(self): return self._rpi_temp

    @pyqtProperty(bool, notify=dataChanged)
    def track_recording(self): return self._track_recording

    @pyqtProperty(str, notify=dataChanged)
    def track_visualization_json(self):
        return json.dumps(self._track_visualization[-200:])

    @pyqtProperty(str, notify=dataChanged)
    def log_files_json(self): return self._log_files_json

    @pyqtProperty(str, notify=dataChanged)
    def storage_total(self): return self._format_bytes(self._storage_total)

    @pyqtProperty(str, notify=dataChanged)
    def storage_used(self): return self._format_bytes(self._storage_used)

    @pyqtProperty(str, notify=dataChanged)
    def storage_free(self): return self._format_bytes(self._storage_free)

    @pyqtProperty(str, notify=dataChanged)
    def logs_size(self): return self._format_bytes(self._logs_size)

    @pyqtProperty(str, notify=dataChanged)
    def system_size(self): return self._format_bytes(self._system_size)

    @pyqtProperty(int, notify=dataChanged)
    def storage_used_percent(self): return self._storage_used_percent

    @pyqtProperty(int, notify=dataChanged)
    def logs_count(self): return self._logs_count

    @pyqtProperty(int, notify=diagnostics_updated)
    def error_count(self): return self._diagnostic_engine.get_error_count()

    @pyqtProperty(int, notify=diagnostics_updated)
    def critical_error_count(self): return self._diagnostic_engine.get_critical_count()

    @pyqtProperty(bool, notify=diagnostics_updated)
    def has_critical_errors(self): return self._diagnostic_engine.has_critical_errors()

    @pyqtProperty(str, notify=diagnostics_updated)
    def error_list_json(self):
        errors = []
        try:
            for err in self._diagnostic_engine.get_active_errors():
                errors.append({
                    'id': err.id,
                    'name': err.name,
                    'description': err.description,
                    'severity': err.severity.value,
                    'severity_name': err.severity.name,
                    'timestamp': datetime.datetime.fromtimestamp(err.timestamp).strftime('%H:%M:%S'),
                    'solution': err.solution,
                    'source': err.source                })
        except Exception as e:
            print(f"[ERRORS] Ошибка: {e}")
        return json.dumps(errors)

    @pyqtProperty(bool, notify=dataChanged)
    def auto_diagnostics_enabled(self): return self._auto_diagnostics_enabled

    @pyqtProperty(float, notify=dataChanged)
    def cpu_temperature(self): return self._rpi_temp

    # ===== НОВЫЕ ПАРАМЕТРЫ (ДЕТОНАЦИЯ, TPS, УГОЛ ЗАЖИГАНИЯ) =====

    @pyqtProperty(float, notify=dataChanged)
    def knock_1(self): return self._knock_1

    @pyqtProperty(float, notify=dataChanged)
    def knock_2(self): return self._knock_2

    @pyqtProperty(bool, notify=dataChanged)
    def knock_occurred(self): return self._knock_occurred

    @pyqtProperty(float, notify=dataChanged)
    def tps(self): return self._tps

    @pyqtProperty(bool, notify=dataChanged)
    def tps_closed(self): return self._tps_closed

    @pyqtProperty(bool, notify=dataChanged)
    def tps_wide(self): return self._tps_wide

    @pyqtProperty(float, notify=dataChanged)
    def ign_angle(self): return self._ign_angle

    @pyqtProperty(str, notify=dataChanged)
    def ign_status(self):
        if self._ign_angle < 10:
            return "Позднее (нагрузка)"
        elif self._ign_angle > 35:
            return "Раннее (экономия)"
        else:
            return "Норма"

    # ===== МЕТОДЫ ОБНОВЛЕНИЯ ДАННЫХ =====

    def _update_knock(self, rpm, load_factor):
        """
        Симуляция датчика детонации.
        В реальности данные читаются с CAN шины или аналогового входа.
        """
        base_knock = load_factor * 0.5 + (rpm / 8000) * 0.3
        spike = random.uniform(0, 0.15) if load_factor > 0.7 else 0
        knock_1 = min(1.0, base_knock + spike)
        knock_2 = min(1.0, base_knock * 0.9 + spike * 0.8)
        self._knock_occurred = knock_1 > 0.7
        return round(knock_1, 2), round(knock_2, 2)

    def _update_tps(self, rpm, load_factor, boost):
        """
        Симуляция положения дроссельной заслонки.
        """
        tps_raw = min(100, (load_factor * 80) + (boost * 15) + 5)
        if tps_raw > self._tps:
            tps = self._tps + (tps_raw - self._tps) * 0.3
        else:
            tps = self._tps + (tps_raw - self._tps) * 0.15
        self._tps_closed = tps < 2
        self._tps_wide = tps > 95
        return round(tps, 1)

    def _update_ignition_angle(self, rpm, load_factor, tps, knock_value):
        """
        Симуляция угла опережения зажигания.
        """
        if rpm < 1000:
            base_angle = 8
        elif rpm < 2000:
            base_angle = 12 + (rpm - 1000) / 1000 * 3
        elif rpm < 4000:
            base_angle = 15 + (rpm - 2000) / 2000 * 8
        elif rpm < 6000:
            base_angle = 23 + (rpm - 4000) / 2000 * 10
        else:
            base_angle = 33 + (rpm - 6000) / 2000 * 5

        load_corr = -load_factor * 15
        tps_corr = (tps - 50) / 50 * 5
        knock_corr = -knock_value * 12

        if self._knock_occurred and self._ign_angle > 10:
            knock_corr = -15

        ign_angle = base_angle + load_corr + tps_corr + knock_corr
        ign_angle = max(0, min(45, ign_angle))
        return round(ign_angle, 1)

    def _add_to_history(self):
        current_time = datetime.datetime.now().timestamp() * 1000
        self._history['timestamp'].append(current_time)
        self._history['rpm'].append(self._rpm)
        self._history['boost'].append(self._boost)
        self._history['coolant_temp'].append(self._coolant_temp)
        self._history['oil_temp'].append(self._oil_temp)
        self._history['oil_pressure'].append(self._oil_pressure)
        self._history['fuel_pressure'].append(self._fuel_pressure)
        self._history['voltage'].append(self._voltage)
        self._history['lambda'].append(self._lambda)
        self._history['afr'].append(self._afr)
        self._history['egt'].append(self._egt)
        self._history['rpi_temp'].append(self._rpi_temp)
        self._history['accel_x'].append(self._accel_x)
        self._history['accel_y'].append(self._accel_y)
        self._history['accel_z'].append(self._accel_z)
        self._history['knock_1'].append(self._knock_1)
        self._history['knock_2'].append(self._knock_2)
        self._history['tps'].append(self._tps)
        self._history['ign_angle'].append(self._ign_angle)

        if len(self._history['timestamp']) > self._history_max_points:
            for key in self._history:
                self._history[key] = self._history[key][-self._history_max_points:]

    def _update_min_max(self):
        metrics = ['rpm', 'boost', 'coolant_temp', 'oil_temp', 'oil_pressure',
                   'fuel_pressure', 'voltage', 'lambda', 'afr', 'egt',
                   'rpi_temp', 'accel_x', 'accel_y', 'accel_z',
                   'knock_1', 'knock_2', 'tps', 'ign_angle']
        for metric in metrics:
            current = getattr(self, '_' + metric)
            if self._min_max[metric]['min'] == 0 or current < self._min_max[metric]['min']:
                self._min_max[metric]['min'] = round(current, 3 if 'lambda' in metric or 'afr' in metric else 1)
            if current > self._min_max[metric]['max']:
                self._min_max[metric]['max'] = round(current, 3 if 'lambda' in metric or 'afr' in metric else 1)

    def _write_log(self):
        if not self._log_file:
            return
        elapsed_ms = (datetime.datetime.now() - self._log_start_time).total_seconds() * 1000
        line = f"{elapsed_ms:.0f},{self._rpm:.0f},{self._boost:.1f},{self._coolant_temp:.1f},{self._oil_temp:.1f},{self._oil_pressure:.1f},{self._fuel_pressure:.1f},{self._voltage:.1f},{self._rpi_temp:.1f},{self._lambda:.3f},{self._afr:.1f},{self._egt:.0f},{self._accel_x:.2f},{self._accel_y:.2f},{self._accel_z:.2f},{self._knock_1:.2f},{self._knock_2:.2f},{self._tps:.1f},{self._ign_angle:.1f}\n"
        self._log_file.write(line)
        self._log_file.flush()

    def _write_overheat_log(self):
        if not self._log_file:
            return
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        self._log_file.write(f"\n# [ПЕРЕГРЕВ RPi] {timestamp}\n")
        self._log_file.write(f"# Температура процессора: {self._rpi_temp}°C\n")
        self._log_file.write(f"# Порог: {self._rpi_max_temp}°C\n")
        self._log_file.write(f"# Обороты: {self._rpm:.0f} RPM\n")
        self._log_file.write(f"# Напряжение: {self._voltage:.1f}V\n")
        self._log_file.write("\n")
        self._log_file.flush()

    def _check_limits(self):
        checks = [
            ('rpm', self._rpm, self._limits['rpm']['value'], False),
            ('boost', self._boost, self._limits['boost']['value'], False),
            ('coolant_temp', self._coolant_temp, self._limits['coolant_temp']['value'], False),
            ('oil_temp', self._oil_temp, self._limits['oil_temp']['value'], False),
            ('oil_pressure', self._oil_pressure, self._limits['oil_pressure']['value'], True),
            ('fuel_pressure', self._fuel_pressure, self._limits['fuel_pressure']['value'], True),
            ('voltage', self._voltage, self._limits['voltage']['value'], True),
            ('lambda', self._lambda, self._limits['lambda']['value'], False),
            ('egt', self._egt, self._limits['egt']['value'], False),
            ('knock', self._knock_1, self._limits.get('knock', {'value': 0.7, 'enabled': True})['value'], False),
            ('ign_angle', self._ign_angle, self._limits.get('ign_angle', {'value': 35, 'enabled': True})['value'], False),
            ('tps', self._tps, self._limits.get('tps', {'value': 85, 'enabled': True})['value'], False),
        ]

        for param, current, limit, below in checks:
            if not self._limits.get(param, {'enabled': True})['enabled']:
                self._exceed_counts[param] = 0
                self._alert_active[param] = False
                continue

            is_exceed = current > limit if not below else current < limit

            if is_exceed:
                self._exceed_counts[param] += 1
                if self._exceed_counts[param] >= 5 and not self._alert_active.get(param, False):
                    self._alert_active[param] = True
                    print(f"[ALERT] Превышение {param}: {current} (лимит {limit})")
            else:
                self._exceed_counts[param] = max(0, self._exceed_counts[param] - 1)
                if self._exceed_counts[param] < 5:
                    self._alert_active[param] = False

        old_global = self._global_alert
        self._global_alert = any(self._alert_active.values())
        if old_global != self._global_alert:
            self.dataChanged.emit()
            is_rpm_over = self._alert_active.get('rpm', False)
            self._rgb_controller.update(self._rpm, is_rpm_over, 8000)

    def update_data(self):
        """Симуляция данных (для тестирования)"""
        self._sim_time += 0.02
        if self._sim_time > 10:
            self._sim_time = 0

        if self._sim_time < 3:
            self._gps_speed = min(50, self._sim_time * 20)
            self._rpm = 800 + self._gps_speed * 150
        elif self._sim_time < 5:
            self._gps_speed = 50
            self._rpm = 8000
        elif self._sim_time < 8:
            self._gps_speed = max(0, 50 - (self._sim_time - 5) * 20)
            self._rpm = 800
        else:
            self._gps_speed = 0
            self._rpm = 800

        self._latitude = 55.751244 + math.sin(self._sim_time) * 0.001
        self._longitude = 37.618423 + math.cos(self._sim_time) * 0.001
        self._gps_satellites = 8 if self._sim_time < 8 else 12
        self._gps_fix = self._gps_satellites >= 4

        self._accel_y = (self._gps_speed - getattr(self, '_last_speed', 0)) / 0.02 if self._sim_time > 0 else 0
        self._last_speed = self._gps_speed
        self._accel_x = math.sin(self._sim_time * 2) * 2

        load = self._rpm / 8000
        self._coolant_temp = 85 + load * 25
        self._oil_temp = 90 + load * 30
        self._boost = load * 1.5
        self._voltage = 14.2 - load * 0.5
        self._lambda = 1.0 - load * 0.1
        self._afr = self._lambda * 14.7
        self._egt = 400 + load * 300
        self._rpi_temp = 45 + load * 25 + random.uniform(-2, 2)
        self._gear = 1 if self._rpm < 3000 else (2 if self._rpm < 5000 else (3 if self._rpm < 6500 else 4))
        self._boost_mode = "Eco" if self._rpm < 3000 else ("Sport" if self._rpm < 5000 else "Race")

        # Новые датчики
        self._knock_1, self._knock_2 = self._update_knock(self._rpm, load)
        self._tps = self._update_tps(self._rpm, load, self._boost)
        self._ign_angle = self._update_ignition_angle(self._rpm, load, self._tps, self._knock_1)

        if self._gps_speed > 0.5:
            if not self._track_recording:
                self._track_recording = True
            self._track_visualization.append({'lat': self._latitude, 'lon': self._longitude})
            if len(self._track_visualization) > 500:
                self._track_visualization = self._track_visualization[-500:]
        elif self._track_recording and self._gps_speed < 0.1:
            self._track_recording = False

        self._add_to_history()
        self._update_min_max()

        if self._logging_active:
            self._write_log()

        self._check_limits()
        self.dataChanged.emit()


# ======================== ЗАПУСК ========================

if __name__ == "__main__":
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()

    car_data = CarData()
    engine.rootContext().setContextProperty("car", car_data)

    qml_file = "dashboard.qml"
    if not os.path.exists(qml_file):
        print(f"[ОШИБКА] Файл {qml_file} не найден!")
        sys.exit(1)

    engine.load(QUrl.fromLocalFile(qml_file))

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec_())
    @pyqtProperty(float, notify=dataChanged)
    def rpm(self): return self._rpm

    @rpm.setter
    def rpm(self, value):
        if abs(self._rpm - value) > 1:
            self._rpm = value
            self._rgb_controller.update(value, False, 8000)
            self.dataChanged.emit()

    @pyqtProperty(float, notify=dataChanged)
    def boost(self): return self._boost

    @pyqtProperty(float, notify=dataChanged)
    def oil_pressure(self): return self._oil_pressure

    @pyqtProperty(float, notify=dataChanged)
    def oil_temp(self): return self._oil_temp

    @pyqtProperty(float, notify=dataChanged)
    def coolant_temp(self): return self._coolant_temp

    @pyqtProperty(float, notify=dataChanged)
    def fuel_pressure(self): return self._fuel_pressure

    @pyqtProperty(float, notify=dataChanged)
    def voltage(self): return self._voltage

    @pyqtProperty(float, notify=dataChanged)
    def lambda_value(self): return self._lambda

    @pyqtProperty(float, notify=dataChanged)
    def afr_value(self): return self._afr

    @pyqtProperty(float, notify=dataChanged)
    def egt(self): return self._egt

    @pyqtProperty(int, notify=dataChanged)
    def gear(self): return self._gear

    @pyqtProperty(str, notify=dataChanged)
    def boost_mode(self): return self._boost_mode

    @pyqtProperty(float, notify=dataChanged)
    def latitude(self): return self._latitude

    @pyqtProperty(float, notify=dataChanged)
    def longitude(self): return self._longitude

    @pyqtProperty(float, notify=dataChanged)
    def gps_speed(self): return self._gps_speed

    @pyqtProperty(int, notify=dataChanged)
    def gps_satellites(self): return self._gps_satellites

    @pyqtProperty(bool, notify=dataChanged)
    def gps_fix(self): return self._gps_fix

    @pyqtProperty(float, notify=dataChanged)
    def accel_x(self): return self._accel_x

    @pyqtProperty(float, notify=dataChanged)
    def accel_y(self): return self._accel_y

    @pyqtProperty(float, notify=dataChanged)
    def accel_z(self): return self._accel_z

    @pyqtProperty(float, notify=dataChanged)
    def rpi_temp(self): return self._rpi_temp

    @pyqtProperty(bool, notify=dataChanged)
    def track_recording(self): return self._track_recording

    @pyqtProperty(str, notify=dataChanged)
    def track_visualization_json(self):
        return json.dumps(self._track_visualization[-200:])

    @pyqtProperty(str, notify=dataChanged)
    def log_files_json(self): return self._log_files_json

    @pyqtProperty(str, notify=dataChanged)
    def storage_total(self): return self._format_bytes(self._storage_total)

    @pyqtProperty(str, notify=dataChanged)
    def storage_used(self): return self._format_bytes(self._storage_used)

    @pyqtProperty(str, notify=dataChanged)
    def storage_free(self): return self._format_bytes(self._storage_free)

    @pyqtProperty(str, notify=dataChanged)
    def logs_size(self): return self._format_bytes(self._logs_size)

    @pyqtProperty(str, notify=dataChanged)
    def system_size(self): return self._format_bytes(self._system_size)

    @pyqtProperty(int, notify=dataChanged)
    def storage_used_percent(self): return self._storage_used_percent

    @pyqtProperty(int, notify=dataChanged)
    def logs_count(self): return self._logs_count

    @pyqtProperty(int, notify=diagnostics_updated)
    def error_count(self): return self._diagnostic_engine.get_error_count()

    @pyqtProperty(int, notify=diagnostics_updated)
    def critical_error_count(self): return self._diagnostic_engine.get_critical_count()

    @pyqtProperty(bool, notify=diagnostics_updated)
    def has_critical_errors(self): return self._diagnostic_engine.has_critical_errors()

    @pyqtProperty(str, notify=diagnostics_updated)
    def error_list_json(self):
        errors = []
        try:
            for err in self._diagnostic_engine.get_active_errors():
                errors.append({
                    'id': err.id,
                    'name': err.name,
                    'description': err.description,
                    'severity': err.severity.value,
                    'severity_name': err.severity.name,
                    'timestamp': datetime.datetime.fromtimestamp(err.timestamp).strftime('%H:%M:%S'),
                    'solution': err.solution,
                    'source': err.source
                })
        except Exception as e:
            print(f"[ERRORS] Ошибка: {e}")
        return json.dumps(errors)

    @pyqtProperty(bool, notify=dataChanged)
    def auto_diagnostics_enabled(self): return self._auto_diagnostics_enabled

    @pyqtProperty(float, notify=dataChanged)
    def cpu_temperature(self): return self._rpi_temp

    # ===== НОВЫЕ ПАРАМЕТРЫ (ДЕТОНАЦИЯ, TPS, УГОЛ ЗАЖИГАНИЯ) =====

    @pyqtProperty(float, notify=dataChanged)
    def knock_1(self): return self._knock_1

    @pyqtProperty(float, notify=dataChanged)
    def knock_2(self): return self._knock_2

    @pyqtProperty(bool, notify=dataChanged)
    def knock_occurred(self): return self._knock_occurred

    @pyqtProperty(float, notify=dataChanged)
    def tps(self): return self._tps

    @pyqtProperty(bool, notify=dataChanged)
    def tps_closed(self): return self._tps_closed

    @pyqtProperty(bool, notify=dataChanged)
    def tps_wide(self): return self._tps_wide

    @pyqtProperty(float, notify=dataChanged)
    def ign_angle(self): return self._ign_angle

    @pyqtProperty(str, notify=dataChanged)
    def ign_status(self):
        if self._ign_angle < 10:
            return "Позднее (нагрузка)"
        elif self._ign_angle > 35:
            return "Раннее (экономия)"
        else:
            return "Норма"

    # ===== МЕТОДЫ ОБНОВЛЕНИЯ ДАННЫХ =====

    def _update_knock(self, rpm, load_factor):
        """
        Симуляция датчика детонации.
        В реальности данные читаются с CAN шины или аналогового входа.
        """
        base_knock = load_factor * 0.5 + (rpm / 8000) * 0.3
        spike = random.uniform(0, 0.15) if load_factor > 0.7 else 0
        knock_1 = min(1.0, base_knock + spike)
        knock_2 = min(1.0, base_knock * 0.9 + spike * 0.8)
        self._knock_occurred = knock_1 > 0.7
        return round(knock_1, 2), round(knock_2, 2)

    def _update_tps(self, rpm, load_factor, boost):
        """
        Симуляция положения дроссельной заслонки.
        """
        tps_raw = min(100, (load_factor * 80) + (boost * 15) + 5)
        if tps_raw > self._tps:
            tps = self._tps + (tps_raw - self._tps) * 0.3
        else:
            tps = self._tps + (tps_raw - self._tps) * 0.15
        self._tps_closed = tps < 2
        self._tps_wide = tps > 95
        return round(tps, 1)

    def _update_ignition_angle(self, rpm, load_factor, tps, knock_value):
        """
        Симуляция угла опережения зажигания.
        """
        if rpm < 1000:
            base_angle = 8
        elif rpm < 2000:
            base_angle = 12 + (rpm - 1000) / 1000 * 3
        elif rpm < 4000:
            base_angle = 15 + (rpm - 2000) / 2000 * 8
        elif rpm < 6000:
            base_angle = 23 + (rpm - 4000) / 2000 * 10
        else:
            base_angle = 33 + (rpm - 6000) / 2000 * 5

        load_corr = -load_factor * 15
        tps_corr = (tps - 50) / 50 * 5
        knock_corr = -knock_value * 12

        if self._knock_occurred and self._ign_angle > 10:
            knock_corr = -15

        ign_angle = base_angle + load_corr + tps_corr + knock_corr
        ign_angle = max(0, min(45, ign_angle))
        return round(ign_angle, 1)

    def _add_to_history(self):
        current_time = datetime.datetime.now().timestamp() * 1000
        self._history['timestamp'].append(current_time)
        self._history['rpm'].append(self._rpm)
        self._history['boost'].append(self._boost)
        self._history['coolant_temp'].append(self._coolant_temp)
        self._history['oil_temp'].append(self._oil_temp)
        self._history['oil_pressure'].append(self._oil_pressure)
        self._history['fuel_pressure'].append(self._fuel_pressure)
        self._history['voltage'].append(self._voltage)
        self._history['lambda'].append(self._lambda)
        self._history['afr'].append(self._afr)
        self._history['egt'].append(self._egt)
        self._history['rpi_temp'].append(self._rpi_temp)
        self._history['accel_x'].append(self._accel_x)
        self._history['accel_y'].append(self._accel_y)
        self._history['accel_z'].append(self._accel_z)
        self._history['knock_1'].append(self._knock_1)
        self._history['knock_2'].append(self._knock_2)
        self._history['tps'].append(self._tps)
        self._history['ign_angle'].append(self._ign_angle)

        if len(self._history['timestamp']) > self._history_max_points:
            for key in self._history:
                self._history[key] = self._history[key][-self._history_max_points:]

    def _update_min_max(self):
        metrics = ['rpm', 'boost', 'coolant_temp', 'oil_temp', 'oil_pressure',
                   'fuel_pressure', 'voltage', 'lambda', 'afr', 'egt',
                   'rpi_temp', 'accel_x', 'accel_y', 'accel_z',
                   'knock_1', 'knock_2', 'tps', 'ign_angle']
        for metric in metrics:
            current = getattr(self, '_' + metric)
            if self._min_max[metric]['min'] == 0 or current < self._min_max[metric]['min']:
                self._min_max[metric]['min'] = round(current, 3 if 'lambda' in metric or 'afr' in metric else 1)
            if current > self._min_max[metric]['max']:
                self._min_max[metric]['max'] = round(current, 3 if 'lambda' in metric or 'afr' in metric else 1)

    def _write_log(self):
        if not self._log_file:
            return
        elapsed_ms = (datetime.datetime.now() - self._log_start_time).total_seconds() * 1000
        line = f"{elapsed_ms:.0f},{self._rpm:.0f},{self._boost:.1f},{self._coolant_temp:.1f},{self._oil_temp:.1f},{self._oil_pressure:.1f},{self._fuel_pressure:.1f},{self._voltage:.1f},{self._rpi_temp:.1f},{self._lambda:.3f},{self._afr:.1f},{self._egt:.0f},{self._accel_x:.2f},{self._accel_y:.2f},{self._accel_z:.2f},{self._knock_1:.2f},{self._knock_2:.2f},{self._tps:.1f},{self._ign_angle:.1f}\n"
        self._log_file.write(line)
        self._log_file.flush()

    def _write_overheat_log(self):
        if not self._log_file:
            return
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        self._log_file.write(f"\n# [ПЕРЕГРЕВ RPi] {timestamp}\n")
        self._log_file.write(f"# Температура процессора: {self._rpi_temp}°C\n")
        self._log_file.write(f"# Порог: {self._rpi_max_temp}°C\n")
        self._log_file.write(f"# Обороты: {self._rpm:.0f} RPM\n")
        self._log_file.write(f"# Напряжение: {self._voltage:.1f}V\n")
        self._log_file.write("\n")
        self._log_file.flush()

    def _check_limits(self):
        checks = [
            ('rpm', self._rpm, self._limits['rpm']['value'], False),
            ('boost', self._boost, self._limits['boost']['value'], False),
            ('coolant_temp', self._coolant_temp, self._limits['coolant_temp']['value'], False),
            ('oil_temp', self._oil_temp, self._limits['oil_temp']['value'], False),
            ('oil_pressure', self._oil_pressure, self._limits['oil_pressure']['value'], True),
            ('fuel_pressure', self._fuel_pressure, self._limits['fuel_pressure']['value'], True),
            ('voltage', self._voltage, self._limits['voltage']['value'], True),
            ('lambda', self._lambda, self._limits['lambda']['value'], False),
            ('egt', self._egt, self._limits['egt']['value'], False),
            ('knock', self._knock_1, self._limits.get('knock', {'value': 0.7, 'enabled': True})['value'], False),
            ('ign_angle', self._ign_angle, self._limits.get('ign_angle', {'value': 35, 'enabled': True})['value'], False),
            ('tps', self._tps, self._limits.get('tps', {'value': 85, 'enabled': True})['value'], False),
        ]

        for param, current, limit, below in checks:
            if not self._limits.get(param, {'enabled': True})['enabled']:
                self._exceed_counts[param] = 0
                self._alert_active[param] = False
                continue

            is_exceed = current > limit if not below else current < limit

            if is_exceed:
                self._exceed_counts[param] += 1
                if self._exceed_counts[param] >= 5 and not self._alert_active.get(param, False):
                    self._alert_active[param] = True
                    print(f"[ALERT] Превышение {param}: {current} (лимит {limit})")
            else:
                self._exceed_counts[param] = max(0, self._exceed_counts[param] - 1)
                if self._exceed_counts[param] < 5:
                    self._alert_active[param] = False

        old_global = self._global_alert
        self._global_alert = any(self._alert_active.values())
        if old_global != self._global_alert:
            self.dataChanged.emit()
            is_rpm_over = self._alert_active.get('rpm', False)
            self._rgb_controller.update(self._rpm, is_rpm_over, 8000)

    def update_data(self):
        """Симуляция данных (для тестирования)"""
        self._sim_time += 0.02
        if self._sim_time > 10:
            self._sim_time = 0

        if self._sim_time < 3:
            self._gps_speed = min(50, self._sim_time * 20)
            self._rpm = 800 + self._gps_speed * 150
        elif self._sim_time < 5:
            self._gps_speed = 50
            self._rpm = 8000
        elif self._sim_time < 8:
            self._gps_speed = max(0, 50 - (self._sim_time - 5) * 20)
            self._rpm = 800
        else:
            self._gps_speed = 0
            self._rpm = 800

        self._latitude = 55.751244 + math.sin(self._sim_time) * 0.001
        self._longitude = 37.618423 + math.cos(self._sim_time) * 0.001
        self._gps_satellites = 8 if self._sim_time < 8 else 12
        self._gps_fix = self._gps_satellites >= 4

        self._accel_y = (self._gps_speed - getattr(self, '_last_speed', 0)) / 0.02 if self._sim_time > 0 else 0
        self._last_speed = self._gps_speed
        self._accel_x = math.sin(self._sim_time * 2) * 2

        load = self._rpm / 8000
        self._coolant_temp = 85 + load * 25
        self._oil_temp = 90 + load * 30
        self._boost = load * 1.5
        self._voltage = 14.2 - load * 0.5
        self._lambda = 1.0 - load * 0.1
        self._afr = self._lambda * 14.7
        self._egt = 400 + load * 300
        self._rpi_temp = 45 + load * 25 + random.uniform(-2, 2)
        self._gear = 1 if self._rpm < 3000 else (2 if self._rpm < 5000 else (3 if self._rpm < 6500 else 4))
        self._boost_mode = "Eco" if self._rpm < 3000 else ("Sport" if self._rpm < 5000 else "Race")

        # Новые датчики
        self._knock_1, self._knock_2 = self._update_knock(self._rpm, load)
        self._tps = self._update_tps(self._rpm, load, self._boost)
        self._ign_angle = self._update_ignition_angle(self._rpm, load, self._tps, self._knock_1)

        if self._gps_speed > 0.5:
            if not self._track_recording:
                self._track_recording = True
            self._track_visualization.append({'lat': self._latitude, 'lon': self._longitude})
            if len(self._track_visualization) > 500:
                self._track_visualization = self._track_visualization[-500:]
        elif self._track_recording and self._gps_speed < 0.1:
            self._track_recording = False

        self._add_to_history()
        self._update_min_max()

        if self._logging_active:
            self._write_log()

        self._check_limits()
        self.dataChanged.emit()