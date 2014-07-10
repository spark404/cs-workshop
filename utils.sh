#!/bin/bash

function download() {
   local source=$1
   local destination=$2
   local checksum=$3
   if [ -f $destination ] ; then
       local checksum2=`/usr/bin/md5sum $destination | awk '{print $1}'`
       if [ "$checksum" == "$checksum2" ] ; then
           echo File already downloaded and OK
           return 0
       fi
   fi
   curl -o $destination http://sunbeam.strocamp.net/workshop/$source
   local checksum2=`/usr/bin/md5sum $destination | awk '{print $1}'`
   if [ "$checksum" == "$checksum2" ] ; then
       echo File OK
       return 0
   fi
   return 1
}   

