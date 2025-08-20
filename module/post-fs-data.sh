#!/system/bin/sh
MODDIR=${0%/*}

. "$MODDIR/wanderer.sh"

CONFIG_DIR="/data/adb/bloatwareslayer"

CONFIG_FILE="$CONFIG_DIR/settings.conf"
TARGET_LIST="$CONFIG_DIR/target.conf"
FLAG_BRICKED="$CONFIG_DIR/bricked"

LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/bs_core_$(date +"%Y%m%dT%H%M%S").log"
TARGET_LIST_BSA="$LOG_DIR/target_bsa.conf"

LAST_WORKED_DIR="$CONFIG_DIR/last_worked"
TARGET_LIST_LW="$LAST_WORKED_DIR/target_lw.conf"

MOD_INTRO="Remove bloatwares systemlessly."

MN_SUPPORT=false
MR_SUPPORT=false
MIRROR_DIR="$MODDIR/system"

unbrick() {
    if [ "$brick_rescue" = false ]; then
        eco "$MOD_NAME will skip brick rescue"
        return 1
    fi

    eco "Check flag brick"
    rescue_from_last_worked_target_list=false

    if [ -f "$FLAG_BRICKED" ]; then
        eco "Flag bricked exists!" "F"
        if [ "$disable_module_as_brick" = false ] && [ "$last_worked_target_list" = true ]; then
            if [ -f "$TARGET_LIST_LW" ]; then
                cp "$TARGET_LIST_LW" "$TARGET_LIST" && eco "Switch to last worked target list"
                rm -f "$MODDIR/disable" && eco "Enable $MOD_NAME again"
                rm -f "$FLAG_BRICKED" && eco "Reset brick state"
                rescue_from_last_worked_target_list=true
                return 0
            fi
        fi

        if [ "$disable_module_as_brick" = true ] && [ ! -f "$MODDIR/disable" ]; then
            eco "Flag bricked exists"
            eco "but $MOD_NAME has NOT been disabled"
            eco "Maybe $MOD_NAME is enabled manually"
            rm -f "$FLAG_BRICKED" && eco "Remove flag bricked"
            return 0
        else
            eco "Skip $MOD_NAME process"
            exit 1
        fi
    else
        eco "Flag bricked does NOT exist"
    fi
}

config_loader() {

    eco "Load config"
    brick_rescue=$(get_config_var "brick_rescue" "$CONFIG_FILE") || brick_rescue=true
    disable_module_as_brick=$(get_config_var "disable_module_as_brick" "$CONFIG_FILE") || disable_module_as_brick=true
    last_worked_target_list=$(get_config_var "last_worked_target_list" "$CONFIG_FILE") || last_worked_target_list=true
    slay_mode=$(get_config_var "slay_mode" "$CONFIG_FILE") || slay_mode=MB
    system_app_paths=$(get_config_var "system_app_paths" "$CONFIG_FILE") || system_app_paths="/system/app /system/product/app /system/product/data-app /system/product/priv-app /system/priv-app /system/system_ext/app /system/system_ext/priv-app /system/vendor/app /system/vendor/priv-app"
    print_line
    print_var "brick_rescue" "disable_module_as_brick" "last_worked_target_list" "slay_mode" "system_app_paths"
    print_line
}

preparation() {

    eco "Some preparation"

    if [ "$MIRROR_DIR" != "/" ] && [ "$MIRROR_DIR" != "/system" ]; then
        rm -rf "$MIRROR_DIR" && eco "Remove old mirror dir"
    fi

    if [ "$DETECT_KSU" = true ] || [ "$DETECT_APATCH" = true ]; then
        eco "Make Node support is present"
        MN_SUPPORT=true
        MR_SUPPORT=false
        [ "$slay_mode" = "MR" ] && slay_mode="MB"
    elif [ "$DETECT_MAGISK" = true ]; then
        if [ $MAGISK_V_VER_CODE -ge 28102 ]; then
            eco "Make Node support is present"
            MN_SUPPORT=true
        else
            MN_SUPPORT=false
            [ "$slay_mode" = "MN" ] && slay_mode="MR"
        fi
        eco "Magisk Replace support is present"
        MR_SUPPORT=true
    fi

    if [ "$ROOT_SOL_COUNT" -gt 1 ]; then
        eco "Find multiple root solutions" "W"
        eco "$MOD_NAME will revert to Mount Bind mode"
        slay_mode="MB"
    fi

    mkdir -p "$MIRROR_DIR" && eco "Create new mirror dir"

    if [ ! -f "$TARGET_LIST" ]; then
        eco "Target list does NOT exist" "F"
        DESCRIPTION="[❌Target list file does NOT exist! 🔮Root: $ROOT_SOL_DETAIL] $MOD_INTRO"
        update_config_var "description" "$MODULE_PROP" "$DESCRIPTION"
        exit 1
    fi
}

mirror_make_node() {

    node_path=$1

    if [ -z "$node_path" ]; then
        eco "Node path is NOT defined (5)" "E"
        return 5
    elif [ ! -e "$node_path" ]; then
        eco "$node_path does NOT exist (6)" "E"
        return 6
    fi

    node_path_parent_dir=$(dirname "$node_path")
    mirror_parent_dir="$MODDIR$node_path_parent_dir"
    mirror_node_path="$MODDIR$node_path"

    if [ ! -d "$mirror_parent_dir" ]; then
        mkdir -p "$mirror_parent_dir"
        eco "Create parent dir $mirror_parent_dir"
    fi

    if [ ! -e "$mirror_node_path" ]; then
        mknod "$mirror_node_path" c 0 0
        result_make_node="$?"
        eco "mknod $mirror_node_path c 0 0 ($result_make_node)"
        if [ $result_make_node -eq 0 ]; then
            return 0
        else
            return $result_make_node
        fi
    else
        eco "Node $mirror_node_path exists already"
        return 1
    fi

}

mirror_magisk_replace() {

    replace_path=$1

    if [ -z "$replace_path" ]; then
        eco "Replace path is NOT defined (5)" "E"
        return 5
    elif [ ! -d "$replace_path" ]; then
        eco "$replace_path is NOT a dir (6)" "E"
        return 6
    fi

    mirror_app_path="$MODDIR$replace_path"

    if [ ! -d "$mirror_app_path" ]; then
        mkdir -p "$mirror_app_path"
        eco "Create mirror path $mirror_app_path"
    fi

    if [ ! -e "$mirror_app_path/.replace" ]; then
        touch "$mirror_app_path/.replace"
        result_magisk_replace="$?"
        eco "touch $mirror_app_path/.replace ($result_magisk_replace)"
        if [ $result_magisk_replace -eq 0 ]; then
            return 0
        else
            return $result_magisk_replace
        fi
    else
        return 1
    fi

}

link_mount_bind() {

    link_path=$1
    target_path=$2

    if [ -z "$link_path" ] || [ -z "$target_path" ]; then
        eco "Link path or target path is NOT defined (5)" "E"
        return 5
    elif [ ! -d "$link_path" ] || [ ! -d "$target_path" ]; then
        eco "$link_path or $target_path is NOT a dir (6)" "E"
        return 6
    fi

    mount -o bind "$link_path" "$target_path"
    result_mount_bind="$?"
    eco "mount -o bind $link_path $target_path ($result_mount_bind)"
    if [ $result_mount_bind -eq 0 ]; then
        return 0
    else
        return $result_mount_bind
    fi
}

bloatware_slayer() {

    print_line
    eco "Slaying bloatwares"
    print_line

    total_apps_count=0
    slain_apps_count=0
    duplicated_apps_count=0

    mb_count=0
    mr_count=0
    mn_count=0

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

        total_apps_count=$((total_apps_count+1))

        for path in $system_app_paths; do

            first_char=$(printf '%s' "$line" | cut -c1)
            if [ "$first_char" = "/" ]; then
                app_path="$package"
                case "$app_path" in
                    /apex*|/system/apex*)
                        case "$app_path" in
                            *.apex|*.capex) ;;
                            *)  if [ "${app_path#/apex}" != "$app_path" ]; then
                                    eco "Redirect to /system$app_path" "*"
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
                        eco "Redirect to /system$app_path" "*"
                        app_path="/system$app_path";;
                    /system*)   [ "$app_path" = "/system" ] && break;;
                    *)  break;;
                esac
            else
                app_path="$path/$package"
            fi

            app_name="$(basename "$app_path")"
            if [ -d "$app_path" ]; then
                eco "Process path $app_path"
                case "$slay_mode" in
                    "MB")   link_mount_bind "$MIRROR_DIR" "$app_path";;
                    "MR")   mirror_magisk_replace "$app_path";;
                    "MN")   mirror_make_node "$app_path";;
                esac
                app_process_result=$?
                if [ $app_process_result -eq 0 ]; then
                    case "$slay_mode" in
                    "MB")   mb_count=$((mb_count + 1));;
                    "MR")   mr_count=$((mr_count + 1));;
                    "MN")   mn_count=$((mn_count + 1));;
                    esac
                    if check_duplicate_items "$app_path" "$TARGET_LIST_BSA"; then
                        echo "$app_path" >> "$TARGET_LIST_BSA"
                        slain_apps_count=$((slain_apps_count + 1))
                        eco "$app_name has been slain" ">"
                    else
                        eco "Find duplicate item $app_name"
                        duplicated_apps_count=$((duplicated_apps_count + 1))
                    fi
                    break
                else
                    eco "Failed to slay $app_name ($app_process_result)" "W"
                fi

            elif [ -f "$app_path" ] && [ -d "$(dirname $app_path)" ]; then
                eco "Process path $app_path"
                if [ "$slay_mode" = "MN" ] || [ "$MN_SUPPORT" = true ]; then
                    mirror_make_node "$app_path"
                    file_process_result=$?
                    if [ $file_process_result -eq 0 ]; then
                        mn_count=$((mn_count + 1))
                        if check_duplicate_items "$app_path" "$TARGET_LIST_BSA"; then
                            echo "$app_path" >> "$TARGET_LIST_BSA"
                            slain_apps_count=$((slain_apps_count + 1))
                            eco "$app_name has been slain" ">"
                        else
                            eco "Find duplicate item $app_name"
                            duplicated_apps_count=$((duplicated_apps_count + 1))
                        fi
                        break
                    else
                        eco "Failed to slay $app_name ($file_process_result)" "W"
                    fi
                fi
            else
                if [ "$first_char" = "/" ]; then
                    eco "Custom dir $app_path does NOT exist"
                    break
                else
                    eco "Dir $app_path does NOT exist"
                fi
            fi
        done
    done < "$TARGET_LIST"

    eco "Clean duplicate items"
    clean_duplicate_items "$TARGET_LIST_BSA"

}

module_status_update() {

    apps_not_found_count=$((total_apps_count - slain_apps_count - duplicated_apps_count))
    print_line
    eco "Total: $total_apps_count APP(s)"
    eco "Slain: $slain_apps_count APP(s)"
    eco "with Mount Bind: $mb_count APP(s)"
    eco "with Magisk Replace: $mr_count APP(s)"
    eco "with Make Node: $mn_count APP(s)"
    eco "Not found: $apps_not_found_count APP(s)"
    eco "Duplicate: $duplicated_apps_count APP(s)"

    [ $mb_count -gt 0 ] && slay_mode_desc="Mount Bind"
    [ $mr_count -gt 0 ] && slay_mode_desc="Magisk Replace"
    [ $mn_count -gt 0 ] && slay_mode_desc="Make Node"

    if [ $mb_count -gt 0 ] && [ $mn_count -gt 0 ]; then
        slay_mode_desc="Mount Bind (${mb_count}), Make Node (${mn_count})"
    elif [ $mr_count -ne 0 ] && [ $mn_count -ne 0 ]; then
        slay_mode_desc="Magisk Replace (${mr_count}), Make Node (${mn_count})"
    fi

    desc_last_worked=""
    no_effect=false
    [ "$rescue_from_last_worked_target_list" = true ] && desc_last_worked=" (last worked)"

    if [ -f "$MODULE_PROP" ]; then
        if [ $slain_apps_count -gt 0 ]; then
            if [ $apps_not_found_count -eq 0 ]; then
                DESCRIPTION="✅All done. $slain_apps_count APP(s) slain."
            else
                DESCRIPTION="✅Done. $slain_apps_count APP(s) slain, $apps_not_found_count APP(s) not found, $total_apps_count APP(s) in total."
            fi
        else
            if [ $total_apps_count -gt 0 ]; then
                if [ $duplicated_apps_count -gt 0 ]; then
                    DESCRIPTION="✅Done. $duplicated_apps_count APP(s) slain."
                else
                    DESCRIPTION="⌛Standby. $total_apps_count APP(s) not found."
                    no_effect=true
                fi
            else
                DESCRIPTION="❌No valid items found in target list!"
                no_effect=true
            fi
        fi
        [ "$no_effect" = false ] && DESCRIPTION="[${DESCRIPTION} ✨Mode: ${slay_mode_desc}${desc_last_worked}, 🔮Root: ${ROOT_SOL_DETAIL}] $MOD_INTRO"
        [ "$no_effect" = true ] && DESCRIPTION="[${DESCRIPTION} 🔮Root: ${ROOT_SOL_DETAIL}] $MOD_INTRO"
        update_config_var "description" "$MODULE_PROP" "$DESCRIPTION"
    fi

}

eco_init "$LOG_DIR"
module_intro >> "$LOG_FILE"
show_system_info >> "$LOG_FILE"
print_line
config_loader
unbrick
preparation && bloatware_slayer
module_status_update
print_line
eco "Case closed!"
