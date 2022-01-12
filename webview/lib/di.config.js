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
Object.defineProperty(exports, "__esModule", { value: true });
require("../css/diagram.css");
require("sprotty/css/sprotty.css");
var inversify_1 = require("inversify");
var sprotty_1 = require("sprotty");
var custom_edge_router_1 = require("./custom-edge-router");
var model_1 = require("./model");
var views_1 = require("./views");
var flyDiagramModule = new inversify_1.ContainerModule(function (bind, unbind, isBound, rebind) {
    rebind(sprotty_1.TYPES.ILogger).to(sprotty_1.ConsoleLogger).inSingletonScope();
    rebind(sprotty_1.TYPES.LogLevel).toConstantValue(sprotty_1.LogLevel.warn);
    rebind(sprotty_1.TYPES.IModelFactory).to(model_1.FLYModelFactory);
    unbind(sprotty_1.ManhattanEdgeRouter);
    bind(sprotty_1.ManhattanEdgeRouter).to(custom_edge_router_1.CustomRouter).inSingletonScope();
    var context = { bind: bind, unbind: unbind, isBound: isBound, rebind: rebind };
    sprotty_1.configureModelElement(context, 'graph', sprotty_1.SGraph, sprotty_1.SGraphView, {
        enable: [sprotty_1.hoverFeedbackFeature, sprotty_1.popupFeature]
    });
    sprotty_1.configureModelElement(context, 'node', model_1.FLYNode, sprotty_1.RectangularNodeView);
    sprotty_1.configureModelElement(context, 'label', sprotty_1.SLabel, sprotty_1.SLabelView, {
        enable: [sprotty_1.editLabelFeature]
    });
    sprotty_1.configureModelElement(context, 'label:xref', sprotty_1.SLabel, sprotty_1.SLabelView, {
        enable: [sprotty_1.editLabelFeature]
    });
    sprotty_1.configureModelElement(context, 'edge', sprotty_1.SEdge, views_1.PolylineArrowEdgeView);
    sprotty_1.configureModelElement(context, 'html', sprotty_1.HtmlRoot, sprotty_1.HtmlRootView);
    sprotty_1.configureModelElement(context, 'pre-rendered', sprotty_1.PreRenderedElement, sprotty_1.PreRenderedView);
    sprotty_1.configureModelElement(context, 'palette', sprotty_1.SModelRoot, sprotty_1.HtmlRootView);
    sprotty_1.configureModelElement(context, 'routing-point', sprotty_1.SRoutingHandle, sprotty_1.SRoutingHandleView);
    sprotty_1.configureModelElement(context, 'volatile-routing-point', sprotty_1.SRoutingHandle, sprotty_1.SRoutingHandleView);
    sprotty_1.configureModelElement(context, 'port', model_1.CreateTransitionPort, views_1.TriangleButtonView, {
        enable: [sprotty_1.popupFeature, sprotty_1.creatingOnDragFeature]
    });
    sprotty_1.configureCommand(context, sprotty_1.CreateElementCommand);
});
function createFLYDiagramContainer(widgetId) {
    var container = new inversify_1.Container();
    sprotty_1.loadDefaultModules(container);
    container.load(flyDiagramModule);
    sprotty_1.overrideViewerOptions(container, {
        needsClientLayout: true,
        needsServerLayout: true,
        baseDiv: widgetId,
        hiddenDiv: widgetId + '_hidden'
    });
    return container;
}
exports.createFLYDiagramContainer = createFLYDiagramContainer;
//# sourceMappingURL=di.config.js.map