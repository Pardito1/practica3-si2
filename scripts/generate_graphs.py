#!/usr/bin/env python3
"""
Genera gráficas de curvas de productividad a partir de los CSV de throughput.
Usa matplotlib. Instalar si no está: pip install matplotlib

Uso:
    python3 scripts/generate_graphs.py

Lee todos los directorios results_* y genera las gráficas.
"""

import os
import csv
import sys

try:
    import matplotlib
    matplotlib.use('Agg')  # Backend sin GUI
    import matplotlib.pyplot as plt
except ImportError:
    print("ERROR: matplotlib no instalado. Ejecuta: pip install matplotlib")
    sys.exit(1)


def read_throughput_csv(filepath):
    """Lee un CSV de throughput y devuelve listas de users y throughput."""
    users = []
    throughput = []
    avg_response = []
    error_pct = []

    with open(filepath, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            users.append(int(row['users']))
            throughput.append(float(row['throughput']))
            avg_response.append(float(row['avg_response']))
            error_pct.append(float(row['error_pct']))

    return users, throughput, avg_response, error_pct


def plot_single_curve(csv_path, output_path, title):
    """Genera gráfica de una sola curva de productividad."""
    users, throughput, _, _ = read_throughput_csv(csv_path)

    fig, ax = plt.subplots(figsize=(10, 6))

    # Curva real
    ax.plot(users, throughput, 'b-o', linewidth=2, markersize=8, label='Throughput (req/s)')

    # Línea ideal (lineal)
    if len(users) > 1 and throughput[0] > 0:
        ideal = [u * throughput[0] for u in users]
        ax.plot(users, ideal, 'g:', linewidth=1, alpha=0.5, label='Lineal (ideal)')

    ax.set_xlabel('Número de usuarios (threads)', fontsize=12)
    ax.set_ylabel('Throughput (req/s)', fontsize=12)
    ax.set_title(title, fontsize=14)
    ax.legend()
    ax.grid(True, alpha=0.3)

    plt.tight_layout()
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    print(f"  Gráfica guardada: {output_path}")


def plot_comparison(csv_paths, labels, output_path, title):
    """Genera gráfica comparativa de varias curvas."""
    fig, ax = plt.subplots(figsize=(10, 6))
    colors = ['b', 'r', 'g', 'orange', 'purple']

    for i, (csv_path, label) in enumerate(zip(csv_paths, labels)):
        if os.path.exists(csv_path):
            users, throughput, _, _ = read_throughput_csv(csv_path)
            color = colors[i % len(colors)]
            ax.plot(users, throughput, f'{color}-o', linewidth=2, markersize=6, label=label)

    ax.set_xlabel('Número de usuarios (threads)', fontsize=12)
    ax.set_ylabel('Throughput (req/s)', fontsize=12)
    ax.set_title(title, fontsize=14)
    ax.legend()
    ax.grid(True, alpha=0.3)

    plt.tight_layout()
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    print(f"  Gráfica guardada: {output_path}")


def main():
    graphs_dir = "graficas"
    os.makedirs(graphs_dir, exist_ok=True)

    print("=== Generando gráficas de productividad ===\n")

    # --- Ejercicio 5: Curvas individuales y comparativa ---
    ej5_csvs = []
    ej5_labels = []
    for project, label in [("p1base_gunicorn", "P1-base"),
                           ("p1ws_gunicorn", "P1-ws"),
                           ("p2rcp_gunicorn", "P2-rcp")]:
        csv_path = f"results_{project}/throughput_summary.csv"
        if os.path.exists(csv_path):
            plot_single_curve(csv_path, f"{graphs_dir}/ej5_{project}.png",
                            f"Curva de productividad - {label}")
            ej5_csvs.append(csv_path)
            ej5_labels.append(label)

    if ej5_csvs:
        plot_comparison(ej5_csvs, ej5_labels,
                       f"{graphs_dir}/ej5_comparativa.png",
                       "Ejercicio 5: Comparativa de productividad")

    # --- Ejercicio 6: gunicorn vs runserver ---
    ej6_csvs = []
    ej6_labels = []
    for config, label in [("p1base_gunicorn", "gunicorn"),
                          ("p1base_runserver", "runserver")]:
        csv_path = f"results_{config}/throughput_summary.csv"
        if os.path.exists(csv_path):
            ej6_csvs.append(csv_path)
            ej6_labels.append(label)

    if ej6_csvs:
        plot_comparison(ej6_csvs, ej6_labels,
                       f"{graphs_dir}/ej6_gunicorn_vs_runserver.png",
                       "Ejercicio 6: gunicorn vs runserver")

    # --- Ejercicio 7: 2 workers + 2 CPUs ---
    ej7_csvs = []
    ej7_labels = []
    for config, label in [("p1base_gunicorn", "1 worker / 1 CPU"),
                          ("p1base_2workers_2cpus", "2 workers / 2 CPUs")]:
        csv_path = f"results_{config}/throughput_summary.csv"
        if os.path.exists(csv_path):
            ej7_csvs.append(csv_path)
            ej7_labels.append(label)

    if ej7_csvs:
        plot_comparison(ej7_csvs, ej7_labels,
                       f"{graphs_dir}/ej7_2workers_2cpus.png",
                       "Ejercicio 7: 2 workers + 2 CPUs + SESSION_ENGINE=db")

    print("\n=== Listo ===")
    if not (ej5_csvs or ej6_csvs or ej7_csvs):
        print("No se encontraron datos. Ejecuta primero run_productivity_curve.sh")


if __name__ == "__main__":
    main()
