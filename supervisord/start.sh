#!/bin/bash
mkdir /home/printer/klipper_logs
chown -hR printer:printer /home/printer/klipper_logs
/usr/bin/supervisord
