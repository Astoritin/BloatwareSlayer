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
MOD_ROOT_DIR=$(dirname "$MODDIR")

EMPTY_DIR="$CONFIG_DIR/empty"
MIRROR_DIR="$MODDIR/system"

UPDATE_TARGET_LIST=true
AUTO_UPDATE_TARGET_LIST=true
DISABLE_MODULE_AS_BRICK=true
SLAY_MODE="MB"

SYSTEM_APP_PATHS="/system/app /system/product/app /system/product/data-app /system/product/priv-app /system/priv-app /system/system_ext/app /system/system_ext/priv-app /system/vendor/app /system/vendor/priv-app"

brick_rescue() {

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
            DESCRIPTION="[❌Disabled. Auto disable from brick! 🧭Root: $ROOT_SOL] A Magisk module to remove bloatware in systemless way"
            update_config_value "description" "$DESCRIPTION" "$MODULE_PROP"
            logowl "Skip mounting"
            exit 1
        fi
    else
        logowl "Flag bricked does NOT detect"
        logowl "$MOD_NAME will keep going"
    fi
}

config_loader() {

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

    logowl "Some preparations"

    if [ -n "$MODDIR" ] && [ -d "$MODDIR" ] && [ "$MODDIR" != "/" ] && [ -d "$MIRROR_DIR" ]; then
        logowl "Remove old mirror folder"
        rm -rf "$MIRROR_DIR"
    fi
    if [ -n "$MODDIR" ] && [ -d "$MODDIR" ] && [ "$MODDIR" != "/" ] && [ -d "$EMPTY_DIR" ]; then
        logowl "Remove old empty folder"
        rm -rf "$EMPTY_DIR"
    fi

    if [ "$SLAY_MODE" = "MN" ]; then
        if is_kernelsu || is_apatch; then
            logowl "Detect $MOD_NAME running on KernelSU / APatch, which supports Make Node mode"
        elif is_magisk; then
            if [ $MAGISK_V_VER_CODE -ge 28102 ]; then
                logowl "Detect $MOD_NAME running on Magisk 28102+, which supports Make Node mode"
            else
                logowl "Make Node mode needs Magisk version 28102 and higher (current $MAGISK_V_VER_CODE)!" "ERROR"
                logowl "$MOD_NAME will revert to Magisk Replace mode"
                SLAY_MODE="MR"
            fi
        else
            logowl "Make Node mode needs Magisk 28102+, KernelSU or APatch!" "ERROR"
            logowl "$MOD_NAME will revert to Mount Bind mode"
            SLAY_MODE="MB"
        fi
    elif [ "$SLAY_MODE" = "MR" ]; then
        if is_kernelsu || is_apatch; then
            logowl "Magisk Replace mode is NOT available as $MOD_NAME running on KernelSU / APatch!" "ERROR"
            logowl "Please use Magisk if you try to use Magisk Replace mode!"
            logowl "$MOD_NAME will revert to Make Node mode"
            SLAY_MODE="MN"
        fi
    fi

    if [ "$ROOT_SOL_COUNT" -gt 1 ]; then
        logowl "Detect multiple root solutions!" "WARN"
        logowl "Using multiple root solutions is NOT a healthy way"
        logowl "Please keep using one root solution ONLY if no need!"
        logowl "$MOD_NAME will revert to mount bind mode for multiple root solutions" "WARN"
        SLAY_MODE="MB"
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
        DESCRIPTION="[❌No effect. Target list does NOT exist! 🧭Root: $ROOT_SOL] A Magisk module to remove bloatware in systemless way"
        update_config_value "description" "$DESCRIPTION" "$MODULE_PROP"
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
                    /system/apex*)
                        logowl "Detect apex dir"
                        app_path=$(echo "$app_path" | sed -n 's|^/system/apex/\(.*\)/.*|\1|p')
                        ;;
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

    logowl "Updating module status"

    APP_NOT_FOUND=$((TOTAL_APPS_COUNT - BLOCKED_APPS_COUNT))
    logowl "$TOTAL_APPS_COUNT APP(s) in total"
    logowl "$BLOCKED_APPS_COUNT APP(s) slain"
    logowl "$APP_NOT_FOUND APP(s) not found"

    if [ -f "$MODULE_PROP" ]; then
        if [ $BLOCKED_APPS_COUNT -gt 0 ]; then
                DESCRIPTION="[✅Enabled. $BLOCKED_APPS_COUNT APP(s) slain, $APP_NOT_FOUND APP(s) missing, $TOTAL_APPS_COUNT APP(s) targeted in total, 🤖Mode: $MODE_MOD, 🧭Root: $ROOT_SOL] Victoire sur victoire ! Hourra !"
            if [ $APP_NOT_FOUND -eq 0 ]; then
                DESCRIPTION="[✅Enabled. $BLOCKED_APPS_COUNT APP(s) slain. All targets neutralized! 🤖Mode: $MODE_MOD, 🧭Root: $ROOT_SOL] Victoire sur victoire ! Hourra !"
            fi
        else
            if [ $TOTAL_APPS_COUNT -gt 0 ]; then
                DESCRIPTION="[✅No effect. No APP slain yet, $TOTAL_APPS_COUNT APP(s) targeted in total, 🤖Mode: $MODE_MOD, 🧭Root: $ROOT_SOL] Victoire sur victoire ! Hourra !"
            else
                logowl "Current blocked apps count: $TOTAL_APPS_COUNT <= 0" "ERROR"
                DESCRIPTION="[❌No effect. Abnormal status! 🤖Mode: $MODE_MOD, 🧭Root: $ROOT_SOL] A Magisk module to remove bloatware in systemless way"
            fi
        fi
        update_config_value "description" "$DESCRIPTION" "$MODULE_PROP"
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
logowl "post-fs-data.sh case closed!"
