# Guia de Execução - soundchain.shop Mailserver

## 🚀 Passos para Configuração Completa

### Passo 1: Verificar Pré-requisitos

```powershell
# Verificar Docker
docker --version

# Verificar Docker Compose
docker-compose --version
```

### Passo 2: Configurar DNS (OBRIGATÓRIO)

Configure estes registros no seu provedor de DNS:

```dns
# Registro A - IP do servidor
mail.soundchain.shop.    A    212.85.1.63

# Registro MX - Direcionamento de email
soundchain.shop.         MX   10   mail.soundchain.shop.

# Registro SPF - Prevenção de spam
soundchain.shop.         TXT  "v=spf1 mx ip4:212.85.1.63 ~all"

# Registro DMARC - Política de autenticação
_dmarc.soundchain.shop.  TXT  "v=DMARC1; p=quarantine; rua=mailto:contact@soundchain.shop"
```

### Passo 3: Iniciar o Mailserver

```powershell
# Navegar para o diretório do projeto
cd c:\Git\docker-mailserver

# Iniciar o container
docker-compose up -d

# Verificar se está rodando
docker ps
```

### Passo 4: Configurar Usuário e Serviços

```powershell
# Executar script de configuração
python configurar_usuario.py
```

### Passo 5: Testar Envio de Email

```powershell
# Teste básico
python teste_email.py

# Ou envio direto
python enviar_email.py destinatario@exemplo.com "Teste" "Mensagem de teste"
```

## 📧 Credenciais de Acesso

### SMTP (Envio)
- **Servidor**: mail.soundchain.shop
- **Porta**: 587 (STARTTLS) ou 465 (SSL)
- **Usuário**: contact@soundchain.shop
- **Senha**: sound@123
- **Autenticação**: Obrigatória
- **Criptografia**: STARTTLS ou SSL/TLS

### IMAP (Recebimento)
- **Servidor**: mail.soundchain.shop
- **Porta**: 993 (SSL) ou 143 (STARTTLS)
- **Usuário**: contact@soundchain.shop
- **Senha**: sound@123
- **Criptografia**: SSL/TLS ou STARTTLS

## 🔧 Comandos Úteis

```powershell
# Ver logs do container
docker logs mailserver

# Ver logs em tempo real
docker logs -f mailserver

# Executar comandos no container
docker exec -it mailserver bash

# Adicionar novo usuário
docker exec -it mailserver setup email add novo@soundchain.shop

# Listar usuários
docker exec mailserver setup email list

# Verificar status dos serviços
docker exec mailserver supervisorctl status

# Testar configuração
docker exec mailserver setup config test

# Parar o mailserver
docker-compose down

# Reiniciar o mailserver
docker-compose restart
```

## 🧪 Testes de Conectividade

```powershell
# Testar resolução DNS
nslookup mail.soundchain.shop

# Testar conectividade SMTP
# No Windows, use telnet se estiver habilitado ou use o PowerShell:
Test-NetConnection -ComputerName mail.soundchain.shop -Port 587
Test-NetConnection -ComputerName mail.soundchain.shop -Port 465

# Testar conectividade IMAP
Test-NetConnection -ComputerName mail.soundchain.shop -Port 993
Test-NetConnection -ComputerName mail.soundchain.shop -Port 143
```

## 📊 Monitoramento

### Verificar DKIM
```powershell
docker exec mailserver cat /tmp/docker-mailserver/opendkim/keys/soundchain.shop/mail.txt
```

### Verificar certificados Let's Encrypt
```powershell
docker exec mailserver setup config ssl
```

### Verificar logs de email
```powershell
docker exec mailserver tail -f /var/log/mail/mail.log
```

## 🚨 Troubleshooting

### Container não inicia
```powershell
# Verificar logs de erro
docker logs mailserver

# Verificar configuração
docker-compose config

# Recriar container
docker-compose down
docker-compose up -d --force-recreate
```

### Emails não chegam
1. Verificar registros DNS (principalmente MX)
2. Verificar se as portas estão abertas no firewall
3. Verificar logs de rejeição no servidor de destino
4. Verificar se o IP não está em blacklist

### Erro de autenticação
```powershell
# Verificar usuários
docker exec mailserver setup email list

# Recriar usuário
docker exec mailserver setup email del contact@soundchain.shop
docker exec -it mailserver setup email add contact@soundchain.shop
```

### Problemas de SSL/Let's Encrypt
```powershell
# Verificar certificados
docker exec mailserver setup config ssl

# Forçar renovação (se necessário)
docker exec mailserver certbot renew --force-renewal
```

## 📁 Estrutura de Arquivos

```
c:\Git\docker-mailserver\
├── compose.yaml                 # Configuração Docker Compose
├── mailserver.env              # Variáveis de ambiente
├── enviar_email.py             # Script para envio de emails
├── teste_email.py              # Script de teste
├── configurar_usuario.py       # Script de configuração inicial
├── setup_mailserver.ps1        # Setup automatizado (PowerShell)
├── README-soundchain.md        # Este arquivo
├── DNS-Config-soundchain.md    # Configurações DNS detalhadas
└── docker-data/
    └── dms/
        ├── config/             # Configurações personalizadas
        ├── mail-data/          # Dados dos emails
        ├── mail-state/         # Estado do servidor
        └── mail-logs/          # Logs
```

## 🔄 Backup e Restore

### Fazer Backup
```powershell
# Backup completo
Compress-Archive -Path "docker-data" -DestinationPath "mailserver-backup-$(Get-Date -Format 'yyyyMMdd').zip"

# Backup apenas emails
Compress-Archive -Path "docker-data\dms\mail-data" -DestinationPath "emails-backup-$(Get-Date -Format 'yyyyMMdd').zip"
```

### Restaurar Backup
```powershell
# Parar container
docker-compose down

# Restaurar arquivos
Expand-Archive -Path "mailserver-backup-YYYYMMDD.zip" -DestinationPath "." -Force

# Reiniciar container
docker-compose up -d
```

## 📞 Suporte

Para problemas específicos:

1. **Consulte os logs**: `docker logs mailserver`
2. **Documentação oficial**: https://docker-mailserver.github.io/
3. **Teste a configuração**: `docker exec mailserver setup config test`
4. **Verifique DNS**: Use ferramentas como MXToolbox.com
5. **Teste conectividade**: Use os comandos de teste listados acima
