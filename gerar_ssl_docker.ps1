# Script PowerShell para gerar certificados SSL usando Docker

Write-Host "🔐 Gerando certificados SSL auto-assinados usando Docker..." -ForegroundColor Cyan

# Verificar se Docker está disponível
try {
    docker --version | Out-Null
    Write-Host "✅ Docker encontrado" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker não encontrado!" -ForegroundColor Red
    exit 1
}

# Criar diretórios necessários
$sslDir = ".\docker-data\dms\config\ssl"
Write-Host "📁 Criando diretório SSL..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $sslDir | Out-Null

# Comando Docker para gerar certificados
$dockerCmd = @"
docker run --rm -v "${PWD}/docker-data/dms/config/ssl:/ssl" alpine/openssl sh -c "
# Criar estrutura de diretórios
mkdir -p /ssl/demoCA/private /ssl/demoCA/newcerts
touch /ssl/demoCA/index.txt
echo '01' > /ssl/demoCA/serial

# Gerar chave privada da CA
openssl genrsa -out /ssl/demoCA/private/cakey.pem 2048

# Gerar certificado da CA
openssl req -new -x509 -key /ssl/demoCA/private/cakey.pem -out /ssl/demoCA/cacert.pem -days 3650 \
  -subj '/C=BR/ST=SP/L=Sao Paulo/O=soundchain.shop/OU=IT/CN=soundchain.shop CA'

# Gerar chave privada do servidor
openssl genrsa -out /ssl/mail.soundchain.shop-key.pem 2048

# Gerar requisição de certificado
openssl req -new -key /ssl/mail.soundchain.shop-key.pem -out /ssl/mail.soundchain.shop.csr \
  -subj '/C=BR/ST=SP/L=Sao Paulo/O=soundchain.shop/OU=Mail Server/CN=mail.soundchain.shop'

# Criar arquivo de extensões
cat > /ssl/v3.ext << 'EOF'
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = mail.soundchain.shop
DNS.2 = soundchain.shop
IP.1 = 212.85.1.63
EOF

# Gerar certificado do servidor
openssl x509 -req -in /ssl/mail.soundchain.shop.csr \
  -CA /ssl/demoCA/cacert.pem -CAkey /ssl/demoCA/private/cakey.pem \
  -CAcreateserial -out /ssl/mail.soundchain.shop-cert.pem -days 365 \
  -extensions v3_req -extfile /ssl/v3.ext

# Limpar arquivos temporários
rm /ssl/mail.soundchain.shop.csr /ssl/v3.ext

# Verificar certificados
echo '=== Informações do Certificado ==='
openssl x509 -in /ssl/mail.soundchain.shop-cert.pem -text -noout | grep -A 3 'Subject:'
echo ''
openssl x509 -in /ssl/mail.soundchain.shop-cert.pem -text -noout | grep -A 5 'X509v3 Subject Alternative Name:'

echo ''
echo 'Certificados gerados com sucesso!'
ls -la /ssl/
"
"@

Write-Host "🐳 Executando Docker para gerar certificados..." -ForegroundColor Yellow

# Executar o comando Docker
Invoke-Expression $dockerCmd

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Certificados SSL gerados com sucesso!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📁 Arquivos criados em ${sslDir}:" -ForegroundColor Cyan
    Get-ChildItem -Path $sslDir -Recurse | ForEach-Object {
        Write-Host "   - $($_.FullName)" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "🚀 Agora você pode reiniciar o mailserver:" -ForegroundColor Yellow
    Write-Host "   docker-compose down" -ForegroundColor White
    Write-Host "   docker-compose up -d" -ForegroundColor White
} else {
    Write-Host "❌ Erro ao gerar certificados!" -ForegroundColor Red
    exit 1
}
