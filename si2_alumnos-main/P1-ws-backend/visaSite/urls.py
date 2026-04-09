from django.urls import path, include

urlpatterns = [
    path('restapiserver/', include('visaAppWSBackend.urls')),
]
