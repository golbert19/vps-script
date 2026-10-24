# 🦅 Golbert VPS - Panel Multiprotocolo V4.5 LTS

> [**Acerca de**](#Acerca-de) | [**Instalación**](#Instalación) | [**Características**](#Características) | [**Puertos y Protocolos**](#Puertos-y-Protocolos) | [**Soporte**](#Soporte)

---

## 📌 Acerca de
**Golbert VPS** es un script de administración avanzado y automatizado diseñado para simplificar la configuración de servidores VPS basados en Linux (Ubuntu y Debian). Está optimizado para la gestión de túneles VPN, proxys, conexiones cifradas y control de usuarios mediante licencias de **Key de único uso**.

Este sistema integra un panel de control interactivo en tiempo real y está perfectamente adaptado para proveedores de VPN que buscan estabilidad, seguridad y facilidad de administración tanto local como remota a través de Telegram.

---

## ⚙️ Requisitos del Sistema

### Sistemas Operativos Soportados
| Sistema Operativo | Versión | Estado |
|-------------------|---------|--------|
| **Ubuntu** | 20.04 LTS / 22.04 LTS / 24.04 LTS | <span style="color:white;background:#5cb85c;padding:2px 6px;border-radius:4px">Estable</span> |
| **Debian** | 11 (Bullseye) / 12 (Bookworm) | <span style="color:white;background:#5cb85c;padding:2px 6px;border-radius:4px">Estable</span> |

---

## 🚀 Instalación

La instalación requiere una **Key de único uso** generada previamente desde el bot de administración de Telegram **[@vpnperu01_bot](https://t.me/vpnperu01_bot)**.

Ejecute el siguiente comando en su VPS limpia como usuario `root`:

```shell
apt update -y && apt install -y wget && wget -O install.sh [https://raw.githubusercontent.com/golbert19/vps-script/main/install.sh](https://raw.githubusercontent.com/golbert19/vps-script/main/install.sh) && chmod +x install.sh && ./install.sh
