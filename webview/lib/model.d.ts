import { Action, CreatingOnDrag, RectangularNode, RectangularPort, SChildElement, SGraphFactory, SModelElementSchema, SParentElement, SRoutableElement } from 'sprotty';
export declare class FLYModelFactory extends SGraphFactory {
    protected initializeChild(child: SChildElement, schema: SModelElementSchema, parent?: SParentElement): SChildElement;
}
export declare class FLYNode extends RectangularNode {
    canConnect(routable: SRoutableElement, role: string): boolean;
}
export declare class CreateTransitionPort extends RectangularPort implements CreatingOnDrag {
    createAction(id: string): Action;
}
//# sourceMappingURL=model.d.ts.map