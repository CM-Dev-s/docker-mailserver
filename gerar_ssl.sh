#!/bin/bash
# Script para gerar certificados SSL auto-assinados para soundchain.shop
# Este script é executado dentro do container docker-mailserver

set -e

DOMAIN="mail.soundchain.shop"
SSL_DIR="/tmp/docker-mailserver/ssl"
KEY_FILE="$SSL_DIR/${DOMAIN}-key.pem"
CERT_FILE="$SSL_DIR/${DOMAIN}-cert.pem"
CA_KEY="$SSL_DIR/demoCA/private/cakey.pem"
CA_CERT="$SSL_DIR/demoCA/cacert.pem"

echo "🔐 Gerando certificados SSL auto-assinados para $DOMAIN"

# Criar diretórios necessários
mkdir -p "$SSL_DIR/demoCA/private"
mkdir -p "$SSL_DIR/demoCA/newcerts"
touch "$SSL_DIR/demoCA/index.txt"
echo "01" > "$SSL_DIR/demoCA/serial"

# Gerar chave privada da CA
echo "📋 Gerando chave privada da CA..."
openssl genrsa -out "$CA_KEY" 2048

# Gerar certificado da CA
echo "📋 Gerando certificado da CA..."
openssl req -new -x509 -key "$CA_KEY" -out "$CA_CERT" -days 3650 -subj "/C=BR/ST=SP/L=Sao Paulo/O=soundchain.shop/OU=IT/CN=soundchain.shop CA"

# Gerar chave privada do servidor
echo "📋 Gerando chave privada do servidor..."
openssl genrsa -out "$KEY_FILE" 2048

# Gerar requisição de certificado
echo "📋 Gerando requisição de certificado..."
openssl req -new -key "$KEY_FILE" -out "$SSL_DIR/${DOMAIN}.csr" -subj "/C=BR/ST=SP/L=Sao Paulo/O=soundchain.shop/OU=Mail Server/CN=$DOMAIN"

# Criar arquivo de configuração para extensões
cat > "$SSL_DIR/v3.ext" << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN
DNS.2 = soundchain.shop
DNS.3 = mail.soundchain.shop
IP.1 = 212.85.1.63
EOF

# Gerar certificado do servidor assinado pela CA
echo "📋 Gerando certificado do servidor..."
openssl x509 -req -in "$SSL_DIR/${DOMAIN}.csr" -CA "$CA_CERT" -CAkey "$CA_KEY" -CAcreateserial -out "$CERT_FILE" -days 365 -extensions v3_req -extfile "$SSL_DIR/v3.ext"

# Definir permissões corretas
chmod 600 "$KEY_FILE" "$CA_KEY"
chmod 644 "$CERT_FILE" "$CA_CERT"

# Verificar certificados
echo "✅ Verificando certificados gerados..."
openssl x509 -in "$CERT_FILE" -text -noout | grep -A 3 "Subject:" || true
openssl x509 -in "$CERT_FILE" -text -noout | grep -A 5 "X509v3 Subject Alternative Name:" || true

# Limpar arquivos temporários
rm -f "$SSL_DIR/${DOMAIN}.csr" "$SSL_DIR/v3.ext"

echo "✅ Certificados SSL auto-assinados gerados com sucesso!"
echo "📁 Arquivos criados:"
echo "   - Chave privada: $KEY_FILE"
echo "   - Certificado: $CERT_FILE"
echo "   - CA Cert: $CA_CERT"

# Listar arquivos SSL para verificação
echo ""
echo "� Estrutura de arquivos SSL:"
ls -la "$SSL_DIR/" 2>/dev/null || echo "Diretório SSL ainda não existe"
find "$SSL_DIR/" -name "*.pem" -exec ls -la {} \; 2>/dev/null || echo "Arquivos PEM criados"

echo ""
echo "🚀 Certificados prontos para uso com SSL_TYPE=self-signed"
