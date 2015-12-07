This script allows you to configure multiple seed routers which will then populate a list of subnets to scan.

Every IP on each subnet will then be tested for ping availability.  It will also provide both a reverse DNS lookup and SNMP hostname query on every IP address whether it is up or down.

Requires:
> + nmap
> + nslookup
> + bash