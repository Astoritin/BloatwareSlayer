#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR=/data/adb/bloatwareslayer
LOG_DIR="$CONFIG_DIR/logs"
BRICKED_STATUS="$CONFIG_DIR/bricked"
TARGET_LIST="$CONFIG_DIR/target.txt"
EMPTY_DIR="$CONFIG_DIR/empty"
BS_LOG_FILE="$LOG_DIR/log_$(date +"%Y-%m-%d_%H-%M-%S")_pfd.txt"
SYSTEM_APP_PATHS="/system/app /system/product/app /system/product/priv-app /system/priv-app /system/system_ext/app /system/system_ext/priv-app"
MODULE_PROP="$MODDIR/module.prop"

. "$MODDIR/aautilities.sh"

if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
fi
ROOT_IMP=$(cat "$CONFIG_DIR/root.txt")
if [ ! -f "$CONFIG_DIR/root.txt" ]; then
    enforce_install_from_magisk_app "$CONFIG_DIR"
    ROOT_IMP=$(cat "$CONFIG_DIR/root.txt")
fi

echo "Bloatware Slayer" >> $BS_LOG_FILE
echo "By Astoritin Ambrosius" >> $BS_LOG_FILE
echo "- Version: 1.0.3" >> $BS_LOG_FILE
echo "- Current time stamp: $(date +"%Y-%m-%d %H:%M:%S")" >> $BS_LOG_FILE
echo "- Starting post-fs-data.sh..." >> $BS_LOG_FILE
echo "- LOG_DIR: $LOG_DIR" >> $BS_LOG_FILE
echo "- BS_LOG_FILE: $BS_LOG_FILE" >> $BS_LOG_FILE
echo "- TARGET_LIST: $TARGET_LIST" >> $BS_LOG_FILE
echo "- BRICKED_STATUS: $BRICKED_STATUS" >> $BS_LOG_FILE
echo "- MODULE_PROP: $MODULE_PROP" >> $BS_LOG_FILE

echo "- Removing old folders and .replace..." >> $BS_LOG_FILE
if [ -d "$MODDIR/system" ]; then
    rm -rf "$MODDIR/system"
    echo "- All clear!" >> $BS_LOG_FILE
else
    echo "! No old folders or .replace to remove!" >> $BS_LOG_FILE
fi

if [ -f "$BRICKED_STATUS" ]; then
    echo "- Detect bricked status!" >> $BS_LOG_FILE
    DESCRIPTION="[❌Disabled. 🚫Auto disabled from brick! 💡Root:$ROOT_IMP] 勝った、勝った、また勝ったぁーっと！！🎉✨"
    sed -i "/^description=/c\description=$DESCRIPTION" "$MODULE_PROP" || {
        echo "! Failed to update module.prop!" >> $BS_LOG_FILE
        echo "- Attempt to create disable manually..." >> $BS_LOG_FILE
        touch "${MODDIR}/disable"
        if [ -f "${MODDIR}/disable" ]; then
            echo '- Create file "disable"' >> $BS_LOG_FILE
        else
            echo '! Failed to create file "disable"!' >> $BS_LOG_FILE
        fi
        exit 1
    }
    echo "- Update module.prop" >> $BS_LOG_FILE
    echo "- Skip post-fs-data.sh process" >> $BS_LOG_FILE
    exit 1
else
    echo "- Not bricked, keep going" >> $BS_LOG_FILE
fi

if [ ! -f "$TARGET_LIST" ]; then
    echo "! Target list does not exist!" >> $BS_LOG_FILE
    exit 1
fi

if [ ! -d "$EMPTY_DIR" ]; then
    echo "- Create $EMPTY_DIR" >> $BS_LOG_FILE
    mkdir -p "$EMPTY_DIR" >> $BS_LOG_FILE
fi 

TOTAL_APPS_COUNT=0
BLOCKED_APPS_COUNT=0
while IFS= read -r package; do
    package=$(echo "$package" | tr -d '\r')
    echo "- Current line: $package" >> $BS_LOG_FILE
    if [ -z "$package" ]; then
        echo "- Detect empty line, skip processing" >> $BS_LOG_FILE
        continue
    elif [ "${package:0:1}" == "#" ]; then
        echo '- Detect comment symbol "#", skip processing' >> $BS_LOG_FILE
        continue
    fi
    echo "- Process App: $package" >> $BS_LOG_FILE
    TOTAL_APPS_COUNT=$((TOTAL_APPS_COUNT+1))
    for path in $SYSTEM_APP_PATHS; do
        app_path="$path/$package"
        echo "- Checking dir: $app_path" >> $BS_LOG_FILE
        if [ -d "$app_path" ]; then
            echo "- Create $MODDIR/$app_path" >> $BS_LOG_FILE
            mkdir -p "$MODDIR/$app_path" >> $BS_LOG_FILE
            if [ -n "$KSU" ] || [ -n "$APATCH" ]; then
                echo "- Execute mount -o bind $EMPTY_DIR $app_path" >> $BS_LOG_FILE
                mount -o bind "$EMPTY_DIR" "$app_path"
                if [ $? -eq 0 ]; then
                    echo "- Succeeded." >> $BS_LOG_FILE
                else
                    echo "- Failed, error code: $?" >> $BS_LOG_FILE
                fi
                BLOCKED_APPS_COUNT=$((BLOCKED_APPS_COUNT + 1))
                break
            else
                touch "$MODDIR/$app_path/.replace"
                echo "- Create .replace file for $app_path" >> $BS_LOG_FILE
                BLOCKED_APPS_COUNT=$((BLOCKED_APPS_COUNT + 1))
                break
            fi
        else
            echo "- Dir not found: $app_path" >> $BS_LOG_FILE
        fi
    done
done < "$TARGET_LIST"

APP_NOT_FOUND=$((TOTAL_APPS_COUNT - BLOCKED_APPS_COUNT))
echo "- $TOTAL_APPS_COUNT APP(s) in total" >> $BS_LOG_FILE
echo "- $BLOCKED_APPS_COUNT APP(s) slain" >> $BS_LOG_FILE
echo "- $APP_NOT_FOUND APP(s) not found" >> $BS_LOG_FILE

if [ -f "$MODULE_PROP" ]; then
    if [ $BLOCKED_APPS_COUNT -gt 0 ]; then
        DESCRIPTION="[✅Enabled. 😋Blocked:$BLOCKED_APPS_COUNT APP(s), 👀Not found:$APP_NOT_FOUND APP(s), 📄Targeted:$TOTAL_APPS_COUNT APP(s), 💡Root:$ROOT_IMP] 勝った、勝った、また勝ったぁーっと！！🎉✨"
    else
        if [ $TOTAL_APPS_COUNT -gt 0]; then
            DESCRIPTION="[✅Enabled. ⭕No APP blocked yet, 📄Targeted:$TOTAL_APPS_COUNT APP(s), 💡Root:$ROOT_IMP] 勝った、勝った、また勝ったぁーっと！！🎉✨"
        else
            DESCRIPTION="[❌Disabled. 🤯Abnormal status! 💡Root:$ROOT_IMP] 勝った、勝った、また勝ったぁーっと！！🎉✨"
        fi
    fi
    sed -i "/^description=/c\description=$DESCRIPTION" "$MODULE_PROP" || {
        echo "- Failed to update module.prop" >> $BS_LOG_FILE
        exit 1
    }
    echo "- Update module.prop:$DESCRIPTION" >> $BS_LOG_FILE
else
    echo "- module.prop not found, skip updating" >> $BS_LOG_FILE
fi

echo "- post-fs-data.sh case closed!" >> $BS_LOG_FILE
echo "- All done!" >> $BS_LOG_FILE
