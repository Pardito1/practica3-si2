# Uses rabbitMQ as the server

import os
import sys
import django
import pika

BASE_DIR = os.path.dirname(
    os.path.dirname(os.path.abspath(__file__)))
sys.path.append(BASE_DIR)

os.environ.setdefault('DJANGO_SETTINGS_MODULE',
                      'visaSite.settings')
django.setup()

from visaAppRPCBackend.models import Tarjeta, Pago


def main():

    if len(sys.argv) != 3:
        print("Debe indicar el host y el puerto")
        exit()

    hostname = sys.argv[1]
    port = sys.argv[2]

    # 1. Crear conexion con RabbitMQ
    credentials = pika.PlainCredentials('alumnomq', 'alumnomq')
    parameters = pika.ConnectionParameters(
        host=hostname,
        port=int(port),
        credentials=credentials
    )
    connection = pika.BlockingConnection(parameters)
    channel = connection.channel()

    # 2. Declarar la cola de mensajes
    channel.queue_declare(queue='pago_cancelacion')

    # 3. Definir la funcion de callback
    def callback(ch, method, properties, body):
        id_pago = body.decode()
        print(f"[x] Recibido mensaje: cancelar pago con ID={id_pago}")
        try:
            pago = Pago.objects.get(id=int(id_pago))
            pago.codigoRespuesta = '111'
            pago.save(update_fields=['codigoRespuesta'])
            print(f"[+] Pago {id_pago} cancelado correctamente "
                  f"(codigoRespuesta='111')")
        except Pago.DoesNotExist:
            print(f"[-] Error: Pago con ID={id_pago} no encontrado")
        except Exception as e:
            print(f"[-] Error al cancelar pago {id_pago}: {e}")

    # 4. Registrar callback y comenzar a consumir
    channel.basic_consume(
        queue='pago_cancelacion',
        on_message_callback=callback,
        auto_ack=True
    )

    print('[*] Esperando mensajes de cancelacion. '
          'Pulsa CTRL+C para salir.')
    channel.start_consuming()


if __name__ == '__main__':
    main()
