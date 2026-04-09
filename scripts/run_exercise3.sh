#!/bin/bash
# =============================================================
# Script para Ejercicio 3: Test de estrés con 1000 threads
# Ramp-Up = 1 segundo
#
# ANTES de ejecutar:
#   1. Lanzar nmon en vm1 y vm2: nmon -f -s 1 -c 120
#   2. Tener el servidor Django corriendo
#
# Uso:
#   ./scripts/run_exercise3.sh
# =============================================================

set -e

JMETER_BIN="./apache-jmeter-5.6.3/bin/jmeter.sh"
JMX_FILE="P3_P1-base.jmx"
RESULTS_DIR="results_ej3_stress"

mkdir -p "$RESULTS_DIR"
rm -rf "${RESULTS_DIR}/output"
rm -f "${RESULTS_DIR}/results.jtl"

echo "=========================================="
echo " Ejercicio 3: Test de estrés"
echo " 1000 threads, Ramp-Up = 1s"
echo "=========================================="
echo ""
echo "RECUERDA: Lanzar nmon en vm1 y vm2 ANTES de continuar"
echo "  En vm1: nmon -f -s 1 -c 120"
echo "  En vm2: nmon -f -s 1 -c 120"
echo ""
read -p "Pulsa Enter cuando nmon esté corriendo..."

# Ejecutar con 1000 threads y ramp-up de 1 segundo
# Nota: Modificamos ramp_time via propiedad. Como el JMX usa valor fijo de 2,
# necesitamos editar el JMX temporalmente o usar una copia
# Creamos una copia temporal con ramp_time=1
cp "$JMX_FILE" "${RESULTS_DIR}/stress_test.jmx"
# macOS compatible sed (BSD sed requiere -i '')
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' 's/<stringProp name="ThreadGroup.ramp_time">2</<stringProp name="ThreadGroup.ramp_time">1</' "${RESULTS_DIR}/stress_test.jmx"
else
    sed -i 's/<stringProp name="ThreadGroup.ramp_time">2</<stringProp name="ThreadGroup.ramp_time">1</' "${RESULTS_DIR}/stress_test.jmx"
fi

$JMETER_BIN -n -t "${RESULTS_DIR}/stress_test.jmx" \
    -Jusers=1000 \
    -Jsamples=1 \
    -l "${RESULTS_DIR}/results.jtl" \
    -Jsummariser.name=summary \
    -e -o "${RESULTS_DIR}/output"

echo ""
echo "=========================================="
echo " Test completado. Resultados en: $RESULTS_DIR"
echo " Ahora para nmon en vm1 y vm2 (Ctrl+C o espera)"
echo " Copia los ficheros .nmon a este directorio"
echo "=========================================="
