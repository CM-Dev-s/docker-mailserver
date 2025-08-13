# Configurações DNS para soundchain.shop
# IP do servidor: 212.85.1.63
# Data: 12 de Agosto de 2025

## Registros DNS Obrigatórios

### 1. Registro A (Principal)
```
mail.soundchain.shop.    A    212.85.1.63
```

### 2. Registro MX (Direcionamento de email)
```
soundchain.shop.         MX   10   mail.soundchain.shop.
```

### 3. Registro SPF (Prevenção de spam)
```
soundchain.shop.         TXT  "v=spf1 mx ip4:212.85.1.63 ~all"
```

### 4. Registro DMARC (Política de autenticação)
```
_dmarc.soundchain.shop.  TXT  "v=DMARC1; p=quarantine; rua=mailto:contact@soundchain.shop; ruf=mailto:contact@soundchain.shop; fo=1"
```

### 5. Registro PTR (Reverse DNS) - Configure no provedor do IP
```
63.1.85.212.in-addr.arpa.  PTR  mail.soundchain.shop.
```

## Registros DKIM (Serão gerados automaticamente)

O registro DKIM será gerado automaticamente pelo docker-mailserver. 
Após executar o setup, você encontrará o conteúdo em:

```bash
docker exec mailserver cat /tmp/docker-mailserver/opendkim/keys/soundchain.shop/mail.txt
```

O formato será similar a:
```
mail._domainkey.soundchain.shop.  TXT  "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC..."
```

## Verificação dos Registros

### Verificar propagação DNS:
```bash
# Verificar registro A
nslookup mail.soundchain.shop

# Verificar registro MX
nslookup -type=MX soundchain.shop

# Verificar registro SPF
nslookup -type=TXT soundchain.shop

# Verificar registro DMARC
nslookup -type=TXT _dmarc.soundchain.shop
```

### Ferramentas online para verificação:
- MX Toolbox: https://mxtoolbox.com/
- DKIM Validator: https://dkimvalidator.com/
- Mail Tester: https://www.mail-tester.com/

## Notas Importantes

1. **Propagação DNS**: Pode levar até 24-48 horas para propagar completamente
2. **TTL**: Configure TTL baixo (300-600s) durante a configuração inicial
3. **Reverse DNS**: Entre em contato com seu provedor de VPS/servidor para configurar o PTR
4. **Firewall**: Certifique-se que as portas 25, 587, 465, 993, 143 estão abertas

## Teste de Conectividade

```bash
# Testar conectividade SMTP
telnet mail.soundchain.shop 25
telnet mail.soundchain.shop 587
telnet mail.soundchain.shop 465

# Testar conectividade IMAP
telnet mail.soundchain.shop 993
telnet mail.soundchain.shop 143
```
