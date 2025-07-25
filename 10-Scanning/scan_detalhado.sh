#!/bin/bash

# Verifique se um IP foi fornecido
if [ -z "$1" ]; then
  echo "Uso: $0 <IP>"
  exit 1
fi

TARGET=$1
OUTPUT_FILE="nmap_results_$TARGET" 

echo "🔎 Iniciando scan rápido em todas as portas de $TARGET..."

# Linha corrigida para extrair as portas de forma robusta
PORTS=$(nmap -p- --min-rate=1000 -T4 -n -Pn $TARGET -oG - | grep -o '[0-9]*/open' | cut -d'/' -f1 | tr '\n' ',' | sed 's/,$//')

if [ -n "$PORTS" ]; then
  echo "✅ Portas abertas encontradas: $PORTS"
  echo "🚀 Iniciando scan detalhado nessas portas..."
  echo "📝 Os resultados serão salvos em arquivos com o nome base: $OUTPUT_FILE"
  
  nmap -A -T4 -Pn -sC -sV --script=vuln -p "$PORTS" -oA "$OUTPUT_FILE" "$TARGET"
  
  echo "🎉 Scan detalhado concluído!"
else
  echo "❌ Nenhuma porta aberta foi encontrada."
fi
