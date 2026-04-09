#!/bin/bash
# =============================================================
# Script para habilitar un solo Thread Group en P3-projects.jmx
# Los demás se deshabilitan.
#
# Uso:
#   ./scripts/enable_threadgroup.sh P1-base
#   ./scripts/enable_threadgroup.sh P1-ws
#   ./scripts/enable_threadgroup.sh P2-rcp
#   ./scripts/enable_threadgroup.sh all    # habilita todos
# =============================================================

JMX_FILE="P3-projects.jmx"
TARGET=$1

if [ -z "$TARGET" ]; then
    echo "Uso: $0 <P1-base|P1-ws|P2-rcp|all>"
    exit 1
fi

# Backup
cp "$JMX_FILE" "${JMX_FILE}.bak"

# Función para habilitar/deshabilitar un Thread Group por nombre
# Usa Python para hacer parsing XML limpio
python3 -c "
import xml.etree.ElementTree as ET
import sys

tree = ET.parse('$JMX_FILE')
root = tree.getroot()

target = '$TARGET'
tg_names = ['P1-base', 'P1-ws', 'P2-rcp']

for tg in root.iter('ThreadGroup'):
    name = tg.get('testname', '')
    if target == 'all':
        tg.set('enabled', 'true')
    elif name == target:
        tg.set('enabled', 'true')
    elif name in tg_names:
        tg.set('enabled', 'false')

tree.write('$JMX_FILE', encoding='UTF-8', xml_declaration=True)
print(f'Thread Group habilitado: {target}')
for tg in root.iter('ThreadGroup'):
    name = tg.get('testname', '')
    enabled = tg.get('enabled', '')
    if name in tg_names:
        status = '✓ HABILITADO' if enabled == 'true' else '✗ deshabilitado'
        print(f'  {name}: {status}')
"

echo ""
echo "Backup guardado en ${JMX_FILE}.bak"
