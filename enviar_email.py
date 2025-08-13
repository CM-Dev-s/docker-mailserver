#!/usr/bin/env python3
"""
Script para envio de e-mails via SMTP para soundchain.shop
Suporta texto simples e anexos
"""

import smtplib
import os
import sys
import argparse
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
from pathlib import Path

# Configurações do servidor SMTP
SMTP_SERVER = "soundchain.shop"  # Mudança temporária para testar localmente
SMTP_PORT = 587  # Para STARTTLS
SMTP_PORT_SSL = 465  # Para SSL direto
DEFAULT_USER = "contact@soundchain.shop"
DEFAULT_PASSWORD = "sound@123"  # Senha padrão (pode ser alterada via parâmetro)

def enviar_email(destinatario, assunto, texto, arquivo_anexo=None, 
                usuario=DEFAULT_USER, senha=None, usar_ssl=False):
    """
    Envia um e-mail via SMTP
    
    Args:
        destinatario (str): Email do destinatário
        assunto (str): Assunto do e-mail
        texto (str): Corpo do e-mail
        arquivo_anexo (str, optional): Caminho para arquivo anexo
        usuario (str): Email do remetente
        senha (str): Senha do email (usa DEFAULT_PASSWORD se não fornecida)
        usar_ssl (bool): True para usar SSL direto (porta 465), False para STARTTLS (porta 587)
    """
    
    if not senha:
        senha = DEFAULT_PASSWORD
        print(f"Usando senha padrão para {usuario}")
    
    # Criar mensagem
    msg = MIMEMultipart()
    msg['From'] = usuario
    msg['To'] = destinatario
    msg['Subject'] = assunto
    
    # Adicionar corpo do e-mail
    msg.attach(MIMEText(texto, 'plain', 'utf-8'))
    
    # Adicionar anexo se fornecido
    if arquivo_anexo and os.path.exists(arquivo_anexo):
        with open(arquivo_anexo, "rb") as attachment:
            part = MIMEBase('application', 'octet-stream')
            part.set_payload(attachment.read())
        
        encoders.encode_base64(part)
        part.add_header(
            'Content-Disposition',
            f'attachment; filename= {os.path.basename(arquivo_anexo)}',
        )
        msg.attach(part)
        print(f"Anexo adicionado: {arquivo_anexo}")
    elif arquivo_anexo:
        print(f"AVISO: Arquivo anexo não encontrado: {arquivo_anexo}")
    
    # Enviar e-mail
    try:
        if usar_ssl:
            # Conexão SSL direta
            server = smtplib.SMTP_SSL(SMTP_SERVER, SMTP_PORT_SSL)
            print(f"Conectado via SSL na porta {SMTP_PORT_SSL}")
        else:
            # Conexão simples ou STARTTLS opcional
            server = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
            try:
                # Tentar STARTTLS se disponível (opcional quando SSL_TYPE está vazio)
                server.starttls()
                print(f"Conectado via STARTTLS na porta {SMTP_PORT}")
            except:
                # Se STARTTLS falhar, continuar sem criptografia
                print(f"Conectado SEM criptografia na porta {SMTP_PORT}")
        
        server.login(usuario, senha)
        server.send_message(msg)
        server.quit()
        
        print(f"✓ E-mail enviado com sucesso!")
        print(f"  De: {usuario}")
        print(f"  Para: {destinatario}")
        print(f"  Assunto: {assunto}")
        
    except Exception as e:
        print(f"✗ Erro ao enviar e-mail: {e}")
        return False
    
    return True

def main():
    parser = argparse.ArgumentParser(description='Enviar e-mail via SMTP para soundchain.shop')
    parser.add_argument('destinatario', help='Email do destinatário')
    parser.add_argument('assunto', help='Assunto do e-mail')
    parser.add_argument('texto', help='Corpo do e-mail ou caminho para arquivo .txt')
    parser.add_argument('--anexo', '-a', help='Caminho para arquivo anexo')
    parser.add_argument('--usuario', '-u', default=DEFAULT_USER, help='Email do remetente')
    parser.add_argument('--senha', '-p', help='Senha do email (será solicitada se não fornecida)')
    parser.add_argument('--ssl', action='store_true', help='Usar SSL direto (porta 465) ao invés de STARTTLS (porta 587)')
    
    args = parser.parse_args()
    
    # Verificar se o texto é um arquivo
    if os.path.exists(args.texto) and args.texto.endswith('.txt'):
        with open(args.texto, 'r', encoding='utf-8') as f:
            texto = f.read()
        print(f"Texto carregado do arquivo: {args.texto}")
    else:
        texto = args.texto
    
    # Enviar e-mail
    sucesso = enviar_email(
        destinatario=args.destinatario,
        assunto=args.assunto,
        texto=texto,
        arquivo_anexo=args.anexo,
        usuario=args.usuario,
        senha=args.senha,
        usar_ssl=args.ssl
    )
    
    sys.exit(0 if sucesso else 1)

if __name__ == "__main__":
    main()
