package org.xtext.ide.launch

import org.eclipse.sprotty.xtext.launch.DiagramServerLauncher

class FLYServerLauncher extends DiagramServerLauncher{
	override createSetup() {
		new FLYLanguageServerSetup
	}

	def static void main(String[] args) {
		new FLYServerLauncher().run(args)
	}
}