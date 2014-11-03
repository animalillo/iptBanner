iptBanner
=========

Iptables ban script, thinked with OpenBL in mind

The script should work with most systems. Its been developed and tested under Ubuntu Server 12.04 LTS

1. Adjust the path variables to your system.

2. Set a valid path for ZONEROOT where the script will save all the requiered files generated durning execution

3. IPTABLES_LOG_MESSAGE Stores the message iptables will add to your logs each time a packet its discarded from any banned IP

Script usage:   
   
ipban.sh [--parameter [option]]   
ipban.sh --count [update|current]  
   
Parameter       Description   
==============  ===================================================================================   
--help          Show this help message   
--version       Show the script version   
--download      will download the updated IPs file   
--count         Show number of ips in current IP base file (may vary from currently banned count)   
    [update]    Show number of ips updating the IP base file first (no banning will be done)   
    [current]   Show the number of IPS banned the last time this script was executed   
--clear         Clear all working rules from the firewall   

without parameters will apply the current most updated list
