#!/bin/bash
# Script wrapper para executar configurações antes do supervisord

set -e

echo "🚀 Iniciando docker-mailserver para soundchain.shop..."

# Executar configuração SSL
if [ -f "/usr/local/bin/setup_ssl_startup.sh" ]; then
    echo "🔐 Executando configuração SSL..."
    /usr/local/bin/setup_ssl_startup.sh
fi

# Executar configurações adicionais se necessário
echo "✅ Configurações iniciais concluídas"

# Iniciar supervisord
echo "🎯 Iniciando supervisord..."
exec supervisord -c /etc/supervisor/supervisord.conf
