# Script completo para teste de email via curl no PowerShell

Write-Host "🧪 Testando email via curl..." -ForegroundColor Cyan

# Função para envio de email
function Send-EmailCurl {
    param(
        [string]$To,
        [string]$Subject,
        [string]$Body,
        [string]$From = "contact@soundchain.shop",
        [string]$Server = "localhost:587",
        [string]$User = "contact@soundchain.shop:sound@123",
        [switch]$NoAuth
    )
    
    $email = @"
From: $From
To: $To
Subject: $Subject

$Body
"@
    
    Write-Host "📧 Enviando email..." -ForegroundColor Yellow
    Write-Host "   De: $From" -ForegroundColor White
    Write-Host "   Para: $To" -ForegroundColor White
    Write-Host "   Assunto: $Subject" -ForegroundColor White
    
    try {
        if ($NoAuth) {
            $resultado = $email | curl.exe --url "smtp://$Server" --mail-from "$From" --mail-rcpt "$To" --upload-file - 2>&1
        } else {
            $resultado = $email | curl.exe --url "smtp://$Server" --user "$User" --mail-from "$From" --mail-rcpt "$To" --upload-file - 2>&1
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Email enviado com sucesso!" -ForegroundColor Green
        } else {
            Write-Host "❌ Erro no envio:" -ForegroundColor Red
            Write-Host $resultado -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Erro: $_" -ForegroundColor Red
    }
}

# Teste 1: Verificar conectividade
Write-Host "`n🔌 Teste 1: Conectividade" -ForegroundColor Cyan
$conn587 = Test-NetConnection -ComputerName localhost -Port 587 -WarningAction SilentlyContinue
$conn25 = Test-NetConnection -ComputerName localhost -Port 25 -WarningAction SilentlyContinue

if ($conn587.TcpTestSucceeded) {
    Write-Host "✅ Porta 587 (SMTP com auth): ABERTA" -ForegroundColor Green
} else {
    Write-Host "❌ Porta 587: FECHADA" -ForegroundColor Red
}

if ($conn25.TcpTestSucceeded) {
    Write-Host "✅ Porta 25 (SMTP sem auth): ABERTA" -ForegroundColor Green
} else {
    Write-Host "❌ Porta 25: FECHADA" -ForegroundColor Red
}

# Teste 2: Envio sem autenticação (porta 25)
if ($conn25.TcpTestSucceeded) {
    Write-Host "`n📮 Teste 2: Envio sem autenticação (porta 25)" -ForegroundColor Cyan
    Send-EmailCurl -To "muriloferraz56@gmail.com" -Subject "Teste sem auth" -Body "Este email foi enviado sem autenticação na porta 25." -Server "localhost:25" -NoAuth
}

# Teste 3: Envio com autenticação (porta 587)
if ($conn587.TcpTestSucceeded) {
    Write-Host "`n🔐 Teste 3: Envio com autenticação (porta 587)" -ForegroundColor Cyan
    Send-EmailCurl -To "muriloferraz56@gmail.com" -Subject "Teste com auth" -Body "Este email foi enviado com autenticação na porta 587."
}

# Teste 4: Informações do container
Write-Host "`n📊 Teste 4: Status do container" -ForegroundColor Cyan
try {
    Write-Host "Portas mapeadas:" -ForegroundColor White
    docker port mailserver
    
    Write-Host "`nServiços internos:" -ForegroundColor White
    docker exec mailserver supervisorctl status | Select-String "postfix|dovecot"
    
    Write-Host "`nPortas internas:" -ForegroundColor White
    docker exec mailserver ss -tlnp | Select-String ":25|:587"
} catch {
    Write-Host "❌ Erro ao acessar informações do container" -ForegroundColor Red
}

Write-Host "`n✅ Testes concluídos!" -ForegroundColor Green
Write-Host "`n💡 Para enviar um email específico, use:" -ForegroundColor Yellow
Write-Host "Send-EmailCurl -To 'destinatario@exemplo.com' -Subject 'Meu Assunto' -Body 'Minha mensagem'" -ForegroundColor White
