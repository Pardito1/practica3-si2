import requests
from django.conf import settings

BASE_URL = settings.RESTAPIBASEURL


def verificar_tarjeta(tarjeta_data):
    """Check if the tarjeta is registered via REST API"""
    try:
        response = requests.post(f"{BASE_URL}tarjeta/", json=tarjeta_data)
        return response.status_code == 200
    except Exception as e:
        print("Error verificando tarjeta:", e)
        return False


def registrar_pago(pago_dict):
    """Register a payment via REST API"""
    try:
        response = requests.post(f"{BASE_URL}pago/", json=pago_dict)
        if response.status_code == 200:
            return response.json()
        return None
    except Exception as e:
        print("Error registrando pago:", e)
        return None


def eliminar_pago(idPago):
    """Delete a pago via REST API"""
    try:
        response = requests.delete(f"{BASE_URL}pago/{idPago}")
        return response.status_code == 200
    except Exception as e:
        print("Error eliminando pago:", e)
        return False


def get_pagos_from_db(idComercio):
    """Get pagos from REST API"""
    try:
        response = requests.get(f"{BASE_URL}comercio/{idComercio}")
        if response.status_code == 200:
            return response.json()
        return []
    except Exception as e:
        print("Error obteniendo pagos:", e)
        return []
