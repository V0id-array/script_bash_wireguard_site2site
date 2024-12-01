# Configuración de WireGuard para conexión Site-to-Site en Debian

Este script bash automatiza la configuración de una conexión WireGuard site-to-site en sistemas Debian. 

## Requisitos previos

- Sistema operativo Debian
- Acceso de superusuario (sudo)
- Uso capacidad de redireccionar puertos en el router.
## Preparación

1. Guarde el script con un nombre descriptivo, por ejemplo `configurar_wireguard_s2s.sh`.
2. Otorgue permisos de ejecución al script:

```bash
chmod +x configurar_wireguard_s2s.sh
```

## Ejecución

1. Abra una terminal y navegue hasta el directorio donde guardó el script.
2. Ejecute el script con privilegios de superusuario:

```bash
sudo ./configurar_wireguard_s2s.sh
```

## Pasos de configuración

El script realizará las siguientes acciones:

1. **Instalación de wireguard-tools**: Verificará e instalará el paquete si es necesario.

2. **Habilitación de IPv4 forwarding**: Configurará el sistema para permitir el reenvío de paquetes IPv4.

3. **Configuración de rangos IP**: 
   - Ingrese los rangos de IP a redirigir, separados por comas (ejemplo: 192.168.1.0/24,10.0.0.0/16).
   - El script validará los rangos ingresados.

4. **Generación de claves WireGuard**:
   - Se generarán claves privada y pública.
   - La clave pública se mostrará en pantalla. Guárdela para compartirla con el otro servidor.

**Llegado a este punto es necesario que ejecute el script en el otro servidor o tenga anotada la clave publica para poder continuar.**

5. **Configuración del peer**:
   - Introduzca la clave pública del otro servidor cuando se le solicite.
   - Proporcione el Endpoint del otro servidor en formato IP:Puerto (ejemplo: 203.0.113.1:51820).

6. **Configuración de la interfaz WireGuard**:
   - Ingrese la dirección IP para la interfaz WireGuard en formato IP/máscara (ejemplo: 10.0.10.1/32).

7. **Creación del archivo de configuración**:
   - El script generará el archivo `/etc/wireguard/wg0.conf` con la configuración necesaria.

## Finalización

Una vez completada la configuración:

- Para iniciar la VPN, ejecute:
  ```bash
  sudo wg-quick up wg0
  ```
- Para detener la VPN, use:
  ```bash
  sudo wg-quick down wg0
  ```

## Notas adicionales

- Asegúrese de configurar correctamente el firewall y las reglas de enrutamiento en ambos sitios para permitir el tráfico VPN.
- El script está diseñado para sistemas Debian, pero puede funcionar en otras distribuciones basadas en Debian como Ubuntu.
- Revise y ajuste la configuración en `/etc/wireguard/wg0.conf` si es necesario para su entorno específico.
