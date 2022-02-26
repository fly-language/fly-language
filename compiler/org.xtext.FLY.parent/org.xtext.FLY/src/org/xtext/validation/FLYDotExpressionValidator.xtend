package org.xtext.validation

import com.google.inject.Inject
import java.lang.reflect.Method
import java.util.ArrayList
import org.eclipse.xtext.validation.Check
import org.xtext.fLY.Assignment
import org.xtext.fLY.FLYPackage
import org.xtext.fLY.MathFunction
import org.xtext.fLY.NameObject
import org.xtext.fLY.NameObjectDef
import org.xtext.fLY.VariableDeclaration
import org.xtext.fLY.VariableFunction
import org.xtext.typing.FlyMethodProvider
import org.xtext.fLY.ForIndex
import org.xtext.typing.FlyTypeProvider

class FLYDotExpressionValidator extends AbstractFLYValidator {
	
	@Inject extension FlyMethodProvider

	
	@Check
	def checkFunction(VariableFunction v) {
		var methods = v.methodsFor
		var method = v.feature
		
		if (methods !== null && !methods.contains(method)) {		
			error(String.format("Undeclared method"), v, FLYPackage.Literals::VARIABLE_FUNCTION__FEATURE)
		}
	}
	
	@Check
	def checkMathFunction(MathFunction f) {		
		
		var ArrayList<Method> methods = new ArrayList<Method>()
		
		for (var i = 0; i < Math.methods.length; i++) {
			if (Math.methods.get(i).name == f.feature) {
				methods.add(Math.methods.get(i))
			}
		}
		
		
		if (methods.empty) {
			error("Undeclared method for class Math", f, FLYPackage.Literals::MATH_FUNCTION__FEATURE)
			return		
		}

		var valid = false
		for (var i = 0; i < methods.length && !valid; i++) {
			var method = methods.get(i)			
			if (method.parameterCount == f.expressions.length) {
				valid = true	
			}
		}
		
		if (!valid)
			error("Invalid number of attributes", f, FLYPackage.Literals::MATH_FUNCTION__EXPRESSIONS)
		
	}
	
	@Check
	def checkObjectField(NameObject o) {
		var v = o.name
		var field = o.value
		
		if (v instanceof VariableDeclaration && v.eContainer instanceof ForIndex) {
			return
		}
		
		if (v.right instanceof NameObjectDef) {
			if (!(o.eContainer instanceof Assignment)) {
				var obj = v.right as NameObjectDef
				for (var i = 0; i < obj.features.length; i++) {
					if (obj.features.get(i).feature == field) {
						return 
					}
				}
				
				warning(String.format("Undefined feature for the object `%s`", v.name), o, FLYPackage.Literals::NAME_OBJECT__VALUE)
			}
			
		} else {
			error(String.format("`%s` is not an object", v.name), o, FLYPackage.Literals::NAME_OBJECT__VALUE)
		}
	}
}