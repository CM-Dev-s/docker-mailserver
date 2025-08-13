#!/bin/bash
# Script de configuração inicial para soundchain.shop mailserver

echo "=== Configuração do Docker Mailserver para soundchain.shop ==="

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar se o Docker está rodando
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker não está rodando!${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker está rodando${NC}"

# Criar diretórios necessários
echo "📁 Criando diretórios necessários..."
mkdir -p docker-data/dms/mail-data
mkdir -p docker-data/dms/mail-state
mkdir -p docker-data/dms/mail-logs
mkdir -p docker-data/dms/config

echo -e "${GREEN}✓ Diretórios criados${NC}"

# Construir o container
echo "🔨 Construindo e iniciando o mailserver..."
docker-compose up -d

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Mailserver iniciado com sucesso${NC}"
else
    echo -e "${RED}❌ Erro ao iniciar o mailserver${NC}"
    exit 1
fi

# Aguardar o container inicializar
echo "⏳ Aguardando inicialização do container..."
sleep 30

# Verificar se o container está rodando
if ! docker ps | grep -q mailserver; then
    echo -e "${RED}❌ Container mailserver não está rodando${NC}"
    docker logs mailserver
    exit 1
fi

echo -e "${GREEN}✓ Container está rodando${NC}"

# Criar usuário principal
echo "👤 Criando usuário principal: contact@soundchain.shop"
echo -e "${YELLOW}Digite a senha para contact@soundchain.shop:${NC}"
docker exec -it mailserver setup email add contact@soundchain.shop

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Usuário contact@soundchain.shop criado${NC}"
else
    echo -e "${RED}❌ Erro ao criar usuário${NC}"
fi

# Configurar DKIM
echo "🔐 Configurando DKIM para soundchain.shop..."
docker exec mailserver setup config dkim domain soundchain.shop

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ DKIM configurado${NC}"
    echo -e "${YELLOW}📋 Registros DNS necessários:${NC}"
    echo ""
    echo "Adicione estes registros ao seu DNS:"
    echo ""
    echo "1. Registro MX:"
    echo "   soundchain.shop    MX 10  mail.soundchain.shop"
    echo ""
    echo "2. Registro A:"
    echo "   mail.soundchain.shop    A    [SEU_IP_SERVIDOR]"
    echo ""
    echo "3. Registro SPF:"
    echo "   soundchain.shop    TXT   \"v=spf1 mx ~all\""
    echo ""
    echo "4. Registro DKIM (será exibido abaixo):"
    docker exec mailserver cat /tmp/docker-mailserver/opendkim/keys/soundchain.shop/mail.txt
    echo ""
    echo "5. Registro DMARC:"
    echo "   _dmarc.soundchain.shop    TXT   \"v=DMARC1; p=quarantine; rua=mailto:contact@soundchain.shop\""
    echo ""
else
    echo -e "${RED}❌ Erro ao configurar DKIM${NC}"
fi

# Mostrar status
echo ""
echo "📊 Status do mailserver:"
docker exec mailserver setup email list
echo ""
docker logs mailserver --tail=20

echo ""
echo -e "${GREEN}🎉 Configuração concluída!${NC}"
echo ""
echo "📧 Para enviar e-mails, use:"
echo "   python3 enviar_email.py destinatario@exemplo.com \"Assunto\" \"Mensagem\""
echo ""
echo "🔧 Para gerenciar usuários:"
echo "   docker exec -it mailserver setup email add novo@soundchain.shop"
echo "   docker exec -it mailserver setup email list"
echo "   docker exec -it mailserver setup email del usuario@soundchain.shop"
echo ""
echo "📋 Para ver logs:"
echo "   docker logs mailserver"
echo ""
echo -e "${YELLOW}⚠️  Não esqueça de configurar os registros DNS listados acima!${NC}"
