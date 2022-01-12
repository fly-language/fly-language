package org.xtext.ide.diagram

import org.eclipse.sprotty.xtext.DiagramServerFactory

class FLYDiagramServerFactory extends DiagramServerFactory{
	
	override getDiagramTypes() {
		#['fly-diagram']
	}
	
}