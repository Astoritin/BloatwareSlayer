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
echo "- If nothing happened after case closed"
echo "- That means I can't find any root file explorer"
echo "- In your device to open config dir"
echo "- Anyway, you can open it on your way"
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
    else
        echo "? $PKG is NOT installed"
        sleep 1
    fi

done

echo "---------------------------------------------------"
echo "- Case closed!"
