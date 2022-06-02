#!/bin/bash

DIR="$(dirname "$0")"

if (( $# <= 0 )) ; then
echo "version: V1.0.1"
echo "Copyright (c) 2005-2022, Kunlun BIOS, ZhongDian Technology (Beijing) Co., Ltd."
echo "USAGE: $0 + params"

echo " "
version=$($DIR/flashrom -h | grep "flashrom V" | awk -F"\r" '{print $1}')
echo $version

version=`$DIR/$1 -v | grep "Version:"`
echo $1 $version 
exit 1;
fi
countparam=0
space=" "
cmd=""
cmd1=""
backcmd=0
help=0
plat=""
platbk=""

plat1="D2000/8"
plat2="FT-2500"
plat3="Hygon"
plat4="3A5000"
plat5="SW3231"
plat6="FT-2000/4"
plat_all=$plat1$space$plat2$space$plat3$space$plat4$space$plat5$space$plat6

function switchPlat() {
  sPlat=""
  if [[ $1 =~ $plat1 ]] ; then
    sPlat="FT2000"
  elif [[ $1 =~ $plat2 ]] ; then
    sPlat="FT2500"
  elif [[ $1 =~ $plat3 ]] ; then
    sPlat="internal"
  elif [[ $1 =~ $plat4 ]] ; then
    sPlat="LS3A5000"
  elif [[ $1 =~ $plat5 ]] ; then
    sPlat="SW64"
  elif [[ $1 =~ $plat6 ]] ; then
    sPlat="FT2000"
  fi
  echo $sPlat
}

function getCmdPlat() {
  sPlat=""
  for param in $*
  do
    if [[ $param =~ "--plat=" ]] ; then
      sPlat=$(switchPlat $param)
    else
      sPlat=$sPlat
    fi
  done
  echo $sPlat
}

function catCpuInfo() {
	echo `cat /proc/cpuinfo | grep "model name" | awk -F":" '{print $2}' | awk -F" " '{print $1}' | awk 'NR==1'`
}

function getCpuInfoPlat() {
  sPlat=""
  sPlat=$(catCpuInfo)
  sPlat=$(switchPlat $sPlat)
  echo $sPlat
}

function getPlat() {
  sPlat=""
  if [[ $* =~ "--plat=" ]] ; then
    sPlat=$(getCmdPlat $*)
  else 
    sPlat=$(getCpuInfoPlat)
  fi
  echo $sPlat
}

for param in $*
do
  if ((countparam > 0));then
    if test $param = "-b" -o $param = "--backup" ;then
      backcmd=1
    elif test $param = "-h" -o $param = "--help" -o $param = "-V" -o $param = "--version" ;then
      cmd=$cmd$space$param
      help=1
    elif [[ $param =~ "--plat=" ]] ;then
      echo $param
      platbk=$param
    else
      cmd=$cmd$space$param
    fi
  fi
  countparam=$countparam+1
done

chmod 777 $DIR/*

echo "platbk: "$platbk
plat=$(getPlat $platbk)
#echo "plat ==== "$plat
if [ ! $plat ];then
  echo "plat is NULL,Please try adding --plat=" $plat_all "etc."
#  echo "Unknown or unsupport platform!"
  exit 1;
fi

if [ "$help" -ne "0" ] ; then
  echo ""
else
  $DIR/flashrom -p $plat -l $DIR/Layout -i NVRAM -r rom.bin
fi

if [ "$backcmd" -ne "0" ] ; then
  cp ./rom.bin ./bak.bin
  exit 0
else
  echo $DIR/$1 $cmd
  $DIR/$1 $cmd
  if [ $? -le 0 ]; then
    echo -e "\033[41;5m ERROR: Failed to generate file. \033[0m"
    exit 1
    # Play noise for alarming ...
    #cat /dev/urandom >/dev/audio
  else
    echo -e "\033[42;37m  File completed OK!\033[0m"
  fi
#  rm $DIR/rom.bin
fi

if [ "$help" -ne "0" ] ; then
  #echo help or info
  exit 0
fi

if [[ $cmd =~ "show" ]] ; then
  echo show
  exit 0
fi

$DIR/flashrom -p $plat -l $DIR/Layout -N -i NVRAM -w rom.bin --flash-contents rom.bin

exit 0;
