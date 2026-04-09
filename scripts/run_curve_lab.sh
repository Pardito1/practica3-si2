#!/bin/bash
# =============================================================
# Curva de productividad adaptada al PC del lab (sin VMs)
#
# Ajustes respecto a run_productivity_curve.sh:
#   - Rutas absolutas configurables por variables de entorno
#   - Limpieza de pagos en la BD antes de cada ejecución (si no,
#     chocamos contra el unique constraint unique_blocking_pago)
#   - Pensado para P3-projects.jmx con P1-base como único Thread
#     Group habilitado (así no hay que tocar P3_P1-base.jmx)
#
# Variables que puedes sobreescribir desde la línea de comandos:
#   JMETER_BIN  — ruta al jmeter.sh        (default: /opt/apache-jmeter-5.6.3/bin/jmeter.sh)
#   JMX_FILE    — ruta al .jmx             (default: $HOME/Escritorio/P3-projects.jmx)
#   P1BASE_DIR  — ruta al proyecto P1-base (default: $HOME/Escritorio/si2_alumnos-main/P1-base)
#   LABEL       — etiqueta del run         (default: p1base_gunicorn)
#   RESULTS_DIR — dónde guardar resultados (default: $HOME/Escritorio/results_$LABEL)
#
# Uso básico:
#   ./scripts/run_curve_lab.sh
#   LABEL=p1base_runserver ./scripts/run_curve_lab.sh
# =============================================================

set -e

JMETER_BIN="${JMETER_BIN:-/opt/apache-jmeter-5.6.3/bin/jmeter.sh}"
JMX_FILE="${JMX_FILE:-$HOME/Escritorio/P3-projects.jmx}"
P1BASE_DIR="${P1BASE_DIR:-$HOME/Escritorio/si2_alumnos-main/P1-base}"
LABEL="${LABEL:-p1base_gunicorn}"
RESULTS_DIR="${RESULTS_DIR:-$HOME/Escritorio/results_${LABEL}}"
SAMPLE="${SAMPLE:-10}"
USERS_LIST="${USERS_LIST:-1 2 3 5 7 10 15 20 25 30}"

echo "=========================================="
echo " Curva de productividad: $LABEL"
echo " JMX:        $JMX_FILE"
echo " JMeter:     $JMETER_BIN"
echo " P1-base:    $P1BASE_DIR"
echo " Resultados: $RESULTS_DIR"
echo " Samples:    $SAMPLE"
echo " Users list: $USERS_LIST"
echo "=========================================="

if [ ! -f "$JMETER_BIN" ]; then
    echo "ERROR: No existe $JMETER_BIN"; exit 1
fi
if [ ! -f "$JMX_FILE" ]; then
    echo "ERROR: No existe $JMX_FILE"; exit 1
fi
if [ ! -d "$P1BASE_DIR" ]; then
    echo "ERROR: No existe $P1BASE_DIR"; exit 1
fi

mkdir -p "$RESULTS_DIR"
echo "users,throughput,avg_response,error_pct" > "${RESULTS_DIR}/throughput_summary.csv"

clean_pagos() {
    # Borra todos los pagos manteniendo las tarjetas poblladas
    (cd "$P1BASE_DIR" && python manage.py shell -c \
        "from visaApp.models import Pago; Pago.objects.all().delete()" \
        > /dev/null 2>&1) || {
        echo "  ! AVISO: no se pudo limpiar la tabla Pago (¿entorno virtual activo?)"
    }
}

for users in $USERS_LIST; do
    echo ""
    echo "--- Ejecutando con $users usuarios ---"

    OUTPUT_DIR="${RESULTS_DIR}/output_users_${users}"
    JTL_FILE="${RESULTS_DIR}/results_users_${users}.jtl"

    rm -rf "$OUTPUT_DIR" "$JTL_FILE"

    echo "  · limpiando tabla Pago..."
    clean_pagos

    "$JMETER_BIN" -n -t "$JMX_FILE" \
        -Jusers=$users \
        -Jsamples=$SAMPLE \
        -l "$JTL_FILE" \
        -Jsummariser.name=summary \
        -e -o "$OUTPUT_DIR" 2>&1 | grep "summary =" | tail -1

    if [ -f "${OUTPUT_DIR}/statistics.json" ]; then
        THROUGHPUT=$(python3 -c "
import json
with open('${OUTPUT_DIR}/statistics.json') as f:
    data = json.load(f)
total = data.get('Total', {})
print(f\"${users},{total.get('throughput', 0):.2f},{total.get('meanResTime', 0):.2f},{total.get('errorPct', 0):.2f}\")
")
        echo "$THROUGHPUT" >> "${RESULTS_DIR}/throughput_summary.csv"
        echo "  → Throughput: $(echo $THROUGHPUT | cut -d',' -f2) req/s   Err%: $(echo $THROUGHPUT | cut -d',' -f4)"
    else
        echo "  ! AVISO: no se generó statistics.json para $users users"
    fi

    sleep 3
done

echo ""
echo "=========================================="
echo " Resultados en: ${RESULTS_DIR}/throughput_summary.csv"
echo "=========================================="
cat "${RESULTS_DIR}/throughput_summary.csv"
