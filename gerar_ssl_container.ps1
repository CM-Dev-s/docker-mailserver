# Script PowerShell para gerar certificados SSL usando o container mailserver

Write-Host "🔐 Gerando certificados SSL usando o container mailserver..." -ForegroundColor Cyan

# Verificar se o container está rodando
try {
    $containerStatus = docker ps --filter "name=mailserver" --format "{{.Names}}" 2>$null
    if (-not $containerStatus -or $containerStatus -notcontains "mailserver") {
        Write-Host "⚠️  Container mailserver não está rodando. Iniciando..." -ForegroundColor Yellow
        docker-compose up -d
        Start-Sleep 10
    } else {
        Write-Host "✅ Container mailserver está rodando" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Erro ao verificar container" -ForegroundColor Red
    exit 1
}

# Script shell para executar dentro do container
$sslScript = @'
#!/bin/bash
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
openssl req -new -x509 -key "$CA_KEY" -out "$CA_CERT" -days 3650 \
  -subj "/C=BR/ST=SP/L=Sao Paulo/O=soundchain.shop/OU=IT/CN=soundchain.shop CA"

# Gerar chave privada do servidor
echo "📋 Gerando chave privada do servidor..."
openssl genrsa -out "$KEY_FILE" 2048

# Gerar requisição de certificado
echo "📋 Gerando requisição de certificado..."
openssl req -new -key "$KEY_FILE" -out "$SSL_DIR/${DOMAIN}.csr" \
  -subj "/C=BR/ST=SP/L=Sao Paulo/O=soundchain.shop/OU=Mail Server/CN=$DOMAIN"

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
openssl x509 -req -in "$SSL_DIR/${DOMAIN}.csr" -CA "$CA_CERT" -CAkey "$CA_KEY" \
  -CAcreateserial -out "$CERT_FILE" -days 365 -extensions v3_req -extfile "$SSL_DIR/v3.ext"

# Definir permissões corretas
chmod 600 "$KEY_FILE" "$CA_KEY"
chmod 644 "$CERT_FILE" "$CA_CERT"

# Verificar certificados
echo "✅ Verificando certificados gerados..."
openssl x509 -in "$CERT_FILE" -text -noout | grep -A 3 "Subject:"
openssl x509 -in "$CERT_FILE" -text -noout | grep -A 5 "X509v3 Subject Alternative Name:"

# Limpar arquivos temporários
rm -f "$SSL_DIR/${DOMAIN}.csr" "$SSL_DIR/v3.ext"

echo "✅ Certificados SSL auto-assinados gerados com sucesso!"
echo "📁 Arquivos criados:"
echo "   - Chave privada: $KEY_FILE"
echo "   - Certificado: $CERT_FILE"
echo "   - CA Cert: $CA_CERT"

# Listar arquivos SSL
echo ""
echo "📋 Estrutura de arquivos SSL:"
ls -la "$SSL_DIR/"
find "$SSL_DIR/" -name "*.pem" -exec ls -la {} \;
'@

Write-Host "📝 Criando script temporário..." -ForegroundColor Yellow
$tempScript = [System.IO.Path]::GetTempFileName() + ".sh"
$sslScript | Out-File -FilePath $tempScript -Encoding UTF8

try {
    Write-Host "🐳 Executando script no container mailserver..." -ForegroundColor Yellow
    
    # Copiar script para o container
    docker cp $tempScript mailserver:/tmp/generate_ssl.sh
    
    # Tornar o script executável e executá-lo
    docker exec mailserver chmod +x /tmp/generate_ssl.sh
    docker exec mailserver /tmp/generate_ssl.sh
    
    # Limpar script temporário do container
    docker exec mailserver rm -f /tmp/generate_ssl.sh
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Certificados SSL gerados com sucesso!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📋 Verificando arquivos gerados no container:" -ForegroundColor Cyan
        docker exec mailserver ls -la /tmp/docker-mailserver/ssl/
        
        Write-Host ""
        Write-Host "🔄 Reiniciando serviços do mailserver..." -ForegroundColor Yellow
        docker exec mailserver supervisorctl restart postfix dovecot
        
        Write-Host ""
        Write-Host "✅ Configuração SSL concluída!" -ForegroundColor Green
        Write-Host "🚀 O mailserver está pronto para uso com SSL auto-assinado" -ForegroundColor Green
    } else {
        Write-Host "❌ Erro ao gerar certificados!" -ForegroundColor Red
        exit 1
    }
    
} finally {
    # Limpar arquivo temporário local
    if (Test-Path $tempScript) {
        Remove-Item $tempScript -Force
    }
}

Write-Host ""
Write-Host "📧 Para testar o envio de email:" -ForegroundColor Yellow
Write-Host "   python teste_email.py" -ForegroundColor White
Write-Host ""
Write-Host "📋 Para ver logs do mailserver:" -ForegroundColor Yellow
Write-Host "   docker logs mailserver" -ForegroundColor White
