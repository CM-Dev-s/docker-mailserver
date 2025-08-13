# Script para monitorar entregas de email

function Monitor-EmailDelivery {
    param(
        [string]$EmailAddress = "muriloferraz56@gmail.com",
        [int]$MinutesToMonitor = 10
    )
    
    Write-Host "📊 Monitorando entregas para $EmailAddress por $MinutesToMonitor minutos..." -ForegroundColor Cyan
    
    $startTime = Get-Date
    $endTime = $startTime.AddMinutes($MinutesToMonitor)
    
    while ((Get-Date) -lt $endTime) {
        Write-Host "`n🔍 $(Get-Date -Format 'HH:mm:ss') - Verificando logs..." -ForegroundColor Yellow
        
        try {
            # Verificar logs recentes
            $logs = docker exec mailserver tail -n 50 /var/log/mail/mail.log 2>$null
            
            if ($logs) {
                # Filtrar por email específico
                $emailLogs = $logs | Select-String $EmailAddress
                
                if ($emailLogs) {
                    Write-Host "📧 Encontradas entradas para $EmailAddress`:" -ForegroundColor Green
                    foreach ($log in $emailLogs) {
                        Write-Host "   $log" -ForegroundColor White
                    }
                } else {
                    Write-Host "   Nenhuma entrada encontrada para $EmailAddress" -ForegroundColor Gray
                }
                
                # Verificar status de entrega
                $delivered = $logs | Select-String "status=sent.*$EmailAddress"
                $deferred = $logs | Select-String "status=deferred.*$EmailAddress"
                $bounced = $logs | Select-String "status=bounced.*$EmailAddress"
                
                if ($delivered) {
                    Write-Host "✅ EMAIL ENTREGUE!" -ForegroundColor Green
                    foreach ($d in $delivered) {
                        Write-Host "   $d" -ForegroundColor Green
                    }
                    break
                }
                
                if ($deferred) {
                    Write-Host "⏳ Email adiado (tentativa posterior)" -ForegroundColor Yellow
                    foreach ($d in $deferred) {
                        Write-Host "   $d" -ForegroundColor Yellow
                    }
                }
                
                if ($bounced) {
                    Write-Host "❌ Email rejeitado!" -ForegroundColor Red
                    foreach ($b in $bounced) {
                        Write-Host "   $b" -ForegroundColor Red
                    }
                    break
                }
            }
            
            # Verificar fila de emails
            $queue = docker exec mailserver postqueue -p 2>$null
            if ($queue -and $queue -notmatch "Mail queue is empty") {
                Write-Host "📮 Emails na fila:" -ForegroundColor Cyan
                Write-Host $queue -ForegroundColor White
            }
            
        } catch {
            Write-Host "❌ Erro ao verificar logs: $_" -ForegroundColor Red
        }
        
        Start-Sleep 30
    }
    
    Write-Host "`n⏰ Monitoramento concluído!" -ForegroundColor Cyan
}

function Test-EmailDeliveryTime {
    param(
        [string]$To = "muriloferraz56@gmail.com",
        [string]$Subject = "Teste de Tempo de Entrega"
    )
    
    $startTime = Get-Date
    $uniqueId = (Get-Date -Format "yyyyMMdd-HHmmss") + "-" + (Get-Random -Maximum 9999)
    $body = "Email de teste enviado em $startTime`nID único: $uniqueId"
    
    Write-Host "🚀 Enviando email de teste..." -ForegroundColor Yellow
    Write-Host "   Horário de envio: $startTime" -ForegroundColor White
    Write-Host "   ID único: $uniqueId" -ForegroundColor White
    
    # Enviar email via curl
    $email = @"
From: contact@soundchain.shop
To: $To
Subject: $Subject - $uniqueId

$body
"@
    
    try {
        $result = $email | curl.exe --url "smtp://localhost:587" --user "contact@soundchain.shop:sound@123" --mail-from "contact@soundchain.shop" --mail-rcpt $To --upload-file - 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Email enviado com sucesso!" -ForegroundColor Green
            Write-Host "📊 Iniciando monitoramento..." -ForegroundColor Cyan
            
            # Monitorar por 15 minutos
            Monitor-EmailDelivery -EmailAddress $To -MinutesToMonitor 15
        } else {
            Write-Host "❌ Erro no envio: $result" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Erro: $_" -ForegroundColor Red
    }
}

# Função para verificar reputação do IP
function Test-IPReputation {
    $ip = "212.85.1.63"
    
    Write-Host "🔍 Verificando reputação do IP $ip..." -ForegroundColor Cyan
    
    $blacklists = @(
        "zen.spamhaus.org",
        "bl.spamcop.net", 
        "b.barracudacentral.org",
        "dnsbl.sorbs.net"
    )
    
    foreach ($bl in $blacklists) {
        $reversedIP = ($ip.Split('.')[3..0]) -join '.'
        $query = "$reversedIP.$bl"
        
        try {
            $result = Resolve-DnsName $query -ErrorAction Stop
            Write-Host "❌ IP listado em $bl" -ForegroundColor Red
        } catch {
            Write-Host "✅ IP não listado em $bl" -ForegroundColor Green
        }
    }
}

Write-Host "📊 Monitor de Entrega de Email - soundchain.shop" -ForegroundColor Cyan
Write-Host "=" * 50

Write-Host "`n1️⃣  Para testar tempo de entrega:"
Write-Host "Test-EmailDeliveryTime -To 'seuemail@gmail.com'" -ForegroundColor Yellow

Write-Host "`n2️⃣  Para monitorar entregas:"
Write-Host "Monitor-EmailDelivery -EmailAddress 'seuemail@gmail.com'" -ForegroundColor Yellow

Write-Host "`n3️⃣  Para verificar reputação do IP:"
Write-Host "Test-IPReputation" -ForegroundColor Yellow

# Executar teste automático
Write-Host "`n🚀 Executando teste automático..." -ForegroundColor Cyan
Test-IPReputation
