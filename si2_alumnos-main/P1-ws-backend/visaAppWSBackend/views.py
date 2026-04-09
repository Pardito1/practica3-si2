from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.forms.models import model_to_dict

from visaAppWSBackend.pagoDB import (verificar_tarjeta, registrar_pago,
                                      eliminar_pago, get_pagos_from_db)
from .serializers import PagoSerializer

TARJETA_FIELDS = ['numero', 'nombre', 'fechaCaducidad', 'codigoAutorizacion']


class TarjetaView(APIView):
    """POST: Verifica si una tarjeta existe en la BD"""
    def post(self, request):
        tarjeta_data = {k: v for k, v in request.data.items()
                        if k in TARJETA_FIELDS}
        if verificar_tarjeta(tarjeta_data):
            return Response(
                {'message': 'Datos encontrados en la base de datos'},
                status=status.HTTP_200_OK)
        return Response(
            {'message': 'Datos no encontrados en la base de datos'},
            status=status.HTTP_404_NOT_FOUND)


class PagoView(APIView):
    """POST: Registra un pago / DELETE: Elimina un pago por ID"""
    def post(self, request):
        pago_dict = {k: v for k, v in request.data.items()
                     if k != '_content'}
        pago = registrar_pago(pago_dict)
        if pago is None:
            return Response(
                {'message': 'Error al registrar pago.'},
                status=status.HTTP_404_NOT_FOUND)
        pago_dict = model_to_dict(pago)
        return Response(pago_dict, status=status.HTTP_200_OK)

    def delete(self, request, id_pago):
        if eliminar_pago(id_pago):
            return Response(
                {'message': 'Pago eliminado correctamente.'},
                status=status.HTTP_200_OK)
        return Response(
            {'message': 'Pago no encontrado.'},
            status=status.HTTP_404_NOT_FOUND)


class ComercioView(APIView):
    """GET: Lista los pagos de un comercio dado"""
    def get(self, request, idComercio):
        pagos = get_pagos_from_db(idComercio)
        if pagos.exists():
            serializer = PagoSerializer(pagos, many=True)
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(
            {'message': 'No se encontraron pagos para este comercio.'},
            status=status.HTTP_404_NOT_FOUND)
