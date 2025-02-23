#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR=/data/adb/bloatwareslayer
LOG_DIR="$CONFIG_DIR/logs"
BRICKED_STATUS="$CONFIG_DIR/bricked"
BS_LOG_FILE="$LOG_DIR/log_s_$(date +"%Y-%m-%d_%H-%M-%S").txt"
TIMEOUT=300

echo " " >> $BS_LOG_FILE
echo "Bloatware Slayer" >> $BS_LOG_FILE
echo "By Astoritin Ambrosius" >> $BS_LOG_FILE
echo "- Version: 1.0.3" >> $BS_LOG_FILE
echo "- current time stamp: $(date +"%Y-%m-%d %H:%M:%S")" >> $BS_LOG_FILE
echo "- Starting service.sh..." >> $BS_LOG_FILE

if [ -f "${MODDIR}/disable" ]; then
    echo "- Disable file already exists. Module is already disabled." >> $BS_LOG_FILE
    echo "- Exiting service.sh..." >> $BS_LOG_FILE
    exit 1
fi

{
    while [ "$(getprop sys.boot_completed)" != "1" ]; do
        echo "- BS_WAIT_BOOT_COMPLETE (Timeout: $TIMEOUT s)" >> $BS_LOG_FILE
        if [ $TIMEOUT -le "0" ]; then
            echo "! Detect boot time longer than $TIMEOUT s!" >> $BS_LOG_FILE
            echo "! Your device may be bricked by Bloatware Slayer!" >> $BS_LOG_FILE
            echo "- Marking device status as bricked..." >> $BS_LOG_FILE
            touch "$BRICKED_STATUS"
            echo "- Done!" >> $BS_LOG_FILE
            reboot
        fi
        TIMEOUT=$((TIMEOUT-1))
        sleep 1
    done

    if [ -f "$BRICKED_STATUS" ]; then
        echo "! Detect bricked status file exists!" >> $BS_LOG_FILE
        echo "! But system boot completely, deleting it..." >> $BS_LOG_FILE
        rm -rf "$BRICKED_STATUS"
        if [ $? -eq 0 ]; then
            echo "- Bricked status file deleted successfully." >> $BS_LOG_FILE
        else
            echo "- Failed to delete bricked status file." >> $BS_LOG_FILE
        fi
    else
        echo "- Bricked status file does not exist. Nothing to delete." >> $BS_LOG_FILE
    fi

    echo "- Boot complete! Current countdown: $TIMEOUT s" >> $BS_LOG_FILE
    echo "- service.sh case closed!" >> $BS_LOG_FILE
} >> $BS_LOG_FILE 2>&1 &
