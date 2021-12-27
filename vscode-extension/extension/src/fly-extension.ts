import * as path from 'path'
import * as vscode from 'vscode';
import {
    LanguageClient,
    LanguageClientOptions,
    ServerOptions,
  } from 'vscode-languageclient/node';

let client: LanguageClient

export function activate(context: vscode.ExtensionContext) {
    const executable = process.platform === 'win32' ? 'fly-server.bat' : 'fly-server';
    const languageServerPath =  path.join('server', 'fly-language-server', 'bin', executable);
    const serverLauncher = context.asAbsolutePath(languageServerPath);
    const serverOptions: ServerOptions = {
        run: {
            command: serverLauncher,
            args: ['-trace']
        },
        debug: {
            command: serverLauncher,
            args: ['-trace']
        }
    };
    const clientOptions: LanguageClientOptions = {
        documentSelector: [{ scheme: 'file', language: 'fly' }],
    };
    const languageClient = new LanguageClient('flyLanguageClient', 'FLY Language Server', serverOptions, clientOptions);
    languageClient.start();
}

export function deactivate(): Thenable<void> {
    if (!client) {
        return client;
    }
    return client.stop();
}
