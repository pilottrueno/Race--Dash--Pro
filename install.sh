#!/bin/bash
#==============================================================================
# RACE DASH PRO - Установщик
# Автор: Бухлаков Евгений
#==============================================================================

echo "╔═══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                       ║"
echo "║   ██████╗  █████╗  ██████╗███████╗    ██████╗  █████╗ ███████╗██╗  ██╗ ║"
echo "║   ██╔══██╗██╔══██╗██╔════╝██╔════╝    ██╔══██╗██╔══██╗██╔════╝██║  ██║ ║"
echo "║   ██████╔╝███████║██║     █████╗      ██║  ██║███████║███████╗███████║ ║"
echo "║   ██╔══██╗██╔══██║██║     ██╔══╝      ██║  ██║██╔══██║╚════██║██╔══██║ ║"
echo "║   ██║  ██║██║  ██║╚██████╗███████╗    ██████╔╝██║  ██║███████║██║  ██║ ║"
echo "║   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚══════╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ║"
echo "║                                                                       ║"
echo "╚═══════════════════════════════════════════════════════════════════════╝"
echo ""
echo "  RACE DASH PRO v3.0 - Установщик"
echo "  Автор: Бухлаков Евгений"
echo ""

# Обновление системы
echo "📦 Обновление системы..."
sudo apt update && sudo apt upgrade -y

# Установка зависимостей
echo "📦 Установка зависимостей..."
sudo apt install -y python3-pyqt5 python3-pyqt5.qtmultimedia
sudo apt install -y python3-smbus i2c-tools can-utils
sudo apt install -y xserver-xorg xinit git

# Установка Python библиотек
echo "📦 Установка Python библиотек..."
pip3 install PyQt5 numpy pyserial python-can

# Включение интерфейсов
echo "⚙️ Настройка интерфейсов..."
sudo raspi-config nonint do_i2c 0
sudo raspi-config nonint do_spi 0

# Создание папки проекта
echo "📁 Создание папки проекта..."
mkdir -p ~/dashboard

echo ""
echo "✅ Установка завершена!"
echo ""
echo "📋 Дальнейшие действия:"
echo "   1. Скопируйте dashboard.py и dashboard.qml в ~/dashboard/"
echo "   2. Запустите панель: cd ~/dashboard && python3 dashboard.py"
echo "   3. Для автозапуска: sudo cp dashboard.service /etc/systemd/system/"
echo ""