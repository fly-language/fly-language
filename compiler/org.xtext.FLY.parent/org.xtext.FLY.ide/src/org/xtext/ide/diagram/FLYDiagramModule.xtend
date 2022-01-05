package org.xtext.ide.diagram

import org.eclipse.sprotty.xtext.DefaultDiagramModule
import org.eclipse.sprotty.xtext.IDiagramGenerator

class FLYDiagramModule extends DefaultDiagramModule {
	
	def Class<? extends IDiagramGenerator> bindIDiagramGenerator() {
		FLYDiagramGenerator
	} 
	
	override bindIDiagramServerFactory() {
		FLYDiagramServerFactory
	}
	
	override bindILayoutEngine() {
		FLYLayoutEngine
	}
	
	override bindIDiagramServer() {
		FLYDiagramServer
	}	
	
}