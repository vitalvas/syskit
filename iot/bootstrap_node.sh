#!/bin/bash

set -eu

export DEBIAN_FRONTEND=noninteractive

function change_hostname() {
  MAC=''
  HWDEV='unkn'

  if [ -f "/sys/class/net/eth0/address" ]; then
    MAC=$(cat /sys/class/net/eth0/address)
  elif [ -f "/sys/class/net/wlan0/address" ]; then
    MAC=$(cat /sys/class/net/wlan0/address)
  else
    if grep -q enx /proc/net/dev ; then
      MAC=$(cat /sys/class/net/$(ls /sys/class/net/ | grep enx | head -1)/address)
    fi
  fi

  if [ -z "${MAC}" ]; then
    echo 'No MAC Address'
    exit 1
  fi

  if grep -q 'Raspberry Pi 3 Model B' /proc/cpuinfo ; then
    HWDEV='rpi3b'
  elif grep -q 'Raspberry Pi 4 Model B' /proc/cpuinfo ; then
    HWDEV='rpi4b'
  elif grep -q 'Raspberry Pi Zero 2' /proc/cpuinfo ; then
    HWDEV='rpiz2'
  elif grep -q 'Raspberry Pi Zero' /proc/cpuinfo ; then
    HWDEV='rpiz'
  elif grep -q 'ODROID-XU4' /proc/cpuinfo ; then
    HWDEV='odroidxu4'
  fi

  HOST="dev-${HWDEV}-$(echo ${MAC} | tr -d ':')"

  echo "MAC address: ${MAC}"
  echo "Hostname: ${HOST}"

  OLD_HOST=$(awk '$1=="127.0.1.1" {print $NF}' /etc/hosts)
  if [ ! -z "${OLD_HOST}" ]; then
    sed -i "s/${OLD_HOST}/${HOST}/" /etc/hosts
  else
    echo -e "127.0.1.1\t${HOST}" >> /etc/hosts
  fi

  hostnamectl set-hostname ${HOST}
}

function manage_pkgs() {
  apt update -qy
  if [ ! -z "$(apt list --upgradable)" ]; then
    apt upgrade -qy
  fi

  apt purge -qy netplan.io ubuntu-release-upgrader-core || true

  if [ "$(hostname)" == "raspberrypi" ]; then
    apt purge -qy lightdm pulseaudio cups-daemon avahi-daemon chromium-browser gvfs mailcap man-db vlc dbus-x11 lightdm-gtk-greeter \
      gnome-desktop3-data gnome-keyring gnome-session-bin gnome-accessibility-themes gnome-icon-theme gnome-menus gnome-session-common \
      gsettings-desktop-schemas desktop-base lxde-common lxde-icon-theme cifs-utils xserver-common xserver-xorg xserver-xorg-core x11-xserver-utils \
      desktop-file-utils gstreamer* gtk-update-icon-cache gtk2-engines hicolor-icon-theme lxhotkey-core lxmenu-data lxsession-data xdg-utils \
      mesa-va-drivers mesa-vdpau-drivers x11-common libgl1-mesa-dri libglapi-mesa libgles2-mesa javascript-common nfs-common manpages manpages-dev \
      python3-webencodings python3-touchphat python3-requests python3-lxml python3-buttonshim python3-scrollphat python3-scrollphathd python3-pianohat \
      python3-phatbeat python3-pantilthat python3-microdotphat python3-fourletterphat python3-flask python3-envirophat python3-drumhat python3-sn3218 \
      python3-automationhat python3-blinkt python3-explorerhat python3-gpiozero python3-motephat python3-skywriter python3-cap1xxx python3-gi \
      python3-picamera python3-pigpio python3-rainbowhat python3-serial python3-unicornhathd python3-rpi.gpio python3-cupshelpers build-essential \
      laptop-detect libx11-data wamerican wbritish vcdbg crda libgtk-3-common libgtk2.0-common xkb-data
  fi

  if [ -z "$(ls /sys/class/net/wlan*/address)"]; then
    apt purge -qy wpasupplicant wireless-tools wireless-regdb modemmanager
  fi

  apt install --no-install-recommends -qy vim apt-transport-https git
  apt autoremove -qy
}

case "$(uname -m)" in
  "armv6l" | "armv7l")
    manage_pkgs
    change_hostname
    ;;
  *)
    echo "Unsupported hardware"
    exit 1
    ;;
esac
