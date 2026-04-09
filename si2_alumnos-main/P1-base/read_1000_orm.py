import os
import sys
import time
import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "visaSite.settings")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
django.setup()

from visaApp.models import Tarjeta

tarjetas = list(Tarjeta.objects.all()[:1000])
numeros = [t.numero for t in tarjetas]

start_time = time.time()

for numero in numeros:
    tarjeta = Tarjeta.objects.get(pk=numero)

end_time = time.time()

print(f"Tiempo: {end_time - start_time:.6f} segundos")
