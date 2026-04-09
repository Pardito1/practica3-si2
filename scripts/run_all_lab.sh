#!/bin/bash
# =============================================================
# SCRIPT MAESTRO PARA LA SESIÓN DE LAB
# Ejecuta TODAS las pruebas en orden de prioridad
#
# ANTES de ejecutar:
#   1. VMs configuradas y Django corriendo
#   2. Ajustar puertos/hosts abajo si es necesario
#   3. chmod +x scripts/*.sh
#
# Uso:
#   ./scripts/run_all_lab.sh
# =============================================================

set -e

echo "============================================"
echo "  PRÁCTICA 3 SI2 - Sesión de laboratorio"
echo "============================================"
echo ""

# -------------------------------------------------------
# PRIORIDAD 1: Ejercicio 1 - Prueba básica P1-base (APROBADO)
# -------------------------------------------------------
echo ">>> [1/6] Ejercicio 1: Prueba básica P1-base"
echo "    Ejecutando con 10 usuarios, 10 samples..."
mkdir -p results_ej1
rm -rf results_ej1/output
./apache-jmeter-5.6.3/bin/jmeter.sh -n -t P3_P1-base.jmx \
    -Jusers=10 -Jsamples=10 \
    -l results_ej1/results.jtl \
    -Jsummariser.name=summary \
    -e -o results_ej1/output
echo "    → Abre results_ej1/output/index.html para ver Aggregate Report"
echo "    → HAZ CAPTURA DE PANTALLA DEL AGGREGATE REPORT"
echo ""
read -p "Pulsa Enter para continuar con el siguiente ejercicio..."

# -------------------------------------------------------
# PRIORIDAD 2: Ejercicio 5 - Curva productividad P1-base (APROBADO)
# -------------------------------------------------------
echo ""
echo ">>> [2/6] Ejercicio 5: Curva productividad P1-base"
./scripts/run_productivity_curve.sh P3_P1-base.jmx p1base_gunicorn
echo ""
read -p "Pulsa Enter para continuar..."

# -------------------------------------------------------
# PRIORIDAD 3: Ejercicio 5 - Curvas P1-ws y P2-rcp
# -------------------------------------------------------
echo ""
echo ">>> [3/6] Ejercicio 5: Curvas P1-ws y P2-rcp"
echo "    NOTA: Habilita solo el Thread Group correspondiente en P3-projects.jmx"
echo ""

echo "    Ejecutando P1-ws..."
./scripts/enable_threadgroup.sh P1-ws
./scripts/run_productivity_curve.sh P3-projects.jmx p1ws_gunicorn

echo "    Ejecutando P2-rcp..."
./scripts/enable_threadgroup.sh P2-rcp
./scripts/run_productivity_curve.sh P3-projects.jmx p2rcp_gunicorn
echo ""
read -p "Pulsa Enter para continuar..."

# -------------------------------------------------------
# PRIORIDAD 4: Ejercicio 6 - gunicorn vs runserver
# -------------------------------------------------------
echo ""
echo ">>> [4/6] Ejercicio 6: gunicorn vs runserver"
echo "    INSTRUCCIONES:"
echo "    1. Para gunicorn en vm2"
echo "    2. Lanza: python manage.py runserver 0.0.0.0:8000"
echo ""
read -p "Pulsa Enter cuando runserver esté corriendo..."
./scripts/run_productivity_curve.sh P3_P1-base.jmx p1base_runserver
echo ""
read -p "Pulsa Enter para continuar..."

# -------------------------------------------------------
# PRIORIDAD 5: Ejercicio 7 - 2 workers + 2 CPUs
# -------------------------------------------------------
echo ""
echo ">>> [5/6] Ejercicio 7: 2 workers + 2 CPUs"
echo "    INSTRUCCIONES:"
echo "    1. Apaga vm2"
echo "    2. En VirtualBox: asigna 2 CPUs a vm2"
echo "    3. Enciende vm2"
echo "    4. Edita settings.py: SESSION_ENGINE = 'django.contrib.sessions.backends.db'"
echo "    5. Lanza: gunicorn visaSite.wsgi:application --bind 0.0.0.0:8000 --workers 2"
echo ""
read -p "Pulsa Enter cuando todo esté configurado..."
./scripts/run_productivity_curve.sh P3_P1-base.jmx p1base_2workers_2cpus
echo ""
read -p "Pulsa Enter para continuar..."

# -------------------------------------------------------
# PRIORIDAD 6: Ejercicio 3 - Test de estrés
# -------------------------------------------------------
echo ""
echo ">>> [6/6] Ejercicio 3: Test de estrés 1000 threads"
./scripts/run_exercise3.sh

echo ""
echo "============================================"
echo "  TODAS LAS PRUEBAS COMPLETADAS"
echo "  Ahora genera las gráficas:"
echo "    python3 scripts/generate_graphs.py"
echo "============================================"
