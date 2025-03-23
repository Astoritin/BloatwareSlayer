#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR="/data/adb/bloatwareslayer"

CONFIG_FILE="$CONFIG_DIR/settings.conf"
BRICKED_STATUS="$CONFIG_DIR/bricked"
EMPTY_DIR="$CONFIG_DIR/empty"
TARGET_LIST="$CONFIG_DIR/target.conf"
TARGET_LIST_BSA="$CONFIG_DIR/logs/target_bsa.conf"
LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/bs_log_core_pfd_$(date +"%Y-%m-%d_%H-%M-%S").log"

MODULE_PROP="$MODDIR/module.prop"
MOD_NAME="$(sed -n 's/^name=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_AUTHOR="$(sed -n 's/^author=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_VER="$(sed -n 's/^version=\(.*\)/\1/p' "$MODULE_PROP") ($(sed -n 's/^versionCode=\(.*\)/\1/p' "$MODULE_PROP"))"

SLAY_MODE="auto"
UPDATE_TARGET_LIST=true
AUTO_UPDATE_TARGET_LIST=true

SYSTEM_APP_PATHS="/system/app /system/product/app /system/product/priv-app /system/priv-app /system/system_ext/app /system/system_ext/priv-app /system/vendor/app /system/vendor/priv-app"

brick_rescue() {
    # brick_rescue: a function to execute brick rescue method to save the device from being "bricked" by Bloatware Slayer itself
    # WARN: It won't conflict with other brick rescue method
    # but this in-built method is for correcting the bricked by Bloatware Slayer itself  
    # if the bricked is caused by other modules / behaviors, Bloatware Slayer has nothing to do with it
    #
    # BRICKED_STATUS: a empty file with a filename "bricked" located in /data/adb/bloatwareslayer
    # if detecting /data/adb/bloatwareslayer/bricked, module will skip mounting to prevent from being bricked by Bloatware Slayer itself
    
    if [ -f "$BRICKED_STATUS" ]; then
        logowl "Detect flag bricked!" "FATAL"
        logowl "Skip post-fs-data.sh process"
        DESCRIPTION="[❌Disabled. Auto disabled from brick! Root: $ROOT_SOL] A Magisk module to remove bloatware in systemlessly way 🎉✨"
        update_module_description "$DESCRIPTION" "$MODULE_PROP"
        logowl "Skip mounting"
        exit 1
    else
        logowl "Flag bricked does NOT detect"
        logowl "$MOD_NAME will keep going"
    fi
}

config_loader() {
    # config_loader: a function to load the config file saved in $CONFIG_FILE
    # the format of $CONFIG_FILE: value=key, one key-value pair per line
    # for system_app_paths, please keep in a line and separate the paths by a space

    logowl "Loading config"

    auto_update_target_list=$(init_variables "auto_update_target_list" "$CONFIG_FILE")
    system_app_paths=$(init_variables "system_app_paths" "$CONFIG_FILE")
    slay_mode=$(init_variables "slay_mode" "$CONFIG_FILE")

    verify_variables "auto_update_target_list" "$auto_update_target_list" "^(true|false)$"
    verify_variables "system_app_paths" "$system_app_paths" "^/system/[^/]+(/[^/]+)*$"
    verify_variables "slay_mode" "$slay_mode" "^(auto|empty|slay)$"

}

preparation() {
    # preparation: a function to initiate the directories and some other preparation steps
    #
    # $TARGET_LIST: the path of config file target.conf located in (/data/adb/bloatwareslayer/target.conf)
    # $TARGET_LIST_BSA: the path of config file target_bsa.conf located in (/tmp/target_bsa.conf)
    # $TARGET_LIST_BSA is generated and arranged by Bloatware Slayer itself, you shouldn't edit it and save the critical information here
    #
    # $AUTO_UPDATE_TARGET_LIST: a key in settings.conf to control the behavior whether updating target.conf to available paths only on each time booting.
    # true by default because it will change the target.conf into directories path to reduce the time of next time booting
    # If false, Bloatware Slayer will NOT update target.conf automatically
    #
    # $UPDATE_TARGET_LIST: different from $AUTO_UPDATE_TARGET_LIST, this boolean variable is for Bloatware Slayer itself (inner behavior) to judge whether need to update or not by checking the hashcode of $TARGET_LIST and $TARGET_LIST_BSA

    logowl "Start preparing something"
    touch -r "/system" "$LOG_DIR/timestamp_ref"

    # for mknod
    cleanup_and_create "$MODDIR/system"
    if [ -n "$MODDIR" ] && [ -d "$MODDIR/system" ]; then
        cleanup_and_create "$MODDIR/system" 755
    fi
    if [ -n "$MODDIR" ] && [ -d "$EMPTY_DIR" ]; then
        cleanup_and_create "$EMPTY_DIR" 755
    fi

    if [ ! -f "$TARGET_LIST" ]; then
        logowl "Target list does NOT exist!" "FATAL"
        DESCRIPTION="[❌Disabled. Target list does NOT exist! Root: $ROOT_SOL] A Magisk module to remove bloatware in systemlessly way🎉✨"
        update_module_description "$DESCRIPTION" "$MODULE_PROP"
        return 1
    fi

    if [ -f "$TARGET_LIST_BSA" ] && [ "$AUTO_UPDATE_TARGET_LIST" = "true" ]; then
        logowl "Target list ($MOD_NAME Arranged) file already exists"
        logowl "Detect flag AUTO_UPDATE_TARGET_LIST=true"
        if file_compare "$TARGET_LIST" "$TARGET_LIST_BSA"; then
            logowl "Files are identical, no changes detected"
            UPDATE_TARGET_LIST=false
        else
            logowl "Files are different, changes detected"
            UPDATE_TARGET_LIST=true
        fi
    fi

    if [ "$UPDATE_TARGET_LIST" = true ] && [ "$AUTO_UPDATE_TARGET_LIST" = "true" ]; then
        TARGET_LIST_BSA_HEADER="# $MOD_NAME $MOD_VER
# Generate timestamp: $(date +"%Y-%m-%d %H:%M:%S")
# This file is generated by $MOD_NAME automatically, only to save the paths of the found APP(s)
# This file will update target.conf automatically if don't want to tidy target.conf up manually"
    touch "$TARGET_LIST_BSA"
    echo -e "$TARGET_LIST_BSA_HEADER\n" > "$TARGET_LIST_BSA"
    fi

}

reset_timestamp() {
    rts_path="${1:-$MODDIR/system}"
    rts_timestamp="${2:-200901010000.00}"

    if [ -f "$timestamp_ref" ]; then
        find "$rts_path" -exec touch -r "$rts_timestamp" {} \;
    elif echo "$2" | grep -qE '^[0-9]+([.][0-9]+)?$'; then
        find "$rts_path" -exec touch -t "$rts_timestamp" {} \;
    else
        logowl "Failed: timestamp is not a valid value!" "ERROR"
    fi
}

bloatware_slayer() {
    # bloatware_slayer: the core function for bloatware slayer

    # check to use mount -o bind or mknod
    is_mknod="false"

    case "$SLAY_MODE" in
        "auto")
            if [ "$MAGISK_V_VER_CODE" -ge 28102 ] || [ "$KSU" ] || [ "$APatch" ]; then
                is_mknod="true"
            fi
            ;;
        "empty")
            is_mknod="false"
            ;;
        "slay")
            is_mknod="true"
            ;;
    esac

    TOTAL_APPS_COUNT=0
    BLOCKED_APPS_COUNT=0
    logowl "Start $MOD_NAME process"
    while IFS= read -r line; do
        if check_value_safety "target.conf" "$line"; then
            logowl "Current line: $line"
        else
            continue
        fi
        line=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        first_char=$(printf '%s' "$line" | cut -c1)
        if [ -z "$line" ]; then
            logowl "Detect empty line, skip processing" "TIPS"
            continue
        elif [ "$first_char" = "#" ]; then
            logowl 'Detect comment symbol "#", skip processing' "TIPS"
            continue
        fi

        package=$(echo "$line" | cut -d '#' -f1)
        package=$(echo "$package" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

        if [ -z "$package" ]; then
            logowl "Detect only comment contains in this line only, skip processing" "TIPS"
            continue
        fi

        case "$package" in
            *\\*)
                logowl "Replace '\\' with '/' in path: $package" "WARN"
                package=$(echo "$package" | sed -e 's/\\/\//g')
                ;;
        esac
        logowl "After processed: $package"
        TOTAL_APPS_COUNT=$((TOTAL_APPS_COUNT+1))
        for path in $SYSTEM_APP_PATHS; do
            first_char=$(printf '%s' "$line" | cut -c1)
            if [ "$first_char" = "/" ]; then
                app_path="$package"
                logowl "Detect custom dir: $app_path"
                case "$app_path" in
                    /system*)
                        ;;
                    *)
                        logowl "Unsupport custom path: $app_path" "WARN"
                        break
                        ;;
                esac
            else
                app_path="$path/$package"
            fi
            logowl "Checking dir: $app_path"
            if [ -d "$app_path" ]; then
                if [ "$is_mknod" = "true" ]; then
                    parent_dir=$(dirname "$app_path")
                    module_parent_dir="$MODDIR/$parent_dir"
                    logowl "Create parent path: $module_parent_dir"
                    mkdir -p "$module_parent_dir"

                    logowl "Execute mknod $app_path c 0 0"
                    mknod "$MODDIR/$app_path" c 0 0
                    result_mknod="$?"
                    logowl "Result: mknod (code: $result_chcon_p)"

                    # logowl "Fix SELinux context"
                    # chcon -R u:object_r:system_file:s0 "$parent_dir" 2>/dev/null
                    # result_chcon_p="$?"
                    # chcon -v u:object_r:system_file:s0 "$MODDIR/$app_path" 2>/dev/null
                    # result_chcon_a="$?"
                    # logowl "Result: chcon parent dir (code: $result_chcon_p), chcon app path (code: $result_chcon_a)"
                    
                    if [ $result_mknod -eq 0 ]; then
                        logowl "Succeeded"
                        BLOCKED_APPS_COUNT=$((BLOCKED_APPS_COUNT + 1))
                        if [ "$UPDATE_TARGET_LIST" = true ] && [ "$AUTO_UPDATE_TARGET_LIST" = "true" ]; then
                            echo "$app_path" >> "$TARGET_LIST_BSA"
                        fi
                        break
                    fi
                else
                    logowl "Execute mount -o bind $EMPTY_DIR $app_path"
                    mount -o bind "$EMPTY_DIR" "$app_path"
                    if [ $? -eq 0 ]; then
                        logowl "Succeeded"
                        BLOCKED_APPS_COUNT=$((BLOCKED_APPS_COUNT + 1))
                        if [ "$UPDATE_TARGET_LIST" = true ] && [ "$AUTO_UPDATE_TARGET_LIST" = "true" ]; then
                            echo "$app_path" >> "$TARGET_LIST_BSA"
                        fi
                        break
                    else
                        logowl "Failed to mount: $app_path, error code: $?" "ERROR"
                    fi
                fi
            else
                if [ "$first_char" = "/" ]; then
                    logowl "Custom dir not found: $app_path" "WARN"
                    break
                else
                    logowl "Dir not found: $app_path" "WARN"
                fi
            fi
        done
    done < "$TARGET_LIST"

    if [ "$UPDATE_TARGET_LIST" = "true" ] && [ "$AUTO_UPDATE_TARGET_LIST" = "true" ]; then
        logowl "Update target list" "TIPS"
        cp -p "$TARGET_LIST_BSA" "$TARGET_LIST"
        chmod 0644 "$TARGET_LIST_BSA"
        chmod 0644 "$TARGET_LIST"
    fi

    set_perm_recursive "$MODDIR" 0 0 0755 0644
    reset_timestamp "$MODDIR/system" "$LOG_DIR/timestamp_ref"
}

module_status_update() {
    # module_status_update: a function to update module status according to the result in function bloatware_slayer
    # TOTAL_APPS_COUNT: the count of all the APPs in target.conf
    # BLOCKED_APPS_COUNT: the count of the APPs being blocked by Bloatware Slayer successfully
    # APP_NOT_FOUND: the count of the APPs not found or failed to block

    APP_NOT_FOUND=$((TOTAL_APPS_COUNT - BLOCKED_APPS_COUNT))
    logowl "$TOTAL_APPS_COUNT APP(s) in total"
    logowl "$BLOCKED_APPS_COUNT APP(s) slain"
    logowl "$APP_NOT_FOUND APP(s) not found"

    if [ -f "$MODULE_PROP" ]; then
        if [ $BLOCKED_APPS_COUNT -gt 0 ]; then
            DESCRIPTION="[😋Enabled. $BLOCKED_APPS_COUNT APP(s) slain, $APP_NOT_FOUND APP(s) missing, $TOTAL_APPS_COUNT APP(s) targeted in total, Root: $ROOT_SOL] 勝った、勝った、また勝ったぁーっと！！🎉✨"
            if [ $APP_NOT_FOUND -eq 0 ]; then
            DESCRIPTION="[😋Enabled. $BLOCKED_APPS_COUNT APP(s) slain. All targets neutralized! Root: $ROOT_SOL] 勝った、勝った、また勝ったぁーっと！！🎉✨"
            fi
        else
            if [ $TOTAL_APPS_COUNT -gt 0 ]; then
                DESCRIPTION="[😋Enabled. No APP slain yet, $TOTAL_APPS_COUNT APP(s) targeted in total, Root: $ROOT_SOL] 勝った、勝った、また勝ったぁーっと！！🎉✨"
            else
                logowl "! Current blocked apps count: $TOTAL_APPS_COUNT <= 0"
                DESCRIPTION="[❌Disabled. Abnormal status! Root: $ROOT_SOL] A Magisk module to remove bloatware in systemlessly way🎉✨"
            fi
        fi
        update_module_description "$DESCRIPTION" "$MODULE_PROP"
    else
        logowl "module.prop not found, skip updating" "WARN"
    fi

}

. "$MODDIR/aautilities.sh"

init_logowl "$LOG_DIR"
module_intro >> "$LOG_FILE"
show_system_info >> "$LOG_FILE"
print_line
logowl "Starting post-fs-data.sh"
config_loader
print_line
brick_rescue
preparation
bloatware_slayer
module_status_update
logowl "Variables before case closed"
debug_print_values >> "$LOG_FILE"
print_line
logowl "post-fs-data.sh case closed!"
