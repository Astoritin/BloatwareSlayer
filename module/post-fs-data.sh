#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR=/data/adb/bloatwareslayer
LOG_DIR="$CONFIG_DIR/logs"
BRICKED_STATUS="$CONFIG_DIR/bricked"
BS_LOG_FILE="$LOG_DIR/log_pfd_$(date +"%Y-%m-%d_%H-%M-%S").txt"
TARGET_LIST="$CONFIG_DIR/target.txt"
SYSTEM_APP_PATHS="/system/app /system/product/app /system/product/priv-app /system/priv-app /system/system_ext/app /system/system_ext/priv-app"
MODULE_PROP="$MODDIR/module.prop"

if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
fi

echo " " >> $BS_LOG_FILE
echo "Bloatware Slayer" >> $BS_LOG_FILE
echo "By Astoritin Ambrosius" >> $BS_LOG_FILE
echo "- Version: 1.0.3" >> $BS_LOG_FILE
echo "- current time stamp: $(date +"%Y-%m-%d %H:%M:%S")" >> $BS_LOG_FILE
echo "- Starting post-fs-data.sh..." >> $BS_LOG_FILE
echo "- LOG_DIR: $LOG_DIR" >> $BS_LOG_FILE
echo "- BS_LOG_FILE: $BS_LOG_FILE" >> $BS_LOG_FILE
echo "- TARGET_LIST: $TARGET_LIST" >> $BS_LOG_FILE
echo "- BRICKED_STATUS: $BRICKED_STATUS" >> $BS_LOG_FILE
echo "- MODULE_PROP: $MODULE_PROR" >> $BS_LOG_FILE

echo "- Removing old folders and .replace..." >> $BS_LOG_FILE
if [ -d "$MODDIR/system" ]; then
    rm -rf "$MODDIR/system"
    echo "- All clear!" >> $BS_LOG_FILE
else
    echo "! No old folders or .replace to remove!" >> $BS_LOG_FILE
fi

if [ -f "$BRICKED_STATUS" ]; then
    echo "- Detect bricked status!" >> $BS_LOG_FILE
    DESCRIPTION="[🚫Auto disabled from brick] 勝った、勝った、また勝ったぁっと！🎉✨"
    sed -i "/^description=/c\description=$DESCRIPTION" "$MODULE_PROP" || {
        echo "! Failed to update module.prop!" >> $BS_LOG_FILE
        echo "- Attempt to create disable Bloatware Slayer manually..." >> $BS_LOG_FILE
        touch "${MODDIR}/disable"
        if [ -f "${MODDIR}/disable" ]; then
            echo "- Created file disable." >> $BS_LOG_FILE
        else
            echo "! Failed to create disable file!" >> $BS_LOG_FILE
        fi
        exit 1
    }
    echo "- Updated module.prop done." >> $BS_LOG_FILE
    echo "- Skip post-fs-data.sh process..." >> $BS_LOG_FILE
    exit 1
else
    echo "Bricked status file not exist, keep going..." >> $BS_LOG_FILE
fi

if [ ! -f "$TARGET_LIST" ]; then
    echo "! Target list file ($TARGET_LIST) does not exist!" >> $BS_LOG_FILE
    exit 1
fi

TOTAL_APPS_COUNT=0
BLOCKED_APPS_COUNT=0
while IFS= read -r package; do
    package=$(echo "$package" | tr -d '\r')
 #   echo "- current line: $package" >> $BS_LOG_FILE
    if [ -z "$package" ]; then
        echo "- Detect empty line, skip processing" >> $BS_LOG_FILE
        continue
    elif [ "${package:0:1}" == "#" ]; then
        echo '- Detect comment symbol "#", skip processing' >> $BS_LOG_FILE
        continue
    fi
    echo "- Processing package: $package" >> $BS_LOG_FILE
    TOTAL_APPS_COUNT=$((TOTAL_APPS_COUNT+1))
    for path in $SYSTEM_APP_PATHS; do
        app_path="$path/$package"
        echo "- Checking dir: $app_path" >> $BS_LOG_FILE
        if [ -d "$app_path" ]; then
            if [ "$KSU" ] || [ "$APATCH" ]; then
                mknod "$MODDIR/$app_path" c 0 0
                echo "- Set mknod for $app_path" >> $BS_LOG_FILE
                BLOCKED_APPS_COUNT=$((BLOCKED_APPS_COUNT + 1))
                break
            else
                mkdir -p "$MODDIR/$app_path"
                touch "$MODDIR/$app_path/.replace"
                echo "- Created .replace file for $app_path" >> $BS_LOG_FILE
                BLOCKED_APPS_COUNT=$((BLOCKED_APPS_COUNT + 1))
                break
            fi
        else
            echo "- dir not found: $app_path" >> $BS_LOG_FILE
        fi
    done
done < "$TARGET_LIST"

APP_NOT_FOUND=$((TOTAL_APPS_COUNT - BLOCKED_APPS_COUNT))
echo "- $TOTAL_APPS_COUNT App(s) in total" >> $BS_LOG_FILE
echo "- Processed $BLOCKED_APPS_COUNT App(s)" >> $BS_LOG_FILE
echo "- $APP_NOT_FOUND App(s) are not found" >> $BS_LOG_FILE

if [ -f "$MODULE_PROP" ]; then
    if [ $BLOCKED_APPS_COUNT -gt 0 ]; then
        DESCRIPTION="[🎯$TOTAL_APPS_COUNT App(s) WANTED 😋$BLOCKED_APPS_COUNT App(s) SLAIN 👀$APP_NOT_FOUND App(s) MISSED] 勝った、勝った、また勝ったぁっと！🎉✨"
    else
        if [ $TOTAL_APPS_COUNT -gt 0]; then
            DESCRIPTION="[🎯$TOTAL_APPS_COUNT App(s) WANTED 😴No targets today...] 勝った、勝った、また勝ったぁっと！🎉✨"
        else
            DESCRIPTION="[❌Abnormal status] 勝った、勝った、また勝ったぁっと！🎉✨"
        fi
    fi
    sed -i "/^description=/c\description=$DESCRIPTION" "$MODULE_PROP" || {
        echo "- Failed to update module.prop. Please check permissions." >> $BS_LOG_FILE
        exit 1
    }
    echo "- Updated module.prop with blocked app count: $DESCRIPTION" >> $BS_LOG_FILE
else
    echo "- module.prop not found. Skip updating." >> $BS_LOG_FILE
fi

echo "- post-fs-data.sh case closed!" >> $BS_LOG_FILE
echo "- All done!" >> $BS_LOG_FILE
echo " " >> $BS_LOG_FILE
