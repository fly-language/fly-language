package org.xtext.ide

import org.eclipse.xtext.ide.server.codeActions.ICodeActionService2
import org.xtext.ide.server.codeActions.FlyCodeActionService

/**
 * Use this class to register ide components.
 */
class FLYIdeModule extends AbstractFLYIdeModule {
	
	def Class<? extends ICodeActionService2> bindICodeActionService2() {
		FlyCodeActionService
	}
}
