#!/bin/bash
# =============================================================
# Script para calcular la curva de productividad (Ej5, Ej6, Ej7)
# Ejecuta JMeter con distintos números de usuarios y recoge throughput
#
# Uso:
#   ./scripts/run_productivity_curve.sh <fichero.jmx> <etiqueta>
#
# Ejemplo:
#   ./scripts/run_productivity_curve.sh P3_P1-base.jmx p1base_gunicorn
#   ./scripts/run_productivity_curve.sh P3_P1-base.jmx p1base_runserver
#
# Requisitos:
#   - Ejecutar desde la raíz del proyecto (donde está apache-jmeter-5.6.3/)
#   - El servidor Django debe estar corriendo
# =============================================================

set -e

JMX_FILE=$1
LABEL=$2
JMETER_BIN="./apache-jmeter-5.6.3/bin/jmeter.sh"
RESULTS_DIR="results_${LABEL}"
SAMPLE=10  # Repetir cada experimento 10 veces

if [ -z "$JMX_FILE" ] || [ -z "$LABEL" ]; then
    echo "Uso: $0 <fichero.jmx> <etiqueta>"
    echo "Ejemplo: $0 P3_P1-base.jmx p1base_gunicorn"
    exit 1
fi

# Crear directorio de resultados
mkdir -p "$RESULTS_DIR"

# Lista de usuarios a probar
USERS_LIST="1 2 3 5 7 10 15 20 25 30"

echo "=========================================="
echo " Curva de productividad: $LABEL"
echo " JMX: $JMX_FILE"
echo " Samples por usuario: $SAMPLE"
echo "=========================================="

# Archivo CSV para recoger throughput
echo "users,throughput,avg_response,error_pct" > "${RESULTS_DIR}/throughput_summary.csv"

for users in $USERS_LIST; do
    echo ""
    echo "--- Ejecutando con $users usuarios ---"

    OUTPUT_DIR="${RESULTS_DIR}/output_users_${users}"
    JTL_FILE="${RESULTS_DIR}/results_users_${users}.jtl"

    # Limpiar ejecución anterior si existe
    rm -rf "$OUTPUT_DIR"
    rm -f "$JTL_FILE"

    # Ejecutar JMeter en modo CLI
    $JMETER_BIN -n -t "$JMX_FILE" \
        -Jusers=$users \
        -Jsamples=$SAMPLE \
        -l "$JTL_FILE" \
        -Jsummariser.name=summary \
        -e -o "$OUTPUT_DIR" 2>&1 | grep "summary =" | tail -1

    # Extraer throughput del statistics.json generado
    if [ -f "${OUTPUT_DIR}/statistics.json" ]; then
        # Extraer throughput Total
        THROUGHPUT=$(python3 -c "
import json
with open('${OUTPUT_DIR}/statistics.json') as f:
    data = json.load(f)
total = data.get('Total', {})
print(f\"${users},{total.get('throughput', 0):.2f},{total.get('meanResTime', 0):.2f},{total.get('errorPct', 0):.2f}\")
")
        echo "$THROUGHPUT" >> "${RESULTS_DIR}/throughput_summary.csv"
        echo "  → Throughput: $(echo $THROUGHPUT | cut -d',' -f2) req/s"
    else
        echo "  → AVISO: No se generó statistics.json"
    fi

    # Pausa entre ejecuciones para que el servidor se recupere
    sleep 3
done

echo ""
echo "=========================================="
echo " Resultados guardados en: ${RESULTS_DIR}/throughput_summary.csv"
echo "=========================================="
cat "${RESULTS_DIR}/throughput_summary.csv"
