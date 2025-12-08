# RedVPN Client Manager

<div align="center">

![RedVPN Logo](https://img.shields.io/badge/RedVPN-Client%20Manager-red?style=for-the-badge&logo=shield&logoColor=white)

**Клиентский менеджер для VPN-провайдера RedVPN с поддержкой ssconf протокола**

[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](../LICENSE)
[![Platform](https://img.shields.io/badge/platform-Debian%20%7C%20Ubuntu-orange.svg?style=flat-square)](https://www.debian.org/)
[![Shell](https://img.shields.io/badge/shell-Bash-green.svg?style=flat-square)](https://www.gnu.org/software/bash/)

[English](../README.md) | [Русский](README-RU.md)

</div>

---

## Содержание

- [Описание](#описание)
- [Особенности](#особенности)
- [Требования](#требования)
- [Быстрая установка](#быстрая-установка)
- [Использование](#использование)
- [Конфигурация](#конфигурация)
- [Часто задаваемые вопросы](#часто-задаваемые-вопросы)
- [Устранение неполадок](#устранение-неполадок)
- [Лицензия](#лицензия)

---

## Описание

**RedVPN Client Manager** — это клиентский менеджер для VPN-провайдера **RedVPN**. Проект предоставляет удобный способ подключения и управления VPN-соединением через протокол **ssconf** с использованием **sing-box** на системах Debian/Ubuntu.

### Ключевые преимущества:

- **Безопасность**: Использует проверенный sing-box для туннелирования
- **Простота**: Один скрипт для полной настройки RedVPN
- **Скорость**: Автоматическое получение конфигурации от сервера RedVPN
- **Удобство**: CLI-интерфейс для управления VPN
- **Автоматизация**: Интеграция с systemd для автозапуска
- **Надежность**: Проверка зависимостей и валидация ssconf ключей

---

## Особенности

### Автоматическая установка
- Проверка и установка всех необходимых зависимостей для Debian/Ubuntu
- Автоматическая настройка systemd сервиса для RedVPN
- Конфигурация polkit для управления без sudo

### Удобное управление
- Простые CLI команды (`redvpn start/stop/status`)
- Интеграция с Custom Command Toggle
- Отображение текущего IP-адреса через RedVPN

### Динамическая конфигурация
- Автоматическое получение параметров сервера RedVPN через API
- Обновление конфигурации sing-box при каждом запуске
- Поддержка ssconf протокола RedVPN

---

## Требования

### Системные требования
- **ОС**: Debian 10+ или Ubuntu 18.04+
- **Архитектура**: x86_64, ARM64
- **Права**: sudo доступ для установки
- **VPN**: Активная подписка на RedVPN с ssconf ключом

### Зависимости
- `curl` - для загрузки и API запросов
- `jq` - для парсинга JSON ответов
- `sing-box` - VPN клиент (устанавливается автоматически)

---

## Быстрая установка

### 1. Клонирование репозитория
```bash
git clone https://github.com/your-username/redvpn-client-manager.git
cd redvpn-client-manager
```

### 2. Запуск установщика
```bash
bash install.sh
```

### 3. Ввод ssconf ключа
```
Введите ваш ssconf ключ RedVPN:
Формат: ssconf://red.alfanw.net/key/ВАШ_КЛЮЧ#RedVPN
```

> **Примечание**: ssconf ключ выдается провайдером RedVPN при покупке подписки

## Использование

### Основные команды

```bash
# Включить VPN
redvpn start

# Выключить VPN  
redvpn stop

# Проверить статус
redvpn status

# Перезапустить VPN
redvpn restart

# Показать справку
redvpn help
```

## Конфигурация

### Структура конфигурации

```
~/.config/redvpn/
├── redvpn.conf          # Основная конфигурация
└── ...

~/.config/sing-box/
└── redvpn.json          # Конфигурация sing-box (автогенерируется)
```

### Файл конфигурации

`~/.config/redvpn/redvpn.conf`:
```bash
# RedVPN Configuration
SSCONF='ssconf://red.alfanw.net/key/ВАШ_КЛЮЧ#RedVPN'
```

### Конфигурация sing-box

Файл `~/.config/sing-box/redvpn.json` создается автоматически при каждом запуске:

```json
{
  "log": { "level": "info" },
  "inbounds": [
    { 
      "type": "tun", 
      "interface_name": "redvpn-tun0",
      "address": ["172.19.0.1/30"],
      "auto_route": true, 
      "strict_route": false,
      "sniff": true,
      "stack": "system" 
    }
  ],
  "outbounds": [
    { 
      "type": "shadowsocks",
      "tag": "proxy",
      "method": "chacha20-ietf-poly1305",
      "password": "your-password",
      "server": "your-server.com",
      "server_port": 443
    },
    { 
      "type": "direct",
      "tag": "direct"
    }
  ],
  "route": {
    "auto_detect_interface": true,
    "final": "proxy",
    "rules": [
      { "protocol": "dns", "outbound": "direct" },
      { "ip_cidr": ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "127.0.0.0/8"], "outbound": "direct" }
    ]
  }
}
```

---

### Как изменить ssconf ключ?

Отредактируйте файл `~/.config/redvpn/redvpn.conf`:
```bash
nano ~/.config/redvpn/redvpn.conf
```

### Как удалить RedVPN?

```bash
# Остановить сервис
systemctl --user stop redvpn.service

# Удалить файлы
sudo rm -f /usr/local/bin/redvpn
sudo rm -f /usr/local/bin/redvpn-update
sudo rm -f /etc/systemd/system/redvpn.service
sudo rm -f /etc/sudoers.d/redvpn-*
sudo rm -f /etc/polkit-1/rules.d/50-redvpn.rules

# Удалить конфигурацию
rm -rf ~/.config/redvpn
rm -rf ~/.config/sing-box

# Перезагрузить systemd
sudo systemctl daemon-reload
```

### Поддерживаются ли другие VPN протоколы?

Этот клиентский менеджер предназначен исключительно для VPN-провайдера **RedVPN** и поддерживает только ssconf протокол через sing-box. Для других VPN-провайдеров используйте соответствующие клиенты.

---

## Устранение неполадок

### Ошибка: "Не удалось получить ответ от сервера"

**Причины:**
- Сервер недоступен
- Неверный ssconf ключ
- Блокировка домена провайдером

**Решение:**
```bash
# Проверьте доступность сервера
curl -I https://red.alfanw.net

# Проверьте формат ключа
cat ~/.config/redvpn/redvpn.conf
```

### Ошибка: "Permission denied"

**Причины:**
- Неправильные права доступа
- Проблемы с polkit

**Решение:**
```bash
# Перезагрузите систему
sudo reboot

# Или обновите группы
newgrp systemd-journal
```

### Ошибка: "sing-box not found"

**Причины:**
- sing-box не установлен
- Проблемы с PATH

**Решение:**
```bash
# Переустановите sing-box
curl -fsSL https://sing-box.app/install.sh | sh

# Проверьте установку
which sing-box
```

### VPN не подключается

**Диагностика:**
```bash
# Проверьте статус сервиса
systemctl --user status redvpn.service

# Проверьте логи
journalctl --user -u redvpn.service -f

# Проверьте конфигурацию
cat ~/.config/sing-box/redvpn.json
```

### Проблемы с маршрутизацией

**Решение:**
```bash
# Проверьте таблицу маршрутизации
ip route show

# Проверьте сетевые интерфейсы
ip addr show
```

---

## Лицензия

Этот проект распространяется под лицензией MIT. См. файл [LICENSE](../LICENSE) для подробностей.

---

<div align="center">

**Сделано для пользователей RedVPN на Debian/Ubuntu**

</div>
