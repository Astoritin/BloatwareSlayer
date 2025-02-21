#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR=/data/adb/bloatwareslayer
BS_LOG_FILE="$CONFIG_DIR/logs/log_$(date +"%Y-%m-%d_%H-%M-%S").txt"
TARGET_LIST="$CONFIG_DIR/target.txt"
SYSTEM_APP_PATHS="/system/app /system/product/app /system/product/priv-app /system/priv-app /system/system_ext/app /system/system_ext/priv-app"
MODULE_PROP="$MODDIR/module.prop"

echo " " >> $BS_LOG_FILE
echo "Bloatware Slayer" >> $BS_LOG_FILE
echo "By Astoritin Ambrosius" >> $BS_LOG_FILE
echo "- Version: 1.0.1" >> $BS_LOG_FILE
echo "- current time stamp: $(date +"%Y-%m-%d %H:%M:%S")" >> $BS_LOG_FILE
echo "- Starting post-fs-data.sh..." >> $BS_LOG_FILE
echo "- Removing old folders and .replace..." >> $BS_LOG_FILE
if [ -d "$MODDIR/system" ]; then
    rm -rf "$MODDIR/system"
    echo "- All clear!" >> $BS_LOG_FILE
else
    echo "- No old folders or .replace to remove." >> $BS_LOG_FILE
fi

TOTAL_APPS_COUNT=0
BLOCKED_APPS_COUNT=0
while IFS= read -r package; do
    package=$(echo "$package" | tr -d '\r')
    echo "- current line: $package" >> $BS_LOG_FILE
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
if [ -f "$MODULE_PROP" ]; then
    if [ $BLOCKED_APPS_COUNT -gt 0 ]; then
        DESCRIPTION="[$TOTAL_APPS_COUNT App(s) in target list, $APP_NOT_FOUND App(s) not found, $BLOCKED_APPS_COUNT App(s) blocked 😋] Remove junk bloatware in systemless way✨"
    else
        DESCRIPTION="[$TOTAL_APPS_COUNT App(s) in target list, No App(s) blocked yet 🧐] Remove junk bloatware in systemless way✨"
    fi

    sed -i "/^description=/c\description=$DESCRIPTION" "$MODULE_PROP" || {
        echo "- Failed to update module.prop. Please check permissions." >> "$BS_LOG_FILE"
        exit 1
    }
    echo "- Updated module.prop with blocked app count: $DESCRIPTION" >> "$BS_LOG_FILE"
else
    echo "- module.prop not found. Skip updating." >> "$BS_LOG_FILE"
fi

echo "- Processed $BLOCKED_APPS_COUNT APP(s)" >> $BS_LOG_FILE
echo "- post-fs-data.sh case closed!" >> $BS_LOG_FILE
echo "- All done!" >> $BS_LOG_FILE
echo " " >> $BS_LOG_FILE