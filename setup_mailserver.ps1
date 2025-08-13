# Script de configuração inicial para soundchain.shop mailserver (PowerShell)

Write-Host "=== Configuração do Docker Mailserver para soundchain.shop ===" -ForegroundColor Cyan

# Verificar se o Docker está rodando
try {
    docker info | Out-Null
    Write-Host "✓ Docker está rodando" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker não está rodando!" -ForegroundColor Red
    exit 1
}

# Criar diretórios necessários
Write-Host "📁 Criando diretórios necessários..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "docker-data\dms\mail-data" | Out-Null
New-Item -ItemType Directory -Force -Path "docker-data\dms\mail-state" | Out-Null
New-Item -ItemType Directory -Force -Path "docker-data\dms\mail-logs" | Out-Null
New-Item -ItemType Directory -Force -Path "docker-data\dms\config" | Out-Null

Write-Host "✓ Diretórios criados" -ForegroundColor Green

# Construir o container
Write-Host "🔨 Construindo e iniciando o mailserver..." -ForegroundColor Yellow
docker-compose up -d

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Mailserver iniciado com sucesso" -ForegroundColor Green
} else {
    Write-Host "❌ Erro ao iniciar o mailserver" -ForegroundColor Red
    exit 1
}

# Aguardar o container inicializar
Write-Host "⏳ Aguardando inicialização do container..." -ForegroundColor Yellow
Start-Sleep 30

# Verificar se o container está rodando
$containerRunning = docker ps --format "table {{.Names}}" | Select-String "mailserver"
if (-not $containerRunning) {
    Write-Host "❌ Container mailserver não está rodando" -ForegroundColor Red
    docker logs mailserver
    exit 1
}

Write-Host "✓ Container está rodando" -ForegroundColor Green

# Criar usuário principal
Write-Host "👤 Criando usuário principal: contact@soundchain.shop" -ForegroundColor Yellow
Write-Host "Digite a senha para contact@soundchain.shop:" -ForegroundColor Yellow
docker exec -it mailserver setup email add contact@soundchain.shop

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Usuário contact@soundchain.shop criado" -ForegroundColor Green
} else {
    Write-Host "❌ Erro ao criar usuário" -ForegroundColor Red
}

# Configurar DKIM
Write-Host "🔐 Configurando DKIM para soundchain.shop..." -ForegroundColor Yellow
docker exec mailserver setup config dkim domain soundchain.shop

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ DKIM configurado" -ForegroundColor Green
    Write-Host "📋 Registros DNS necessários:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Adicione estes registros ao seu DNS:"
    Write-Host ""
    Write-Host "1. Registro MX:"
    Write-Host "   soundchain.shop    MX 10  mail.soundchain.shop"
    Write-Host ""
    Write-Host "2. Registro A:"
    Write-Host "   mail.soundchain.shop    A    [SEU_IP_SERVIDOR]"
    Write-Host ""
    Write-Host "3. Registro SPF:"
    Write-Host "   soundchain.shop    TXT   `"v=spf1 mx ~all`""
    Write-Host ""
    Write-Host "4. Registro DKIM (será exibido abaixo):"
    docker exec mailserver cat /tmp/docker-mailserver/opendkim/keys/soundchain.shop/mail.txt
    Write-Host ""
    Write-Host "5. Registro DMARC:"
    Write-Host "   _dmarc.soundchain.shop    TXT   `"v=DMARC1; p=quarantine; rua=mailto:contact@soundchain.shop`""
    Write-Host ""
} else {
    Write-Host "❌ Erro ao configurar DKIM" -ForegroundColor Red
}

# Mostrar status
Write-Host ""
Write-Host "📊 Status do mailserver:" -ForegroundColor Cyan
docker exec mailserver setup email list
Write-Host ""
docker logs mailserver --tail=20

Write-Host ""
Write-Host "🎉 Configuração concluída!" -ForegroundColor Green
Write-Host ""
Write-Host "📧 Para enviar e-mails, use:"
Write-Host "   python enviar_email.py destinatario@exemplo.com `"Assunto`" `"Mensagem`""
Write-Host ""
Write-Host "🔧 Para gerenciar usuários:"
Write-Host "   docker exec -it mailserver setup email add novo@soundchain.shop"
Write-Host "   docker exec -it mailserver setup email list"
Write-Host "   docker exec -it mailserver setup email del usuario@soundchain.shop"
Write-Host ""
Write-Host "📋 Para ver logs:"
Write-Host "   docker logs mailserver"
Write-Host ""
Write-Host "⚠️  Não esqueça de configurar os registros DNS listados acima!" -ForegroundColor Yellow
