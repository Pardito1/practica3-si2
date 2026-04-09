# Plan Completo — Práctica 3 SI2

## Situación actual
- VMs: hay que configurarlas desde cero
- Proyectos Django: solo código (ws/rpc son stubs, hay que tener el código de P1/P2)
- JMeter: no instalado (aunque el zip de 5.6.3 está en la carpeta)
- Sesiones de lab: **1 sola sesión**

## Estrategia general
Maximizar el trabajo previo en Mac (ficheros JMX, scripts, memoria) para que en el lab solo haya que: configurar VMs, desplegar, ejecutar pruebas y recoger datos.

---

## FASE 0 — Requisitos previos (Mac + verificación)
**Dónde:** Mac
**Cuándo:** Antes de ir al lab

### 0.1 Verificar código de prácticas anteriores
- [ ] Confirmar que tenéis el código completo de P1-ws (ws-frontend + ws-backend) y P2-rpc (rpc-frontend + rpc-backend) de prácticas anteriores
- [ ] Los directorios actuales ws-frontend/backend y rpc-frontend/backend solo contienen stubs (test_views.py y readme.md). **Necesitáis el código que implementasteis en P1 y P2**
- [ ] Si no lo tenéis, recuperarlo del repositorio o de los PCs del lab

### 0.2 Tener listo el fichero data2.csv
- [ ] El CSV Data Set Config del enunciado referencia `/P1-base/visaApp/management/commands/data2.csv`
- [ ] Solo existe `data.csv`. Verificar si `data2.csv` es diferente o si es un alias

---

## FASE 1 — Crear ficheros JMX en Mac
**Dónde:** Mac (JMeter GUI)
**Cuándo:** Antes de ir al lab (puede hacerse ahora mismo)

### 1.1 Instalar/configurar JMeter en Mac
- [ ] El directorio `apache-jmeter-5.6.3/` ya está descargado
- [ ] Verificar que Java está instalado: `java -version`
- [ ] Lanzar JMeter GUI: `./apache-jmeter-5.6.3/bin/jmeter.sh`

### 1.2 Crear P3_P1-base.jmx (Ejercicio 1)
Estructura del plan de pruebas:

```
Test Plan
├── User Defined Variables (globales): sample=1, debug=false
├── Test Fragment "Common Logic"
│   ├── Counter (nombre: contador, start=1, incr=1, ref=contador)
│   ├── CSV Data Set Config (fichero data2.csv, delimitador=,)
│   ├── HTTP Request "GET Tarjeta Form" (GET, ${host}:${port}, path=${entrypoint}/tarjeta/)
│   │   └── Regular Expression Extractor (csrf_token)
│   ├── Gaussian Random Timer (offset=3000, σ=500)
│   ├── HTTP Request "POST Tarjeta" (POST, misma ruta, params: numero, nombre, etc.)
│   │   └── HTTP Header Manager (X-CSRFToken = ${csrf_token})
│   ├── Gaussian Random Timer
│   └── HTTP Request "POST Pago" (POST, path=${entrypoint}/pago/, params: idComercio, idTransaccion, importe)
│       ├── HTTP Header Manager (X-CSRFToken = ${csrf_token})
│       └── Response Assertion ("Pago Registrado")
├── Thread Group "P1-base"
│   ├── User Defined Variables (locales): entrypoint=visaApp, port=18000, host=localhost
│   ├── Module Controller → Common Logic
│   ├── Aggregate Report
│   └── View Results Tree
├── HTTP Cookie Manager
└── User Defined Variables (globales adicionales si hace falta)
```

Configuración Thread Group P1-base:
- Number of Threads: `${__P(users,10)}`
- Ramp-Up: 2 segundos
- Loop Count: `${sample}`

### 1.3 Crear P3-projects.jmx (Ejercicio 2)
Duplicar el plan anterior y añadir 2 Thread Groups más:

```
Test Plan
├── (todo lo de arriba)
├── Thread Group "P1-base" (entrypoint=visaApp, port=18000, host=vm2)
├── Thread Group "P1-ws" (entrypoint=visaAppWSFrontend, port=18003, host=vm3)
└── Thread Group "P2-rcp" (entrypoint=visaAppRPCFrontend, port=18005, host=vm3)
```

Nota: los puertos y hosts exactos dependen de vuestra configuración de VMs.

### 1.4 Verificar los JMX
- [ ] Abrir ambos ficheros en JMeter GUI y revisar que la estructura es correcta
- [ ] No se pueden ejecutar todavía (no hay servidor), pero la estructura debe ser válida

---

## FASE 2 — Preparar scripts de automatización (Mac)
**Dónde:** Mac
**Cuándo:** Antes de ir al lab

### 2.1 Script para curvas de productividad (Ej5, Ej6, Ej7)
Crear un script bash que automatice la ejecución de JMeter con distintos números de usuarios:

```bash
#!/bin/bash
# run_productivity_curve.sh
# Uso: ./run_productivity_curve.sh <fichero.jmx> <nombre_proyecto>
JMX=$1
PROJECT=$2
for users in 1 2 3 5 7 10 15 20 25 30; do
    echo "=== Ejecutando con $users usuarios ==="
    rm -rf output_${PROJECT}_${users}
    ./apache-jmeter-5.6.3/bin/jmeter.sh -n -t $JMX \
        -Jusers=$users -l results_${PROJECT}_${users}.jtl \
        -Jsummariser.name=summary \
        -e -o output_${PROJECT}_${users}
    sleep 5
done
```

### 2.2 Script para extraer throughput de los resultados
Crear un script Python que lea los resultados y genere la tabla/gráfica de throughput vs usuarios.

### 2.3 Script para Ejercicio 3 (1000 threads)
Preparar el comando específico con 1000 threads y ramp-up=1s.

---

## FASE 3 — Preparar la memoria (Mac)
**Dónde:** Mac
**Cuándo:** Antes y después del lab

### 3.1 Redactar secciones que NO necesitan datos experimentales
- [ ] Ejercicio 1: Explicación de cada columna del Aggregate Report (teórica)
- [ ] Cuestión 1: Diferencias Thread Group P1-base vs P1-ws (los entrypoints, hosts y puertos son distintos)
- [ ] Cuestión 2: ¿Dónde cambiar SESSION_ENGINE en ws? → Respuesta: en el settings.py del **backend**, porque es donde se almacenan las sesiones (el frontend es solo cliente)
- [ ] Ejercicio 4: Argumentar teóricamente (el segundo loop comienza tras **atender** las peticiones del primero, opción b)

### 3.2 Dejar huecos para datos experimentales
- [ ] Ejercicio 1: hueco para captura de Aggregate Report
- [ ] Ejercicio 3: hueco para capturas de nmon y análisis
- [ ] Ejercicio 5: hueco para gráficas de curva de productividad × 3 proyectos
- [ ] Ejercicio 6: hueco para gráfica gunicorn vs runserver
- [ ] Ejercicio 7: hueco para gráfica con 2 workers + 2 CPUs

---

## FASE 4 — Sesión de laboratorio (PCs del Lab)
**Dónde:** PCs del laboratorio
**Cuándo:** La única sesión disponible
**CRÍTICO: Esta es la fase más importante. Hay que ir con todo preparado.**

### 4.1 Setup del entorno (~30 min)
- [ ] Copiar todo el proyecto al PC del lab (USB o repositorio)
- [ ] Configurar VMs en VirtualBox:
  - vm1: base de datos PostgreSQL
  - vm2: servidor Django (P1-base con gunicorn)
  - vm3: frontend para ws y rpc
- [ ] Desplegar P1-base en vm2:
  - Instalar dependencias (pip install -r requirements.txt)
  - Configurar .env con DATABASE_SERVER_URL apuntando a vm1
  - Ejecutar migraciones y populate
  - Lanzar gunicorn: `gunicorn visaSite.wsgi:application --bind 0.0.0.0:8000`
- [ ] Desplegar ws-backend en vm2, ws-frontend en vm3
- [ ] Desplegar rpc-backend en vm2, rpc-frontend en vm3
- [ ] Verificar que todo funciona accediendo desde navegador del host

### 4.2 Instalar JMeter en el host del lab
- [ ] Copiar apache-jmeter-5.6.3 al PC
- [ ] Verificar Java y ejecutar una prueba rápida con 1 usuario

### 4.3 Ejercicio 1 — Prueba básica P1-base (~10 min)
- [ ] Ejecutar P3_P1-base.jmx con 10 threads, sample=10
- [ ] Captura de pantalla del Aggregate Report
- [ ] Verificar que Response Assertion pasa (0% error)

### 4.4 Ejercicio 3 — Test de estrés 1000 threads (~15 min)
- [ ] Configurar nmon en vm1, vm2 (y vm3 si aplica)
- [ ] Ejecutar con 1000 threads, Ramp-Up=1s
- [ ] Capturar: salida de JMeter + nmon (CPU, memoria, disco, red)
- [ ] Analizar qué hipótesis se cumple (a, b, o c)

### 4.5 Ejercicio 4 — Segundo loop (~10 min)
- [ ] Ejecutar con pocos threads (2-3) y Loop Count=2
- [ ] Observar en View Results Tree cuándo empieza el segundo loop
- [ ] Capturar evidencia

### 4.6 Ejercicio 5 — Curvas de productividad ×3 (~30 min)
- [ ] Ejecutar script `run_productivity_curve.sh` para P1-base
- [ ] Repetir para P1-ws (habilitar solo ese Thread Group)
- [ ] Repetir para P2-rcp
- [ ] Recoger todos los ficheros de resultados (output_*/statistics.json)

### 4.7 Ejercicio 6 — Gunicorn vs Runserver (~15 min)
- [ ] Parar gunicorn en vm2
- [ ] Lanzar: `python manage.py runserver 0.0.0.0:8000`
- [ ] Ejecutar curva de productividad para runserver
- [ ] Recoger resultados

### 4.8 Ejercicio 7 — 2 workers + 2 CPUs (~20 min)
- [ ] En VirtualBox: asignar 2 CPUs a vm2
- [ ] Editar settings.py: `SESSION_ENGINE = "django.contrib.sessions.backends.db"`
- [ ] Lanzar gunicorn con 2 workers: `gunicorn visaSite.wsgi:application --bind 0.0.0.0:8000 --workers 2`
- [ ] Ejecutar curva de productividad
- [ ] Recoger resultados

### 4.9 Recoger todo (~5 min)
- [ ] Copiar TODOS los resultados al USB/repo
- [ ] Copiar capturas de nmon
- [ ] Copiar los .jmx finales
- [ ] Copiar el código fuente de los 3 proyectos

---

## FASE 5 — Completar memoria y empaquetar (Mac)
**Dónde:** Mac
**Cuándo:** Después de la sesión de lab

### 5.1 Procesar resultados
- [ ] Extraer throughput de cada ejecución
- [ ] Generar gráficas de curvas de productividad
- [ ] Insertar capturas de pantalla en la memoria

### 5.2 Completar la memoria
- [ ] Rellenar todos los huecos con datos experimentales
- [ ] Ej1: Captura Aggregate Report + explicación columnas
- [ ] Ej3: Análisis con capturas de nmon
- [ ] Ej4: Evidencia experimental + argumentación
- [ ] Ej5: 3 gráficas + tabla + comparativa
- [ ] Ej6: Gráfica comparativa + análisis
- [ ] Ej7: Gráfica + análisis del impacto de 2 workers/CPUs/SESSION_ENGINE
- [ ] Cuestión 1 y 2: ya pre-redactadas

### 5.3 Generar entregable
- [ ] Exportar memoria a PDF: `memoria.pdf`
- [ ] Verificar ficheros: P3_P1-base.jmx, P3-projects.jmx
- [ ] Empaquetar todo en ZIP con:
  - memoria.pdf
  - P3_P1-base.jmx
  - P3-projects.jmx
  - Código fuente de P1-base, P1-ws-frontend/backend, P2-rcp-frontend/backend

---

## Resumen de tiempos estimados en el lab

| Tarea | Tiempo |
|-------|--------|
| Setup VMs + deploy | 30 min |
| Ej1 (prueba básica) | 10 min |
| Ej3 (1000 threads) | 15 min |
| Ej4 (segundo loop) | 10 min |
| Ej5 (3 curvas) | 30 min |
| Ej6 (runserver) | 15 min |
| Ej7 (2 workers) | 20 min |
| Recoger datos | 5 min |
| **TOTAL** | **~2h 15min** |

## Riesgos principales
1. **VMs desde cero = mucho tiempo de setup.** Consejo: id al lab antes de la sesión para preparar las VMs si es posible.
2. **Código de ws/rpc incompleto.** Si no tenéis el código de P1 y P2, los ejercicios 2 y 5 (para ws y rpc) no se podrán hacer.
3. **Falta de tiempo.** Prioridad: Ej1 + una curva de productividad = aprobado (5). Luego ir añadiendo ejercicios por valor de puntos.

## Orden de prioridad (si falta tiempo)
1. **Ej1** (aprobado) — Plan de pruebas P1-base funcional
2. **Ej5 solo para P1-base** (parte del aprobado) — Curva de productividad
3. **Ej2** (0.5) — Generalizar plan
4. **Ej6** (0.5) — Gunicorn vs runserver
5. **Ej7** (1.0) — 2 workers + 2 CPUs
6. **Ej3** (0.5) — 1000 threads
7. **Ej4** (0.5) — Segundo loop
8. **C1 + C2** (1.0) — Se pueden responder teóricamente
