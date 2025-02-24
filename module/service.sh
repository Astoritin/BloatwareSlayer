#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR=/data/adb/bloatwareslayer
BRICKED_STATUS="$CONFIG_DIR/bricked"
LOG_DIR="$CONFIG_DIR/logs"
BS_LOG_FILE="$LOG_DIR/log_$(date +"%Y-%m-%d_%H-%M-%S")_s.txt"
TIMEOUT=300


echo "Bloatware Slayer" >> $BS_LOG_FILE
echo "By Astoritin Ambrosius" >> $BS_LOG_FILE
echo "- Version: 1.0.6" >> $BS_LOG_FILE
echo "- Current time stamp: $(date +"%Y-%m-%d %H:%M:%S")" >> $BS_LOG_FILE
echo "- Starting service.sh..." >> $BS_LOG_FILE

if [ -f "${MODDIR}/disable" ]; then
    echo '- Detect file "disable", module is already disabled' >> $BS_LOG_FILE
    echo "- Exiting service.sh..." >> $BS_LOG_FILE
    exit 1
fi

{
    echo "- Current booting timeout: $TIMEOUT" >> $BS_LOG_FILE
    while [ "$(getprop sys.boot_completed)" != "1" ]; do
        echo "- BS_WAIT_BOOT_COMPLETE (Timeout: $TIMEOUT s)" >> $BS_LOG_FILE
        if [ $TIMEOUT -le "0" ]; then
            echo "! Detect failed to boot after reaching the set limit!" >> $BS_LOG_FILE
            echo "! Your device may be bricked by Bloatware Slayer!" >> $BS_LOG_FILE
            echo "! Please make sure no improper APP(s) being blocked!"
            echo "- Mark status as bricked" >> $BS_LOG_FILE
            touch "$BRICKED_STATUS"
            echo "- Rebooting..." >> $BS_LOG_FILE
            reboot
        fi
        TIMEOUT=$((TIMEOUT-1))
        sleep 1
    done

    if [ -f "$BRICKED_STATUS" ]; then
        echo "- Detect bricked status file existed!" >> $BS_LOG_FILE
        echo "- But system boot completely, deleting it..." >> $BS_LOG_FILE
        rm -rf "$BRICKED_STATUS"
        if [ $? -eq 0 ]; then
            echo "- Bricked status clear" >> $BS_LOG_FILE
        else
            echo "- Failed to clear bricked status" >> $BS_LOG_FILE
        fi
    else
        echo "- Bricked status file does not exist, nothing to delete" >> $BS_LOG_FILE
    fi

    echo "- Boot complete! Final countdown: $TIMEOUT s" >> $BS_LOG_FILE
    echo "- service.sh case closed!" >> $BS_LOG_FILE

    # MOD_DESC_OLD=$(grep_prop description "${TMPDIR}/module.prop")
    # MOD_LAST_STATUS=""
    # MOD_CURRENT_STATUS=""
    # MOD_REAL_TIME_DESC=""
    # while true; do
    #     if [ -f "$MODDIR/disable" ]; then
    #         MOD_CURRENT_STATUS="disabled"
    #     elif [ -f "$MODDIR/remove" ]; then
    #         MOD_CURRENT_STATUS="removed"
    #     else
    #         MOD_CURRENT_STATUS="enabled"
    #     fi
    #     if [ "$MOD_CURRENT_STATUS" != "$MOD_LAST_STATUS" ]; then
    #         echo "- Detect status changed:$MOD_LAST_STATUS -> $MOD_CURRENT_STATUS" >> $BS_LOG_FILE
    #         case $MOD_CURRENT_STATUS in
    #             disabled)
    #                 echo "- Detect module disabled" >> $BS_LOG_FILE
    #                 MOD_REAL_TIME_DESC="[❌Disabled (Reboot to take effect). Root:$ROOT_IMP] 勝った、勝った、また勝ったぁーっと！！🎉✨"
    #                 ;;
    #             removed)
    #                 echo "- Detect module disabled" >> $BS_LOG_FILE
    #                 MOD_REAL_TIME_DESC="[🗑Removed (Reboot to take effect). Root:$ROOT_IMP] 勝った、勝った、また勝ったぁーっと！！🎉✨"
    #                 ;;
    #             enabled)
    #                 echo "- Detect module enabled" >> $BS_LOG_FILE
    #                 MOD_REAL_TIME_DESC=$MOD_DESC_OLD
    #                 ;;
    #         esac
    #         sed -i "s/description=\[.*\]/description=\[$MOD_REAL_TIME_DESC\]/" "$MODDIR/module.prop"
    #         MOD_LAST_STATUS=$MOD_CURRENT_STATUS
    #     fi
    #     sleep 3
    # done
} >> $BS_LOG_FILE 2>&1 &
