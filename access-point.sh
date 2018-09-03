#!/usr/bin/env bash

hostapd \
  -P /var/run/hostapd-br0.pid \
  -B ./hostapd-test.conf
