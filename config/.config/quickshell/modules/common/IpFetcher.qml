// root:/modules/common/ipfetcher.qml
import QtQuick
import Quickshell.Io // O IMPORT CERTO PARA Process!
import Quickshell // Mantenha

Item {
    id: root

    property string ipAddress: ""
    property bool tun0IsUp: false

    // O Process que vai buscar o IP
    Process {
        id: ipProcess
        // Define o comando. Teste-o manualmente no terminal com e sem VPN!
        command: ["bash", "-c", "ip -4 addr show tun0 | grep -oP '(?<=inet\\s)\\d+(\\.\\d+){3}'"]
        
        // Inicializa o processo automaticamente
        running: true // <<<< Inicia automaticamente na criação

        stdout: SplitParser {
            onRead: data => {
                const output = data.trim();
                console.log(`ipfetcher.qml (Process stdout): DATA = "${output}"`);
                if (output) {
                    root.ipAddress = output;
                    root.tun0IsUp = true;
                    console.log(`ipfetcher.qml: IP updated to: ${root.ipAddress}`);
                } else {
                    root.ipAddress = ""; // Nenhuma saída = IP não encontrado
                    root.tun0IsUp = false;
                    console.log("ipfetcher.qml: No IP found in stdout. Resetting.");
                }
            }
        }
        
        stderr: SplitParser {
            onRead: errorData => {
                const errorOutput = errorData.trim();
                if (errorOutput) {
                    console.warn(`ipfetcher.qml (Process stderr): ERROR = "${errorOutput}"`);
                }
                // Nao resete o IP apenas por stderr, pode ser um warning.
                // O stdout vazio ja vai resetar se o IP nao for encontrado.
            }
        }

        // AGORA TEMOS onExited!
        onExited: (exitCode, exitStatus) => {
            console.log(`ipfetcher.qml (Process): Command exited with code ${exitCode}, status ${exitStatus}.`);
            // Se exitCode não for 0 e não houve output, garantimos que o IP é resetado.
            if (exitCode !== 0 && root.ipAddress === "") {
                root.tun0IsUp = false;
            }
            // Não precisamos chamar ipProcess.close() ou start() aqui,
            // o Timer abaixo fará o "restart" via 'running'.
        }

        Component.onCompleted: {
            console.log(`ipfetcher.qml (Process): Process component created. Initial command: ${command}`);
        }
    }

    // Timer para REFRESHAR o IP
    Timer {
        id: refreshTrigger
        interval: 5000 // A cada 5 segundos
        running: true
        repeat: true
        onTriggered: {
            console.log("ipfetcher.qml: Timer triggered. Restarting IP process.");
            // O jeito de "restartar" um Process com 'running' é desligar e ligar de novo.
            ipProcess.running = false; // Parar o processo (se estiver rodando)
            ipProcess.running = true;  // Reiniciar o processo
        }
    }

    // A primeira execução já acontece por 'running: true' no Process
    Component.onCompleted: {
        console.log("ipfetcher.qml: Componente IpFetcher inicializado.");
        // Não precisamos chamar fetchIp() ou start() aqui.
        // O Process já inicia sozinho, e o Timer cuida dos refreshes.
    }
}