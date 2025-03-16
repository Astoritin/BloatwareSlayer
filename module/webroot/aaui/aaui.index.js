// Environment values

const moduleDir = "/data/adb/module/bloatwareslayer";
const configDir = "/data/adb/bloatwareslayer";
let moduleProp = `${moduleDir}/module.prop`;

const fs = require("fs");
const path = require("path");

// Get module info

async function getRootSol() {
    try {

        await bsExec(`su -c ". ${moduleDir}/aautilities.sh"`);
        await bsExec("su -c 'install_env_check'");

        const rootSol = fs.readFileSync(tempFilePath, "utf-8").trim();
        console.log("Root Solution:", rootSol);

        fs.unlinkSync(tempFilePath);
        return rootSol;
    } catch (error) {
        console.error("Error getting root solution:", error);
        throw error;
    }
}

// button refresh

document.getElementById('bs_top_btn_refresh').addEventListener('click', () => {
    window.location.reload(true);
});

document.querySelector('.bs_buttons > .button-group-right > mdui-button').addEventListener('click', () => {
    mdui.snackbar({ message: 'Applying settings...' });
});

document.querySelector('.bs_buttons > .button-group-left > mdui-button:nth-child(2)').addEventListener('click', () => {
    mdui.snackbar({ message: 'Resetting settings...' });
});

document.querySelector('.bs_buttons > .button-group-left > mdui-button:nth-child(1)').addEventListener('click', () => {
    mdui.snackbar({ message: 'Discarding changes...' });
});

// Execute shell commands
export async function bsExec(cmd) {

    return new Promise((resolve, reject) => {
        const callbackName = `exec_callback_${Date.now()}`;
        window[callbackName] = (errno, stdout, stderr) => {
            try {
                if (errno === 0) {
                    resolve(stdout);
                } else {
                    toast(`Error executing command "${cmd}": ${stderr}`)
                    console.error(`Error executing command "${cmd}": ${stderr}`);
                    mdui.snackbar({ message: `Error in executing command: ${stderr}`, position: "bottom" });
                    reject(stderr);
                }
            } finally {
                delete window[callbackName];
            }
        };

        try {
            ksu.exec(cmd, "{}", callbackName);
        } catch (error) {
            toast(`Execute error: ${error}`)
            reject(error);
        }
    });
}

// Show notification
export function toast(message) {

    if (window.mdui && typeof window.mdui.snackbar === "function") {
        mdui.snackbar({ message, position: "bottom" });
    } else {
        console.warn(`${message}`);
    }
}
