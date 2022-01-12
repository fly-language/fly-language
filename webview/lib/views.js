"use strict";
/********************************************************************************
 * Copyright (c) 2020 TypeFox and others.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v. 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * This Source Code may also be made available under the following Secondary
 * Licenses when the conditions for such availability set forth in the Eclipse
 * Public License v. 2.0 are satisfied: GNU General Public License, version 2
 * with the GNU Classpath Exception which is available at
 * https://www.gnu.org/software/classpath/license.html.
 *
 * SPDX-License-Identifier: EPL-2.0 OR GPL-2.0 WITH Classpath-exception-2.0
 ********************************************************************************/
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
/** @jsx svg */
var snabbdom_jsx_1 = require("snabbdom-jsx");
var inversify_1 = require("inversify");
var sprotty_1 = require("sprotty");
var PolylineArrowEdgeView = /** @class */ (function (_super) {
    __extends(PolylineArrowEdgeView, _super);
    function PolylineArrowEdgeView() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    PolylineArrowEdgeView.prototype.renderAdditionals = function (edge, segments, context) {
        var p1 = segments[segments.length - 2];
        var p2 = segments[segments.length - 1];
        return [
            snabbdom_jsx_1.svg("path", { "class-sprotty-edge-arrow": true, d: "M 6,-3 L 0,0 L 6,3 Z", transform: "rotate(" + this.angle(p2, p1) + " " + p2.x + " " + p2.y + ") translate(" + p2.x + " " + p2.y + ")" })
        ];
    };
    PolylineArrowEdgeView.prototype.angle = function (x0, x1) {
        return sprotty_1.toDegrees(Math.atan2(x1.y - x0.y, x1.x - x0.x));
    };
    PolylineArrowEdgeView = __decorate([
        inversify_1.injectable()
    ], PolylineArrowEdgeView);
    return PolylineArrowEdgeView;
}(sprotty_1.PolylineEdgeView));
exports.PolylineArrowEdgeView = PolylineArrowEdgeView;
var TriangleButtonView = /** @class */ (function () {
    function TriangleButtonView() {
    }
    TriangleButtonView.prototype.render = function (model, context, args) {
        return snabbdom_jsx_1.svg("path", { "class-sprotty-button": true, d: "M 0,0 L 8,4 L 0,8 Z" });
    };
    TriangleButtonView = __decorate([
        inversify_1.injectable()
    ], TriangleButtonView);
    return TriangleButtonView;
}());
exports.TriangleButtonView = TriangleButtonView;
//# sourceMappingURL=views.js.map