# Script PowerShell para testar SMTP com curl

Write-Host "🧪 Testando SMTP com curl..." -ForegroundColor Cyan

# Verificar se curl está disponível
try {
    curl.exe --version | Out-Null
    Write-Host "✅ curl encontrado" -ForegroundColor Green
} catch {
    Write-Host "❌ curl não encontrado! Instale ou use o curl do Windows 10+" -ForegroundColor Red
    exit 1
}

# Teste 1: Conectividade básica
Write-Host "`n🔌 Teste 1: Conectividade básica" -ForegroundColor Yellow
Write-Host "Testando conexão com localhost:587..."

$conectividade = Test-NetConnection -ComputerName "localhost" -Port 587 -WarningAction SilentlyContinue
if ($conectividade.TcpTestSucceeded) {
    Write-Host "✅ Porta 587 está aberta" -ForegroundColor Green
} else {
    Write-Host "❌ Porta 587 está fechada ou inacessível" -ForegroundColor Red
}

$conectividade25 = Test-NetConnection -ComputerName "localhost" -Port 25 -WarningAction SilentlyContinue
if ($conectividade25.TcpTestSucceeded) {
    Write-Host "✅ Porta 25 está aberta" -ForegroundColor Green
} else {
    Write-Host "❌ Porta 25 está fechada ou inacessível" -ForegroundColor Red
}

# Teste 2: Handshake SMTP
Write-Host "`n📧 Teste 2: Handshake SMTP" -ForegroundColor Yellow

$smtpTest = @"
EHLO localhost
QUIT
"@

try {
    $resultado = $smtpTest | curl.exe --url "smtp://localhost:587" --upload-file - 2>&1
    Write-Host "✅ Handshake SMTP OK" -ForegroundColor Green
    Write-Host "Resposta: $resultado" -ForegroundColor White
} catch {
    Write-Host "❌ Erro no handshake SMTP: $_" -ForegroundColor Red
}

# Teste 3: Envio simples sem autenticação
Write-Host "`n📮 Teste 3: Envio sem autenticação" -ForegroundColor Yellow

$emailSimples = @"
From: test@localhost
To: muriloferraz56@gmail.com
Subject: Teste curl simples

Este é um teste de email via curl sem autenticação.
"@

try {
    $resultado = $emailSimples | curl.exe --url "smtp://localhost:25" --mail-from "test@localhost" --mail-rcpt "muriloferraz56@gmail.com" --upload-file - 2>&1
    Write-Host "✅ Envio simples OK" -ForegroundColor Green
    Write-Host "Resultado: $resultado" -ForegroundColor White
} catch {
    Write-Host "❌ Erro no envio simples: $_" -ForegroundColor Red
}

# Teste 4: Envio com autenticação
Write-Host "`n🔐 Teste 4: Envio com autenticação" -ForegroundColor Yellow

$emailAuth = @"
From: contact@soundchain.shop
To: muriloferraz56@gmail.com
Subject: Teste curl com autenticacao

Este é um teste com autenticação via curl.
"@

try {
    $resultado = $emailAuth | curl.exe --url "smtp://localhost:587" --user "contact@soundchain.shop:sound@123" --mail-from "contact@soundchain.shop" --mail-rcpt "muriloferraz56@gmail.com" --upload-file - 2>&1
    Write-Host "✅ Envio com autenticação OK" -ForegroundColor Green
    Write-Host "Resultado: $resultado" -ForegroundColor White
} catch {
    Write-Host "❌ Erro no envio com autenticação: $_" -ForegroundColor Red
}

# Informações adicionais
Write-Host "`n📋 Informações do container:" -ForegroundColor Cyan
try {
    docker exec mailserver ss -tlnp | Select-String ":587|:25"
    docker exec mailserver supervisorctl status | Select-String "postfix|dovecot"
} catch {
    Write-Host "❌ Erro ao acessar container" -ForegroundColor Red
}

Write-Host "`n✅ Teste concluído!" -ForegroundColor Green
