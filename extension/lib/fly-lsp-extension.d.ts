import * as vscode from 'vscode';
import { LanguageClient } from 'vscode-languageclient';
import { SprottyLspEditVscodeExtension } from "sprotty-vscode/lib/lsp/editing";
import { SprottyDiagramIdentifier } from 'sprotty-vscode/lib/lsp';
import { SprottyWebview } from 'sprotty-vscode/lib/sprotty-webview';
export declare class FLYLspVscodeExtension extends SprottyLspEditVscodeExtension {
    constructor(context: vscode.ExtensionContext);
    protected getDiagramType(commandArgs: any[]): string | undefined;
    createWebView(identifier: SprottyDiagramIdentifier): SprottyWebview;
    protected activateLanguageClient(context: vscode.ExtensionContext): LanguageClient;
}
//# sourceMappingURL=fly-lsp-extension.d.ts.map