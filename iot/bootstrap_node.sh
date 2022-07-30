#!/bin/bash

set -eu

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

  apt purge -qy netplan.io nano ubuntu-release-upgrader-core

  if [ -z "$(ls /sys/class/net/wlan*/address)"]; then
    apt purge -qy wpasupplicant wireless-tools wireless-regdb modemmanager
  fi

  apt install --no-install-recommends -qy vim apt-transport-https git
  apt autoremove -qy
  apt clean -qy
  apt autoclean -qy
}

case "$(uname -m)" in
  "armv6l" | "armv7l")
    change_hostname
    ;;
  *)
    echo "Unsupported hardware"
    exit 1
    ;;
esac

