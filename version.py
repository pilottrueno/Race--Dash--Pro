#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
RACE DASH PRO - Информация о версии
"""

__version__ = "3.0"
__author__ = "Бухлаков Евгений"
__created__ = "29.04.2026"
__license__ = "MIT"
__github__ = "https://github.com/buhlakov/race-dash-pro"
__telegram__ = "@race_dash_pro"
__email__ = "buhlakov@race-dash.ru"

PROJECT_INFO = {
    "name": "RACE DASH PRO",
    "version": __version__,
    "author": __author__,
    "created": __created__,
    "license": __license__,
    "github": __github__,
    "telegram": __telegram__,
    "email": __email__,
}

def print_info():
    print("=" * 50)
    print(f"  {PROJECT_INFO['name']} v{PROJECT_INFO['version']}")
    print("=" * 50)
    print(f"  Автор:    {PROJECT_INFO['author']}")
    print(f"  Дата:     {PROJECT_INFO['created']}")
    print(f"  GitHub:   {PROJECT_INFO['github']}")
    print(f"  Telegram: {PROJECT_INFO['telegram']}")
    print("=" * 50)

if __name__ == "__main__":
    print_info()