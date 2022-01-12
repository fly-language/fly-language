package org.xtext.typing

import org.xtext.fLY.ArithmeticExpression
import org.xtext.fLY.Assignment
import org.xtext.fLY.BinaryOperation
import org.xtext.fLY.BooleanLiteral
import org.xtext.fLY.CastExpression
import org.xtext.fLY.DatSingleObject
import org.xtext.fLY.DatTableObject
import org.xtext.fLY.DeclarationObject
import org.xtext.fLY.FloatLiteral
import org.xtext.fLY.IndexObject
import org.xtext.fLY.NameObject
import org.xtext.fLY.NameObjectDef
import org.xtext.fLY.NumberLiteral
import org.xtext.fLY.ParenthesizedExpression
import org.xtext.fLY.PostfixOperation
import org.xtext.fLY.StringLiteral
import org.xtext.fLY.UnaryOperation
import org.xtext.fLY.VariableDeclaration
import org.xtext.fLY.VariableFunction
import org.xtext.fLY.VariableLiteral
import org.xtext.fLY.ChannelReceive
import org.xtext.fLY.MathFunction
import org.xtext.fLY.TimeFunction

class FlyTypeProvider {
	public static val FlyType stringType = new StringType
	public static val FlyType intType = new NumericalType
	public static val FlyType boolType = new BooleanType
	public static val FlyType floatType = new FloatType
	public static val FlyType datType = new DatType
	public static val FlyType objectType = new ObjectType
	public static val FlyType unknownType = new UnknownType


	def dispatch FlyType typeFor(ArithmeticExpression e) {
		switch (e) {
			StringLiteral: stringType
			NumberLiteral: intType
			BooleanLiteral: boolType
			FloatLiteral: floatType
			NameObject: objectType
			NameObjectDef: objectType
			IndexObject: objectType
			DatSingleObject: objectType
			DatTableObject: datType
			VariableFunction: unknownType
			ChannelReceive: unknownType
			MathFunction: floatType
			TimeFunction: unknownType
			default: null
		}
	}

	def dispatch FlyType typeFor(VariableLiteral e) {
		if (e.variable === null)
			return null
		else
			e.variable.typeFor
	}

	def dispatch FlyType typeFor(VariableDeclaration e) {
		if (e.right !== null)
			return e.right.typeFor
		else
			return objectType
	}

	def dispatch FlyType typeFor(CastExpression e) {
		if (e.type == 'String' || e.type == 'Date')
			return stringType
		else if (e.type == 'Integer')
			return intType
		else if (e.type == 'Double')
			return floatType
		else if (e.type == 'Dat')
			return datType
	}

	def dispatch FlyType typeFor(BinaryOperation e) {
		var leftType = e.left.typeFor
		var rightType = e.right.typeFor
		var op = e.feature
		if (op == '+' || op == '-' || op == '*' || op == '/') {
			if (op == '+' && (leftType == stringType || rightType == stringType)) {
				return stringType
			} else if (leftType == floatType || rightType == floatType) {
				return floatType
			} else {
				return intType
			}
		}
		return boolType
	}

	def dispatch FlyType typeFor(Assignment e){
		return e.value.typeFor
	}
	def dispatch FlyType typeFor(ParenthesizedExpression e) {
		return e.expression.typeFor
	}

	def dispatch FlyType typeFor(UnaryOperation e) {
		val op = e.feature
		if (op == '!')
			return boolType
		else {
			return e.operand.typeFor
		}
	}

	def dispatch FlyType typeFor(PostfixOperation e) {
		return e.variable.typeFor
	}
	
	def dispatch FlyType typeFor(DeclarationObject e) {
		return objectType
	}
}