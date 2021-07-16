package org.xtext.validation

import org.eclipse.xtext.validation.Check
import org.xtext.fLY.FLYPackage
import org.xtext.fLY.FlyFunctionCall
import org.xtext.fLY.FunctionDefinition
import org.xtext.fLY.LocalFunctionCall
import org.xtext.fLY.VariableDeclaration
import org.xtext.fLY.DeclarationObject

class FLYFunctionValidator extends AbstractFLYValidator {
	
	static final String LOCAL_ERR = "Error in local function call: "
	static final String FLY_ERR = "Error in fly function call: "
	
	@Check
	def checkLocalFunctionCall(LocalFunctionCall f) {
		var taken = f.target.parameters.length
		var given = f.input.inputs.length
		if (f.target.parameters.length != f.input.inputs.length) {
			error(String.format(LOCAL_ERR + "the function `%s` takes %d arguments, but %d were given", f.target.name, taken, given),
				FLYPackage.Literals::LOCAL_FUNCTION_CALL__INPUT
			)
		}
	}
	
	@Check
	def checkFlyFunctionCall(FlyFunctionCall f) {
		checkFlyFunctionCallTarget(f.target)
		checkFlyFunctionCallEnvironment(f.environment)
		
	}
	
	def private checkFlyFunctionCallTarget(FunctionDefinition f) {
//		if (f.parameters.length > 0) {
//			error(FLY_ERR + String.format("fly target functions don't accept parameters, but `%s` has %d parameters", f.name, f.parameters.length),
//				FLYPackage.Literals::FLY_FUNCTION_CALL__TARGET
//			)
//		}
	}
	
	def private checkFlyFunctionCallEnvironment(VariableDeclaration v) {
		var correct = false
		
		if (v.right instanceof DeclarationObject) {
			var dec = v.right as DeclarationObject
			
			if (FLYDomainObjectValidator.listEnvironment.contains(dec.features.get(0).value_s))
				correct = true
		}
		
		if (!correct) {
			error(FLY_ERR + String.format("`%s` is not a valid environment", v.name),
				FLYPackage.Literals::FLY_FUNCTION_CALL__ENVIRONMENT
			)
		}
	}
}
