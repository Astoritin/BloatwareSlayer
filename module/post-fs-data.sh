#!/system/bin/sh
MODDIR=${0%/*}

CONFIG_DIR="/data/adb/bloatwareslayer"
DEBUG=false

CONFIG_FILE="$CONFIG_DIR/settings.conf"
BRICKED_STATUS="$CONFIG_DIR/bricked"
TARGET_LIST="$CONFIG_DIR/target.conf"
LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/bs_core_$(date +"%Y-%m-%d_%H-%M-%S").log"
TARGET_LIST_BSA="$LOG_DIR/target_bsa.conf"

MODULE_PROP="$MODDIR/module.prop"
MOD_NAME="$(sed -n 's/^name=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_AUTHOR="$(sed -n 's/^author=\(.*\)/\1/p' "$MODULE_PROP")"
MOD_VER="$(sed -n 's/^version=\(.*\)/\1/p' "$MODULE_PROP") ($(sed -n 's/^versionCode=\(.*\)/\1/p' "$MODULE_PROP"))"
MOD_ROOT_DIR=$(dirname "$MODDIR")

EMPTY_DIR="$CONFIG_DIR/empty"
MIRROR_DIR="$MODDIR/system"

MN_SUPPORT=false
MR_SUPPORT=false

AUTO_UPDATE_TARGET_LIST=true
DISABLE_MODULE_AS_BRICK=true
SLAY_MODE=MB
MB_UMOUNT_BIND=true

SYSTEM_APP_PATHS="/system/app /system/product/app /system/product/data-app /system/product/priv-app /system/priv-app /system/system_ext/app /system/system_ext/priv-app /system/vendor/app /system/vendor/priv-app"

brick_rescue() {

    logowl "Check brick status"

    if [ -f "$BRICKED_STATUS" ]; then
        logowl "Detect flag bricked!" "FATAL"
        if [ "$DISABLE_MODULE_AS_BRICK" = true ] && [ ! -f "$MODDIR/disable" ]; then
            logowl "Detect flag DISABLE_MODULE_AS_BRICK=true, but $MOD_NAME has NOT been disabled"
            logowl "Maybe $MOD_NAME is enabled by user manually, reset brick status"
            rm -f "$BRICKED_STATUS"
            logowl "$MOD_NAME will keep going"
            return 0
        else
            logowl "Start brick rescue processing"
            DESCRIPTION="[❌Disabled. Auto disable from brick! 🧭Root: $ROOT_SOL_DETAIL] A Magisk module to remove bloatware in systemless way"
            update_config_value "description" "$DESCRIPTION" "$MODULE_PROP"
            logowl "Skip post-fs-data.sh process"
            exit 1
        fi
    else
        logowl "Flag bricked does NOT exist, $MOD_NAME will keep going"
    fi
}

config_loader() {

    logowl "Load config"

    debug=$(init_variables "debug" "$CONFIG_FILE")
    auto_update_target_list=$(init_variables "auto_update_target_list" "$CONFIG_FILE")
    system_app_paths=$(init_variables "system_app_paths" "$CONFIG_FILE")
    disable_module_as_brick=$(init_variables "disable_module_as_brick" "$CONFIG_FILE")
    slay_mode=$(init_variables "slay_mode" "$CONFIG_FILE")
    mb_umount_bind=$(init_variables "mb_umount_bind" "$CONFIG_FILE")

    verify_variables "debug" "$debug" "^(true|false)$"
    verify_variables "auto_update_target_list" "$auto_update_target_list" "^(true|false)$"
    verify_variables "system_app_paths" "$system_app_paths" "^/system/[^/]+(/[^/]+)*$"
    verify_variables "disable_module_as_brick" "$disable_module_as_brick" "^(true|false)$"
    verify_variables "slay_mode" "$slay_mode" "^(MB|MN|MR)$"
    verify_variables "mb_umount_bind" "$mb_umount_bind" "^(true|false)$"

}

preparation() {

    logowl "Some preparatory work"

    if [ -n "$MODDIR" ] && [ -d "$MODDIR" ] && [ "$MODDIR" != "/" ] && [ -d "$MIRROR_DIR" ]; then
        logowl "Remove old mirror folder"
        rm -rf "$MIRROR_DIR"
    fi
    if [ -n "$MODDIR" ] && [ -d "$MODDIR" ] && [ "$MODDIR" != "/" ] && [ -d "$EMPTY_DIR" ]; then
        logowl "Remove old bind folder"
        rm -rf "$EMPTY_DIR"
    fi


    if [ "$DETECT_KSU" = true ] || [ "$DETECT_APATCH" = true ]; then
        logowl "$MOD_NAME is running on KernelSU / APatch, which supports Make Node mode"
        MN_SUPPORT=true
        MR_SUPPORT=false
        [ "$SLAY_MODE" = "MR" ] && SLAY_MODE=MN

    elif [ "$DETECT_MAGISK" = true ]; then
        MR_SUPPORT=true
        if [ $MAGISK_V_VER_CODE -ge 28102 ]; then
            logowl "$MOD_NAME is running on Magisk 28102+, which supports Make Node mode"
            MN_SUPPORT=true
        else
            logowl "Make Node mode requires Magisk version 28102 and higher (current $MAGISK_V_VER_CODE)!" "WARN"
            logowl "$MOD_NAME will revert to Magisk Replace mode"
            MN_SUPPORT=false
            [ "$SLAY_MODE" = "MN" ] && SLAY_MODE="MR"
        fi
    fi

    if [ "$ROOT_SOL_COUNT" -gt 1 ]; then
        logowl "Detect multiple root solutions!" "WARN"
        logowl "Install multiple root solutions is NOT a healthy or normal way"
        logowl "Please keep using one root solution ONLY!"
        logowl "$MOD_NAME will revert to mount bind mode for multiple root solutions"
        SLAY_MODE="MB"
    fi

    case "$SLAY_MODE" in
        MB)
            SLAY_MODE_DESC="Mount Bind"
            logowl "Create $EMPTY_DIR"
            mkdir -p "$EMPTY_DIR"
            ;;
        MN|MR)
            if [ "$SLAY_MODE" = "MN" ]; then
                SLAY_MODE_DESC="Make Node"
            elif [ "$SLAY_MODE" = "MR" ]; then
                SLAY_MODE_DESC="Magisk Replace"
            fi
            logowl "Create $MIRROR_DIR"
            mkdir -p "$MIRROR_DIR"
            ;;
    esac
    logowl "Current mode: $SLAY_MODE ($SLAY_MODE_DESC)"

    if [ "$MN_SUPPORT" = true ]; then
        logowl "Current root solution supports Make Node mode"
        logowl "Create $MIRROR_DIR"
        [ ! -e "$MIRROR_DIR" ] && mkdir -p "$MIRROR_DIR"
    fi

    if [ ! -f "$TARGET_LIST" ]; then
        logowl "Target list does NOT exist!" "FATAL"
        DESCRIPTION="[❌No effect. Target list does NOT exist! 🧭Root: $ROOT_SOL_DETAIL] A Magisk module to remove bloatware in systemless way"
        update_config_value "description" "$DESCRIPTION" "$MODULE_PROP"
        return 1
    fi

    touch "$TARGET_LIST_BSA"
    echo -e "# Target List $MOD_NAME Arranged\n# Version: $MOD_VER\n" > "$TARGET_LIST_BSA"

}

mirror_make_node() {

    node_path=$1

    if [ -z "$node_path" ]; then
        logowl "node_path is NOT ordered!" "ERROR"
        return 5
    elif [ ! -e "$node_path" ]; then
        logowl "$node_path does NOT exist!" "ERROR"
        return 6
    fi

    node_path_parent_dir=$(dirname "$node_path")
    mirror_parent_dir="$MODDIR$node_path_parent_dir"
    mirror_node_path="$MODDIR$node_path"

    if [ ! -d "$mirror_parent_dir" ]; then
        [ "$DEBUG" = true ] && logowl "Parent dir $mirror_parent_dir does NOT exist"
        logowl "Create parent dir: $mirror_parent_dir"
        mkdir -p "$mirror_parent_dir"
    fi

    if [ ! -e "$mirror_node_path" ]; then
        [ "$DEBUG" = true ] && logowl "Node $mirror_node_path does NOT exist"
        logowl "Execute: mknod $mirror_node_path c 0 0"
        mknod "$mirror_node_path" c 0 0
        result_make_node="$?"
        if [ $result_make_node -eq 0 ]; then
            return 0
        else
            return $result_make_node
        fi
    else
        [ "$DEBUG" = true ] && logowl "Node $mirror_node_path exists already"
        return 0
    fi

}

mirror_magisk_replace() {

    replace_path=$1

    if [ -z "$replace_path" ]; then
        logowl "replace_path is NOT ordered!" "ERROR"
        return 5
    elif [ ! -d "$replace_path" ]; then
        logowl "$replace_path is NOT a directory!" "ERROR"
        return 6
    fi

    mirror_app_path="$MODDIR$replace_path"

    if [ ! -d "$mirror_app_path" ]; then
        logowl "Create mirror path: $mirror_app_path"
        mkdir -p "$mirror_app_path"
    fi

    if [ ! -e "$mirror_app_path/.replace" ]; then
        logowl "Execute: touch $mirror_app_path/.replace"
        touch "$mirror_app_path/.replace"
        result_magisk_replace="$?"
        if [ $result_magisk_replace -eq 0 ]; then
            return 0
        else
            return $result_magisk_replace
        fi
    else
        return 0
    fi

}

link_mount_bind() {

    link_path=$1

    if [ -z "$link_path" ]; then
        logowl "link_path is NOT ordered!" "ERROR"
        return 5
    elif [ ! -d "$link_path" ]; then
        logowl "$link_path is NOT a directory!" "ERROR"
        return 6
    fi

    logowl "Execute: mount -o bind $EMPTY_DIR $app_path"
    mount -o bind "$EMPTY_DIR" "$app_path"

    result_mount_bind="$?"
    if [ $result_mount_bind -eq 0 ]; then
        return 0
    else
        return $result_mount_bind
    fi

}

bloatware_slayer() {

    logowl "Slaying bloatwares"

    TOTAL_APPS_COUNT=0
    BLOCKED_APPS_COUNT=0
    hybrid_mode=false
    lines_count=0

    while IFS= read -r line; do
        lines_count=$((lines_count + 1))

        if ! check_value_safety "line $lines_count" "$line"; then
            continue
        fi

        line=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        first_char=$(printf '%s' "$line" | cut -c1)

        if [ -z "$line" ]; then
            logowl "Detect empty line, skip processing" "TIPS"
            continue
        elif [ "$first_char" = "#" ]; then
            logowl "Detect comment line, skip processing" "TIPS"
            continue
        fi

        package=$(echo "$line" | cut -d '#' -f1)
        package=$(echo "$package" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

        if [ -z "$package" ]; then
            logowl "Detect only comment left in this line, skip processing" "TIPS"
            continue
        fi

        case "$package" in
            *\\*)
                logowl "Replace '\\' with '/' in path: $package" "WARN"
                package=$(echo "$package" | sed -e 's/\\/\//g')
                ;;
        esac
        logowl "After processing: $package"

        TOTAL_APPS_COUNT=$((TOTAL_APPS_COUNT+1))

        for path in $SYSTEM_APP_PATHS; do
            first_char=$(printf '%s' "$line" | cut -c1)

            if [ "$first_char" = "/" ]; then
                app_path="$package"
                logowl "Detect custom dir: $app_path"
                case "$app_path" in
                    /system/apex*)
                        case "$app_path" in
                        *.apex|*.capex)
                            ;;
                        *)
                            app_path=$(echo "$app_path" | sed -n 's|^/system/apex/\([^/]*\).*|/system/apex/\1|p')
                            if [ -f "${app_path}.apex" ]; then
                                logowl "Detect apex path: ${app_path}.apex"
                                app_path="${app_path}.apex"
                            elif [ -f "${app_path}.capex" ]; then
                                logowl "Detect capex path: ${app_path}.capex"
                                app_path="${app_path}.capex"
                            else
                                logowl "Neither ${app_path}.apex nor ${app_path}.capex exists"
                                break
                            fi
                            ;;
                        esac
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

            if [ -d "$app_path" ]; then
                logowl "Processing app path: $app_path"
                if [ "$SLAY_MODE" = "MB" ]; then
                    link_mount_bind "$app_path"
                elif [ "$SLAY_MODE" = "MN" ]; then
                    mirror_make_node "$app_path"
                elif [ "$SLAY_MODE" = "MR" ]; then
                    mirror_magisk_replace "$app_path"
                fi
                bloatware_slay_result=$?
                if [ $bloatware_slay_result -eq 0 ]; then
                    logowl "Succeeded (code: $bloatware_slay_result)"
                    BLOCKED_APPS_COUNT=$((BLOCKED_APPS_COUNT + 1))
                    echo "$app_path" >> "$TARGET_LIST_BSA"
                    break
                else
                    logowl "Failed to mount $app_path (code: $bloatware_slay_result)"
                fi

            elif [ -f "$app_path" ] && [ -d "$(dirname $app_path)" ]; then
                logowl "Processing file path: $app_path"
                if [ "$SLAY_MODE" = "MN" ] || [ "$MN_SUPPORT" = true ]; then
                    mirror_make_node "$app_path"
                    bloatware_slay_result=$?
                    if [ $bloatware_slay_result -eq 0 ]; then
                        logowl "Succeeded (code: $bloatware_slay_result)"
                        BLOCKED_APPS_COUNT=$((BLOCKED_APPS_COUNT + 1))
                        [ "$SLAY_MODE" != "MN" ] && hybrid_mode=true
                        echo "$app_path" >> "$TARGET_LIST_BSA"
                        break
                    else
                        logowl "Failed to mount $app_path (code: $bloatware_slay_result)"
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

    logowl "Clean duplicate items"
    clean_duplicate_items "$TARGET_LIST_BSA"

    if [ "$AUTO_UPDATE_TARGET_LIST" = true ]; then
        logowl "Update target list"
        cp -p "$TARGET_LIST_BSA" "$TARGET_LIST"
    fi

}

module_status_update() {

    APP_NOT_FOUND=$((TOTAL_APPS_COUNT - BLOCKED_APPS_COUNT))
    logowl "$TOTAL_APPS_COUNT APP(s) in total"
    logowl "$BLOCKED_APPS_COUNT APP(s) has been slain"
    logowl "$APP_NOT_FOUND APP(s) not found"

    [ "$hybrid_mode" = true ] && SLAY_MODE_DESC="Hybrid ($SLAY_MODE_DESC + Make Node)"

    if [ -f "$MODULE_PROP" ]; then
        if [ $BLOCKED_APPS_COUNT -gt 0 ]; then
                DESCRIPTION="[✅Enabled. $BLOCKED_APPS_COUNT APP(s) slain, $APP_NOT_FOUND APP(s) missing, $TOTAL_APPS_COUNT APP(s) targeted in total, 🤖Mode: $SLAY_MODE_DESC, 🧭Root: $ROOT_SOL_DETAIL] Victoire sur victoire ! Hourra !"
            if [ $APP_NOT_FOUND -eq 0 ]; then
                DESCRIPTION="[✅Enabled. $BLOCKED_APPS_COUNT APP(s) slain. All targets neutralized! 🤖Mode: $SLAY_MODE_DESC, 🧭Root: $ROOT_SOL_DETAIL] Victoire sur victoire ! Hourra !"
            fi
        else
            if [ $TOTAL_APPS_COUNT -gt 0 ]; then
                DESCRIPTION="[✅No effect. No APP slain yet, $TOTAL_APPS_COUNT APP(s) targeted in total, 🤖Mode: $SLAY_MODE_DESC, 🧭Root: $ROOT_SOL_DETAIL] Victoire sur victoire ! Hourra !"
            else
                logowl "Current blocked apps count: $TOTAL_APPS_COUNT <= 0" "ERROR"
                DESCRIPTION="[❌No effect. Abnormal status! 🤖Mode: $SLAY_MODE_DESC, 🧭Root: $ROOT_SOL_DETAIL] A Magisk module to remove bloatware in systemless way"
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
set_permission_recursive "$MODDIR" 0 0 0755 0644
set_permission_recursive "$CONFIG_DIR" 0 0 0755 0644
debug_print_values >> "$LOG_FILE"
logowl "post-fs-data.sh case closed!"
