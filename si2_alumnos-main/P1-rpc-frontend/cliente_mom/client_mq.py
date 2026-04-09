import pika
import sys


def cancelar_pago(hostname, port, id_pago):
    """Envia un mensaje a la cola de RabbitMQ para cancelar un pago.
    :param hostname: IP/hostname del servidor RabbitMQ
    :param port: puerto del servidor RabbitMQ
    :param id_pago: ID del pago a cancelar
    """
    try:
        # 1. Crear conexion con RabbitMQ
        credentials = pika.PlainCredentials('alumnomq', 'alumnomq')
        parameters = pika.ConnectionParameters(
            host=hostname,
            port=int(port),
            credentials=credentials
        )
        connection = pika.BlockingConnection(parameters)
    except Exception as e:
        print(f"Error al conectar al host remoto: {e}")
        exit()

    channel = connection.channel()

    # 2. Declarar la cola (si no existe, se crea)
    channel.queue_declare(queue='pago_cancelacion')

    # 3. Publicar el mensaje con el ID del pago
    channel.basic_publish(
        exchange='',
        routing_key='pago_cancelacion',
        body=str(id_pago)
    )

    print(f"[x] Enviado mensaje: cancelar pago con ID={id_pago}")

    # 4. Cerrar la conexion
    connection.close()


def main():

    if len(sys.argv) != 4:
        print("Debe indicar el host, el numero de puerto, "
              "y el ID del pago a cancelar como un argumento.")
        exit()

    cancelar_pago(sys.argv[1], sys.argv[2], sys.argv[3])


if __name__ == "__main__":
    main()
