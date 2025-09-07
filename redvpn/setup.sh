#!/usr/bin/env bash
set -euo pipefail

# Проверяем формат ssconf ключа
validate_ssconf_key() {
    local key="$1"
    
    if [ -z "$key" ]; then
        echo "Ошибка: Ключ не может быть пустым!"
        return 1
    fi
    
    if [[ ! "$key" =~ ^ssconf:// ]]; then
        echo "Ошибка: Неверный формат ssconf ключа!"
        echo "Получен ключ: '$key'"
        echo "Ожидаемый формат: ssconf://red.alfanw.net/key/ВАШ_КЛЮЧ#RedVPN"
        return 1
    fi
    
    return 0
}

# Проверяем, что передан ssconf ключ
if [ $# -ne 1 ]; then
    echo "Ошибка: Необходимо передать ssconf ключ в качестве аргумента"
    echo "Использование: $0 <ssconf_key>"
    exit 1
fi

SSCONF_KEY="$1"

# Проверяем формат ключа
if ! validate_ssconf_key "$SSCONF_KEY"; then
    exit 1
fi

echo "Настройка RedVPN..."
echo "==================="

# Создаем необходимые директории
echo "Создание директорий..."
mkdir -p "$HOME/.config/redvpn"
mkdir -p "$HOME/.config/sing-box"

# Записываем ключ в redvpn.conf
echo "Сохранение ssconf ключа..."
cat > "$HOME/.config/redvpn/redvpn.conf" << EOF
# RedVPN Configuration
SSCONF='$SSCONF_KEY'
EOF

echo "Ключ сохранен в $HOME/.config/redvpn/redvpn.conf"

# Копируем готовый redvpn-update
echo "Копирование redvpn-update..."
SCRIPT_DIR="$(dirname "$0")"

# Копируем redvpn-update в /usr/local/bin/
echo "Копирование redvpn-update в /usr/local/bin/..."
sudo cp "$SCRIPT_DIR/redvpn-update" "/usr/local/bin/redvpn-update"
sudo chmod +x "/usr/local/bin/redvpn-update"

# Копируем redvpn CLI в /usr/local/bin/
echo "Копирование redvpn CLI в /usr/local/bin/..."
sudo cp "$SCRIPT_DIR/redvpn" "/usr/local/bin/redvpn"
sudo chmod +x "/usr/local/bin/redvpn"

# Копируем redvpn.service в /etc/systemd/system/ с заменой плейсхолдеров
echo "Копирование systemd сервиса..."
CURRENT_USER="$(whoami)"
CURRENT_GROUP="$(id -gn)"
sed "s/__USER__/$CURRENT_USER/g; s/__GROUP__/$CURRENT_GROUP/g; s|__HOME__|$HOME|g" "$SCRIPT_DIR/redvpn.service" | sudo tee "/etc/systemd/system/redvpn.service" > /dev/null

# Перезагружаем systemd (НЕ включаем автозапуск)
echo "Настройка systemd сервиса..."
sudo systemctl daemon-reload
# Сервис НЕ включается для автозапуска - только по требованию пользователя

# Настраиваем sudo без пароля для команд systemctl redvpn
echo "Настройка sudo без пароля для redvpn команд..."
SUDOERS_RULE="$CURRENT_USER ALL=(ALL) NOPASSWD: /usr/local/bin/redvpn"
echo "$SUDOERS_RULE" | sudo tee "/etc/sudoers.d/redvpn-$CURRENT_USER" > /dev/null
sudo chmod 440 "/etc/sudoers.d/redvpn-$CURRENT_USER"

# Добавляем пользователя в группу systemd-journal для управления сервисами
echo "Добавление пользователя в группу systemd-journal..."
sudo usermod -a -G systemd-journal "$CURRENT_USER"

# Удаляем старые polkit правила
echo "Очистка старых polkit правил..."
sudo rm -f "/etc/polkit-1/localauthority/50-local.d/50-redvpn.pkla"
sudo rm -f "/etc/polkit-1/localauthority/50-local.d/51-redvpn-service.pkla"
sudo rm -f "/etc/polkit-1/rules.d/50-redvpn.rules"

# Создаем простое и эффективное polkit правило
echo "Создание polkit правила для redvpn..."
sudo mkdir -p "/etc/polkit-1/rules.d"
sudo tee "/etc/polkit-1/rules.d/50-redvpn.rules" > /dev/null << EOF
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.systemd1.manage-units" &&
        subject.user == "$CURRENT_USER" &&
        (action.lookup("unit") == "redvpn.service" || 
         action.lookup("unit") == "redvpn")) {
        return polkit.Result.YES;
    }
});
EOF

echo ""
echo "Настройка завершена!"
echo "===================="
echo "RedVPN сервис настроен."
echo ""
echo "⚠️  ВАЖНО: Для применения изменений в группах и polkit:"
echo "   1. Перезагрузите систему ИЛИ"
echo "   2. Выполните: newgrp systemd-journal"
echo "   3. Перезапустите сессию (logout/login)"
echo ""
echo "Доступные команды:"
echo "  redvpn start   - Включить VPN"
echo "  redvpn stop    - Выключить VPN"
echo "  redvpn status  - Показать статус VPN"
echo "  redvpn restart - Перезапустить VPN"
echo ""
echo "Для Custom Command Toggle используйте:"
echo "  Toggle Command:   redvpn start"
echo "  Untoggle Command: redvpn stop"
echo "  Status Command:   redvpn status"