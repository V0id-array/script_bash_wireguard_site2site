#!/bin/bash

# Función para validar direcciones IP y rangos
validar_ip() {
    local ip=$1
    if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?$ ]]; then
        IFS='.' read -r -a octetos <<< "${ip%/*}"
        [[ ${octetos[0]} -le 255 && ${octetos[1]} -le 255 && ${octetos[2]} -le 255 && ${octetos[3]} -le 255 ]]
        return $?
    fi
    return 1
}

# Función para validar el formato IP:Puerto
validar_endpoint() {
    local endpoint=$1
    local ip_part
    local port_part
    
    IFS=':' read -r ip_part port_part <<< "$endpoint"
    
    if validar_ip "$ip_part" && [[ $port_part =~ ^[0-9]+$ ]] && [ "$port_part" -ge 1 ] && [ "$port_part" -le 65535 ]; then
        return 0
    else
        return 1
    fi
}

# 1. Revisar/instalar wireguard-tools
echo "Comprobando la instalación de wireguard-tools..."
if ! command -v wg &> /dev/null; then
    echo "wireguard-tools no está instalado. Instalando..."
    sudo apt update && sudo apt install -y wireguard-tools
else
    echo "wireguard-tools ya está instalado."
fi

# 2. Habilitar IPv4 forwarding
echo "Habilitando IPv4 forwarding..."
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# 3. Preguntar por los rangos de IP a redirigir
echo "Introduce los rangos de IP a redirigir (separados por comas):"
read -r ip_ranges

IFS=',' read -ra ADDR <<< "$ip_ranges"
valid_ranges=()
for i in "${ADDR[@]}"; do
    if validar_ip "$(echo "$i" | tr -d '[:space:]')"; then
        valid_ranges+=("$(echo "$i" | tr -d '[:space:]')")
    else
        echo "Rango inválido: $i"
    fi
done

if [ ${#valid_ranges[@]} -eq 0 ]; then
    echo "No se proporcionaron rangos válidos. Saliendo."
    exit 1
fi

echo "Rangos válidos: ${valid_ranges[*]}"

# 4. Generar claves
echo "Generando claves WireGuard..."
private_key=$(wg genkey)
public_key=$(echo "$private_key" | wg pubkey)

echo "Clave privada: $private_key" > wg_keys.txt
echo "Clave pública: $public_key" >> wg_keys.txt

echo "Tu clave pública es: $public_key"
echo "Guarda esta clave y compártela con el otro servidor."

# 5. Pedir la clave pública del otro servidor
echo "Introduce la clave pública del otro servidor:"
read -r peer_public_key

# 6. Pedir el Endpoint del otro servidor
while true; do
    echo "Introduce el Endpoint del otro servidor (formato IP:Puerto):"
    read -r peer_endpoint
    if validar_endpoint "$peer_endpoint"; then
        break
    else
        echo "Formato inválido. Por favor, usa el formato IP:Puerto (ejemplo: 203.0.113.1:51820)"
    fi
done

# 7. Pedir la dirección IP para la interfaz WireGuard
while true; do
    echo "Introduce la dirección IP para la interfaz WireGuard (formato IP/máscara, ejemplo: 10.0.10.1/32):"
    read -r interface_address
    if validar_ip "$interface_address"; then
        break
    else
        echo "Formato inválido. Por favor, usa el formato IP/máscara (ejemplo: 10.0.10.1/32)"
    fi
done

# 8. Generar archivo de configuración de wg0
echo "Generando archivo de configuración wg0.conf..."

cat << EOF | sudo tee /etc/wireguard/wg0.conf
[Interface]
PrivateKey = $private_key
Address = $interface_address
ListenPort = 51820
DNS = 1.1.1.1
PostUp = iptables -A FORWARD -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = $peer_public_key
AllowedIPs = ${valid_ranges[*]}
Endpoint = $peer_endpoint
PersistentKeepalive = 25
EOF

echo "Configuración completada. El archivo wg0.conf ha sido creado en /etc/wireguard/wg0.conf"
echo "Para iniciar la VPN, ejecuta: sudo wg-quick up wg0"
echo "Para detener la VPN, ejecuta: sudo wg-quick down wg0"