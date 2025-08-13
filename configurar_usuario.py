#!/usr/bin/env python3
"""
Script para configurar o usuário contact@soundchain.shop com senha específica
"""

import subprocess
import sys
import time

def executar_comando(comando, input_text=None):
    """Executa um comando e retorna o resultado"""
    try:
        if input_text:
            process = subprocess.Popen(
                comando, 
                shell=True, 
                stdin=subprocess.PIPE, 
                stdout=subprocess.PIPE, 
                stderr=subprocess.PIPE,
                text=True
            )
            stdout, stderr = process.communicate(input=input_text)
        else:
            process = subprocess.run(
                comando, 
                shell=True, 
                capture_output=True, 
                text=True
            )
            stdout = process.stdout
            stderr = process.stderr
        
        return stdout, stderr, process.returncode if hasattr(process, 'returncode') else 0
    except Exception as e:
        return "", str(e), 1

def verificar_docker():
    """Verifica se o Docker está instalado e rodando"""
    print("🔍 Verificando Docker...")
    stdout, stderr, code = executar_comando("docker --version")
    if code != 0:
        print("❌ Docker não está instalado ou não está funcionando")
        return False
    print(f"✅ {stdout.strip()}")
    return True

def verificar_container():
    """Verifica se o container mailserver está rodando"""
    print("🔍 Verificando container mailserver...")
    stdout, stderr, code = executar_comando("docker ps --filter name=mailserver --format '{{.Names}}'")
    if "mailserver" not in stdout:
        print("❌ Container mailserver não está rodando")
        print("Execute primeiro: docker-compose up -d")
        return False
    print("✅ Container mailserver está rodando")
    return True

def aguardar_inicializacao():
    """Aguarda o container inicializar completamente"""
    print("⏳ Aguardando inicialização completa do mailserver...")
    for i in range(30):
        stdout, stderr, code = executar_comando("docker exec mailserver supervisorctl status")
        if code == 0 and "RUNNING" in stdout:
            print("✅ Mailserver inicializado")
            return True
        time.sleep(2)
        print(f"   Aguardando... ({i+1}/30)")
    
    print("⚠️  Timeout na inicialização, continuando mesmo assim...")
    return True

def criar_usuario():
    """Cria o usuário contact@soundchain.shop com senha sound@123"""
    print("👤 Criando usuário contact@soundchain.shop...")
    
    # Senha em formato criptografado compatível com Dovecot
    senha = "sound@123"
    
    # Comando para adicionar usuário
    comando = f"docker exec mailserver setup email add contact@soundchain.shop '{senha}'"
    
    stdout, stderr, code = executar_comando(comando)
    
    if code == 0:
        print("✅ Usuário contact@soundchain.shop criado com sucesso")
        return True
    else:
        print(f"❌ Erro ao criar usuário: {stderr}")
        return False

def configurar_dkim():
    """Configura DKIM para soundchain.shop"""
    print("🔐 Configurando DKIM...")
    
    comando = "docker exec mailserver setup config dkim domain soundchain.shop"
    stdout, stderr, code = executar_comando(comando)
    
    if code == 0:
        print("✅ DKIM configurado com sucesso")
        
        # Mostrar chave DKIM
        print("\n📋 Registro DKIM para adicionar ao DNS:")
        comando_dkim = "docker exec mailserver cat /tmp/docker-mailserver/opendkim/keys/soundchain.shop/mail.txt"
        stdout, stderr, code = executar_comando(comando_dkim)
        if code == 0:
            print(stdout)
        
        return True
    else:
        print(f"⚠️  Aviso DKIM: {stderr}")
        return True  # Não é crítico para o funcionamento básico

def listar_usuarios():
    """Lista todos os usuários configurados"""
    print("\n📊 Usuários configurados:")
    comando = "docker exec mailserver setup email list"
    stdout, stderr, code = executar_comando(comando)
    
    if code == 0:
        if stdout.strip():
            print(stdout)
        else:
            print("Nenhum usuário encontrado")
    else:
        print(f"Erro ao listar usuários: {stderr}")

def testar_configuracao():
    """Testa a configuração básica"""
    print("\n🔧 Testando configuração...")
    
    # Testar configuração geral
    comando = "docker exec mailserver setup config test"
    stdout, stderr, code = executar_comando(comando)
    
    if code == 0:
        print("✅ Configuração básica OK")
    else:
        print(f"⚠️  Avisos na configuração: {stderr}")
    
    # Mostrar status dos serviços
    comando = "docker exec mailserver supervisorctl status"
    stdout, stderr, code = executar_comando(comando)
    
    if code == 0:
        print("\n📋 Status dos serviços:")
        print(stdout)

def main():
    print("🚀 Configurando usuário e serviços para soundchain.shop")
    print("=" * 60)
    
    # Verificações iniciais
    if not verificar_docker():
        sys.exit(1)
    
    if not verificar_container():
        sys.exit(1)
    
    # Aguardar inicialização
    aguardar_inicializacao()
    
    # Configurar usuário
    if not criar_usuario():
        print("❌ Falha ao criar usuário principal")
        sys.exit(1)
    
    # Configurar DKIM
    configurar_dkim()
    
    # Listar usuários
    listar_usuarios()
    
    # Testar configuração
    testar_configuracao()
    
    print("\n" + "=" * 60)
    print("🎉 Configuração concluída!")
    print("\n📧 Credenciais de acesso:")
    print("   Email: contact@soundchain.shop")
    print("   Senha: sound@123")
    print("   Servidor SMTP: mail.soundchain.shop:587 (STARTTLS)")
    print("   Servidor IMAP: mail.soundchain.shop:993 (SSL)")
    print("\n📋 Para enviar e-mail de teste:")
    print("   python enviar_email.py destinatario@exemplo.com 'Teste' 'Mensagem de teste'")
    print("\n⚠️  Não esqueça de configurar os registros DNS!")
    print("   Consulte: DNS-Config-soundchain.md")

if __name__ == "__main__":
    main()
