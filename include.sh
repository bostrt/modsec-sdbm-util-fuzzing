#!/bin/bash
PROJECT=$(dirname $0)
red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
cyn=$'\e[1;36m'
end=$'\e[0m'
numre='^[0-9]+$'
numrangere='^[0-9]+\-[0-9]+$'

error() {
  echo -e "${red}$*${end}"
}

warn() {
  echo -e "${yel}$*${end}"
}

info() {
  echo -e ${cyn}$*${end}
}

success() {
  echo -e "${grn}$*${end}"
}
