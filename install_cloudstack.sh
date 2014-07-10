#!/bin/bash

echo Installing CloudStack
ssh -i ~/.ssh/bootstrap_key_rsa bootstrap@$1 'cat > cs_install.sh' <<EOF
cp -p vhd-util /usr/share/cloudstack-common/scripts/vm/hypervisor/xenserver/
chmod +x /usr/share/cloudstack-common/scripts/vm/hypervisor/xenserver/vhd-util
cloudstack-setup-databases cloud:cloud@localhost --deploy-as=root:cloud
EOF
ssh -i ~/.ssh/bootstrap_key_rsa bootstrap@$1 'sudo bash -x cs_install.sh'

