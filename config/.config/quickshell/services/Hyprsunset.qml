pragma Singleton

import "root:/modules/common"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

/**
 * Simple hyprsunset service with automatic mode.
 * In theory we don't need this because hyprsunset has a config file, but it somehow doesn't work.
 * It should also be possible to control it via hyprctl, but it doesn't work consistently either so we're just killing and launching.
 */
Singleton {
    id: root
    property var manualActive
    property string from: Config.options?.light?.night?.from ?? "19:00" // Default to 7 PM
    property string to: Config.options?.light?.night?.to ?? "06:30" // Default to 6:30 AM
    property bool automatic: Config.options?.light?.night?.automatic && (Config?.ready ?? true)
    property int colorTemperature: Config.options?.light?.night?.colorTemperature ?? 5000 // Default color temperature
    property bool shouldBeOn
    property bool firstEvaluation: true
    property bool active: false

    property int fromHour: Number(from.split(":")[0])
    property int fromMinute: Number(from.split(":")[1])
    property int toHour: Number(to.split(":")[0])
    property int toMinute: Number(to.split(":")[1])

    property int clockHour: DateTime.clock.hours
    property int clockMinute: DateTime.clock.minutes


    function isNoLater(hour1, minute1, hour2, minute2) {
        if (hour1 < hour2)
            return true;
        if (hour1 === hour2 && minute1 < minute2)
            return true;
        return false;
    }


    onClockMinuteChanged: reEvaluate()
    onAutomaticChanged: {
        root.manualActive = undefined;
        root.firstEvaluation = true;
        reEvaluate();
    }
    onFromChanged: {
        root.firstEvaluation = true;
        reEvaluate();
    }
    onToChanged: {
        root.firstEvaluation = true;
        reEvaluate();
    }
    onColorTemperatureChanged: {
        if (root.active) {
            // Re-apply with new temperature
            root.enable();
        }
    }
    function reEvaluate() {
        const toHourIsNextDay = !isNoLater(fromHour, fromMinute, toHour, toMinute);
        
        if (toHourIsNextDay) {
            // Night period crosses midnight (e.g., 19:00 to 06:30)
            // Should be on if: current time >= from OR current time <= to
            const afterStart = isNoLater(fromHour, fromMinute, clockHour, clockMinute) || 
                              (clockHour === fromHour && clockMinute >= fromMinute);
            const beforeEnd = isNoLater(clockHour, clockMinute, toHour, toMinute);
            root.shouldBeOn = afterStart || beforeEnd;
        } else {
            // Normal period within same day (e.g., 09:00 to 17:00)
            const toHourWrapped = toHour;
            const toMinuteWrapped = toMinute;
            root.shouldBeOn = isNoLater(fromHour, fromMinute, clockHour, clockMinute) && isNoLater(clockHour, clockMinute, toHourWrapped, toMinuteWrapped);
        }
        
        if (firstEvaluation) {
            firstEvaluation = false;
            root.ensureState();
        }
    }

    onShouldBeOnChanged: ensureState()
    function ensureState() {
        console.log("[Hyprsunset] Ensuring state - shouldBeOn:", root.shouldBeOn, "automatic:", root.automatic, "manualActive:", root.manualActive, "currentlyActive:", root.active);
        if (!root.automatic || root.manualActive !== undefined) {
            console.log("[Hyprsunset] Skipping ensure state - not in automatic mode or manual override active");
            return;
        }
        if (root.shouldBeOn) {
            console.log("[Hyprsunset] Should be on - enabling");
            root.enable();
        } else {
            console.log("[Hyprsunset] Should be off - disabling");
            root.disable();
        }
    }

    function load() { } // Dummy to force init
    
    // Listen for Hyprland events to handle idle/resume
    Connections {
        target: Hyprland
        
        function onRawEvent(event) {
            // Re-evaluate state when potentially resuming from idle
            // Listen to more events to catch system resume
            if (event.name === "screencast" || 
                event.name === "activewindow" || 
                event.name === "focusedmon" ||
                event.name === "workspace" ||
                event.name === "monitoradded" ||
                event.name === "configreloaded") {
                // Multiple delayed checks to ensure we catch the resume
                stateCheckTimer.restart();
                delayedStateCheckTimer.restart();
            }
        }
    }
    
    // Timer to re-check state after potential idle resume
    Timer {
        id: stateCheckTimer
        interval: 1000 // 1 second delay
        repeat: false
        onTriggered: {
            console.log("[Hyprsunset] Re-checking state after potential resume (1s)");
            forceRestart();
        }
    }
    
    // Second delayed check to catch cases where first check was too early
    Timer {
        id: delayedStateCheckTimer
        interval: 3000 // 3 second delay
        repeat: false
        onTriggered: {
            console.log("[Hyprsunset] Re-checking state after potential resume (3s)");
            forceSync();
        }
    }
    
    // Periodic state verification (every 2 minutes instead of 5)
    Timer {
        id: periodicCheckTimer
        interval: 2 * 60 * 1000 // 2 minutes
        repeat: true
        running: true
        onTriggered: {
            console.log("[Hyprsunset] Periodic state check");
            forceSync();
        }
    }

    function enable() {
        root.active = true;
        // console.log("[Hyprsunset] Enabling");
        Quickshell.execDetached(["bash", "-c", `pidof hyprsunset || hyprsunset --temperature ${root.colorTemperature}`]);
    }

    function disable() {
        root.active = false;
        // console.log("[Hyprsunset] Disabling");
        Quickshell.execDetached(["bash", "-c", `pkill hyprsunset`]);
    }

    function fetchState() {
        fetchProc.running = true;
    }
    
    function forceSync() {
        console.log("[Hyprsunset] Force sync requested");
        // First re-evaluate what state should be
        reEvaluate();
        // Then fetch actual state and ensure it matches
        fetchState();
        // After a delay, ensure state is correct
        Qt.callLater(function() {
            ensureState();
        });
    }
    
    function forceRestart() {
        console.log("[Hyprsunset] Force restart requested - cycling off/on to sync UI");
        if (!root.automatic || root.manualActive !== undefined) {
            console.log("[Hyprsunset] Skipping force restart - not in automatic mode");
            return;
        }
        
        // First check what state should be
        reEvaluate();
        
        if (root.shouldBeOn) {
            console.log("[Hyprsunset] Should be on - forcing restart cycle");
            // Force kill any existing hyprsunset process
            disable();
            // Wait a moment then restart
            restartTimer.restart();
        } else {
            console.log("[Hyprsunset] Should be off - ensuring it's disabled");
            disable();
        }
    }
    
    // Timer to restart hyprsunset after disabling
    Timer {
        id: restartTimer
        interval: 500 // 500ms delay
        repeat: false
        onTriggered: {
            console.log("[Hyprsunset] Restarting hyprsunset after force cycle");
            enable();
        }
    }
    
    // Force a complete state sync on component completion
    Component.onCompleted: {
        console.log("[Hyprsunset] Component completed - performing initial sync");
        // Small delay to ensure all bindings are established
        Qt.callLater(forceSync);
    }

    Process {
        id: fetchProc
        running: true
        command: ["bash", "-c", "hyprctl hyprsunset temperature"]
        stdout: StdioCollector {
            id: stateCollector
            onStreamFinished: {
                const output = stateCollector.text.trim();
                const previousActive = root.active;
                let newActive = false;
                
                console.log("[Hyprsunset] Fetch result:", output, "length:", output.length);
                
                if (output.length == 0 || output.startsWith("Couldn't")) {
                    newActive = false;
                } else {
                    // Consider active if temperature is not the default 6500K
                    newActive = (output !== "6500");
                }
                
                console.log("[Hyprsunset] State update - Previous:", previousActive, "New:", newActive, "Expected:", root.shouldBeOn);
                
                root.active = newActive;
                
                // Always verify state consistency in automatic mode
                if (root.automatic && root.manualActive === undefined) {
                    const expectedActive = root.shouldBeOn;
                    if (root.active !== expectedActive) {
                        console.log("[Hyprsunset] State mismatch! Expected:", expectedActive, "Actual:", root.active, "Will fix...");
                        // Use a small delay to avoid infinite loops
                        fixStateTimer.restart();
                    } else {
                        console.log("[Hyprsunset] State is correct:", root.active);
                    }
                }
            }
        }
        stderr: StdioCollector {
            id: errorCollector
            onStreamFinished: {
                if (errorCollector.text.trim().length > 0) {
                    console.log("[Hyprsunset] Error output:", errorCollector.text.trim());
                }
            }
        }
    }
    
    // Timer to fix state mismatches with a small delay
    Timer {
        id: fixStateTimer
        interval: 500 // 500ms delay
        repeat: false
        onTriggered: {
            console.log("[Hyprsunset] Fixing state mismatch");
            ensureState();
        }
    }

    function toggle() {
        if (root.manualActive === undefined)
            root.manualActive = root.active;

        root.manualActive = !root.manualActive;
        if (root.manualActive) {
            root.enable();
        } else {
            root.disable();
        }
    }
}