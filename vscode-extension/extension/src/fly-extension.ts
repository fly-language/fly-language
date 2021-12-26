import * as path from 'path'
import * as vscode from 'vscode';
import {
    LanguageClient,
    LanguageClientOptions,
    ServerOptions,
    TransportKind
  } from 'vscode-languageclient/node';

let client: LanguageClient

export function activate(context: vscode.ExtensionContext) {
    const executable = process.platform === 'win32' ? 'fly-ls.bat' : 'fly-ls';
    let serverModule = context.asAbsolutePath(path.join('server', 'fly-language-server', executable))

    let debugOptions = {execArgv: ['--nolazy', '--inspect=6009']}

    let serverOptions: ServerOptions = {
        run: { module: serverModule, transport: TransportKind.ipc },
        debug: {
            module: serverModule,
            transport: TransportKind.ipc,
            options: debugOptions
        }
    };

    const clientOptions: LanguageClientOptions = {
        documentSelector: [{ scheme: 'file', language: 'fly' }],
    };

    client = new LanguageClient(
        'flyLanguageClient', 
        'FLY Language Server', 
        serverOptions, 
        clientOptions
    );

    client.start();
}

export function deactivate(): Thenable<void> {
    if (!client) {
        return client;
    }
    return client.stop();
}
