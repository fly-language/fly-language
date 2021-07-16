package org.xtext.validation

import org.eclipse.xtext.validation.Check
import org.xtext.fLY.ArithmeticExpression
import org.xtext.fLY.ArrayDefinition
import org.xtext.fLY.ArrayInit
import org.xtext.fLY.ArrayValue
import org.xtext.fLY.DeclarationObject
import org.xtext.fLY.FLYPackage
import org.xtext.fLY.ForExpression
import org.xtext.fLY.RangeLiteral
import org.xtext.fLY.VariableDeclaration
import org.xtext.fLY.VariableLiteral
import org.xtext.fLY.WhileExpression
import org.xtext.typing.FlyTypeProvider
import com.google.inject.Inject
import org.xtext.fLY.IfExpression

class FLYFlowControlValidator extends AbstractFLYValidator {
	
	@Inject extension FlyTypeProvider
	
	static final String ARRAY_OBJECT = "array"
	static final String DATAFRAME_OBJECT = "dataframe"
	static final String RANGE_OBJECT = "range"
	static final String OBJECT = "object"
	
	@Check
	def checkIf(IfExpression e) {
		var type = e.cond.typeFor
		
		if (type !== FlyTypeProvider::boolType) {
			error(String.format("Type mismatch: cannot convert from %s to %s", type, FlyTypeProvider.boolType),
				FLYPackage.Literals::IF_EXPRESSION__COND
			)
		}
	}
	
	@Check
	def checkWhile(WhileExpression e) {
		var type = e.cond.typeFor
		
		if (type !== FlyTypeProvider::boolType) {
			error(String.format("Type mismatch: cannot convert from %s to %s", type, FlyTypeProvider.boolType),
				FLYPackage.Literals::WHILE_EXPRESSION__COND
			)
		}
	}
	
	@Check
	def checkFor(ForExpression e) {
		checkForObjectDeclaration(e.object)
		
		if (!isMatrix(e.object) && e.delimeter !== null) {
			error("You can use delimiter only if you are using a matrix as for object",
				FLYPackage.Literals::FOR_EXPRESSION__DELIMETER
			)
		}
	}
	
	
	def private checkForObjectDeclaration(ArithmeticExpression object) {
		val meta = FLYPackage.Literals::FOR_EXPRESSION__OBJECT
		
		if (!(getType(object) == ARRAY_OBJECT)
			&& !(getType(object) == DATAFRAME_OBJECT)
			&& !(getType(object) == RANGE_OBJECT)
			&& !(getType(object) == OBJECT)
			) {
 			error(String.format("Invalid type for object delcaration, found %s", object.typeFor), meta, FLYValidationErrors.WRONG_FOR_OBJECT_DECLARATION)
		}
	}
	
	def private String getType(ArithmeticExpression e) {
		if (e instanceof RangeLiteral) {
			return RANGE_OBJECT
		} else if (e instanceof VariableLiteral) {
			if (e.variable instanceof VariableDeclaration) {
				var v = (e.variable as VariableDeclaration)
				if (v.right instanceof DeclarationObject) {
					var o = (v.right as DeclarationObject)
					if (o.features.get(0).feature == "type" && o.features.get(0).value_s == "dataframe")
						return DATAFRAME_OBJECT
				} else if (v.right instanceof ArrayDefinition || v.right instanceof ArrayInit) {
					return ARRAY_OBJECT
				} else {
					return OBJECT
				}
			}
		}
		
		return null
	}
	
	def private boolean isMatrix(ArithmeticExpression e) {
		if (getType(e) == DATAFRAME_OBJECT) {
			return true
		}
		
		if (getType(e) == ARRAY_OBJECT) {
			var arr = (e as VariableLiteral).variable.right
			if (arr instanceof ArrayDefinition) {
				var arr2 = arr as ArrayDefinition
				if (arr2.indexes.length == 2)
					return true 
			} else if (arr instanceof ArrayInit) {
				var arr2 = arr as ArrayInit
				if (arr2.values.length > 0 && getArrayDimension(arr2.values.get(0)) == 2)
					return true
			}
		}
		
		return false
	}
	
	def private int getArrayDimension(ArrayValue o) {
		var size = 1
		
		if (o instanceof ArithmeticExpression)
			return 1
		
		var tmp = o
		while (tmp !== null && tmp.values !== null && tmp.values.length > 0 && tmp.values.get(0) instanceof ArrayValue) {
			size += 1
			tmp = tmp.values.get(0) as ArrayValue
		}
		
		return size
	}
}