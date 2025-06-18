#!/system/bin/sh
MODDIR=${0%/*}

ROOT_FILE_MANAGERS="
com.speedsoftware.rootexplorer/com.speedsoftware.rootexplorer.RootExplorer
com.mixplorer/com.mixplorer.activities.BrowseActivity
bin.mt.plus/.Main
bin.mt.plus/bin.mt.plus.Main
com.lonelycatgames.Xplore/com.lonelycatgames.Xplore.Browser
com.ghisler.android.TotalCommander/com.ghisler.android.TotalCommander.MainActivity
pl.solidexplorer2/pl.solidexplorer.activities.MainActivity
com.amaze.filemanager/com.amaze.filemanager.activities.MainActivity
io.github.muntashirakon.AppManager/io.github.muntashirakon.AppManager.fm.FmActivity
io.github.muntashirakon.AppManager.debug/io.github.muntashirakon.AppManager.fm.FmActivity
nextapp.fx/nextapp.fx.ui.ExplorerActivity
me.zhanghai.android.files/me.zhanghai.android.files.filelist.FileListActivity
"

echo "---------------------------------------------------"
echo "- Bloatware Slayer"
echo "- By Astoritin Ambrosius"
echo "---------------------------------------------------"
echo "- Opening config dir"
echo "---------------------------------------------------"
sleep 1

IFS=$'\n'

for fm in $ROOT_FILE_MANAGERS; do

    PKG=${fm%/*}

    if pm path "$PKG" >/dev/null 2>&1; then
        echo "> Launching $PKG"
        am start -n "$fm" "file://$CONFIG_DIR"
        result_action="$?"
        echo "- am start -n $fm file://$CONFIG_DIR ($result_action)"
        if [ $result_action -eq 0 ]; then
            echo "---------------------------------------------------"
            echo "- Case closed!"
            sleep 2
            exit 0
        fi
    else
        echo "? $PKG is NOT installed"
        sleep 1
    fi

done

echo "---------------------------------------------------"
echo "! Not any available Root File Explorer found!"
echo "! Please open config dir manually if needed!"
echo "---------------------------------------------------"
echo "- Case closed!"
