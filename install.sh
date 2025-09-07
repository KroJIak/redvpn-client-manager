
#!/usr/bin/env bash
set -euo pipefail

echo "RedVPN Quick Start Button Installer"
echo "===================================="

# Проверяем и устанавливаем необходимые зависимости
check_dependencies() {
    local missing_deps=()
    
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi
    
    if ! command -v sing-box &> /dev/null; then
        missing_deps+=("sing-box")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "Обнаружены отсутствующие зависимости:"
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        echo ""
        echo "Начинаю установку..."
        
        # Обновляем пакеты
        echo "Обновление списка пакетов..."
        sudo apt update
        
        # Устанавливаем curl и jq через apt
        if [[ " ${missing_deps[@]} " =~ " curl " ]]; then
            echo "Установка curl..."
            sudo apt install -y curl
        fi
        
        if [[ " ${missing_deps[@]} " =~ " jq " ]]; then
            echo "Установка jq..."
            sudo apt install -y jq
        fi
        
        # Устанавливаем sing-box через официальный скрипт
        if [[ " ${missing_deps[@]} " =~ " sing-box " ]]; then
            echo "Установка sing-box..."
            curl -fsSL https://sing-box.app/install.sh | sh
        fi
        
        echo ""
        echo "Установка зависимостей завершена!"
        echo ""
    fi
}

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
        return 1
    fi
    
    return 0
}

# Основная функция
main() {
    echo "Проверка и установка зависимостей..."
    check_dependencies
    echo "✓ Зависимости проверены"
    
    echo ""
    echo "Введите ваш ssconf ключ RedVPN:"
    echo "Формат: ssconf://red.alfanw.net/key/ВАШ_КЛЮЧ#RedVPN"
    echo ""
    
    # Проверяем, что stdin доступен для чтения
    if [ ! -t 0 ]; then
        echo "Ошибка: Нет доступа к stdin для ввода ключа"
        echo "Запустите скрипт интерактивно: bash install.sh"
        exit 1
    fi
    
    echo -n "ssconf ключ: "
    read -r ssconf_key
    
    # Проверяем ключ
    if ! validate_ssconf_key "$ssconf_key"; then
        exit 1
    fi
    
    echo "✓ Ключ принят: ${ssconf_key:0:20}..."
    
    echo ""
    echo "Запуск настройки RedVPN..."
    echo "=========================="
    
    # Запускаем setup.sh с передачей ключа
    bash "$(dirname "$0")/redvpn/setup.sh" "$ssconf_key"
    
    echo ""
    echo "Установка завершена!"
    echo "Теперь вы можете добавить команду в Custom Command Toggle:"
    echo "  Включить VPN: systemctl --user start redvpn.service"
    echo "  Выключить VPN: systemctl --user stop redvpn.service"
    echo "  Статус VPN: systemctl --user is-active redvpn.service"
}

main "$@"