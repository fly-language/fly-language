package org.xtext.ide.launch

import org.eclipse.sprotty.xtext.launch.DiagramServerSocketLauncher

class FLYSocketServer extends DiagramServerSocketLauncher {
	
	override createSetup() {
		new FLYLanguageServerSetup
	}
	
	def static void main(String... args){
		new FLYSocketServer().run(args)
	}
	
}