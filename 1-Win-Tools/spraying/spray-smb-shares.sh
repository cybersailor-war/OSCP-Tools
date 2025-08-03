#!/bin/bash

# --- Cores para o output ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # Sem Cor
# ---------------------------

# --- Função Principal de Enumeração SMB ---
# Argumentos: $1=Tipo de Autenticação ('domain' ou 'local')
run_smb_enum() {
    local auth_type=$1

    clear
    echo -e "${BLUE}--- MODO: Enumeração de Shares SMB (${auth_type^^}) ---${NC}"
    read -p "Digite o caminho para o arquivo de ALVOS (ex: targets.txt): " TARGETS_FILE
    if [ ! -f "$TARGETS_FILE" ]; then
        echo -e "${RED}Erro: Arquivo de alvos não encontrado.${NC}"
        return
    fi
    
    echo ""
    echo "Como você quer fornecer as credenciais?"
    echo "1) Usar arquivos (users.txt e pass.txt)"
    echo "2) Usar credencial única (usuário e senha)"
    read -p "Escolha uma opção [1-2]: " cred_choice

    local cred_flags=""
    
    if [ "$cred_choice" == "1" ]; then
        read -p "Digite o caminho para o arquivo de USUÁRIOS (ex: users.txt): " USERS_FILE
        if [ ! -f "$USERS_FILE" ]; then echo -e "${RED}Erro: Arquivo de usuários não encontrado.${NC}"; return; fi
        read -p "Digite o caminho para o arquivo de SENHAS (ex: pass.txt): " PASSWORDS_FILE
        if [ ! -f "$PASSWORDS_FILE" ]; then echo -e "${RED}Erro: Arquivo de senhas não encontrado.${NC}"; return; fi
        creds="-u '$USERS_FILE' -p '$PASSWORDS_FILE'"
    elif [ "$cred_choice" == "2" ]; then
        read -p "Digite um único NOME DE USUÁRIO: " USERNAME
        read -p "Digite uma única SENHA: " PASSWORD
        creds="-u '$USERNAME' -p '$PASSWORD'"
    else
        echo -e "${RED}Opção de credencial inválida.${NC}"; return
    fi

    echo ""

    if [ "$auth_type" == "domain" ]; then
        read -p "Digite o nome do DOMÍNIO (ex: medtech.com): " DOMAIN
        echo -e "\n${YELLOW}[*] Executando enumeração de shares de DOMÍNIO...${NC}"
        eval "nxc smb '$TARGETS_FILE' $creds -d '$DOMAIN' --shares"
    else
        echo -e "\n${YELLOW}[*] Executando enumeração de shares LOCAIS...${NC}"
        eval "nxc smb '$TARGETS_FILE' $creds --local-auth --shares"
    fi
}

# --- Loop Principal do Menu ---
while true; do
    clear
    echo -e "${BLUE}"
cat << "EOF"
             ____ ____  _____           __ _  ___        
            |  _ \___ \|  __ \         /_ | |/ _ \       
   ___ _   _| |_) |__) | |__) |___  __ _| | | | | |_ __  
  / __| | | |  _ <|__ <|  _  // __|/ _` | | | | | | '__| 
 | (__| |_| | |_) |__) | | \ \\__ \ (_| | | | |_| | |    
  \___|\__, |____/____/|_|  \_\___/\__,_|_|_|\___/|_|    
        __/ |                                            
   ____|___/ __ ____     _____ _                         
  / ____|  \/  |  _ \   / ____| |                        
 | (___ | \  / | |_) | | (___ | |__   __ _ _ __ ___  ___ 
  \___ \| |\/| |  _ <   \___ \| '_ \ / _` | '__/ _ \/ __|
  ____) | |  | | |_) |  ____) | | | | (_| | | |  __/\__ \
 |_____/|_|  |_|____/  |_____/|_| |_|\__,_|_|  \___||___/
                                                         
                                                                                  
EOF
    echo -e "${NC}"
    echo "              Ferramenta de Enumeração de Shares SMB"
    echo "------------------------------------------------------------------"

    echo ""
    echo -e "${GREEN}1)${NC} Enumerar Shares (Autenticação de Domínio)"
    echo -e "${GREEN}2)${NC} Enumerar Shares (Autenticação Local)"
    echo -e "${RED}3)${NC} Sair"
    echo ""
    read -p "Escolha uma opção [1-3]: " choice

    case $choice in
        1) run_smb_enum "domain" ;;
        2) run_smb_enum "local" ;;
        3) clear; echo -e "${YELLOW}Saindo...${NC}"; exit 0 ;;
        *) echo -e "${RED}Opção inválida.${NC}" ;;
    esac

    echo ""
    read -p "Pressione [Enter] para retornar ao menu..."
done
