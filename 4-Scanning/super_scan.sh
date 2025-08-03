#!/bin/bash

# Cores para o output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # Sem Cor

# >>>>> FUNÇÃO CORRIGIDA <<<<<
# Função para mostrar um resumo limpo dos resultados
summarize_results() {
    local base_file=$1
    # A variável TARGET é acessível pois a função é chamada de dentro de scan_host
    echo -e "\n${YELLOW}📊 Resumo dos Resultados para ${GREEN}$TARGET:${NC}"
    echo -e "${CYAN}----------------------------------------------------------------------${NC}"
    
    printf "${BLUE}%-10s %-8s %-25s %s${NC}\n" "PORTA" "ESTADO" "SERVIÇO" "VERSÃO"
    
    # Pipeline corrigido para extrair os dados corretamente do arquivo .gnmap
    # 1. Pega a linha que contém as portas
    # 2. Isola apenas a lista de portas
    # 3. Troca vírgulas por quebras de linha para processar uma porta por vez
    # 4. Remove espaços em branco no início da linha
    # 5. Usa o awk para formatar e imprimir os campos corretos (Serviço é o campo 5, Versão é o 7)
    grep 'Ports:' "${base_file}.gnmap" | \
    sed 's/.*Ports: //' | \
    tr ',' '\n' | \
    sed 's/^[ \t]*//' | \
    awk -F/ '/open/ {printf "%-10s %-8s %-25s %s\n", $1"/"$3, $2, $5, $7}'

    echo -e "${CYAN}----------------------------------------------------------------------${NC}"
    echo -e "${YELLOW}📝 O relatório completo foi salvo nos arquivos: ${GREEN}${base_file}.*${NC}"
}

# Função principal de scan, com modo "normal" ou "vuln"
scan_host() {
    local TARGET=$1
    local MODE=$2
    local OUTPUT_FILE="nmap_results_${TARGET}_${MODE}"

    echo -e "\n${BLUE}=======================================================${NC}"
    echo -e "${YELLOW}🔎 Iniciando scan de portas ultra-rápido em ${GREEN}$TARGET...${NC} (--min-rate 5000)"

    PORTS=$(nmap -p- --min-rate=5000 -Pn -n -T4 $TARGET -oG - | grep -oP '\d+/open' | cut -d'/' -f1 | tr '\n' ',' | sed 's/,$//')

    if [ -n "$PORTS" ]; then
        echo -e "${GREEN}✅ Portas abertas encontradas: $PORTS${NC}"
        
        if [ "$MODE" == "vuln" ]; then
            echo -e "${RED}🚀 Iniciando scan DETALHADO + VULNERABILIDADES...${NC}"
            nmap -A -Pn --script=vuln -p "$PORTS" -oA "$OUTPUT_FILE" "$TARGET"
        else
            echo -e "${YELLOW}🚀 Iniciando scan detalhado (Versão, Scripts Padrão)...${NC}"
            nmap -A -Pn -p "$PORTS" -oA "$OUTPUT_FILE" "$TARGET"
        fi
        
        echo -e "${GREEN}🎉 Scan detalhado concluído para ${GREEN}$TARGET!${NC}"
        summarize_results "$OUTPUT_FILE"

    else
        echo -e "${RED}❌ Nenhuma porta aberta foi encontrada em ${GREEN}$TARGET.${NC}"
    fi
    echo -e "${BLUE}=======================================================${NC}"
}

# As funções a seguir chamam scan_host com o modo "normal"
scan_network() {
    read -p "Digite a rede a ser varrida (ex: 192.168.0.0/24): " NETWORK
    if [ -z "$NETWORK" ]; then echo -e "${RED}Erro: Nenhum CIDR fornecido.${NC}"; return; fi
    echo -e "\n${BLUE}🔎 Buscando hosts ativos na rede ${GREEN}$NETWORK...${NC}"
    HOSTS_UP=$(nmap -sn -T4 "$NETWORK" -oG - | awk '/Status: Up/{print $2}')
    if [ -z "$HOSTS_UP" ]; then echo -e "${RED}❌ Nenhum host ativo encontrado.${NC}"; return; fi
    echo -e "${GREEN}✅ Hosts ativos encontrados:${NC}\n$HOSTS_UP"
    for host in $HOSTS_UP; do scan_host "$host" "normal"; done
    echo -e "\n${GREEN}🎉 Varredura completa da rede concluída!${NC}"
}

scan_multiple_ips() {
    read -p "Digite os IPs separados por vírgula: " IP_LIST
    if [ -z "$IP_LIST" ]; then echo -e "${RED}Erro: Nenhum IP fornecido.${NC}"; return; fi
    for host in $(echo "$IP_LIST" | tr ',' ' '); do scan_host "$host" "normal"; done
    echo -e "\n${GREEN}🎉 Varredura de múltiplos IPs concluída!${NC}"
}

scan_single_ip() {
    read -p "Digite o IP alvo para o scan padrão: " TARGET_IP
    if [ -z "$TARGET_IP" ]; then echo -e "${RED}Erro: Nenhum IP fornecido.${NC}"; return; fi
    scan_host "$TARGET_IP" "normal"
}

# Nova função que chama scan_host com o modo "vuln"
scan_vuln_ip() {
    read -p "Digite o IP alvo para o Scan de Vulnerabilidades: " TARGET_IP
    if [ -z "$TARGET_IP" ]; then echo -e "${RED}Erro: Nenhum IP fornecido.${NC}"; return; fi
    scan_host "$TARGET_IP" "vuln"
}

# --- Loop Principal do Menu ---
while true; do
    # clear
    echo -e "${BLUE}###########################################${NC}"
    echo -e "${BLUE}#                                         #${NC}"
    echo -e "${BLUE}#         ${YELLOW}Ferramenta de Scan Nmap${NC}         ${BLUE}#${NC}"
    echo -e "${BLUE}#                                         #${NC}"
    echo -e "${BLUE}###########################################${NC}"
    echo ""
    echo -e "${GREEN}1)${NC} Varrer uma Rede Completa"
    echo -e "${GREEN}2)${NC} Varrer um IP Específico (Scan Padrão)"
    echo -e "${GREEN}3)${NC} Varrer Múltiplos IPs (Scan Padrão)"
    echo -e "${RED}4)${NC} Scan de Vulnerabilidades (IP Específico)"
    echo -e "${CYAN}5)${NC} Sair"
    echo ""
    read -p "Escolha uma opção [1-5]: " choice

    case $choice in
        1) scan_network ;;
        2) scan_single_ip ;;
        3) scan_multiple_ips ;;
        4) scan_vuln_ip ;;
        5) echo -e "${YELLOW}Saindo... Até logo!${NC}"; exit 0 ;;
        *) echo -e "${RED}Opção inválida. Por favor, tente novamente.${NC}" ;;
    esac

    echo ""
    read -p "Pressione [Enter] para retornar ao menu..."
done
