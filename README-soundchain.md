# Docker Mailserver - soundchain.shop

Configuração do docker-mailserver para o domínio **soundchain.shop** com email principal **contact@soundchain.shop**.

## 📋 Informações Configuradas

- **Domínio**: soundchain.shop
- **Servidor**: mail.soundchain.shop (IP: 212.85.1.63)
- **Email principal**: contact@soundchain.shop
- **Senha**: sound@123
- **SSL**: Let's Encrypt
- **Timezone**: America/Sao_Paulo

## 🚀 Configuração Rápida

### 1. Pré-requisitos

- Docker e Docker Compose instalados
- Domínio `soundchain.shop` configurado
- IP público para o servidor
- Acesso aos registros DNS do domínio

### 2. Configuração Inicial

Execute o script de configuração:

**Windows (PowerShell):**
```powershell
.\setup_mailserver.ps1
```

**Linux/Mac:**
```bash
chmod +x setup_mailserver.sh
./setup_mailserver.sh
```

### 3. Configuração DNS Obrigatória

Adicione estes registros ao seu DNS:

```dns
# Registro MX (obrigatório)
soundchain.shop.         MX 10  mail.soundchain.shop.

# Registro A (obrigatório - substitua SEU_IP_SERVIDOR)
mail.soundchain.shop.    A      SEU_IP_SERVIDOR

# Registro SPF (recomendado)
soundchain.shop.         TXT    "v=spf1 mx ~all"

# Registro DMARC (recomendado)
_dmarc.soundchain.shop.  TXT    "v=DMARC1; p=quarantine; rua=mailto:contact@soundchain.shop"

# Registro DKIM (será gerado automaticamente - veja logs do setup)
mail._domainkey.soundchain.shop.  TXT  "v=DKIM1; k=rsa; p=..."
```

## 📧 Enviando E-mails

### Usando o Script Python

```bash
# Envio simples
python enviar_email.py destinatario@exemplo.com "Assunto" "Corpo da mensagem"

# Com anexo
python enviar_email.py destinatario@exemplo.com "Assunto" "Mensagem" --anexo arquivo.pdf

# Especificando remetente diferente
python enviar_email.py destinatario@exemplo.com "Assunto" "Mensagem" --usuario outro@soundchain.shop

# Usando SSL direto (porta 465)
python enviar_email.py destinatario@exemplo.com "Assunto" "Mensagem" --ssl
```

### Usando Cliente de E-mail

**Configurações SMTP:**
- Servidor: `mail.soundchain.shop`
- Porta: `587` (STARTTLS) ou `465` (SSL)
- Usuário: `contact@soundchain.shop`
- Senha: [definida durante setup]
- Autenticação: Obrigatória
- Criptografia: STARTTLS ou SSL/TLS

**Configurações IMAP:**
- Servidor: `mail.soundchain.shop`
- Porta: `993` (SSL) ou `143` (STARTTLS)
- Usuário: `contact@soundchain.shop`
- Senha: [definida durante setup]
- Criptografia: SSL/TLS ou STARTTLS

## 🔧 Gerenciamento de Usuários

```bash
# Adicionar usuário
docker exec -it mailserver setup email add novo@soundchain.shop

# Listar usuários
docker exec -it mailserver setup email list

# Remover usuário
docker exec -it mailserver setup email del usuario@soundchain.shop

# Alterar senha
docker exec -it mailserver setup email update contact@soundchain.shop

# Adicionar alias
docker exec -it mailserver setup alias add info@soundchain.shop contact@soundchain.shop

# Listar aliases
docker exec -it mailserver setup alias list
```

## 📊 Monitoramento

```bash
# Ver logs em tempo real
docker logs -f mailserver

# Ver status dos serviços
docker exec mailserver supervisorctl status

# Verificar configuração
docker exec mailserver setup config test

# Verificar conectividade SMTP
docker exec mailserver setup debug fetchmail
```

## 🔒 Segurança

### Recursos Ativados

- ✅ **Rspamd**: Anti-spam e antivírus
- ✅ **Fail2Ban**: Proteção contra ataques de força bruta
- ✅ **OpenDKIM**: Assinatura de e-mails
- ✅ **OpenDMARC**: Validação DMARC
- ✅ **TLS/SSL**: Criptografia em trânsito
- ✅ **SPF**: Proteção contra spoofing

### Certificados SSL

Por padrão, está configurado para usar certificados auto-assinados. Para produção:

1. **Let's Encrypt (recomendado):**
   ```env
   SSL_TYPE=letsencrypt
   ```

2. **Certificados próprios:**
   ```env
   SSL_TYPE=custom
   SSL_CERT_PATH=/tmp/docker-mailserver/ssl/cert.pem
   SSL_KEY_PATH=/tmp/docker-mailserver/ssl/key.pem
   ```

## 🛠️ Troubleshooting

### Container não inicia
```bash
docker logs mailserver
docker-compose down && docker-compose up -d
```

### E-mails não chegam
1. Verificar registros DNS (MX, A, SPF)
2. Verificar portas abertas (25, 587, 465, 993)
3. Verificar logs: `docker logs mailserver | grep ERROR`

### E-mails vão para spam
1. Configurar registros DKIM, SPF e DMARC
2. Verificar reputação do IP
3. Configurar PTR (reverse DNS)

### Problemas de autenticação
```bash
# Verificar usuários
docker exec mailserver setup email list

# Resetar senha
docker exec -it mailserver setup email update contact@soundchain.shop
```

## 📂 Estrutura de Arquivos

```
docker-mailserver/
├── compose.yaml              # Configuração do Docker Compose
├── mailserver.env           # Variáveis de ambiente
├── enviar_email.py          # Script para envio de e-mails
├── setup_mailserver.ps1     # Setup para Windows
├── setup_mailserver.sh      # Setup para Linux/Mac
└── docker-data/dms/
    ├── config/              # Configurações personalizadas
    │   ├── postfix-accounts.cf     # Contas de usuário
    │   ├── postfix-virtual.cf      # Aliases
    │   └── postfix-main.cf         # Configuração Postfix
    ├── mail-data/           # Dados dos e-mails
    ├── mail-state/          # Estado do servidor
    └── mail-logs/           # Logs
```

## 🔄 Backup e Restore

### Backup
```bash
# Backup completo
tar -czf mailserver-backup-$(date +%Y%m%d).tar.gz docker-data/

# Backup apenas e-mails
tar -czf emails-backup-$(date +%Y%m%d).tar.gz docker-data/dms/mail-data/
```

### Restore
```bash
# Parar container
docker-compose down

# Restaurar arquivos
tar -xzf mailserver-backup-YYYYMMDD.tar.gz

# Reiniciar container
docker-compose up -d
```

## 📞 Suporte

Para problemas específicos:

1. Consulte os logs: `docker logs mailserver`
2. Verifique a documentação oficial: https://docker-mailserver.github.io/
3. Teste a configuração: `docker exec mailserver setup config test`

## 📝 Aliases Configurados

Os seguintes aliases estão configurados automaticamente:

- `info@soundchain.shop` → `contact@soundchain.shop`
- `admin@soundchain.shop` → `contact@soundchain.shop`
- `support@soundchain.shop` → `contact@soundchain.shop`
- `noreply@soundchain.shop` → `contact@soundchain.shop`

Para adicionar novos aliases, edite o arquivo `docker-data/dms/config/postfix-virtual.cf` e reinicie o container.
