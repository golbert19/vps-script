# 🦅 Golbert VPS - Panel Multiprotocolo V4.5 LTS

Script avanzado de administración para servidores VPS (Ubuntu / Debian), optimizado para conexiones VPN de alta velocidad, gestión automatizada de clientes y sistema de licencias por **Key de único uso**.

---

## 🚀 Características Principales

* **Panel de Control V4.5 LTS:** Interfaz interactiva de terminal en tiempo real con monitoreo detallado de uso de **CPU, Memoria RAM, Disco, Uptime y estado de servicios**.
* **Sistema de Licencias (One-Time Keys):** Validación de instalación mediante claves de un solo uso conectadas de forma segura a un servidor central (`45.41.207.172`) y gestionadas desde el bot de Telegram **@vpnperu01_bot**.
* **Limitador Multi-Login Automático:** Demonio en segundo plano (`vps-limiter`) que controla las conexiones simultáneas permitidas por usuario y elimina automáticamente cuentas expiradas.
* **Soporte Multitúnel y Protocolos:**
  * **SSH + Proxy HTTP (Custom Payload):** Puertos `80` y `8080` con soporte para respuestas HTTP `200 OK` y WebSockets (`101 Switching Protocols`).
  * **TLS/SSL (Stunnel):** Puerto `443` para conexiones seguras mediante SNI.
  * **DNS (DNSTT / SlowDNS):** Túnel UDP a través del puerto `53` para bypass de operadoras.
  * **V2Ray / Xray:** Protocolo VMess sobre WebSocket en el puerto `8880` con autogeneración de enlaces `vmess://`.
  * **Hysteria UDP:** Alta velocidad y ofuscación en el puerto `36712`.
  * **BadVPN UDPGW:** Optimización de paquetes UDP en el puerto `7300` para juegos online y llamadas VoIP.

---

## 📋 Estructura del Repositorio

```text
vps-script/
├── install.sh       # Instalador principal con validación de Key
├── proxy.py         # Motor Proxy HTTP + Custom Payload (Puertos 80 y 8080)
├── limiter.sh       # Servicio anti multi-login y limpieza automática
└── menu.sh          # Panel de administración visual V4.5 LTS
