#!/system/bin/sh
MODDIR=${0%/*}

TIMEOUT=300

CONFIG_DIR="/data/adb/bloatwareslayer"
BRICKED_STATUS="$CONFIG_DIR/bricked"
EMPTY_DIR="$CONFIG_DIR/empty"
TARGET_LIST="$CONFIG_DIR/target.txt"
LOG_DIR="$CONFIG_DIR/logs"
STATUS_DIR="$CONFIG_DIR/status.info"
BS_LOG_FILE="$LOG_DIR/bs_log_$(date +"%Y-%m-%d_%H-%M-%S").txt"

SYSTEM_APP_PATHS="/system/app /system/product/app /system/product/priv-app /system/priv-app /system/system_ext/app /system/system_ext/priv-app /system/vendor/app /system/vendor/priv-app"

MODULE_PROP="${MODDIR}/module.prop"
MOD_NAME="$(sed -n 's/^name=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_AUTHOR="$(sed -n 's/^author=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_VER="$(sed -n 's/^version=\(.*\)/\1/p' "$MODULE_PROP") ($(sed -n 's/^versionCode=\(.*\)/\1/p' "$MODULE_PROP"))"

if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
fi

. "$MODDIR/aautilities.sh"
install_env_check "$CONFIG_DIR"
ROOT_IMP=$(sed -n 's/^root=//p' "$CONFIG_DIR/status.info")

if [ -f "$BRICKED_STATUS" ]; then
    echo "- Detect flag bricked!"
    echo "- Skip service.sh process"
    DESCRIPTION="[❌ Disabled. Auto disabled from brick! Root: $ROOT_IMP] 勝った、勝った、また勝ったぁーっと！！🎉✨"
    sed -i "/^description=/c\description=$DESCRIPTION" "$MODULE_PROP"
    echo "- Update module.prop"
    echo "- Skip mounting..."
    rm -rf "$BRICKED_STATUS"
    if [ $? -eq 0 ]; then
        echo "- Bricked status cleared"
    else
        echo "! Failed to clear bricked status"
    fi
    return 1    
else
    echo "- Flag bricked does not detect"
    echo "- $MOD_NAME will keep going..."
fi

{
    echo "- Magisk Module Info"
    print_line
    echo "- $MOD_NAME"
    echo "- By $MOD_AUTHOR"
    echo "- Version: $MOD_VER"
    echo "- ROOT_IMP: $ROOT_IMP"
    echo "- Current time stamp: $(date +"%Y-%m-%d %H:%M:%S")"
    echo "- Starting service.sh..."
    print_line
    echo "- env Info"
    print_line
    env | sed 's/^/- /'
    print_line
    echo "- Start service"
    print_line

    if [ -f "${MODDIR}/disable" ]; then
        echo '- Detect file "disable", module is already disabled'
        echo "- Exiting service.sh..."
        return 1
    fi
    
    if [ ! -f "$TARGET_LIST" ]; then
        echo "! Target list does not exist!"
        DESCRIPTION="[❌ Disabled. Target list does not exist! Root: $ROOT_IMP] 勝った、勝った、また勝ったぁーっと！！🎉✨"
        sed -i "/^description=/c\description=$DESCRIPTION" "$MODULE_PROP"
        return 1
    fi
    
    if [ -d "$EMPTY_DIR" ]; then
        echo "- Detect $EMPTY_DIR existed"
        rm -rf "$EMPTY_DIR"
    fi
    echo "- Create $EMPTY_DIR"
    mkdir -p "$EMPTY_DIR"
    chmod 755 "$EMPTY_DIR"

    TOTAL_APPS_COUNT=0
    BLOCKED_APPS_COUNT=0
    while IFS= read -r package; do
        if [[ "$package" =~ \\ ]]; then
            echo "- Warning: Replaced '\\' with '/' in path: $package"
        fi
        package=$(echo "$package" | sed -e 's/^[[:space:]]*//' -e 's/\\/\//g')
        echo "- Current line: ${package:0:20}"
        if [ -z "$package" ]; then
            echo "- Warning: Detect empty line, skip processing"
            continue
        elif [ "${package:0:1}" == "#" ]; then
            echo '- Warning: Detect comment symbol "#", skip processing'
            continue
        fi
        echo "- Process App: $package"
        TOTAL_APPS_COUNT=$((TOTAL_APPS_COUNT+1))
        for path in $SYSTEM_APP_PATHS; do
            if [[ "${package:0:1}" == "/" ]]; then
                app_path="$package"
                if [[ ! "$app_path" =~ ^/system ]]; then
                    echo "- Warning: Unsupport custom path: $app_path"
                    break
                fi
                if [[ "${package:0:1}" == "/" ]]; then
                    echo "- Detect custom dir: $app_path"
                fi
            else
                app_path="$path/$package"
            fi
            echo "- Checking dir: $app_path"
            if [ -d "$app_path" ]; then
                echo "- Execute mount -o bind $EMPTY_DIR $app_path"
                mount -o bind "$EMPTY_DIR" "$app_path"
                if [ $? -eq 0 ]; then
                    echo "- Succeeded."
                else
                    echo "- Failed to mount: $app_path, error code: $?"
                fi
                BLOCKED_APPS_COUNT=$((BLOCKED_APPS_COUNT + 1))
                break
                if [[ "${package:0:1}" == "/" ]]; then
                    echo "- Warning: Custom dir not found: $app_path"
                    break
                else
                    echo "- Warning: Dir not found: $app_path"
                fi
            fi
        done
    done < "$TARGET_LIST"

    APP_NOT_FOUND=$((TOTAL_APPS_COUNT - BLOCKED_APPS_COUNT))
    echo "- $TOTAL_APPS_COUNT APP(s) in total"
    echo "- $BLOCKED_APPS_COUNT APP(s) slain"
    echo "- $APP_NOT_FOUND APP(s) not found"

    if [ -f "$MODULE_PROP" ]; then
        if [ $BLOCKED_APPS_COUNT -gt 0 ]; then
            DESCRIPTION="[❤️ Enabled. $BLOCKED_APPS_COUNT APP(s) slain, $APP_NOT_FOUND APP(s) missing, $TOTAL_APPS_COUNT APP(s) targeted in total, Root: $ROOT_IMP] 勝った、勝った、また勝ったぁーっと！！🎉✨"
        else
            if [ $TOTAL_APPS_COUNT -gt 0]; then
                DESCRIPTION="[❤️ Enabled. No APP slain yet, $TOTAL_APPS_COUNT APP(s) targeted in total, Root: $ROOT_IMP] 勝った、勝った、また勝ったぁーっと！！🎉✨"
            else
                echo "! Current blocked apps count: $TOTAL_APPS_COUNT <= 0"
                DESCRIPTION="[❌ Disabled. Abnormal status! Root: $ROOT_IMP] 勝った、勝った、また勝ったぁーっと！！🎉✨"
            fi
        fi
        if ! grep -q "^description=" "$CONFIG_DIR/status.info"; then
        echo "description=" >> "$CONFIG_DIR/status.info"
        fi
        sed -i "/^description=/c\description=$DESCRIPTION" "$MODULE_PROP"
        sed -i "/^description=/c\description=$DESCRIPTION" "$CONFIG_DIR/status.info"
        echo "- Update module.prop: $DESCRIPTION"
    else
        echo "- Warning: module.prop not found, skip updating"
    fi

}  >> $BS_LOG_FILE

{
    echo "- Current booting timeout: $TIMEOUT"
    while [ "$(getprop sys.boot_completed)" != "1" ]; do
        if [ $TIMEOUT -le "0" ]; then
            print_line
            echo "! Detect failed to boot after reaching the set limit!"
            echo "! Your device may be bricked by Bloatware Slayer!"
            echo "! Please make sure no improper APP(s) being blocked!"
            echo "- Mark status as bricked"
            touch "$BRICKED_STATUS"
            print_line
            echo "- Rebooting..."
            sync
            reboot
            sleep 5
            echo "- Reboot command did not take effect, exiting..."
            exit 1
        fi
        TIMEOUT=$((TIMEOUT-1))
        sleep 1
    done

    echo "- Boot complete! Final countdown: $TIMEOUT s"
    echo "- service.sh case closed!"
    print_line

    MOD_DESC_OLD=$(sed -n 's/^description=//p' "$STATUS_DIR")
    ROOT_IMP=$(sed -n 's/^root=//p' "$STATUS_DIR")
    MOD_LAST_STATUS=""
    MOD_CURRENT_STATUS=""
    MOD_REAL_TIME_DESC=""
    while true; do
        if [ -f "$MODDIR/remove" ]; then
            MOD_CURRENT_STATUS="remove"
        elif [ -f "$MODDIR/disable" ]; then
            MOD_CURRENT_STATUS="disable"
        else
            MOD_CURRENT_STATUS="enabled"
        fi
        if [ "$MOD_CURRENT_STATUS" != "$MOD_LAST_STATUS" ]; then
            echo "- Detect status changed:$MOD_LAST_STATUS -> $MOD_CURRENT_STATUS"
            if [ "$MOD_CURRENT_STATUS" == "remove" ]; then
                echo "- Detect module is set as remove"
                MOD_REAL_TIME_DESC="[🗑️ Remove (Reboot to take effect), Root: $ROOT_IMP] 勝った、勝った、また勝ったぁーっと！！🎉✨"
            elif [ "$MOD_CURRENT_STATUS" == "disable" ]; then
                echo "- Detect module is set as disable"
                MOD_REAL_TIME_DESC="[❌ Disable (Reboot to take effect), Root: $ROOT_IMP] 勝った、勝った、また勝ったぁーっと！！🎉✨"
            else
                echo "- Detect module is set as enabled"
                MOD_REAL_TIME_DESC="$MOD_DESC_OLD"
            fi
            sed -i "s/description=.*/description=$MOD_REAL_TIME_DESC/" "$MODDIR/module.prop"
            MOD_LAST_STATUS="$MOD_CURRENT_STATUS"
        fi
        sleep 3
    done
} >> $BS_LOG_FILE 2>&1 &
