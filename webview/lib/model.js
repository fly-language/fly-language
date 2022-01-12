"use strict";
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
var inversify_1 = require("inversify");
var sprotty_1 = require("sprotty");
var FLYModelFactory = /** @class */ (function (_super) {
    __extends(FLYModelFactory, _super);
    function FLYModelFactory() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    FLYModelFactory.prototype.initializeChild = function (child, schema, parent) {
        _super.prototype.initializeChild.call(this, child, schema, parent);
        if (child instanceof sprotty_1.SEdge) {
            child.routerKind = sprotty_1.ManhattanEdgeRouter.KIND;
            child.targetAnchorCorrection = Math.sqrt(5);
        }
        else if (child instanceof sprotty_1.SLabel) {
            child.edgePlacement = {
                rotate: true,
                position: 0.6
            };
        }
        return child;
    };
    FLYModelFactory = __decorate([
        inversify_1.injectable()
    ], FLYModelFactory);
    return FLYModelFactory;
}(sprotty_1.SGraphFactory));
exports.FLYModelFactory = FLYModelFactory;
var FLYNode = /** @class */ (function (_super) {
    __extends(FLYNode, _super);
    function FLYNode() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    FLYNode.prototype.canConnect = function (routable, role) {
        return true;
    };
    return FLYNode;
}(sprotty_1.RectangularNode));
exports.FLYNode = FLYNode;
var CreateTransitionPort = /** @class */ (function (_super) {
    __extends(CreateTransitionPort, _super);
    function CreateTransitionPort() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    CreateTransitionPort.prototype.createAction = function (id) {
        return new sprotty_1.CreateElementAction(this.root.id, {
            id: id, type: 'edge', sourceId: this.parent.id, targetId: this.id
        });
    };
    return CreateTransitionPort;
}(sprotty_1.RectangularPort));
exports.CreateTransitionPort = CreateTransitionPort;
//# sourceMappingURL=model.js.map