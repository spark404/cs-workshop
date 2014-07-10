Workshop CloudStack
===================

Part 0 - Your Student Environment
---------------------------------

As part of this lab you should have received a form with accounts and IP addresses.

Please check your environment by making an ssh connection to the ip 
address listed under 'cloudstack management host (external)'. The account you can use
is student with password student. 

Verify if the XenServer hypervisor is properly up and running by making an ssh connection
from the management host to ip address 10.1.1.4. The credentials are root/password 
for this XenServer installation.

Part 1 - Installing CloudStack
------------------------------

Connect to the cloudstack management host (see Part 0) and become the root user by executing the 
following command.

    sudo bash

We are using RPM installation packages to install Apache CloudStack. The packages to install 
are located in /opt/cloudstack-rpms. Run the following commands install Apache CloudStack.

    cd /opt/cloudstack-rpms
    yum localinstall cloudstack-*.rpm
    cp -p vhd-util /usr/share/cloudstack-common/scripts/vm/hypervisor/xenserver/
    chmod +x /usr/share/cloudstack-common/scripts/vm/hypervisor/xenserver/vhd-util

The version you have just installed is 4.4.0-SNAPSHOT. This is the latest build of the upcoming 4.4.0 release
that is currently being testing by the community and now by you as well. The vhd-util you copied is a slightly
modified version of the vhd-util supplied with XenServer. Due to licensing issues Apache CloudStack can't include
this file in the release, so we need to copy it separately.

Apache CloudStack needs a database to store its persistent information. The cloudstack-mgmt server already has 
as installed MySQL database. We do need to configure the database to be used by CloudStack.

First we install the database schema and we import some setting specific for this workshop into the database.

    cloudstack-setup-databases cloud:cloud@localhost --deploy-as=root:cloud
    mysql -u cloud -p'cloud' cloud < ~bootstrap/post_install.sql
    cloudstack-setup-management

With these steps completed you can start the Apache CloudStack Management server

    /etc/init.d/cloudstack-management start

When the management server has completed its startup procedure the web UI is reachable at the URL listed on you sheet. This can take a couple of minutes to complete. When you presented with the login screen use the credentials admin/password to login.


Part 2 - Creating a Cloud
-------------------------


Select “I have used CloudStack before” on the introduction page. The configuration wizard allows you to configure a basic Apache Cloudstack setup, but for this workshop we will use a more advanced configuration.

Select the Infrastructure tab and Select View All on the Zones panel. Click Add Zone. This starts the zone wizard which will guide you through the entire setup for a CloudStack Zone.

The following screens will ask for various configuration details. The relevant details are listed below or they will refer you to the student handout with specific configuration settings. After configuring the settings on a page use the next button to proceed to the next page.

* Basic Setup
    * Select Advanced

* Zone Configuration
    * Name: Zone
    * IPv4 DNS1: 8.8.8.8
    * Internal DNS 1: 10.1.1.1
    * Hypervisor: XenServer
    * Guest CIDR: 172.16.100.0/24

* Setup Network
    * leave at the defaults

* Guest network
    * Configure as noted on the handout and click add

* Setup Pod
    * Configure as noted on the handout

* Configure VLAN
    * Enter vlan 100 and 300

* Cluster
    * Name: Cluster

* Host:
    * Enter the details as listed for XenServer on the handout

* Primary: 
    * Enter the details as listed for Primary Storage on the handout

* Secondary: 
    * Select NFS as type
    * Enter the details as listed for Secondary Storage on the handout


Select Launch Zone to start the configuration process. If any of the steps fails check the settings and try again or contact the trainer.

After the configuration procedure is completed Apache CloudStack will show a popup asking to enable the Zone. Confirm enabling the zone. This will trigger internal processes that will prepare the Zone for actual usage. This can take several minutes to complete. A good indication that the process completed successfully is watching the status of the System VMs (Infrastructure tab). The Secondary Storage VM is Running with agent status Up when the process is completed. If the System VMs remain in status stopped or error the system did not activate properly. Contact your instructor in this case.


Part 3 - Isolated Networks
---------------------------------

In Apache CloudStack Advanced zones an isolated network is the basic type of network you encounter. And isolated network typically uses a router with NAT functionality to connect to the public network (Internet) and uses an RFC 1918 cidr on the network itself. The name isolated comes from the fact that this network is not shared with any other tenants, infact IP spaces can and will often overlap.

Apache CloudStack contains a build-in router to take care of the connection to the internet, but it also supports several external devices with the same functionality.

In this part we will create a basic isolated network with a single instance in it.

First create the network by going to the ‘Network’ tab and select ‘Add Isolated Network’. Complete the form by entering a name and a display text and press OK. The network should no show up in the list, not that the CIDR is what we entered during the installation as the default guest network.

Select the ‘Instances’ tab to start with creating the first instance. Select ‘Add Instance’ to open the new instance wizard. We are going to create an instance from a Template.

* Select Template and press next. 
* Select the featured tiny Linux template and press next. 
* Select tinyOffering in step 3 and press next. 
* Keep the ‘No thanks’ default in step 4 and press next. 
* Press next on the Affinity tab. 
* Select the network you created previously and press next.
* Optionally enter a name for the new instance and select Launch VM.

This process will take some time. First the system will need to instantiate a virtual router and next our new instance. As we are working with a bare setup the templates aren’t downloaded to the hypervisor yet so this also takes some time.

At this point feel free to play around with the various options and settings to create instances before we proceed to the next part.


Part 4 - VPC Networks
---------------------------------

Apache CloudStack provides a construct for multi-tiered isolated networks. This is called a Virtual Private Cloud (VPC). A VPC consists of a single routing construct and multiple networks. This particularly useful for building and environment for multi-tiered application. 

Consider for example an application with a database server, an application server and one or more webservers. In such a setup only the web servers would need to be exposed to the public and the application servers would only need to be exposed to the web servers and the database servers only to the application servers. In a VPC each network can have its won set of ingress and egress access list limiting what traffic can flow between the tiers and between the VPC and the public internet. 
combine 
There a a number of additional features in the Apache CloudStack VPC like private gateways and site-to-site VPNs.

To setup a VPC start at the ‘Network’ tab and select the ‘VPC’ view. Select ‘Add VPC’ to start the new VPC dialog. Fill in a name and description for the VPC. The super net is the total IP space available for networks inside the VPC. In this exercise enter the CIDR 172.16.0.0/22. Submit the form by selecting the OK button.

The page will now display a list of created VPCs, select the Configure button for the VPC you just created. You will be presented with the ‘new tier’ dialog as you don’t have any networks in your VPC yet. Enter a name for the tier. The gateway and net mask together must combine in a CIDR inside the allocated VPC ip space. Use 172.16.1.1 with netmask 255.255.255.0 and select the OK button. 

At this point you a presented with the default VPC configuration screen, create some additional networks and create instances within each network.


Part 5 - Conclusion
------------------

This concludes the guided part of the workshop. Feel free to play around with the system you configured to get a feel for Apache CloudStack

Here are some exercises that will help you get familiar with Apache CloudStack
* Configure a firewall on the isolated network created in Part 3.
* Add an additional instance to the isolated network and configure load balancing
* Create in ingress firewall for the VPC created in Part 4







