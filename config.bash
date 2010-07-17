#!/bin/bash

#####  ROUTERS contains the different routers and their respective read-only SNMP community  #####
ROUTERS="192.168.14.1,rocommunity;192.168.1.1,rocommunity2"

#####  SYSTEM_COMMUNITY sets the SNMP community used by all the systems on the network, this value must be the same for all systems  #####
SYSTEM_COMMUNITY="sysrocommunity"

#####  OUTPUT_FILE is where all of the output will be sent, usually an HTML or similar file  #####
OUTPUT_FILE="/var/www/network/index.html"

#####  HISTORY_DIR is where the previous snapshots of the output will be stored  #####
HISTORY_DIR="/var/www/network/history/"

#####  DEBUG 1=on 0=off  #####
DEBUG=1
