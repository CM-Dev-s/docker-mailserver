#!/usr/bin/env python3
"""
Script de teste para envio de email via soundchain.shop
"""

import sys
import os

# Adicionar o diretório atual ao path para importar o módulo de envio
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from enviar_email import enviar_email

def teste_basico():
    """Teste básico de envio de email"""
    print("🧪 Teste básico de envio de email")
    print("=" * 50)
    
    # Dados do teste
    destinatario = input("Digite o email de destino para teste: ").strip()
    if not destinatario:
        print("❌ Email de destino é obrigatório")
        return False
    
    assunto = "Teste do mailserver soundchain.shop"
    texto = """Olá!

Este é um email de teste enviado pelo mailserver configurado para soundchain.shop.

Se você recebeu este email, significa que:
✅ O servidor de email está funcionando
✅ As configurações SMTP estão corretas
✅ A autenticação está funcionando
✅ Os registros DNS estão configurados

Informações técnicas:
- Servidor: mail.soundchain.shop
- Email: contact@soundchain.shop
- Data/Hora: """ + str(__import__('datetime').datetime.now()) + """

Atenciosamente,
Equipe soundchain.shop
"""
    
    print(f"📧 Enviando para: {destinatario}")
    print(f"📝 Assunto: {assunto}")
    
    # Tentar envio
    sucesso = enviar_email(
        destinatario=destinatario,
        assunto=assunto,
        texto=texto,
        usar_ssl=False  # Usar STARTTLS por padrão
    )
    
    if sucesso:
        print("✅ Email de teste enviado com sucesso!")
        print("\n💡 Verifique:")
        print("   1. Caixa de entrada do destinatário")
        print("   2. Pasta de spam/lixo eletrônico")
        print("   3. Logs do servidor: docker logs mailserver")
        return True
    else:
        print("❌ Falha no envio do email de teste")
        print("\n🔧 Possíveis soluções:")
        print("   1. Verificar se o container está rodando: docker ps")
        print("   2. Verificar logs: docker logs mailserver")
        print("   3. Verificar DNS: nslookup mail.soundchain.shop")
        print("   4. Verificar conectividade: telnet mail.soundchain.shop 587")
        return False

def teste_com_anexo():
    """Teste de envio com anexo"""
    print("\n🧪 Teste de envio com anexo")
    print("=" * 50)
    
    # Criar um arquivo de teste temporário
    arquivo_teste = "teste_anexo.txt"
    with open(arquivo_teste, 'w', encoding='utf-8') as f:
        f.write("Este é um arquivo de teste para anexo.\n")
        f.write("Gerado automaticamente pelo script de teste.\n")
        f.write(f"Data: {__import__('datetime').datetime.now()}\n")
    
    destinatario = input("Digite o email de destino para teste com anexo: ").strip()
    if not destinatario:
        print("❌ Email de destino é obrigatório")
        return False
    
    assunto = "Teste com anexo - soundchain.shop"
    texto = "Este é um teste de envio de email com anexo.\n\nO arquivo anexo foi gerado automaticamente."
    
    print(f"📧 Enviando para: {destinatario}")
    print(f"📎 Anexo: {arquivo_teste}")
    
    sucesso = enviar_email(
        destinatario=destinatario,
        assunto=assunto,
        texto=texto,
        arquivo_anexo=arquivo_teste
    )
    
    # Limpar arquivo temporário
    try:
        os.remove(arquivo_teste)
    except:
        pass
    
    if sucesso:
        print("✅ Email com anexo enviado com sucesso!")
        return True
    else:
        print("❌ Falha no envio do email com anexo")
        return False

def verificar_configuracao():
    """Verifica se a configuração está OK"""
    print("🔍 Verificando configuração do mailserver")
    print("=" * 50)
    
    import subprocess
    
    # Verificar se o container está rodando
    try:
        result = subprocess.run(
            ["docker", "ps", "--filter", "name=mailserver", "--format", "{{.Names}}"],
            capture_output=True,
            text=True
        )
        
        if "mailserver" in result.stdout:
            print("✅ Container mailserver está rodando")
        else:
            print("❌ Container mailserver não está rodando")
            print("Execute: docker-compose up -d")
            return False
    except:
        print("❌ Erro ao verificar container")
        return False
    
    # Verificar usuários configurados
    try:
        result = subprocess.run(
            ["docker", "exec", "mailserver", "setup", "email", "list"],
            capture_output=True,
            text=True
        )
        
        if result.returncode == 0:
            print("✅ Usuários configurados:")
            if result.stdout.strip():
                print(f"   {result.stdout.strip()}")
            else:
                print("   Nenhum usuário encontrado")
        else:
            print("❌ Erro ao listar usuários")
    except:
        print("❌ Erro ao verificar usuários")
    
    # Verificar status dos serviços
    try:
        result = subprocess.run(
            ["docker", "exec", "mailserver", "supervisorctl", "status"],
            capture_output=True,
            text=True
        )
        
        if result.returncode == 0:
            print("✅ Status dos serviços:")
            for linha in result.stdout.strip().split('\n'):
                if linha.strip():
                    print(f"   {linha}")
        else:
            print("❌ Erro ao verificar serviços")
    except:
        print("❌ Erro ao verificar status dos serviços")
    
    return True

def main():
    print("🧪 Script de Teste - soundchain.shop Mailserver")
    print("=" * 60)
    
    # Menu de opções
    while True:
        print("\nEscolha uma opção:")
        print("1. Verificar configuração")
        print("2. Teste básico de envio")
        print("3. Teste com anexo")
        print("4. Sair")
        
        opcao = input("\nDigite sua opção (1-4): ").strip()
        
        if opcao == "1":
            verificar_configuracao()
        elif opcao == "2":
            teste_basico()
        elif opcao == "3":
            teste_com_anexo()
        elif opcao == "4":
            print("👋 Saindo...")
            break
        else:
            print("❌ Opção inválida")

if __name__ == "__main__":
    main()
