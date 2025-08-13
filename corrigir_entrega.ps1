# Script para resolver problemas de entrega de email
# Executa correções DKIM e Amavis

Write-Host "🔧 Corrigindo problemas de entrega de email..." -ForegroundColor Cyan

# 1. Gerar chaves DKIM
Write-Host "`n1️⃣ Gerando chaves DKIM..." -ForegroundColor Yellow
docker exec mailserver setup config dkim domain soundchain.shop

# 2. Verificar se as chaves foram criadas
Write-Host "`n2️⃣ Verificando chaves DKIM..." -ForegroundColor Yellow
docker exec mailserver ls -la /tmp/docker-mailserver/opendkim/keys/

# 3. Mostrar chave pública para DNS
Write-Host "`n3️⃣ Chave pública DKIM para DNS:" -ForegroundColor Green
$dkimKey = docker exec mailserver cat /tmp/docker-mailserver/opendkim/keys/soundchain.shop/mail.txt 2>$null
if ($dkimKey) {
    Write-Host $dkimKey -ForegroundColor White
    Write-Host "`n📋 COPIE esta chave e adicione no DNS como registro TXT!" -ForegroundColor Yellow
} else {
    Write-Host "❌ Chave DKIM não encontrada" -ForegroundColor Red
}

# 4. Reiniciar container para aplicar mudanças
Write-Host "`n4️⃣ Reiniciando container..." -ForegroundColor Yellow
docker rrestart mailserve

# 5. Aguardar container ficar pronto
Write-Host "`n⏳ Aguardando container ficar pronto..." -ForegroundColor Cyan
Start-Sleep 30

# 6. Verificar status dos serviços
Write-Host "`n5️⃣ Verificando status dos serviços..." -ForegroundColor Yellow
docker exec mailserver supervisorctl status

# 7. Testar envio com configuração corrigida
Write-Host "`n6️⃣ Testando envio de email..." -ForegroundColor Green

$testEmail = @"
From: contact@soundchain.shop
To: muriloferraz56@gmail.com
Subject: Teste DKIM Configurado - $(Get-Date -Format 'HH:mm:ss')

Este email foi enviado após configurar DKIM e relaxar Amavis.
Timestamp: $(Get-Date)
Status: Configuração corrigida
"@

try {
    $result = $testEmail | curl.exe --url "smtp://soundchain.shop:587" --user "contact@soundchain.shop:sound@123" --mail-from "contact@soundchain.shop" --mail-rcpt "muriloferraz56@gmail.com" --upload-file - 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Email enviado com sucesso!" -ForegroundColor Green
        
        # Monitorar logs em tempo real
        Write-Host "`n📊 Monitorando logs (30 segundos)..." -ForegroundColor Cyan
        $startTime = Get-Date
        
        while ((Get-Date) -lt $startTime.AddSeconds(30)) {
            $logs = docker exec mailserver tail -n 10 /var/log/mail/mail.log 2>$null
            if ($logs) {
                $recentLogs = $logs | Where-Object { $_ -match "muriloferraz56@gmail.com" -and $_ -match (Get-Date -Format "yyyy-MM-dd") }
                if ($recentLogs) {
                    Write-Host "📧 Logs do email:" -ForegroundColor Yellow
                    $recentLogs | ForEach-Object { Write-Host "   $_" -ForegroundColor White }
                    
                    # Verificar se foi entregue
                    if ($recentLogs | Where-Object { $_ -match "status=sent" -and $_ -notmatch "BOUNCE" }) {
                        Write-Host "🎉 EMAIL ENTREGUE COM SUCESSO!" -ForegroundColor Green
                        break
                    }
                    
                    if ($recentLogs | Where-Object { $_ -match "Blocked|quarantine" }) {
                        Write-Host "⚠️ Email ainda sendo bloqueado pelo Amavis" -ForegroundColor Red
                    }
                }
            }
            Start-Sleep 3
        }
    } else {
        Write-Host "❌ Erro no envio: $result" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Erro: $_" -ForegroundColor Red
}

Write-Host "`n✅ Script concluído!" -ForegroundColor Cyan
Write-Host "📝 Se o problema persistir, considere:" -ForegroundColor Yellow
Write-Host "   - Adicionar a chave DKIM no DNS" -ForegroundColor White
Write-Host "   - Aguardar propagação DNS (1-24h)" -ForegroundColor White
Write-Host "   - Configurar SPF e DMARC" -ForegroundColor White
