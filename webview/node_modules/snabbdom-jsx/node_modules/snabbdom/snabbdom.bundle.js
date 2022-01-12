"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var snabbdom_1 = require("./snabbdom");
var attributes_1 = require("./modules/attributes"); // for setting attributes on DOM elements
var class_1 = require("./modules/class"); // makes it easy to toggle classes
var props_1 = require("./modules/props"); // for setting properties on DOM elements
var style_1 = require("./modules/style"); // handles styling on elements with support for animations
var eventlisteners_1 = require("./modules/eventlisteners"); // attaches event listeners
var h_1 = require("./h"); // helper function for creating vnodes
var patch = snabbdom_1.init([
    attributes_1.attributesModule,
    class_1.classModule,
    props_1.propsModule,
    style_1.styleModule,
    eventlisteners_1.eventListenersModule
]);
exports.snabbdomBundle = { patch: patch, h: h_1.h };
exports.default = exports.snabbdomBundle;
//# sourceMappingURL=snabbdom.bundle.js.map