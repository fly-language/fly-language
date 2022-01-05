import * as path from 'path'
import * as vscode from 'vscode';
import {
    LanguageClient,
    LanguageClientOptions,
    ServerOptions,
    TransportKind,
  } from 'vscode-languageclient';


let client: LanguageClient | undefined = undefined;

export function activate(context: vscode.ExtensionContext) {
    const executable = process.platform === 'win32' ? 'fly-server.bat' : 'fly-server';
    const languageServerPath =  path.join('server', 'bin', executable);
    const serverLauncher = context.asAbsolutePath(languageServerPath);

    const serverOptions: ServerOptions = {
        run: {
            command: serverLauncher,
            transport: TransportKind.socket,
            args: ['-trace']
        },
        debug: {
            command: serverLauncher,
            transport: TransportKind.socket,
            args: ['-trace']
        }
    };
    const clientOptions: LanguageClientOptions = {
        documentSelector: [{ scheme: 'file', language: 'fly' }],
    };
    const languageClient = new LanguageClient('flyLanguageClient', 'FLY Language Server', serverOptions, clientOptions, true);

    languageClient.start();
}

export function deactivate(): Thenable<void> {
    if (!client)
       return Promise.resolve(undefined);
    return client.stop();
}

// import * as vscode from 'vscode';
// import { FLYLspVscodeExtension } from './fly-lsp-extension';
// import { SprottyLspVscodeExtension } from 'sprotty-vscode/lib/lsp';

// let extension: SprottyLspVscodeExtension;

// export function activate(context: vscode.ExtensionContext) {
//     extension = new FLYLspVscodeExtension(context);
// }

// export function deactivate(): Thenable<void> {
//     if (!extension)
//        return Promise.resolve(undefined);
//     return extension.deactivateLanguageClient();
// }
