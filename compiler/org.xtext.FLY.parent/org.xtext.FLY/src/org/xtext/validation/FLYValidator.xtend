/*
 * generated by Xtext 2.13.0
 */
package org.xtext.validation

import org.eclipse.xtext.validation.Check
import org.xtext.fLY.DeclarationFeature
import org.xtext.fLY.FLYPackage
import com.google.inject.Inject

class FLYValidator extends AbstractFLYValidator {
	
	@Inject extension FLYDotExpressionValidator
	@Inject extension FLYDomainObjectValidator
	@Inject extension FLYOperationValidator
	@Inject extension FLYFlowControlValidator
	@Inject extension FLYObjectValidator
	@Inject extension FLYFunctionValidator
	
	@Check
	def checkFilePath(DeclarationFeature feature) {
		if (feature.feature == "path" || feature.feature == "name") {
			if (!feature.value_s.matches("^(.*)(.txt|.json|.csv|.img)$"))
				error("Invalid file path. Only json, txt and csv file are permitted", 
					FLYPackage.Literals::DECLARATION_FEATURE__VALUE_S, 
					FLYValidationErrors.INVALID_FILE_TYPE
				)
		}
	}
}

