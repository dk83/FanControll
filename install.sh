##!/bin/bash
#
Init="/etc/init.d";
Bin="/usr/local/sbin";
# Fan Controll
sudo ln -s "${PWD}/FanControll.init"  "${Init}/FanControll"
sudo ln -s "${PWD}/FanControll.sh"    "/etc/FanControll.sh"
sudo ln -s "${PWD}/FanControll.sh"    "${Bin}/FanControll"
sudo update-rc.d FanControll defaults
