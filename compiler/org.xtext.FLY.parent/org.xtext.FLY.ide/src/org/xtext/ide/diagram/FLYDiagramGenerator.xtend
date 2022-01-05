package org.xtext.ide.diagram

import org.eclipse.sprotty.xtext.IDiagramGenerator
import org.eclipse.sprotty.xtext.IDiagramGenerator.Context
import org.xtext.fLY.Fly
import com.google.inject.Inject
import org.eclipse.sprotty.xtext.tracing.ITraceProvider
import org.eclipse.sprotty.xtext.SIssueMarkerDecorator
import org.eclipse.sprotty.SModelElement
import org.eclipse.emf.ecore.EObject
import org.eclipse.sprotty.SGraph
import org.eclipse.sprotty.SNode
import org.xtext.fLY.Expression
import org.eclipse.sprotty.SLabel
import org.eclipse.sprotty.SPort
import org.eclipse.sprotty.LayoutOptions
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.sprotty.SEdge

class FLYDiagramGenerator implements IDiagramGenerator {
	
	
	@Inject extension ITraceProvider
	@Inject extension SIssueMarkerDecorator
	
	EStructuralFeature EXPRESSION__NAME
	
	override generate(Context context) {
		println("sto generando il diagramma")
		(new SGraph [
			id = "FLY Program"
			children = (context.resource.contents.toList.map[toSNode(context)])
		]).traceAndMark(context.resource.contents.head, context)
	}
	
	
	def SNode toSNode(EObject exp, extension Context context) {
		val theId = idCache.uniqueId(exp, exp.toString) 
		println("sto generando il nodo con id "+theId)
		(new SNode [
			id = theId
			 children =  #[
			 	(new SLabel [
			 		id = idCache.uniqueId(theId + '.label')
			 		text = "prova" 
			 	]).trace(exp, EXPRESSION__NAME, -1)
			// 	new SPort [
			// 		id = idCache.uniqueId(theId + '.newTransition')
			// 	]				
			]
			layout = 'stack'
			layoutOptions = new LayoutOptions [
				paddingTop = 10.0
				paddingBottom = 10.0
				paddingLeft = 10.0
				paddingRight = 10.0
				
			]
		]).traceAndMark(exp, context)
	}
	
// 	def SEdge toSEdge(Expression transition, extension Context context) {
// 		(new SEdge [
// //			sourceId = idCache.getId(transition.eContainer) 
// //			targetId = idCache.getId(transition.state)
// //			val theId = idCache.uniqueId(transition, sourceId + ':' + transition.event.name + ':' + targetId)
// //			id = theId 
// //			children = #[
// //				(new SLabel [
// //					id = idCache.uniqueId(theId + '.label')
// //					type = 'label:xref'
// //					text = transition.event.name
// //				]).trace(transition, StatesPackage.Literals.TRANSITION__EVENT, -1)
// //			]
// 		]).traceAndMark(transition, context)
// 	}
	
	def <T extends SModelElement> T traceAndMark(T sElement, EObject element, Context context) {
		sElement.trace(element).addIssueMarkers(element, context) 
	}
}