#!/system/bin/sh
MODDIR=${0%/*}

. "$MODDIR/aa-util.sh"

CONFIG_DIR="/data/adb/bloatwareslayer"

CONFIG_FILE="$CONFIG_DIR/settings.conf"
TARGET_LIST="$CONFIG_DIR/target.conf"
FLAG_BRICKED="$CONFIG_DIR/bricked"

LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/bs_core_$(date +"%Y%m%dT%H%M%S").log"
TARGET_LIST_BSA="$LOG_DIR/target_bsa.conf"

LAST_WORKED_DIR="$CONFIG_DIR/last_worked"
TARGET_LIST_LW="$LAST_WORKED_DIR/target_lw.conf"

MOD_INTRO="Remove bloatware in systemless way."

MN_SUPPORT=false
MR_SUPPORT=false
MIRROR_DIR="$MODDIR/system"

brick_rescue=true
disable_module_as_brick=true
last_worked_target_list=true
slay_mode=MB
system_app_paths="/system/app /system/product/app /system/product/data-app /system/product/priv-app /system/priv-app /system/system_ext/app /system/system_ext/priv-app /system/vendor/app /system/vendor/priv-app"

unbrick() {

    if [ "$brick_rescue" = false ]; then
        logowl "$MOD_NAME will skip brick rescue process"
        return 1
    fi

    logowl "Check flag brick"
    rescue_from_last_worked_target_list=false

    if [ -f "$FLAG_BRICKED" ]; then
        logowl "Flag bricked exists!" "F"
        if [ "$disable_module_as_brick" = false ] && [ "$last_worked_target_list" = true ]; then
            if [ -f "$TARGET_LIST_LW" ]; then
                cp "$TARGET_LIST_LW" "$TARGET_LIST" && logowl "Switch to last worked target list"
                rm -f "$MODDIR/disable" && logowl "Enable $MOD_NAME again"
                rm -f "$FLAG_BRICKED" && logowl "Reset brick state"
                rescue_from_last_worked_target_list=true
                return 0
            fi
        fi

        if [ "$disable_module_as_brick" = true ] && [ ! -f "$MODDIR/disable" ]; then
            logowl "Flag bricked exists"
            logowl "but $MOD_NAME has NOT been disabled"
            logowl "Maybe $MOD_NAME is enabled manually"
            rm -f "$FLAG_BRICKED" && logowl "Remove flag bricked"
            return 0
        else
            logowl "Skip $MOD_NAME process"
            exit 1
        fi
    else
        logowl "Flag bricked does NOT exist"
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

    if [ -d "$MIRROR_DIR" ]; then
        if [ "$MIRROR_DIR" != "/" ] && [ "$MIRROR_DIR" != "/system" ]; then
            rm -rf "$MIRROR_DIR"
            logowl "Remove old mirror dir"
        fi
    fi

    if [ "$DETECT_KSU" = true ] || [ "$DETECT_APATCH" = true ]; then
        logowl "Make Node support is present"
        MN_SUPPORT=true
        MR_SUPPORT=false
        [ "$slay_mode" = "MR" ] && slay_mode="MB"
    elif [ "$DETECT_MAGISK" = true ]; then
        if [ $MAGISK_V_VER_CODE -ge 28102 ]; then
            logowl "Make Node support is present"
            MN_SUPPORT=true
        else
            MN_SUPPORT=false
            [ "$slay_mode" = "MN" ] && slay_mode="MR"
        fi
        logowl "Magisk Replace support is present"
        MR_SUPPORT=true
    fi

    if [ "$ROOT_SOL_COUNT" -gt 1 ]; then
        logowl "Find multiple root solutions" "W"
        logowl "$MOD_NAME will revert to Mount Bind mode"
        slay_mode="MB"
    fi

    mkdir -p "$MIRROR_DIR" && logowl "Create new mirror dir"

    if [ ! -f "$TARGET_LIST" ]; then
        logowl "Target list does NOT exist" "F"
        DESCRIPTION="[❌No effect. Target list does NOT exist! ⚙️Root: $ROOT_SOL_DETAIL] $MOD_INTRO"
        update_config_var "description" "$DESCRIPTION" "$MODULE_PROP"
        return 1
    fi

    case "$slay_mode" in
        MB) SLAY_MODE_DESC="Mount Bind"
            ;;
        MN) SLAY_MODE_DESC="Make Node"
            ;;
        MR) SLAY_MODE_DESC="Magisk Replace"
            ;;
    esac

}

mirror_make_node() {

    node_path=$1

    if [ -z "$node_path" ]; then
        logowl "Node path is NOT ordered (5)" "E"
        return 5
    elif [ ! -e "$node_path" ]; then
        logowl "$node_path does NOT exist (6)" "E"
        return 6
    fi

    node_path_parent_dir=$(dirname "$node_path")
    mirror_parent_dir="$MODDIR$node_path_parent_dir"
    mirror_node_path="$MODDIR$node_path"

    if [ ! -d "$mirror_parent_dir" ]; then
        logowl "Parent dir $mirror_parent_dir does NOT exist"
        mkdir -p "$mirror_parent_dir"
        logowl "Create parent dir $mirror_parent_dir"
    fi

    if [ ! -e "$mirror_node_path" ]; then
        logowl "Node $mirror_node_path does NOT exist"
        mknod "$mirror_node_path" c 0 0
        result_make_node="$?"
        logowl "mknod $mirror_node_path c 0 0 ($result_make_node)"
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
        logowl "Replace path is NOT ordered (5)" "E"
        return 5
    elif [ ! -d "$replace_path" ]; then
        logowl "$replace_path is NOT a dir (6)" "E"
        return 6
    fi

    mirror_app_path="$MODDIR$replace_path"

    if [ ! -d "$mirror_app_path" ]; then
        mkdir -p "$mirror_app_path"
        logowl "Create mirror path $mirror_app_path"
    fi

    if [ ! -e "$mirror_app_path/.replace" ]; then
        touch "$mirror_app_path/.replace"
        result_magisk_replace="$?"
        logowl "touch $mirror_app_path/.replace ($result_magisk_replace)"
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
        logowl "Link path or target path is NOT ordered (5)" "E"
        return 5
    elif [ ! -d "$link_path" ] || [ ! -d "$target_path" ]; then
        logowl "$link_path or $target_path is NOT a dir (6)" "E"
        return 6
    fi

    mount -o bind "$link_path" "$target_path"
    result_mount_bind="$?"
    logowl "mount -o bind $link_path $target_path ($result_mount_bind)"
    if [ $result_mount_bind -eq 0 ]; then
        return 0
    else
        return $result_mount_bind
    fi
}

bloatware_slayer() {

    print_line
    logowl "Slaying bloatwares"
    print_line

    TOTAL_APPS_COUNT=0
    BLOCKED_APPS_COUNT=0
    DUPLICATED_APPS_COUNT=0
    hybrid_mode=false

    touch "$TARGET_LIST_BSA"

    while IFS= read -r line || [ -n "$line" ]; do
        line=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        first_char=$(printf '%s' "$line" | cut -c1)
        [ "$first_char" = "#" ] && continue

        package=$(echo "$line" | cut -d '#' -f1)
        package=$(echo "$package" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        [ -z "$package" ] && continue
        
        case "$package" in
            *\\*)
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
                                logowl "Redirect to /system$app_path" "*"
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
                        logowl "Redirect to /system$app_path" "*"
                        app_path="/system$app_path"
                        ;;
                    /system*)
                        [ "$app_path" = "/system" ] && break
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
                logowl "Process path $app_path"
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
                        logowl "Find duplicate item $app_name"
                        DUPLICATED_APPS_COUNT=$((DUPLICATED_APPS_COUNT + 1))
                    fi
                    break
                else
                    logowl "Failed to slay $app_name ($app_process_result)" "W"
                fi

            elif [ -f "$app_path" ] && [ -d "$(dirname $app_path)" ]; then
                logowl "Process path $app_path"
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
                            logowl "Find duplicate item $app_name"
                            DUPLICATED_APPS_COUNT=$((DUPLICATED_APPS_COUNT + 1))
                        fi
                        break
                    else
                        logowl "Failed to slay $app_name ($file_process_result)" "W"
                    fi
                fi
            else
                if [ "$first_char" = "/" ]; then
                    logowl "Custom dir $app_path does NOT exist"
                    break
                else
                    logowl "Dir $app_path does NOT exist"
                fi
            fi
        done
    done < "$TARGET_LIST"

    logowl "Clean duplicate items"
    clean_duplicate_items "$TARGET_LIST_BSA"

}

module_status_update() {

    MISSING_APPS_COUNT=$((TOTAL_APPS_COUNT - BLOCKED_APPS_COUNT - DUPLICATED_APPS_COUNT))
    print_line
    logowl "Total: $TOTAL_APPS_COUNT APP(s)"
    logowl "Slain: $BLOCKED_APPS_COUNT APP(s)"
    logowl "Missing: $MISSING_APPS_COUNT APP(s)"
    logowl "Duplicate: $DUPLICATED_APPS_COUNT APP(s)"

    [ "$hybrid_mode" = true ] && SLAY_MODE_DESC="Hybrid ($SLAY_MODE_DESC + Make Node)"

    desc_last_worked=""
    [ "$rescue_from_last_worked_target_list" = true ] && desc_last_worked=" (last worked)"

    if [ -f "$MODULE_PROP" ]; then
        if [ $BLOCKED_APPS_COUNT -gt 0 ]; then
                DESCRIPTION="[✅Done. $BLOCKED_APPS_COUNT APP(s) slain, $MISSING_APPS_COUNT APP(s) missing, $DUPLICATED_APPS_COUNT APP(s) duplicated, $TOTAL_APPS_COUNT APP(s) targeted in total, 🐦Mode: $SLAY_MODE_DESC${desc_last_worked}, ⚙️Root: $ROOT_SOL_DETAIL] $MOD_INTRO"
            if [ $MISSING_APPS_COUNT -eq 0 ]; then
                DESCRIPTION="[✅Cleared. $BLOCKED_APPS_COUNT APP(s) slain. 🐦Mode: $SLAY_MODE_DESC${desc_last_worked}, ⚙️Root: $ROOT_SOL_DETAIL] $MOD_INTRO"
            fi
        else
            if [ $TOTAL_APPS_COUNT -gt 0 ]; then
                DESCRIPTION="[✅Standby. No APP slain yet. $TOTAL_APPS_COUNT APP(s) targeted in total. 🐦Mode: $SLAY_MODE_DESC${desc_last_worked}, ⚙️Root: $ROOT_SOL_DETAIL] $MOD_INTRO"
            else
                DESCRIPTION="[❌No effect. Something went wrong! 🐦Mode: $SLAY_MODE_DESC, ⚙️Root: $ROOT_SOL_DETAIL] $MOD_INTRO"
            fi
        fi
        update_config_var "description" "$DESCRIPTION" "$MODULE_PROP"
    fi

}

logowl_init "$LOG_DIR"
module_intro >> "$LOG_FILE"
show_system_info >> "$LOG_FILE"
print_line
config_loader
print_line
unbrick
preparation
bloatware_slayer
module_status_update
print_line
logowl "Case closed!"
