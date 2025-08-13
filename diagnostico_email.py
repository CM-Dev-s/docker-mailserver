#!/usr/bin/env python3
"""
Script de diagnóstico completo para o mailserver soundchain.shop
"""

import socket
import smtplib
import subprocess
import sys

def testar_dns():
    """Testa resolução DNS"""
    print("🔍 Testando resolução DNS...")
    hosts = ["localhost", "127.0.0.1", "mail.soundchain.shop"]
    
    for host in hosts:
        try:
            ip = socket.gethostbyname(host)
            print(f"✅ {host} -> {ip}")
        except socket.gaierror as e:
            print(f"❌ {host} -> Erro: {e}")

def testar_conectividade():
    """Testa conectividade nas portas SMTP"""
    print("\n🔌 Testando conectividade SMTP...")
    hosts = [("localhost", 25), ("localhost", 587), ("127.0.0.1", 25), ("127.0.0.1", 587)]
    
    for host, port in hosts:
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(5)
            result = sock.connect_ex((host, port))
            sock.close()
            
            if result == 0:
                print(f"✅ {host}:{port} - Conectado")
            else:
                print(f"❌ {host}:{port} - Porta fechada")
        except Exception as e:
            print(f"❌ {host}:{port} - Erro: {e}")

def testar_smtp_basico():
    """Testa conexão SMTP básica"""
    print("\n📧 Testando conexão SMTP básica...")
    
    hosts = ["localhost", "127.0.0.1"]
    
    for host in hosts:
        try:
            print(f"Tentando conectar em {host}:587...")
            server = smtplib.SMTP(host, 587, timeout=10)
            server.ehlo()
            print(f"✅ {host}:587 - Conexão SMTP OK")
            print(f"   Recursos: {server.esmtp_features}")
            server.quit()
            return host
        except Exception as e:
            print(f"❌ {host}:587 - Erro SMTP: {e}")
    
    return None

def verificar_container():
    """Verifica status do container"""
    print("\n🐳 Verificando container...")
    
    try:
        # Verificar se container está rodando
        result = subprocess.run(
            ["docker", "ps", "--filter", "name=mailserver", "--format", "{{.Names}}"],
            capture_output=True, text=True, timeout=10
        )
        
        if "mailserver" in result.stdout:
            print("✅ Container mailserver está rodando")
            
            # Verificar serviços internos
            result = subprocess.run(
                ["docker", "exec", "mailserver", "supervisorctl", "status"],
                capture_output=True, text=True, timeout=10
            )
            
            if result.returncode == 0:
                print("✅ Serviços internos:")
                for linha in result.stdout.strip().split('\n'):
                    if linha.strip():
                        print(f"   {linha}")
            else:
                print("❌ Erro ao verificar serviços internos")
                
        else:
            print("❌ Container mailserver não está rodando")
            return False
            
    except Exception as e:
        print(f"❌ Erro ao verificar container: {e}")
        return False
    
    return True

def main():
    print("🧪 Diagnóstico Completo - soundchain.shop Mailserver")
    print("=" * 60)
    
    # Testes básicos
    testar_dns()
    testar_conectividade()
    
    # Verificar container
    if not verificar_container():
        print("\n❌ Container não está funcionando corretamente")
        return
    
    # Testar SMTP
    host_funcional = testar_smtp_basico()
    
    if host_funcional:
        print(f"\n✅ SMTP funcional em: {host_funcional}")
        print(f"\n💡 Para enviar emails, use:")
        print(f"   python enviar_email.py destinatario@exemplo.com 'Assunto' 'Mensagem'")
        print(f"   (O script já foi configurado para usar {host_funcional})")
    else:
        print("\n❌ Nenhuma conexão SMTP funcionando")
        print("\n🔧 Possíveis soluções:")
        print("   1. Verificar se o container está rodando: docker ps")
        print("   2. Verificar logs: docker logs mailserver")
        print("   3. Reiniciar container: docker-compose restart")

if __name__ == "__main__":
    main()
