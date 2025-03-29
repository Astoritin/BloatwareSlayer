#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR="/data/adb/bloatwareslayer"

CONFIG_FILE="$CONFIG_DIR/settings.conf"
BRICKED_STATUS="$CONFIG_DIR/bricked"
TARGET_LIST="$CONFIG_DIR/target.conf"
TARGET_LIST_BSA="$CONFIG_DIR/logs/target_bsa.conf"
LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/bs_log_core_$(date +"%Y-%m-%d_%H-%M-%S").log"

MODULE_PROP="$MODDIR/module.prop"
MOD_NAME="$(sed -n 's/^name=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_AUTHOR="$(sed -n 's/^author=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_VER="$(sed -n 's/^version=\(.*\)/\1/p' "$MODULE_PROP") ($(sed -n 's/^versionCode=\(.*\)/\1/p' "$MODULE_PROP"))"

EMPTY_DIR="$CONFIG_DIR/empty"
MIRROR_DIR="$MODDIR/system"

UPDATE_TARGET_LIST=true
AUTO_UPDATE_TARGET_LIST=true
DISABLE_MODULE_AS_BRICK=true
SLAY_MODE="MB"

SYSTEM_APP_PATHS="/system/app /system/product/app /system/product/data-app /system/product/priv-app /system/priv-app /system/system_ext/app /system/system_ext/priv-app /system/vendor/app /system/vendor/priv-app"

brick_rescue() {
    # brick_rescue: a function to execute brick rescue method to save the device from being "bricked" by Bloatware Slayer itself
    # WARN: It won't conflict with other brick rescue method
    # but this in-built method is for correcting the bricked by Bloatware Slayer itself  
    # if the bricked is caused by other modules / behaviors, Bloatware Slayer has nothing to do with it
    #
    # BRICKED_STATUS: a empty file with a filename "bricked" located in /data/adb/bloatwareslayer
    # if detecting /data/adb/bloatwareslayer/bricked, module will skip mounting to prevent from being bricked by Bloatware Slayer itself

    logowl "Checking brick status"

    if [ -f "$BRICKED_STATUS" ]; then
        logowl "Detect flag bricked!" "FATAL"
        if [ "$DISABLE_MODULE_AS_BRICK" = "true" ] && [ ! -f "$MODDIR/disable" ]; then
            logowl "Detect flag DISABLE_MODULE_AS_BRICK=true"
            logowl "But module itself has NOT been disabled"
            logowl "Maybe $MOD_NAME is enabled by user manually"
            logowl "Reset brick status"
            rm -f "$BRICKED_STATUS"
            logowl "$MOD_NAME will keep going"
            return 0
        else
            logowl "Starting brick rescue"
            logowl "Skip post-fs-data.sh process"
            DESCRIPTION="[❌Disabled. Auto disable from brick! ⭐Root: $ROOT_SOL] A Magisk module to remove bloatware in systemlessly way✨"
            update_module_description "$DESCRIPTION" "$MODULE_PROP"
            logowl "Skip mounting"
            exit 1
        fi
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
    disable_module_as_brick=$(init_variables "disable_module_as_brick" "$CONFIG_FILE")
    slay_mode=$(init_variables "slay_mode" "$CONFIG_FILE")

    verify_variables "auto_update_target_list" "$auto_update_target_list" "^(true|false)$"
    verify_variables "system_app_paths" "$system_app_paths" "^/system/[^/]+(/[^/]+)*$"
    verify_variables "disable_module_as_brick" "$disable_module_as_brick" "^(true|false)$"
    verify_variables "slay_mode" "$slay_mode" "^(MB|MN|MR)$"

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

    logowl "Some preparations"

    if [ -n "$MODDIR" ] && [ -d "$MIRROR_DIR" ]; then
        logowl "Remove old mirror folder"
        rm -rf "$MIRROR_DIR"
    fi
    if [ -n "$MODDIR" ] && [ -d "$EMPTY_DIR" ]; then
        logowl "Remove old empty folder"
        rm -rf "$EMPTY_DIR"
    fi

    if [ "$SLAY_MODE" = "MN" ]; then
        if [ -n "$KSU" ] || [ -n "$APATCH" ]; then
            logowl "Detect $MOD_NAME running on KernelSU / APatch, which supports Make Node mode"
        elif [ -n "$MAGISK_V_VER_CODE" ]; then
            if [ $MAGISK_V_VER_CODE -ge 28102 ]; then
                logowl "Detect $MOD_NAME running on Magisk 28102+, which supports Make Node mode"
            else
                logowl "Make Node mode needs Magisk version 28102 or higher (current $MAGISK_V_VER_CODE)!" "ERROR"
                logowl "$MOD_NAME will revert to Magisk Replace mode"
                SLAY_MODE="MR"
            fi
        else
            logowl "Make Node mode needs Magisk 28102+, KernelSU or APatch!" "ERROR"
            SLAY_MODE="MB"
        fi
    elif [ "$SLAY_MODE" = "MR" ]; then
        if [ -n "$KSU" ] || [ -n "$APATCH" ]; then
            logowl "Magisk Replace mode is NOT available as $MOD_NAME running on KernelSU / APatch!" "ERROR"
            logowl "Please use Magisk if you try to use Magisk Replace mode!"
            SLAY_MODE="MN"
        fi
    fi

    case "$SLAY_MODE" in
        MB)
            MODE_MOD="Mount Bind"
            logowl "Create $EMPTY_DIR"
            mkdir -p "$EMPTY_DIR"
            logowl "Set permissions"
            chmod 0755 "$EMPTY_DIR"
            ;;
        MN|MR)
            if [ "$SLAY_MODE" = "MN" ]; then
                MODE_MOD="Make Node"
            elif [ "$SLAY_MODE" = "MR" ]; then
                MODE_MOD="Magisk Replace"
            fi
            logowl "Create $MIRROR_DIR"
            mkdir -p "$MIRROR_DIR"
            logowl "Set permissions"
            chmod 0755 "$MIRROR_DIR"
            ;;
        *)
            MODE_MOD="Unknown"
            logowl "Unknown mode: $SLAY_MODE" "ERROR"
            ;;
    esac
    logowl "Current mode: $SLAY_MODE ($MODE_MOD)"


    if [ ! -f "$TARGET_LIST" ]; then
        logowl "Target list does NOT exist!" "FATAL"
        DESCRIPTION="[❌No effect. Target list does NOT exist! ⭐Root: $ROOT_SOL] A Magisk module to remove bloatware in systemlessly way✨"
        update_module_description "$DESCRIPTION" "$MODULE_PROP"
        return 1
    fi

    if [ -f "$TARGET_LIST_BSA" ] && [ "$AUTO_UPDATE_TARGET_LIST" = "true" ]; then
        logowl "Target list ($MOD_NAME Arranged) file already exists"
        logowl "Detect flag AUTO_UPDATE_TARGET_LIST=true"
        if file_compare "$TARGET_LIST" "$TARGET_LIST_BSA"; then
            logowl "Detect no changes"
            UPDATE_TARGET_LIST=false
        else
            logowl "Detect changes"
            UPDATE_TARGET_LIST=true
        fi
    fi

    if [ "$UPDATE_TARGET_LIST" = true ] && [ "$AUTO_UPDATE_TARGET_LIST" = "true" ]; then
        TARGET_LIST_BSA_HEADER="# $MOD_NAME $MOD_VER
# Generate timestamp: $(date +"%Y-%m-%d %H:%M:%S")
# This file is generated by $MOD_NAME automatically
# only to save the paths of the found APP(s)
# This file will sync the items into target.conf automatically by default"
        touch "$TARGET_LIST_BSA"
        echo -e "$TARGET_LIST_BSA_HEADER\n" > "$TARGET_LIST_BSA"
    fi

}

bloatware_slayer() {
    # bloatware_slayer: the core function for bloatware slayer

    logowl "Slaying bloatwares"

    TOTAL_APPS_COUNT=0
    BLOCKED_APPS_COUNT=0
    lines_count=0

    while IFS= read -r line; do

        lines_count=$((lines_count + 1))

        if check_value_safety "line $lines_count" "$line"; then
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
                if [ "$SLAY_MODE" = "MB" ]; then
                    logowl "Execute mount -o bind $EMPTY_DIR $app_path"
                    mount -o bind "$EMPTY_DIR" "$app_path"
                    result_mount_bind=$?
                    if [ $result_mount_bind -eq 0 ]; then
                        logowl "Succeeded (code: $result_mount_bind)"
                        BLOCKED_APPS_COUNT=$((BLOCKED_APPS_COUNT + 1))
                        if [ "$UPDATE_TARGET_LIST" = true ] && [ "$AUTO_UPDATE_TARGET_LIST" = "true" ]; then
                            echo "$app_path" >> "$TARGET_LIST_BSA"
                        fi
                        break
                    else
                        logowl "Failed to mount: $app_path (code: $result_mount_bind)" "ERROR"
                    fi
                elif [ "$SLAY_MODE" = "MN" ]; then
                    app_path_parent_dir=$(dirname "$app_path")
                    mirror_parent_dir="${MODDIR}${app_path_parent_dir}"
                    mirror_app_path="${MODDIR}${app_path}"
                    logowl "Create parent path: $mirror_parent_dir"
                    mkdir -p "$mirror_parent_dir"
                    logowl "Execute mknod $mirror_app_path c 0 0"
                    mknod "$mirror_app_path" c 0 0
                    result_make_node="$?"
                    if [ $result_make_node -eq 0 ]; then
                        logowl "Succeeded (code: $result_make_node)"
                        BLOCKED_APPS_COUNT=$((BLOCKED_APPS_COUNT + 1))
                        if [ "$UPDATE_TARGET_LIST" = true ] && [ "$AUTO_UPDATE_TARGET_LIST" = "true" ]; then
                            echo "$app_path" >> "$TARGET_LIST_BSA"
                        fi
                        break
                    else
                        logowl "Failed to make node: $mirror_app_path (code: $result_make_node)" "ERROR"
                    fi
                elif [ "$SLAY_MODE" = "MR" ]; then
                    mirror_app_path="${MODDIR}${app_path}"
                    logowl "Create mirror path: $mirror_app_path"
                    mkdir -p "$mirror_app_path"
                    logowl "Execute touch $mirror_app_path/.replace"
                    touch "$mirror_app_path/.replace"
                    result_touch_replace="$?"
                    if [ $result_touch_replace -eq 0 ]; then
                        logowl "Succeeded (code: $result_touch_replace)"
                        BLOCKED_APPS_COUNT=$((BLOCKED_APPS_COUNT + 1))
                        if [ "$UPDATE_TARGET_LIST" = true ] && [ "$AUTO_UPDATE_TARGET_LIST" = "true" ]; then
                            echo "$app_path" >> "$TARGET_LIST_BSA"
                        fi
                        break
                    else
                        logowl "Failed to touch .replace: $mirror_app_path (code: $result_touch_replace)" "ERROR"
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
        logowl "Updating target list"
        cp -p "$TARGET_LIST_BSA" "$TARGET_LIST"
        chmod 0644 "$TARGET_LIST_BSA"
        chmod 0644 "$TARGET_LIST"
    fi
}

module_status_update() {
    # module_status_update: a function to update module status according to the result in function bloatware_slayer
    # TOTAL_APPS_COUNT: the count of all the APPs in target.conf
    # BLOCKED_APPS_COUNT: the count of the APPs being blocked by Bloatware Slayer successfully
    # APP_NOT_FOUND: the count of the APPs not found or failed to block

    logowl "Updating module status"

    APP_NOT_FOUND=$((TOTAL_APPS_COUNT - BLOCKED_APPS_COUNT))
    logowl "$TOTAL_APPS_COUNT APP(s) in total"
    logowl "$BLOCKED_APPS_COUNT APP(s) slain"
    logowl "$APP_NOT_FOUND APP(s) not found"

    if [ -f "$MODULE_PROP" ]; then
        if [ $BLOCKED_APPS_COUNT -gt 0 ]; then
                DESCRIPTION="[😋Enabled. $BLOCKED_APPS_COUNT APP(s) slain, $APP_NOT_FOUND APP(s) missing, $TOTAL_APPS_COUNT APP(s) targeted in total, ⚡Mode: $MODE_MOD, ⭐Root: $ROOT_SOL] 勝った、勝った、また勝ったぁーっと！！🎉✨"
            if [ $APP_NOT_FOUND -eq 0 ]; then
                DESCRIPTION="[😋Enabled. $BLOCKED_APPS_COUNT APP(s) slain. All targets neutralized! ⚡Mode: $MODE_MOD, ⭐Root: $ROOT_SOL] 勝った、勝った、また勝ったぁーっと！！🎉✨"
            fi
        else
            if [ $TOTAL_APPS_COUNT -gt 0 ]; then
                DESCRIPTION="[😋No effect. No APP slain yet, $TOTAL_APPS_COUNT APP(s) targeted in total, ⚡Mode: $MODE_MOD, ⭐Root: $ROOT_SOL] 勝った、勝った、また勝ったぁーっと！！🎉✨"
            else
                logowl "Current blocked apps count: $TOTAL_APPS_COUNT <= 0" "ERROR"
                DESCRIPTION="[❌No effect. Abnormal status! ⚡Mode: $MODE_MOD, ⭐Root: $ROOT_SOL] A Magisk module to remove bloatware in systemlessly way✨"
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
logowl "post-fs-data.sh case closed!"
