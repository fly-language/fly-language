import * as vscode from 'vscode';
import { FLYLspVscodeExtension } from './fly-lsp-extension';
import { SprottyLspVscodeExtension } from 'sprotty-vscode/lib/lsp';

let extension: SprottyLspVscodeExtension;

export function activate(context: vscode.ExtensionContext) {
    extension = new FLYLspVscodeExtension(context);
}

export function deactivate(): Thenable<void> {
    if (!extension)
       return Promise.resolve(undefined);
    return extension.deactivateLanguageClient();
}
