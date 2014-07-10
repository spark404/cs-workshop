#!/bin/bash

ACCOUNT=$1
if [ "x$ACCOUNT" == "x" ] ; then
  exit 1
fi

NETID=`cloudmonkey create network name=${ACCOUNT}-network displaytext=${ACCOUNT}-network zoneid=2 networkofferingid=c348cabe-0208-49e0-91ad-32b88c55fd8c | grep ^id\ = | awk '{print $3}'`

ROUTERID=`cloudmonkey deploy virtualmachine templateid=5915341e-2f68-4c9e-a961-6b1809bc227b zoneid=2 serviceofferingid=290af1a1-0ee1-45b1-8fd4-8e330308b377 ipaddress=10.1.1.2 name=workshop-rtr networkids=${NETID} | grep ^id\ = | awk '{print $3}'`

echo Network           : $NETID
echo Router            : $ROUTERID

if [ "x$ROUTERID" == "x" ] ; then
    echo Deploy Failed
    exit 1
fi

for STUDENT in 1 2 3 4 5 6 7 8 ; do

    MGMTIP=$((($STUDENT - 1) * 32 + 3))
    XENIP=$(($MGMTIP + 1)) 
    # deploy cloudstack management server
    VM1ID=`cloudmonkey deploy virtualmachine templateid=5915341e-2f68-4c9e-a961-6b1809bc227b zoneid=2 serviceofferingid=290af1a1-0ee1-45b1-8fd4-8e330308b377 ipaddress=10.1.1.${MGMTIP} name=workshop-mgmt-s${STUDENT} networkids=${NETID} | grep ^id\ = | awk '{print $3}'`
    
    # deploy xen hypervisor
    VM2ID=`cloudmonkey deploy virtualmachine templateid=b068c82a-1d17-47ff-bf32-4b732377b946 zoneid=2 serviceofferingid=290af1a1-0ee1-45b1-8fd4-8e330308b377 ipaddress=10.1.1.${XENIP} name=workshop-xen-s${STUDENT} networkids=${NETID} | grep ^id\ = | awk '{print $3}'`
    
    echo Account           : $ACCOUNT
    echo Management Server : $VM1ID  10.1.1.${MGMTIP}
    echo XenServer         : $VM2ID  10.1.1.${XENIP}

done

