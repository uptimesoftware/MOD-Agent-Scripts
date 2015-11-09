#!/bin/ksh
#=======================================================================
# sysinfo.sh - <SPYNuptm/bin/sysinfo.sh>
#-----------------------------------------------------------------------
#
# - DESCRIPTION:
#
#   Return system information to the data collector
#
# - DEPENDENCIES:
#
#=======================================================================
# $Id: sysinfo.sh,v 1.6 2007-03-28 19:00:49 dgermiquet Exp $
#
export LANG=en_US.ISO8859-1
export LC_COLLATE=C
export PATH=$PATH:/usr/bin:/etc:/usr/sbin:/sbin:/bin

function aixversion {
  OSLEVEL=$(oslevel -s)
  AIXVERSION=$(echo "scale=1; $(echo $OSLEVEL | cut -d'-' -f1)/1000" | bc)
  AIXTL=$(echo $OSLEVEL | cut -d'-' -f2 | bc)
  AIXSP=$(echo $OSLEVEL | cut -d'-' -f3 | bc)
  echo "AIX ${AIXVERSION} - Technology Level ${AIXTL} - Service Pack ${AIXSP}"
}

echo "SYSNAME="`hostname`
echo "DOMAIN="
echo "ARCH=\""`/usr/bin/uname -a`"\""
echo "OSVER= "$(aixversion)
NUMCPUS=`/usr/sbin/lsdev -Cc processor | grep Available | wc -l`
echo "NUMCPUS=$NUMCPUS"





function get_memsize
{

  total_memory=0
  total_l2_cache=0

  lsdev -C -c memory | awk '{print $1}' |  while read memdevice
  do
    mem_count=`lsattr -E -l$memdevice | grep ^size | awk '{print $2}'`
    case $memdevice in
      
      mem*)
           (( total_memory = total_memory + mem_count ));;

      L2cache*)
           (( total_l2_cache = total_l2_cache + mem_count ));;

    esac
  done

   (( total_memory = total_memory * 1024 ))

   echo "MEMSIZE=$total_memory"
   echo "L2CACHE=$total_l2_cache"
}

get_memsize

echo "PAGESIZE="`/usr/bin/pagesize`

function get_swapsize
{
   swap=`lsps -s | tail -1 | awk '{print $1}'`
   total_swap=`echo ${swap%??}`

  (( total_swap = total_swap * 1024 ))
  echo "SWAPSIZE=$total_swap"  
}

get_swapsize


echo "GPGSLO=0"
echo "VXVM=\"\""
echo "SDS=\"\""
echo "HOSTID=\"`hostid`\""
ARCH=`/usr/bin/uname -m`
CPU_SPEED=0

PROC=`/usr/sbin/lsdev -Cc processor | grep Available | head -1 | awk '{print $1}'`
CPU_SPEED=`/usr/sbin/lsattr -El $PROC 2>/dev/null | grep frequency | awk '{print $2}'`
if [[ "$CPU_SPEED" -eq "" ]]; then
  CPU_SPEED=0
fi
CPU_SPEED=$(($CPU_SPEED/1000000))

  CPU_MODEL=`/usr/sbin/lsattr -El $PROC 2>/dev/null | grep type | awk '{print $2}'`
  if [[ "$CPU_MODEL" = "" ]]; then
    CPU_MODEL=0
  fi
  i=0
  while true
  do
    echo "CPU"$i"=\" $i 0 0 ${CPU_SPEED} 0 ${CPU_MODEL} 0 \" "
    i=$(($i+1))
    if [[ $i -ge $NUMCPUS ]]; then
      break
    fi
  done

/usr/sbin/ifconfig -a | /usr/bin/nawk 'BEGIN { i=0; prev="" } /^(.*)\: / { intf=substr($1,0,index($1,":")-1); if ( intf != prev ) { prev=intf; getline; print "NET"i"="intf"="$2; i=i+1 }}'

/opt/uptime-agent/bin/lparhost.sh
