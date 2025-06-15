#!/system/bin/sh
MODDIR=${0%/*}

. "$MODDIR/aa-util.sh"

CONFIG_DIR="/data/adb/bloatwareslayer"

CONFIG_FILE="$CONFIG_DIR/settings.conf"
LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/bs_core_$(date +"%Y%m%dT%H%M%S").log"

BRICKED_STATE="$CONFIG_DIR/bricked"

TARGET_LIST="$CONFIG_DIR/target.conf"
TARGET_LIST_BSA="$LOG_DIR/target_bsa.conf"
TARGET_LIST_LW="$LOG_DIR/target_lw.conf"

MOD_INTRO="Remove bloatware in systemless way."
MOD_SLOGAN="勝った、勝った、また勝ったぁーっと！！🎉✨"

MN_SUPPORT=false
MR_SUPPORT=false
MIRROR_DIR="$MODDIR/system"

brick_rescue=true
disable_module_as_brick=true
last_worked_target_list=true
slay_mode=MB
system_app_paths="/system/app /system/product/app /system/product/data-app /system/product/priv-app /system/priv-app /system/system_ext/app /system/system_ext/priv-app /system/vendor/app /system/vendor/priv-app"

brick_rescue_savior() {

    if [ "$brick_rescue" = false ]; then
        logowl "Detect flag brick_rescue=false" "WARN"
        logowl "$MOD_NAME will skip brick rescue process"
        return 1
    fi

    logowl "Check brick state"
    rescue_from_last_worked_target_list=false

    if [ -f "$BRICKED_STATE" ]; then
        logowl "Detect flag bricked!" "FATAL"
        if [ "$disable_module_as_brick" = false ] && [ "$last_worked_target_list" = true ]; then
            logowl "Detect flag disable_module_as_brick=false"
            logowl "Detect flag last_worked_target_list=true"
            if [ -f "$TARGET_LIST_LW" ]; then
                cp "$TARGET_LIST_LW" "$TARGET_LIST" && logowl "Attempt to use last worked target list"
                rm -f "$TARGET_LIST_LW" && logowl "Reset last worked target list state"
                rm -f "$BRICKED_STATE" && logowl "Reset brick state"
                rm -f "$MODDIR/disable" && logowl "Enable $MOD_NAME again"
                logowl "$MOD_NAME will keep going"
                rescue_from_last_worked_target_list=true
                return 0
            else
                logowl "Last worked target list file does NOT exist!" "WARN"
            fi
        fi

        if [ "$disable_module_as_brick" = true ] && [ ! -f "$MODDIR/disable" ]; then
            logowl "Detect flag disable_module_as_brick=true"
            logowl "But $MOD_NAME has NOT been disabled"
            logowl "Maybe $MOD_NAME is enabled by user manually"
            rm -f "$BRICKED_STATE" && logowl "Reset brick state"
            logowl "$MOD_NAME will keep going"
            return 0
        else
            logowl "Start brick rescue"
            logowl "Skip executing post-fs-data.sh"
            exit 1
        fi
    else
        logowl "Flag bricked does NOT exist"
        logowl "$MOD_NAME will keep going"
    fi
}

config_loader() {

    logowl "Load config"

    brick_rescue=$(get_config_var "brick_rescue" "$CONFIG_FILE")
    disable_module_as_brick=$(get_config_var "disable_module_as_brick" "$CONFIG_FILE")
    last_worked_target_list=$(get_config_var "last_worked_target_list" "$CONFIG_FILE")
    slay_mode=$(get_config_var "slay_mode" "$CONFIG_FILE")
    system_app_paths=$(get_config_var "system_app_paths" "$CONFIG_FILE")

}

preparation() {

    logowl "Some preparation"

    [ -d "$MIRROR_DIR" ] && [ "$MIRROR_DIR" != "/" ] && rm -rf "$MIRROR_DIR" && logowl "Remove old mirror folder"

    logowl "$MOD_NAME is running on $ROOT_SOL"
    if [ "$DETECT_KSU" = true ] || [ "$DETECT_APATCH" = true ]; then
        logowl "Make Node support is present"
        MN_SUPPORT=true
        MR_SUPPORT=false
        [ "$slay_mode" = "MR" ] && slay_mode=MN
    elif [ "$DETECT_MAGISK" = true ]; then
        if [ $MAGISK_V_VER_CODE -ge 28102 ]; then
            logowl "Make Node support is present"
            MN_SUPPORT=true
        else
            logowl "Make Node support is NOT present" "WARN"
            MN_SUPPORT=false
            [ "$slay_mode" = "MN" ] && slay_mode="MR"
        fi
        logowl "Magisk Replace support is present"
        MR_SUPPORT=true
    fi

    if [ "$ROOT_SOL_COUNT" -gt 1 ]; then
        logowl "Detect multiple root solutions!" "WARN"
        logowl "$MOD_NAME will revert to mount bind mode for multiple root solutions"
        slay_mode="MB"
    fi

    case "$slay_mode" in
        MB) SLAY_MODE_DESC="Mount Bind"
            ;;
        MN) SLAY_MODE_DESC="Make Node"
            ;;
        MR) SLAY_MODE_DESC="Magisk Replace"
            ;;
    esac

    mkdir -p "$MIRROR_DIR"
    logowl "Create $MIRROR_DIR"
    logowl "Current mode: $SLAY_MODE_DESC"

    if [ ! -f "$TARGET_LIST" ]; then
        logowl "Target list does NOT exist!" "FATAL"
        DESCRIPTION="[❌No effect. Target list does NOT exist! ⚙️Root: $ROOT_SOL_DETAIL] $MOD_INTRO"
        update_config_var "description" "$DESCRIPTION" "$MODULE_PROP"
        return 1
    fi

    touch "$TARGET_LIST_BSA"
    echo -e "# Target List $MOD_NAME Arranged\n# Version: $MOD_VER\n" > "$TARGET_LIST_BSA"

}

mirror_make_node() {

    node_path=$1

    if [ -z "$node_path" ]; then
        logowl "node_path is NOT ordered! (5)" "ERROR"
        return 5
    elif [ ! -e "$node_path" ]; then
        logowl "$node_path does NOT exist! (6)" "ERROR"
        return 6
    fi

    node_path_parent_dir=$(dirname "$node_path")
    mirror_parent_dir="$MODDIR$node_path_parent_dir"
    mirror_node_path="$MODDIR$node_path"

    if [ ! -d "$mirror_parent_dir" ]; then
        logowl "Parent dir $mirror_parent_dir does NOT exist"
        mkdir -p "$mirror_parent_dir"
        logowl "Create parent dir: $mirror_parent_dir"
    fi

    if [ ! -e "$mirror_node_path" ]; then
        logowl "Node $mirror_node_path does NOT exist"
        mknod "$mirror_node_path" c 0 0
        result_make_node="$?"
        logowl "mknod $mirror_node_path c 0 0"
        if [ $result_make_node -eq 0 ]; then
            return 0
        else
            return $result_make_node
        fi
    else
        logowl "Node $mirror_node_path exists already"
        return 0
    fi

}

mirror_magisk_replace() {

    replace_path=$1

    if [ -z "$replace_path" ]; then
        logowl "replace_path is NOT ordered! (5)" "ERROR"
        return 5
    elif [ ! -d "$replace_path" ]; then
        logowl "$replace_path is NOT a dir! (6)" "ERROR"
        return 6
    fi

    mirror_app_path="$MODDIR$replace_path"

    if [ ! -d "$mirror_app_path" ]; then
        mkdir -p "$mirror_app_path"
        logowl "Create mirror path: $mirror_app_path"
    fi

    if [ ! -e "$mirror_app_path/.replace" ]; then
        touch "$mirror_app_path/.replace"
        result_magisk_replace="$?"
        logowl "touch $mirror_app_path/.replace"
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
    target_path=$2

    if [ -z "$link_path" ] || [ -z "$target_path" ]; then
        logowl "Link path or target path is NOT ordered! (5)" "ERROR"
        return 5
    elif [ ! -d "$link_path" ] || [ ! -d "$target_path" ]; then
        logowl "$link_path or $target_path is NOT a dir! (6)" "ERROR"
        return 6
    fi

    mount -o bind "$link_path" "$target_path"
    result_mount_bind="$?"
    logowl "mount -o bind $link_path $target_path"
    if [ $result_mount_bind -eq 0 ]; then
        return 0
    else
        return $result_mount_bind
    fi
}

bloatware_slayer() {

    logowl "Slay bloatware"

    TOTAL_APPS_COUNT=0
    BLOCKED_APPS_COUNT=0
    DUPLICATED_APPS_COUNT=0
    hybrid_mode=false

    while IFS= read -r line || [ -n "$line" ]; do
        line=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        first_char=$(printf '%s' "$line" | cut -c1)

        if [ "$first_char" = "#" ]; then
            continue
        fi

        package=$(echo "$line" | cut -d '#' -f1)
        package=$(echo "$package" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

        if [ -z "$package" ]; then
            logowl "Detect only comment left in this line, skip processing"
            continue
        fi

        case "$package" in
            *\\*)
                logowl "Replace '\\' with '/' in path: $package"
                package=$(echo "$package" | sed -e 's/\\/\//g')
                ;;
        esac

        TOTAL_APPS_COUNT=$((TOTAL_APPS_COUNT+1))

        for path in $system_app_paths; do

            first_char=$(printf '%s' "$line" | cut -c1)
            if [ "$first_char" = "/" ]; then
                app_path="$package"
                case "$app_path" in
                    /apex*|/system/apex*)
                        case "$app_path" in
                        *.apex|*.capex)
                            ;;
                        *)
                            if [ "${app_path#/apex}" != "$app_path" ]; then
                                logowl "Redirect $app_path -> /system$app_path" "*"
                                app_path="/system$app_path"
                            fi
                            app_path=$(echo "$app_path" | sed -n 's|^/system/apex/\([^/]*\).*|/system/apex/\1|p')
                            if [ -f "$app_path.apex" ]; then
                                app_path="$app_path.apex"
                            elif [ -f "$app_path.capex" ]; then
                                app_path="$app_path.capex"
                            else
                                break
                            fi
                            ;;
                        esac
                        ;;
                    /app*|/product*|/priv-app*|/system_ext*|/vendor*|/data-app*)
                        logowl "Redirect: $app_path -> /system$app_path" "*"
                        app_path="/system$app_path"
                        ;;
                    /system*)
                        [ "$app_path" = "/system" ] && logowl "Process /system is prohibited!" "ERROR" && break
                        ;;
                    *)
                        break
                        ;;
                esac
            else
                app_path="$path/$package"
            fi

            app_name="$(basename "$app_path")"
            if [ -d "$app_path" ]; then
                logowl "Process path: $app_path"
                if [ "$slay_mode" = "MB" ]; then
                    link_mount_bind "$MIRROR_DIR" "$app_path"
                elif [ "$slay_mode" = "MN" ]; then
                    mirror_make_node "$app_path"
                elif [ "$slay_mode" = "MR" ]; then
                    mirror_magisk_replace "$app_path"
                fi
                app_process_result=$?
                if [ $app_process_result -eq 0 ]; then
                    if check_duplicate_items "$app_path" "$TARGET_LIST_BSA"; then
                        echo "$app_path" >> "$TARGET_LIST_BSA"
                        BLOCKED_APPS_COUNT=$((BLOCKED_APPS_COUNT + 1))
                        logowl "$app_name has been slain" ">"
                    else
                        logowl "Detect dulpicate item: $app_name"
                        DUPLICATED_APPS_COUNT=$((DUPLICATED_APPS_COUNT + 1))
                    fi
                    break
                else
                    logowl "Slay $app_name failed (code: $app_process_result)" "WARN"
                fi

            elif [ -f "$app_path" ] && [ -d "$(dirname $app_path)" ]; then
                logowl "Process path: $app_path"
                if [ "$slay_mode" = "MN" ] || [ "$MN_SUPPORT" = true ]; then
                    mirror_make_node "$app_path"
                    file_process_result=$?
                    if [ $file_process_result -eq 0 ]; then
                        [ "$slay_mode" != "MN" ] && hybrid_mode=true
                        if check_duplicate_items "$app_path" "$TARGET_LIST_BSA"; then
                            echo "$app_path" >> "$TARGET_LIST_BSA"
                            BLOCKED_APPS_COUNT=$((BLOCKED_APPS_COUNT + 1))
                            logowl "$app_name has been slain" ">"
                        else
                            logowl "Detect dulpicate item: $app_name"
                            DUPLICATED_APPS_COUNT=$((DUPLICATED_APPS_COUNT + 1))
                        fi
                        break
                    else
                        logowl "Slay $app_name failed (code: $file_process_result)" "WARN"
                    fi
                fi
            else
                if [ "$first_char" = "/" ]; then
                    logowl "Custom dir $app_path NOT found"
                    break
                else
                    logowl "Dir $app_path NOT found"
                fi
            fi
        done
    done < "$TARGET_LIST"

    logowl "Clean duplicate items"
    clean_duplicate_items "$TARGET_LIST_BSA"

}

module_status_update() {

    APP_NOT_FOUND=$((TOTAL_APPS_COUNT - BLOCKED_APPS_COUNT - DUPLICATED_APPS_COUNT))
    logowl "$TOTAL_APPS_COUNT APP(s) in total"
    logowl "$DUPLICATED_APPS_COUNT item(s) dulpicated"
    logowl "$BLOCKED_APPS_COUNT APP(s) has been slain"
    logowl "$APP_NOT_FOUND APP(s) not found"

    [ "$hybrid_mode" = true ] && SLAY_MODE_DESC="Hybrid ($SLAY_MODE_DESC + Make Node)"

    desc_rescue_from_last_worked=""

    [ "$rescue_from_last_worked_target_list" = true ] && desc_rescue_from_last_worked=" (Last worked target list)"

    if [ -f "$MODULE_PROP" ]; then
        if [ $BLOCKED_APPS_COUNT -gt 0 ]; then
                DESCRIPTION="[✅Done${desc_rescue_from_last_worked}. $BLOCKED_APPS_COUNT APP(s) slain, $DUPLICATED_APPS_COUNT APP(s) duplicated, $APP_NOT_FOUND APP(s) missing, $TOTAL_APPS_COUNT APP(s) targeted in total, 🐦Mode: $SLAY_MODE_DESC, ⚙️Root: $ROOT_SOL_DETAIL] $MOD_SLOGAN"
            if [ $APP_NOT_FOUND -eq 0 ]; then
                DESCRIPTION="[✅All Done${desc_rescue_from_last_worked}. $BLOCKED_APPS_COUNT APP(s) slain. 🐦Mode: $SLAY_MODE_DESC, ⚙️Root: $ROOT_SOL_DETAIL] $MOD_SLOGAN"
            fi
        else
            if [ $TOTAL_APPS_COUNT -gt 0 ]; then
                DESCRIPTION="[✅Standby${desc_rescue_from_last_worked}. No APP slain yet. $TOTAL_APPS_COUNT APP(s) targeted in total. 🐦Mode: $SLAY_MODE_DESC, ⚙️Root: $ROOT_SOL_DETAIL] $MOD_SLOGAN"
            else
                logowl "Current blocked apps count: $TOTAL_APPS_COUNT <= 0" "ERROR"
                DESCRIPTION="[❌No effect. Maybe something went wrong? 🐦Mode: $SLAY_MODE_DESC, ⚙️Root: $ROOT_SOL_DETAIL] $MOD_INTRO"
            fi
        fi
        update_config_var "description" "$DESCRIPTION" "$MODULE_PROP"
    else
        logowl "module.prop not found, skip updating" "WARN"
    fi

}

logowl_init "$LOG_DIR"
logowl_clean "30"
module_intro >> "$LOG_FILE"
show_system_info >> "$LOG_FILE"
print_line
logowl "Start post-fs-data.sh"
print_line
config_loader
print_line
brick_rescue_savior
preparation
bloatware_slayer
module_status_update
set_permission_recursive "$MODDIR" 0 0 0755 0644
set_permission_recursive "$CONFIG_DIR" 0 0 0755 0644
print_line
logowl "post-fs-data.sh case closed!"
