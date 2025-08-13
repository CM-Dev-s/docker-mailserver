#!/bin/bash
# Script de startup personalizado para soundchain.shop
# Este script verifica e gera certificados SSL se necessário

set -e

SSL_DIR="/tmp/docker-mailserver/ssl"
CERT_FILE="$SSL_DIR/mail.soundchain.shop-cert.pem"
KEY_FILE="$SSL_DIR/mail.soundchain.shop-key.pem"

# Função para gerar certificados SSL
generate_ssl_certificates() {
    echo "🔐 Certificados SSL não encontrados. Gerando certificados auto-assinados..."
    
    # Executar script de geração de SSL
    if [ -f "/usr/local/bin/gerar_ssl.sh" ]; then
        /usr/local/bin/gerar_ssl.sh
    else
        echo "❌ Script gerar_ssl.sh não encontrado!"
        exit 1
    fi
}

# Verificar se SSL_TYPE está configurado para self-signed
if [ "${SSL_TYPE}" = "self-signed" ]; then
    echo "🔍 Verificando certificados SSL para SSL_TYPE=self-signed..."
    
    # Verificar se os certificados existem
    if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
        generate_ssl_certificates
    else
        echo "✅ Certificados SSL já existem"
        
        # Verificar se os certificados são válidos
        if ! openssl x509 -in "$CERT_FILE" -noout -checkend 86400 2>/dev/null; then
            echo "⚠️  Certificado expirado ou inválido. Regenerando..."
            generate_ssl_certificates
        else
            echo "✅ Certificados SSL são válidos"
        fi
    fi
else
    echo "ℹ️  SSL_TYPE não é self-signed. Pulando geração de certificados."
fi

echo "✅ Configuração SSL concluída"
