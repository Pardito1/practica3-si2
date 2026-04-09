"Interface with the RPC backend"
from django.conf import settings
from xmlrpc.client import ServerProxy


def verificar_tarjeta(tarjeta_data):
    """Verifica si una tarjeta esta registrada en la BD remota.
    :param tarjeta_data: diccionario con los datos de la tarjeta
                         (numero, nombre, fechaCaducidad, codigoAutorizacion)
    :return: True si la tarjeta existe, False en caso contrario
    """
    with ServerProxy(settings.RPCAPIBASEURL) as proxy:
        return proxy.verificar_tarjeta(tarjeta_data)


def registrar_pago(pago_dict):
    """Registra un pago invocando el procedimiento remoto del backend.
    :param pago_dict: diccionario con datos del pago
                      (idComercio, idTransaccion, importe, tarjeta_id)
    :return: diccionario con los datos del pago registrado
             (id, idComercio, idTransaccion, importe, marcaTiempo,
              codigoRespuesta, tarjeta). None si hubo error.
    """
    with ServerProxy(settings.RPCAPIBASEURL) as proxy:
        return proxy.registrar_pago(pago_dict)


def eliminar_pago(idPago):
    """Elimina un pago invocando el procedimiento remoto del backend.
    :param idPago: ID (entero) del pago a eliminar
    :return: True si se elimino correctamente, False si no existe
    """
    with ServerProxy(settings.RPCAPIBASEURL) as proxy:
        return proxy.eliminar_pago(idPago)


def get_pagos_from_db(idComercio):
    """Obtiene los pagos de un comercio invocando el procedimiento remoto.
    :param idComercio: ID del comercio a consultar
    :return: lista de diccionarios con los datos de cada pago
             (id, idComercio, idTransaccion, importe, marcaTiempo,
              codigoRespuesta, tarjeta)
    """
    with ServerProxy(settings.RPCAPIBASEURL) as proxy:
        return proxy.get_pagos_from_db(idComercio)