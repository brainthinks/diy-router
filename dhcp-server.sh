#!/usr/bin/env bash

# @see - https://renaudcerrato.github.io/2016/05/23/build-your-homemade-router-part2/

# Note that I have chosen to set up my IP range to go from
# 25 to 90.  I want to have space at the beginning of the IP
# range to allow for my statically-addressed devices, like
# my networking equipment, security equipment, printer, etc.

dnsmasq \
  --pid-file=/var/run/dnsmasq-br0.pid \
  --conf-file=/dev/null \
  --interface=br0 --except-interface=lo \
  --dhcp-range=192.168.1.25,192.168.1.90,24h

