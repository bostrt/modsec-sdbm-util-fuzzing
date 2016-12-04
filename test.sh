#!/bin/bash
PROJECT=$(dirname $0)
red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
cyn=$'\e[1;36m'
end=$'\e[0m'

if ! which zzuf &>/dev/null; then
  echo "${red}Please install zzuf or make sure it exists on PATH.${end}"
  exit 1
fi

if [[ ! -e "$PROJECT/modsec-sdbm-util/modsec-sdbm-util" ]]; then
  echo -e "${yel}Building modsec-sdbm-util${end}"
  pushd . &> /dev/null
  cd $PROJECT/modsec-sdbm-util
  ./autogen.sh &> /dev/null
  ./configure &> /dev/null
  make &> /dev/null
  popd &> /dev/null
  if [[ ! -e "$PROJECT/modsec-sdbm-util/modsec-sdbm-util" ]]; then
    echo -e "${red}Error while building modsec-sdbm-util. Please investigate why build could not complete.${end}"
    exit 1
  fi
  echo -e "${grn}Modsec-sdbm-util build complete, proceeding with test.${end}\n"
fi

echo -e "${cyn}Starting.${end}"
if [[ ! -e "$PROJECT/data/data.pag" ]] || [[ ! -e "$PROJECT/data/data.dir" ]]; then
  echo -e "${red}Starter data is required. Please create database in $PROJECT/data/data.{pag,dir}${end}"
  exit 1
fi

mkdir -p $PROJECT/data
mkdir -p $PROJECT/testdata
mkdir -p $PROJECT/results

echo -e "${cyn}Cleaning up an old data.${end}"
rm -f $PROJECT/testdata/*
rm -f $PROJECT/results/*

echo -e "${cyn}Creating test data.${end}"
for i in {1000..1500}; do zzuf -r 0.01 -s $i < $PROJECT/data/data.pag > $PROJECT/testdata/data$i.pag; cp $PROJECT/data/data.dir $PROJECT/testdata/data$i.dir; done

echo -e "${grn}Executing project against test data.${end}"
for f in $PROJECT/testdata/*.pag; do echo "Testing $f"; timeout 3 $PROJECT/modsec-sdbm-util/modsec-sdbm-util -du $f; echo -e '\n'; done &>> $PROJECT/results/fuzzing.log

echo -e "${grn}Done${end}"
