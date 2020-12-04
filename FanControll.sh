#!/bin/bash
##################
# Fan Settings for 25mm CPU Fan - 30mm Case Fan
# CPU  Fan(5V/80mA) -  PWM: MIN: 365<->370  MID: 378  Max:450
# Case Fan(5V/150mA) - PWM: MIN: 235<->250  MID: 265  Max:310
##################
#
# Settings for CPU Fan
CPU_Min="361"; CPU_Max="450";
# Settings for Case Fan
CASE_Min="232"; CASE_Max="350";
# Minimum:  CPU Temperature |  Case Temperature
CpuTempMin="55";
# TempMax: Max System Temperature | TempFail: Hardware Protection Temperature
TempFail="68";
# Read DS18B20 Sensore from OneWire for Case Temperature from gpio:4
DS18B20="28-00000b2a78ee";
###   Speed Logging   ###
Log="/var/log/Do/FanControll.log"; sudo chown $USER:$USER $Log;
CpuLog="/var/log/Do/CpuSpeed";
CaseLog="/var/log/Do/CaseSpeed";
if ! [ -d "/var/log/Do" ]; then sudo mkdir "/var/log/Do"; sudo chown -R $USER:$USER "/var/log/Do"; fi
#
###   wiringpi commands   ###
Off() { gpio -g write 18 0; gpio -g write 19 0; gpio -g pwm 18 0; gpio -g pwm 19 0; }
ON() { gpio -g mode 18 out; gpio -g write 18 1; gpio -g mode 19 out; gpio -g write 19 1; }
CPU() { $(gpio -g pwm 18 $1); if [[ "$1" > "$CPU_Min" ]]; then echo "$(( (($1-$CPU_Min) * 100) / ($CPU_Max-$CPU_Min) )) %" > $CpuLog; else echo "0 %" > $CpuLog; fi }
CASE() { $(gpio -g pwm 19 $1); echo "$(( (($1-$CASE_Min) * 100) / ($CASE_Max-$CASE_Min) )) %" > $CaseLog; }
IntFan() { gpio -g mode 18 pwm; gpio -g mode 19 pwm; }
Write() { now="$(date +%H:%M:%S)"; echo -e "${now} |->  $1" >> $Log; }
###   Intern Variables   ###
RE=0; CpuTemp=0; CaseTemp=0; CpuSpeed=0; CaseSpeed=0;
Time="5";
#

###   FailSave: disable overclocking   ###
FailSave() {
    echo -e "\n\t-->>  FailTemp: Speed up Fans!  <<--\n";
    ON; sleep 5s; GetCpuTemp;
    if [[ "$CpuTemp" > "$TempFail" ]] || [[ "$CaseTemp" > "$TempFail" ]]; then
        echo -e "\n\t-->>  FailTemp: OverHeat protection  <<<--\n\t-->>  Disable Overclocking and ShutDown now!  <<--\n"; sleep 5s;
        sudo cp "/boot/config.txt" "/boot/FailSave-config.txt";
        sudo sed -i 's/over_voltage=4/#over_voltage=4/g' "/boot/config.txt";
        sudo sed -i 's/arm_freq=1875/#arm_freq=1875/g' "/boot/config.txt";
        sudo sync; sleep 0.5s; gpio -g mode 13 out; gpio -g mode 13 out;
        gpio -g write 12 1; gpio -g write 13 1; sleep 0.5s;
        sudo poweroff -p && gpio -g write 13 0;
    fi
    echo -e "\n\t-->>  FailTemp: Temperature okay  <<<--\n";
}
#
###   Get Temperature   ###
GetCpuTemp() {
    val="$(vcgencmd measure_temp | tr -d 'temp=')";
    CpuTemp=(${val//.**C});
    return "$CpuTemp";
}
GetCaseTemp() {
    val=$(echo $(cat /sys/bus/w1/devices/$DS18B20/w1_slave | grep "t=") | cut -d "=" -f2);
    CaseTemp="$(( $val / 1000 ))";
    return "$CaseTemp";
}
Status() {
    Write "FanControll: CpuSpeed:${CpuSpeed}; CaseSpeed:${CaseSpeed}; CpuTemp:${CpuTemp};";
}
###   Set CPU Fan PWM   ###
SetCpuFanSpeed() {
    GetCpuTemp; x=0;
    CpuStep="$(( ($CPU_Max - $CPU_Min) / ($TempFail - $CpuTempMin) ))";
    while (( ${CpuTempMin} != ${CpuTemp} )); do
        x="$(($x+1))";
        if [[ "$(( $CpuTempMin + $x))" == "$CpuTemp" ]]; then
             ###   Set CASE   ###
             CaseSpeed="$(( $CASE_Min + ( ($x *4) + 12 ) ))";
             CaseSpeed="$CaseSpeed";
             ###   Set CPU   ###
             if [[ "$x" -gt "9" ]]; then
                 CpuSpeed="$(( $CPU_Min + ( $x * $CpuStep * 2) ))";
                 CpuSpeed="$CpuSpeed"; Status; Time="2";
             elif [[ "$x" -gt "2" ]]; then
                 CpuSpeed="$(( $CPU_Min + ( $x * $CpuStep) ))";
                 CpuSpeed="$CpuSpeed"; Status; Time="4";
             else CpuSpeed="$(($CPU_Min + 10))"; Time="6"; fi
             break;
        elif [[ "$CpuTemp" < "$(($CpuTempMin + 1))" ]]; then
            if [[ "$CpuTemp" < "$(( $CpuTempMin - 1 ))" ]]; then CpuSpeed="$(($CPU_Min - 10 ))"; CaseSpeed="$(( $CASE_Min + 12 ))"; Time="16";
            elif [[ "$CpuTemp" < "$(( $CpuTempMin ))" ]]; then CpuSpeed="$(($CPU_Min + 2 ))"; CaseSpeed="$(( $CASE_Min + 16 ))"; Time="12";
            else CpuSpeed="$(($CPU_Min + 8 ))"; CaseSpeed="$(( $CASE_Min + 22 ))"; Time="8"; fi
            break;
        elif [[ "$CpuTemp" > "$(($TempFail - 1))" ]]; then FailSave; break;
        else sleep 6s; fi
    done
}
#
##########################
##########################
###   START PROGRAMM   ###
Write "FanControll.sh geladen <-|";
while true; do
        IntFan;
	SetCpuFanSpeed;
        CPU "$CpuSpeed";
        CASE "$CaseSpeed";
        sleep "${Time}s";
done
