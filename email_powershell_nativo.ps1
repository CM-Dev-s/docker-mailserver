# Script PowerShell nativo para envio de email SMTP

function Send-SmtpEmail {
    param(
        [Parameter(Mandatory=$true)]
        [string]$To,
        
        [Parameter(Mandatory=$true)]
        [string]$Subject,
        
        [Parameter(Mandatory=$true)]
        [string]$Body,
        
        [string]$From = "contact@soundchain.shop",
        [string]$SmtpServer = "localhost",
        [int]$Port = 587,
        [string]$Username = "contact@soundchain.shop",
        [string]$Password = "sound@123",
        [switch]$NoAuth,
        [switch]$UseSsl
    )
    
    try {
        Write-Host "📧 Configurando cliente SMTP..." -ForegroundColor Yellow
        
        # Criar cliente SMTP
        $smtpClient = New-Object System.Net.Mail.SmtpClient($SmtpServer, $Port)
        
        # Configurar autenticação se necessário
        if (-not $NoAuth) {
            $smtpClient.Credentials = New-Object System.Net.NetworkCredential($Username, $Password)
            Write-Host "🔐 Autenticação configurada para: $Username" -ForegroundColor Cyan
        } else {
            Write-Host "📭 Enviando sem autenticação" -ForegroundColor Cyan
        }
        
        # Configurar SSL/TLS
        if ($UseSsl) {
            $smtpClient.EnableSsl = $true
            Write-Host "🔒 SSL/TLS habilitado" -ForegroundColor Green
        } else {
            $smtpClient.EnableSsl = $false
            Write-Host "📡 Enviando sem criptografia" -ForegroundColor Yellow
        }
        
        # Configurar timeout
        $smtpClient.Timeout = 30000
        
        # Criar mensagem
        $mailMessage = New-Object System.Net.Mail.MailMessage
        $mailMessage.From = New-Object System.Net.Mail.MailAddress($From)
        $mailMessage.To.Add($To)
        $mailMessage.Subject = $Subject
        $mailMessage.Body = $Body
        $mailMessage.IsBodyHtml = $false
        
        Write-Host "📮 Enviando email..." -ForegroundColor Yellow
        Write-Host "   Servidor: $SmtpServer`:$Port" -ForegroundColor White
        Write-Host "   De: $From" -ForegroundColor White
        Write-Host "   Para: $To" -ForegroundColor White
        Write-Host "   Assunto: $Subject" -ForegroundColor White
        
        # Enviar email
        $smtpClient.Send($mailMessage)
        
        Write-Host "✅ Email enviado com sucesso!" -ForegroundColor Green
        
        # Limpar recursos
        $mailMessage.Dispose()
        $smtpClient.Dispose()
        
        return $true
        
    } catch {
        Write-Host "❌ Erro ao enviar email:" -ForegroundColor Red
        Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
        
        # Detalhes adicionais do erro
        if ($_.Exception.InnerException) {
            Write-Host "   Erro interno: $($_.Exception.InnerException.Message)" -ForegroundColor Red
        }
        
        return $false
    } finally {
        # Garantir limpeza dos recursos
        if ($mailMessage) { $mailMessage.Dispose() }
        if ($smtpClient) { $smtpClient.Dispose() }
    }
}

# Função para testar conectividade
function Test-SmtpConnection {
    param(
        [string]$Server = "localhost",
        [int]$Port = 587,
        [int]$Timeout = 5000
    )
    
    try {
        Write-Host "🔌 Testando conectividade com $Server`:$Port..." -ForegroundColor Yellow
        
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $asyncResult = $tcpClient.BeginConnect($Server, $Port, $null, $null)
        $waitHandle = $asyncResult.AsyncWaitHandle
        
        if ($waitHandle.WaitOne($Timeout)) {
            $tcpClient.EndConnect($asyncResult)
            $tcpClient.Close()
            Write-Host "✅ Conectividade OK com $Server`:$Port" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ Timeout na conexão com $Server`:$Port" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ Erro de conectividade: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    } finally {
        if ($tcpClient) { $tcpClient.Close() }
    }
}

# Script principal de teste
Write-Host "🧪 Teste de Email PowerShell Nativo" -ForegroundColor Cyan
Write-Host "=" * 50

# Teste 1: Conectividade
Write-Host "`n🔌 Teste 1: Conectividade" -ForegroundColor Cyan
$conectividade587 = Test-SmtpConnection -Server "localhost" -Port 587
$conectividade25 = Test-SmtpConnection -Server "localhost" -Port 25

# Teste 2: Envio sem autenticação (porta 25)
if ($conectividade25) {
    Write-Host "`n📮 Teste 2: Envio sem autenticação (porta 25)" -ForegroundColor Cyan
    $resultado1 = Send-SmtpEmail -To "muriloferraz56@gmail.com" -Subject "Teste PowerShell sem auth" -Body "Este email foi enviado via PowerShell nativo sem autenticação na porta 25." -Port 25 -NoAuth
}

# Teste 3: Envio com autenticação sem SSL (porta 587)
if ($conectividade587) {
    Write-Host "`n🔐 Teste 3: Envio com autenticação sem SSL (porta 587)" -ForegroundColor Cyan
    $resultado2 = Send-SmtpEmail -To "muriloferraz56@gmail.com" -Subject "Teste PowerShell com auth sem SSL" -Body "Este email foi enviado via PowerShell nativo com autenticação mas sem SSL na porta 587." -Port 587
}

# Teste 4: Envio com autenticação e SSL (porta 587)
if ($conectividade587) {
    Write-Host "`n🔒 Teste 4: Envio com autenticação e SSL (porta 587)" -ForegroundColor Cyan
    $resultado3 = Send-SmtpEmail -To "muriloferraz56@gmail.com" -Subject "Teste PowerShell com auth e SSL" -Body "Este email foi enviado via PowerShell nativo com autenticação e SSL na porta 587." -Port 587 -UseSsl
}

Write-Host "`n📊 Resumo dos testes:" -ForegroundColor Cyan
Write-Host "   Conectividade 25: $(if($conectividade25){'✅'}else{'❌'})" -ForegroundColor White
Write-Host "   Conectividade 587: $(if($conectividade587){'✅'}else{'❌'})" -ForegroundColor White
if ($conectividade25) { Write-Host "   Envio porta 25: $(if($resultado1){'✅'}else{'❌'})" -ForegroundColor White }
if ($conectividade587) { Write-Host "   Envio porta 587 sem SSL: $(if($resultado2){'✅'}else{'❌'})" -ForegroundColor White }
if ($conectividade587) { Write-Host "   Envio porta 587 com SSL: $(if($resultado3){'✅'}else{'❌'})" -ForegroundColor White }

Write-Host "`n💡 Para enviar um email específico:" -ForegroundColor Yellow
Write-Host "Send-SmtpEmail -To 'destinatario@exemplo.com' -Subject 'Meu Assunto' -Body 'Minha Mensagem'" -ForegroundColor White
