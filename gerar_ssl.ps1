# Script PowerShell para gerar certificados SSL auto-assinados para soundchain.shop

param(
    [string]$Domain = "mail.soundchain.shop",
    [string]$SslDir = ".\docker-data\dms\config\ssl"
)

Write-Host "🔐 Gerando certificados SSL auto-assinados para $Domain" -ForegroundColor Cyan

# Verificar se OpenSSL está disponível
try {
    $null = Get-Command openssl -ErrorAction Stop
    Write-Host "✅ OpenSSL encontrado" -ForegroundColor Green
} catch {
    Write-Host "❌ OpenSSL não encontrado!" -ForegroundColor Red
    Write-Host "Instale o OpenSSL ou use o WSL/Git Bash para executar gerar_ssl.sh" -ForegroundColor Yellow
    Write-Host "Download: https://slproweb.com/products/Win32OpenSSL.html" -ForegroundColor Yellow
    exit 1
}

# Criar diretórios necessários
$keyFile = "$SslDir\$Domain-key.pem"
$certFile = "$SslDir\$Domain-cert.pem"
$caDir = "$SslDir\demoCA"
$caPrivateDir = "$caDir\private"
$caKey = "$caPrivateDir\cakey.pem"
$caCert = "$caDir\cacert.pem"

Write-Host "📁 Criando diretórios..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $SslDir | Out-Null
New-Item -ItemType Directory -Force -Path $caPrivateDir | Out-Null
New-Item -ItemType Directory -Force -Path "$caDir\newcerts" | Out-Null

# Criar arquivos necessários para CA
New-Item -ItemType File -Force -Path "$caDir\index.txt" | Out-Null
Set-Content -Path "$caDir\serial" -Value "01" -Force

try {
    # Gerar chave privada da CA
    Write-Host "📋 Gerando chave privada da CA..." -ForegroundColor Yellow
    & openssl genrsa -out $caKey 2048 2>$null
    if ($LASTEXITCODE -ne 0) { throw "Erro ao gerar chave da CA" }

    # Gerar certificado da CA
    Write-Host "📋 Gerando certificado da CA..." -ForegroundColor Yellow
    & openssl req -new -x509 -key $caKey -out $caCert -days 3650 -subj "/C=BR/ST=SP/L=Sao Paulo/O=soundchain.shop/OU=IT/CN=soundchain.shop CA" 2>$null
    if ($LASTEXITCODE -ne 0) { throw "Erro ao gerar certificado da CA" }

    # Gerar chave privada do servidor
    Write-Host "📋 Gerando chave privada do servidor..." -ForegroundColor Yellow
    & openssl genrsa -out $keyFile 2048 2>$null
    if ($LASTEXITCODE -ne 0) { throw "Erro ao gerar chave do servidor" }

    # Gerar requisição de certificado
    Write-Host "📋 Gerando requisição de certificado..." -ForegroundColor Yellow
    $csrFile = "$SslDir\$Domain.csr"
    & openssl req -new -key $keyFile -out $csrFile -subj "/C=BR/ST=SP/L=Sao Paulo/O=soundchain.shop/OU=Mail Server/CN=$Domain" 2>$null
    if ($LASTEXITCODE -ne 0) { throw "Erro ao gerar CSR" }

    # Criar arquivo de configuração para extensões
    $extFile = "$SslDir\v3.ext"
    $extContent = @"
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $Domain
DNS.2 = soundchain.shop
DNS.3 = mail.soundchain.shop
IP.1 = 212.85.1.63
"@
    Set-Content -Path $extFile -Value $extContent -Force

    # Gerar certificado do servidor assinado pela CA
    Write-Host "📋 Gerando certificado do servidor..." -ForegroundColor Yellow
    & openssl x509 -req -in $csrFile -CA $caCert -CAkey $caKey -CAcreateserial -out $certFile -days 365 -extensions v3_req -extfile $extFile 2>$null
    if ($LASTEXITCODE -ne 0) { throw "Erro ao gerar certificado do servidor" }

    # Verificar certificados
    Write-Host "✅ Verificando certificados gerados..." -ForegroundColor Green
    & openssl x509 -in $certFile -text -noout | Select-String -Pattern "Subject:" -A 3
    & openssl x509 -in $certFile -text -noout | Select-String -Pattern "X509v3 Subject Alternative Name:" -A 5

    # Limpar arquivos temporários
    Remove-Item -Path $csrFile -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $extFile -Force -ErrorAction SilentlyContinue

    Write-Host "✅ Certificados SSL auto-assinados gerados com sucesso!" -ForegroundColor Green
    Write-Host "📁 Arquivos criados:" -ForegroundColor Cyan
    Write-Host "   - Chave privada: $keyFile" -ForegroundColor White
    Write-Host "   - Certificado: $certFile" -ForegroundColor White
    Write-Host "   - CA Cert: $caCert" -ForegroundColor White

    Write-Host ""
    Write-Host "🚀 Agora você pode reiniciar o mailserver:" -ForegroundColor Yellow
    Write-Host "   docker-compose down" -ForegroundColor White
    Write-Host "   docker-compose up -d" -ForegroundColor White

} catch {
    Write-Host "❌ Erro durante a geração dos certificados: $_" -ForegroundColor Red
    Write-Host "Verifique se o OpenSSL está instalado corretamente" -ForegroundColor Yellow
    exit 1
}
