package org.xtext.validation

import com.google.inject.Inject
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.validation.Check
import org.xtext.fLY.ArithmeticExpression
import org.xtext.fLY.Assignment
import org.xtext.fLY.BinaryOperation
import org.xtext.fLY.FLYPackage
import org.xtext.fLY.Fly
import org.xtext.fLY.FunctionDefinition
import org.xtext.fLY.FunctionReturn
import org.xtext.fLY.ObjectLiteral
import org.xtext.fLY.PostfixOperation
import org.xtext.fLY.UnaryOperation
import org.xtext.fLY.VariableLiteral
import org.xtext.typing.FlyType
import org.xtext.typing.FlyTypeProvider
import org.xtext.fLY.DeclarationObject

class FLYOperationValidator extends AbstractFLYValidator {
	
	@Inject extension FlyTypeProvider
	

	@Check
	def checkBinaryOperation(BinaryOperation e) {
		if (e.feature == "+" || e.feature == "+=") {
			val left = getTypeAndCheckNotNull(e.left, FLYPackage.Literals::BINARY_OPERATION__LEFT)
			val right = getTypeAndCheckNotNull(e.right, FLYPackage.Literals::BINARY_OPERATION__RIGHT)
			if (left == FlyTypeProvider::intType || right == FlyTypeProvider::intType 
				|| (left != FlyTypeProvider::stringType && right != FlyTypeProvider::stringType)
				) {
				if (e.feature == "+=") {
					checkExpectedSame(left, right)
				}
				checkNotBoolean(left, FLYPackage.Literals::BINARY_OPERATION__LEFT)
				checkNotBoolean(right, FLYPackage.Literals::BINARY_OPERATION__RIGHT)
				checkNotObject(left, FLYPackage.Literals::BINARY_OPERATION__LEFT)
				checkNotObject(right, FLYPackage.Literals::BINARY_OPERATION__RIGHT)
				checkNotDat(left, FLYPackage.Literals::BINARY_OPERATION__LEFT)
				checkNotDat(right, FLYPackage.Literals::BINARY_OPERATION__RIGHT)
			}
		} else if (e.feature == "-" || e.feature == "*" || e.feature == "/") {
			val left = getTypeAndCheckNotNull(e.left, FLYPackage.Literals::BINARY_OPERATION__LEFT)
			val right = getTypeAndCheckNotNull(e.right, FLYPackage.Literals::BINARY_OPERATION__RIGHT)
			if (left == FlyTypeProvider::intType || right == FlyTypeProvider::intType ||
				(left != FlyTypeProvider::floatType && right != FlyTypeProvider::floatType
				)) {
				checkNotBoolean(left, FLYPackage.Literals::BINARY_OPERATION__LEFT)
				checkNotBoolean(right, FLYPackage.Literals::BINARY_OPERATION__RIGHT)
				checkNotString(left, FLYPackage.Literals::BINARY_OPERATION__LEFT)
				checkNotString(right, FLYPackage.Literals::BINARY_OPERATION__RIGHT)
				checkNotBoolean(left, FLYPackage.Literals::BINARY_OPERATION__LEFT)
				checkNotBoolean(right, FLYPackage.Literals::BINARY_OPERATION__RIGHT)
				checkNotObject(left, FLYPackage.Literals::BINARY_OPERATION__LEFT)
				checkNotObject(right, FLYPackage.Literals::BINARY_OPERATION__RIGHT)
				checkNotDat(left, FLYPackage.Literals::BINARY_OPERATION__LEFT)
				checkNotDat(right, FLYPackage.Literals::BINARY_OPERATION__RIGHT)
			}
		} else if (e.feature == "and" || e.feature == "or") {
			checkExpectedBoolean(e.left, FLYPackage.Literals::BINARY_OPERATION__LEFT)
			checkExpectedBoolean(e.right, FLYPackage.Literals::BINARY_OPERATION__RIGHT)
		} else if (e.feature == "==" || e.feature == "!=") {
			getTypeAndCheckNotNull(e.left, FLYPackage.Literals::BINARY_OPERATION__LEFT)
			getTypeAndCheckNotNull(e.right, FLYPackage.Literals::BINARY_OPERATION__RIGHT)
		} else if (e.feature == ">=" || e.feature == "<=" || e.feature == "<" || e.feature == ">") {
			val left = getTypeAndCheckNotNull(e.left, FLYPackage.Literals::BINARY_OPERATION__LEFT)
			val right = getTypeAndCheckNotNull(e.right, FLYPackage.Literals::BINARY_OPERATION__RIGHT)
			checkNotBoolean(left, FLYPackage.Literals::BINARY_OPERATION__LEFT)
			checkNotBoolean(right, FLYPackage.Literals::BINARY_OPERATION__RIGHT)
		}
	}

	@Check
	def checkUnaryOperation(UnaryOperation e) {
		if (e.feature == "not") {
			checkExpectedBoolean(e.operand, FLYPackage.Literals::UNARY_OPERATION__OPERAND)
		} else {
			checkNotBoolean(e.operand?.typeFor, FLYPackage.Literals::POSTFIX_OPERATION__VARIABLE)
			checkNotString(e.operand?.typeFor, FLYPackage.Literals::POSTFIX_OPERATION__VARIABLE)
			checkNotObject(e.operand?.typeFor, FLYPackage.Literals::POSTFIX_OPERATION__VARIABLE)
			checkNotDat(e.operand?.typeFor, FLYPackage.Literals::POSTFIX_OPERATION__VARIABLE)
		}
	}

	@Check
	def checkPostfixOperation(PostfixOperation e) {
		checkNotBoolean(e.variable?.typeFor, FLYPackage.Literals::POSTFIX_OPERATION__VARIABLE)
		checkNotString(e.variable?.typeFor, FLYPackage.Literals::POSTFIX_OPERATION__VARIABLE)
		checkNotObject(e.variable?.typeFor, FLYPackage.Literals::POSTFIX_OPERATION__VARIABLE)
		checkNotDat(e.variable?.typeFor, FLYPackage.Literals::POSTFIX_OPERATION__VARIABLE)
	}
	
	@Check
	def checkReturn(FunctionReturn ret){
		var parent=getParent(ret);
		if(!(parent instanceof FunctionDefinition)){
			error("the return must be in a function",FLYPackage.Literals::FUNCTION_RETURN__EXPRESSION, FLYValidationErrors.WRONG_RETURN)
		}
	}
	
	@Check
	def checkAssignment(Assignment a) {
		if (a.feature instanceof VariableLiteral) {
			var v = a.feature as VariableLiteral
			
			if (v.variable.typeobject == "const") {
				error("Cannot assign a new value to a constant", FLYPackage.Literals::ASSIGNMENT__FEATURE)
				return
			}
			
			var left = v.typeFor
			var right = a.value.typeFor
			
			if (right === null) {
				error("Invalid right-value", FLYPackage.Literals::ASSIGNMENT__VALUE)
				return
			}
			
			if (right !== null && left !== null && left !== FlyTypeProvider::unknownType 
				&& right !== left
			) {
				error("Expected the same type, but was " + left + ", " + right,
					FLYPackage.Literals::ASSIGNMENT__OP)
			}
		} else if (a.feature instanceof ObjectLiteral) {
			error("Cannot assign a new value for an object variable", FLYPackage.Literals::ASSIGNMENT__FEATURE)
		}
		
		if (a.value instanceof VariableLiteral) {
			var right = (a.value as VariableLiteral).variable.right
			if (right instanceof DeclarationObject) {
				var type = (right as DeclarationObject).features.get(0).value_s
				
				if (FLYDomainObjectValidator.listEnvironment.contains(type)) {
					error("Environment objects can not be right-value of an assignment",
						FLYPackage.Literals::ASSIGNMENT__VALUE
					)
				}
			}
		}
	}
	
	def private EObject getParent(EObject e){
		if (e instanceof FunctionDefinition || e instanceof Fly){
			return e
		}
		else return getParent(e.eContainer)
	}

	def private checkExpectedSame(Object left, Object right) {
		if (right !== null && left !== null && right != left) {
			error("expected the same type, but was " + left + ", " + right,
				FLYPackage.Literals::BINARY_OPERATION__FEATURE, FLYValidationErrors.WRONG_OPERAND_TYPE)
		}
	}

	def private checkNotBoolean(Object type, EReference reference) {
		if (type == FlyTypeProvider::boolType) {
			error("cannot be Boolean", reference, FLYValidationErrors.WRONG_OPERAND_TYPE)
		}
	}

	def private checkNotString(Object type, EReference reference) {
		if (type == FlyTypeProvider::stringType) {
			error("cannot be String", reference, FLYValidationErrors.WRONG_OPERAND_TYPE)
		}
	}
	

	def private checkNotObject(Object type, EReference reference) {
		if (type == FlyTypeProvider::objectType) {
			error("cannot be Object", reference, FLYValidationErrors.WRONG_OPERAND_TYPE)
		}
	}

	def private checkNotDat(Object type, EReference reference) {
		if (type == FlyTypeProvider::datType) {
			error("cannot be Dat variable", reference, FLYValidationErrors.WRONG_OPERAND_TYPE)
		}
	}

	def private checkExpectedType(ArithmeticExpression exp, FlyType expectedType, EReference reference) {
		val actualType = getTypeAndCheckNotNull(exp, reference)
		if (actualType != expectedType)
			error("expected " + expectedType + " type, but was " + actualType, reference, FLYValidationErrors.WRONG_OPERAND_TYPE)
	}

	def private checkExpectedBoolean(ArithmeticExpression exp, EReference reference) {
		checkExpectedType(exp, FlyTypeProvider::boolType, reference)
	}

//	def private checkExpectedInt(ArithmeticExpression exp, EReference reference) {
//		checkExpectedType(exp, FlyTypeProvider::intType, reference)
//	}

	def private Object getTypeAndCheckNotNull(ArithmeticExpression exp, EReference reference) {
		val type = exp?.typeFor
		if (type === null)
			error("null type", reference, FLYValidationErrors.WRONG_OPERAND_TYPE)
		return type
	}
}