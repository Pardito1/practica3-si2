from django.urls import path
from visaAppWSBackend.views import TarjetaView, PagoView, ComercioView

urlpatterns = [
    path('tarjeta/', TarjetaView.as_view(), name='tarjeta'),
    path('pago/', PagoView.as_view(), name='pago'),
    path('comercio/<str:idComercio>', ComercioView.as_view(), name='comercio'),
    path('pago/<str:id_pago>', PagoView.as_view(), name='pago'),
]
