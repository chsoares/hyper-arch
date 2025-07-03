// root:/services/ResourceUsage.qml
pragma Singleton
pragma ComponentBehavior: Bound

import "root:/modules/common"
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Service to poll and expose system resource usage (RAM, Swap, CPU, Disk, Temperature, Network).
 */
Singleton {
    // --- Properties ---
	property double memoryTotal: 1
	property double memoryFree: 1
	property double memoryUsed: memoryTotal - memoryFree
    property double memoryUsedPercentage: memoryUsed / memoryTotal
    property double swapTotal: 1
	property double swapFree: 1
	property double swapUsed: swapTotal - swapFree
    property double swapUsedPercentage: swapTotal > 0 ? (swapUsed / swapTotal) : 0
    property double cpuUsage: 0
    property var previousCpuStats // Internal for CPU calculation

    property double diskUsedPercentage: 0
    property double cpuTemperature: 0 // In Celsius
    property double netDownloadSpeed: 0 // In KB/s
    property double netUploadSpeed: 0   // In KB/s
    property var previousNetStats // Internal for network speed calculation

	// --- Main Polling Timer ---
	Timer {
		interval: 1 // Starts fast, then adjusts to Config.options?.resources?.updateInterval
        running: true
        repeat: true
		onTriggered: {
            // Reload file data
            fileMeminfo.reload()
            fileStat.reload()
            fileNetDev.reload()

            // Parse Memory and Swap usage
            const textMeminfo = fileMeminfo.text()
            ResourceUsage.memoryTotal = Number(textMeminfo.match(/MemTotal: *(\d+)/)?.[1] ?? 1)
            ResourceUsage.memoryFree = Number(textMeminfo.match(/MemAvailable: *(\d+)/)?.[1] ?? 0)
            ResourceUsage.swapTotal = Number(textMeminfo.match(/SwapTotal: *(\d+)/)?.[1] ?? 1)
            ResourceUsage.swapFree = Number(textMeminfo.match(/SwapFree: *(\d+)/)?.[1] ?? 0)
            ResourceUsage.memoryUsed = ResourceUsage.memoryTotal - ResourceUsage.memoryFree;
            ResourceUsage.memoryUsedPercentage = ResourceUsage.memoryUsed / ResourceUsage.memoryTotal;
            ResourceUsage.swapUsed = ResourceUsage.swapTotal - ResourceUsage.swapFree;
            ResourceUsage.swapUsedPercentage = ResourceUsage.swapTotal > 0 ? (ResourceUsage.swapUsed / ResourceUsage.swapTotal) : 0;

            // Parse CPU usage
            const textStat = fileStat.text()
            const cpuLine = textStat.match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/)
            if (cpuLine) {
                const stats = cpuLine.slice(1).map(Number)
                const total = stats.reduce((a, b) => a + b, 0)
                const idle = stats[3]

                if (ResourceUsage.previousCpuStats) {
                    const totalDiff = total - ResourceUsage.previousCpuStats.total
                    const idleDiff = idle - ResourceUsage.previousCpuStats.idle
                    ResourceUsage.cpuUsage = totalDiff > 0 ? (1 - idleDiff / totalDiff) : 0
                } else {
                    ResourceUsage.cpuUsage = 0;
                }
                ResourceUsage.previousCpuStats = { total, idle }
            }

            // Trigger Disk Usage Process
            diskUsageProcess.running = false;
            diskUsageProcess.running = true;
            
            // Trigger CPU Temperature Process
            cpuTempProcess.running = false;
            cpuTempProcess.running = true;

            // Parse Network Usage
            const textNetDev = fileNetDev.text()
            // >>> USER ADJUSTMENT: Change 'wlp0s20f3' to your primary network interface name <<<
            // You can find your interface name using 'ip link show' or 'ip a' in your terminal.
            const netLine = textNetDev.match(/enp34s0:\s*(\d+)\s*\d+\s*\d+\s*\d+\s*\d+\s*\d+\s*\d+\s*\d+\s*(\d+)/);
            if (netLine) {
                const receivedBytes = Number(netLine[1]);
                const transmittedBytes = Number(netLine[2]);

                if (ResourceUsage.previousNetStats) {
                    const timeDiffSec = (interval / 1000);
                    if (timeDiffSec > 0) {
                        ResourceUsage.netDownloadSpeed = (receivedBytes - ResourceUsage.previousNetStats.received) / timeDiffSec / 1024; // KB/s
                        ResourceUsage.netUploadSpeed = (transmittedBytes - ResourceUsage.previousNetStats.transmitted) / timeDiffSec / 1024; // KB/s
                    } else {
                        ResourceUsage.netDownloadSpeed = 0;
                        ResourceUsage.netUploadSpeed = 0;
                    }
                } else {
                    ResourceUsage.netDownloadSpeed = 0;
                    ResourceUsage.netUploadSpeed = 0;
                }
                ResourceUsage.previousNetStats = { received: receivedBytes, transmitted: transmittedBytes };
            } else {
                ResourceUsage.netDownloadSpeed = 0;
                ResourceUsage.netUploadSpeed = 0;
            }

            // Update interval based on configuration
            interval = Config.options?.resources?.updateInterval ?? 3000
        }
	}

    // --- File Views ---
	FileView { id: fileMeminfo; path: "/proc/meminfo" }
    FileView { id: fileStat; path: "/proc/stat" }
    FileView { id: fileNetDev; path: "/proc/net/dev" }

    // --- Processes ---
    // Process for Disk Usage
    Process {
        id: diskUsageProcess
        // >>> USER ADJUSTMENT: Change '/home' to '/' if you want to monitor your root filesystem <<<
        command: ["bash", "-c", "df -kP / | awk 'NR==2 {print $3, $2}'"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(/\s+/);
                if (parts.length === 2) {
                    const usedBlocks = Number(parts[0]);
                    const totalBlocks = Number(parts[1]);
                    if (totalBlocks > 0) {
                        ResourceUsage.diskUsedPercentage = usedBlocks / totalBlocks;
                    } else {
                        ResourceUsage.diskUsedPercentage = 0;
                    }
                } else {
                    ResourceUsage.diskUsedPercentage = 0;
                }
            }
        }
        stderr: SplitParser { onRead: data => console.error(`ResourceUsage: Disk process error: ${data.trim()}`); }
    }

    // Process for CPU Temperature
    Process {
        id: cpuTempProcess
        // >>> USER ADJUSTMENT: You MUST customize this command for your specific CPU sensor <<<
        // Run 'sensors -j' in your terminal and identify the JSON path to your CPU temperature.
        // Example path from your output: '."k10temp-pci-00c3".Tctl."temp1_input"'
        command: ["bash", "-c", "sensors -j | jq '.\"k10temp-pci-00c3\".Tctl.\"temp1_input\"'"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                const tempC = parseFloat(data.trim());
                if (!isNaN(tempC)) {
                    ResourceUsage.cpuTemperature = tempC;
                } else {
                    ResourceUsage.cpuTemperature = 0;
                }
            }
        }
        stderr: SplitParser { onRead: data => console.error(`ResourceUsage: Temp process error: ${data.trim()}`); }
    }
}