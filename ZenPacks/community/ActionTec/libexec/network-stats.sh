#!/bin/sh

#
# a simple script that uses expect and telnet to retrieve rx and tx metrics
# from an actiontec router.
#
# unfortunately the actiontec routers do not expose any metrics over snmp.
# fortunately they do have a telnet based interface and very fortunately
# that telnet interface grants us access to an underlying busybox shell
# running atop the linux os.
#
# because we can interactively interact with an underlying shell we can 
# then step back and run an expect script to issue commands and capture 
# output.  this shell is the wrapper around that process.
#
# this shell script takes the following input paramters:
#   $1: ip address of router
#   $2: username to authenticate with
#   $3: password to authenticate with
#
# this shell script passes that information down to an expect script, which
# performs the actual telnet and command execution.  the output of the expect
# script is written to a temp file and various grep and cut commands are used
# to munge the output and produce a single line of the following format:
# rxbtes txbytes
#
# where ...
#   rxbytes:  the number of bytes that have been received on the WAN interface
#   txbytes:  the number of bytes that have been sent on the WAN interface
#
#

# arguments to this script are:  hostname username password
HOST=$1
USERNAME=$2
PASSWORD=$3

# location of expect executable
EXPECT=/usr/bin/expect

# the basename of the expect script we will execute
EXPECT_SCRIPT=network-stats.expect


# sanity check
if [ -z "${HOST}" -o -z "${USERNAME}" -o -z "${PASSWORD}" ]; then
  echo "usage:   ./network-stats.sh hostname username password"
  echo "example: ./network-stats.sh 192.168.1.1 myusername mypassword"
  echo ""
  exit 1
fi

# another sanity check
if [ ! -x "${EXPECT}" ]; then
  echo "you must have expect installed"
  exit 1
fi

# and the glorious fail
fail() {
  echo $1
  exit 1
}

# map the ./network-stats.sh vs /path/to/network-stats.sh
DIR=`dirname $0`
if [ "${DIR}" = "." ]; then
  DIR=`pwd`
fi

# we'll dump output in a temp file
OUTPUT=`mktemp`

# run an expect script to connect to the router
${EXPECT} \
  ${DIR}/${EXPECT_SCRIPT} \
  ${HOST} \
  ${USERNAME} \
  ${PASSWORD} \
> ${OUTPUT} || fail "could not run expect"

# grep the output for ifconfig signature RX bytes
LINE=`grep "RX bytes" ${OUTPUT}`

# if no output received we exit with a bad error code
if [ -z "${LINE}" ]; then
  exit 1
fi

# debug... uncomment if interested...
#echo "line: ${LINE}"

# parse the output by grepping and cutting
rx=`echo ${LINE} | cut -d ':' -f2 | cut -d' ' -f1`
tx=`echo ${LINE} | cut -d ':' -f3 | cut -d' ' -f1`


# print the receive and then the transmit in bytes
echo $rx $tx

# remove our temp file
rm ${OUTPUT}


