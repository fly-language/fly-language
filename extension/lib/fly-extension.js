"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var fly_lsp_extension_1 = require("./fly-lsp-extension");
var extension;
function activate(context) {
    extension = new fly_lsp_extension_1.FLYLspVscodeExtension(context);
}
exports.activate = activate;
function deactivate() {
    if (!extension)
        return Promise.resolve(undefined);
    return extension.deactivateLanguageClient();
}
exports.deactivate = deactivate;
//# sourceMappingURL=fly-extension.js.map