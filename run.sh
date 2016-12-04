#!/bin/bash
PROJECT=$(dirname $0)
FUZZINGLOG=$PROJECT/results/fuzzing.log
OPTSTRING=":d:h:s:va:"
DATAFILE="$PROJECT/data/data"
RANGE="100-200"
ACTION="dump"
VERBOSE=0

source $PROJECT/include.sh

printhelp() {
  info "$0 -d data"
}

# Make sure zzuf is installed
if ! which zzuf &>/dev/null; then
  echo "${red}Please install zzuf or make sure it exists on PATH.${end}"
  exit 1
fi

# Parse args
while getopts $OPTSTRING opt; do
  case $opt in
    a)
      ACTION=$OPTARG
      ;;
    d)
      DATAFILE=$(echo $OPTARG | sed 's/\.dir\|\.pag//')
      ;;
    h)
      printhelp
      exit 0
      ;;
    s)
      if ! [[ $OPTARG =~ $numrangere ]]; then
        error "Seed range ($opt) option must be in format: ###-###"
        exit 2
      fi
      RANGE=$OPTARG
      ;;
    v)
      VERBOSE=1
      ;;
    :)
      error "Missing option for -$OPTARG"
      exit 1
      ;;
    *)
      error "Invalid options: -$OPTARG"
      ;;
  esac
done

# Validate action
case $ACTION in
  dump);;
  expired);;
  shrink);;
  extract);;
  status);;
  *)
    error "\"$ACTION\" is not a valid action."
    exit 3;;
esac

if [[ ! -e "$DATAFILE.pag" ]] || [[ ! -e "$DATAFILE.dir" ]]; then
  error "${red}Starter data is required. Please create database in $DATAFILE.{pag,dir}${end}"
  exit 1
fi

if [[ ! -e "$PROJECT/modsec-sdbm-util/modsec-sdbm-util" ]]; then
  warn "${yel}Building modsec-sdbm-util${end}"
  pushd . &> /dev/null
  cd $PROJECT/modsec-sdbm-util
  ./autogen.sh &> /dev/null
  ./configure &> /dev/null
  make &> /dev/null
  popd &> /dev/null
  if [[ ! -e "$PROJECT/modsec-sdbm-util/modsec-sdbm-util" ]]; then
    error "${red}Error while building modsec-sdbm-util. Please investigate why build could not complete.${end}"
    exit 1
  fi
  success "Modsec-sdbm-util build complete, proceeding with test\n"
fi

mkdir -p $PROJECT/testdata
mkdir -p $PROJECT/results

info "Cleaning up any old data"
rm -f $PROJECT/testdata/*
rm -f $PROJECT/results/*

# Extract begin and end locations for seed
BEGIN=$(echo $RANGE | cut -d '-' -f1)
END=$(echo $RANGE | cut -d '-' -f2)

info "${cyn}Running tests...${end}"

mkfuzz() {
  zzuf -r 0.01 -s $1 < $DATAFILE.pag > $PROJECT/testdata/data$1.pag
  cp $DATAFILE.dir $PROJECT/testdata/data$1.dir
}

cleanfuzz() {
  rm -f $PROJECT/testdata/data$1.pag $PROJECT/testdata/data$1.dir
}

# Dump/Unpack action
dump() {
  for i in $(seq $BEGIN $END); do
    mkfuzz $i
    echo "Running dump test iteration $i"
    timeout 3 $PROJECT/modsec-sdbm-util/modsec-sdbm-util -du $PROJECT/testdata/data$i
    echo -e '\n'
    cleanfuzz $i
  done &>> $FUZZINGLOG
}

expired() {
  for i in $(seq $BEGIN $END); do
    mkfuzz $i
    echo "Running expired test iteration $i"
    timeout 3 $PROJECT/modsec-sdbm-util/modsec-sdbm-util -dx $PROJECT/testdata/data$i
    echo -e '\n'
    cleanfuzz $i
  done &>> $FUZZINGLOG
}

shrink() {
  for i in $(seq $BEGIN $END); do
    mkfuzz $i
    echo "Running expired test iteration $i"
    timeout 3 $PROJECT/modsec-sdbm-util/modsec-sdbm-util -k $PROJECT/testdata/data$i
    echo -e '\n'
    cleanfuzz $i
  done &>> $FUZZINGLOG
}

extract() {
  for i in $(seq $BEGIN $END); do
    mkfuzz $i
    echo "Running expired test iteration $i"
    timeout 3 $PROJECT/modsec-sdbm-util/modsec-sdbm-util -n $PROJECT/testdata/data$i -D $PROJECT/testdata/
    echo -e '\n'
    cleanfuzz $i
    rm $PROJECT/testdata/new_db.*
  done &>> $FUZZINGLOG
}

status() {
  for i in $(seq $BEGIN $END); do
    mkfuzz $i
    echo "Running expired test iteration $i"
    timeout 3 $PROJECT/modsec-sdbm-util/modsec-sdbm-util -s $PROJECT/testdata/data$i
    echo -e '\n'
    cleanfuzz $i
  done &>> $FUZZINGLOG
}

# Run the specified action
$ACTION

success "Complete"

# Show how many segfaults we hit
sigsegvcount=$(grep -c Segmentation $FUZZINGLOG)
[[ $sigsegvcount = 1 ]] && faults="fault" || faults="faults"
success "Found $sigsegvcount Segmentation "$faults

# Show how many AddressSanitizer messages we hit. In order to see these,
# modsec-sdbm-util must be built with -fsanitize=address -ggdb in CFLAGS
asancount=$(grep -c 'ERROR: AddressSanitizer' $FUZZINGLOG)
[[ $asancount = 1 ]] && messages="message" || messages="messages"
success "Found $asancount Address Sanitizer (libasan) "$messages

success "Check $FUZZINGLOG"
