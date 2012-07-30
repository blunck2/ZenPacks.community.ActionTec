#!/bin/sh

# arguments to this script are:  hostname username password
HOST=$1
USERNAME=$2
PASSWORD=$3

# sanity check
if [ -z "${HOST}" -o -z "${USERNAME}" -o -z "${PASSWORD}" ]; then
  echo "usage:   ./network-stats-nagios.sh hostname username password"
  echo "example: ./network-stats-nagios.sh 192.168.1.1 myusername mypassword"
  echo ""
  exit 1
fi


# map our directory
DIR=`dirname $0`
if [ "${DIR}" = "." ]; then
  DIR=`pwd`
fi

# the underlying program we'll call
WORKER="${DIR}/network-stats.sh ${HOST} ${USERNAME} ${PASSWORD}"

# run the program and capture the output
OUTPUT=`${WORKER}`

# check for error
if [ -z "${OUTPUT}" ]; then
  echo "command failed|"
  exit 1
fi

# gather results
RX=`echo ${OUTPUT} | awk '{print $1}'`
TX=`echo ${OUTPUT} | awk '{print $2}'`

# convert to mb
RX_MB=`echo $(( ${RX} / 1024 / 1024))`
TX_MB=`echo $(( ${TX} / 1024 / 1024))`

# run and tell that
echo "router ok|rx=${RX_MB} tx=${TX_MB}"
