package org.xtext.validation

import com.google.inject.Inject
import java.util.ArrayList
import java.util.HashSet
import org.eclipse.xtext.validation.Check
import org.xtext.fLY.ArithmeticExpression
import org.xtext.fLY.ArrayDefinition
import org.xtext.fLY.ArrayInit
import org.xtext.fLY.ArrayValue
import org.xtext.fLY.DeclarationObject
import org.xtext.fLY.FLYPackage
import org.xtext.fLY.NameObjectDef
import org.xtext.fLY.NumberLiteral
import org.xtext.fLY.UnaryOperation
import org.xtext.fLY.VariableLiteral
import org.xtext.typing.FlyType
import org.xtext.typing.FlyTypeProvider

class FLYObjectValidator extends AbstractFLYValidator {
	
	@Inject extension FlyTypeProvider
	
	@Check
	def checkNameObjectDef(NameObjectDef o) {
		var names = new HashSet<String>()
		
		for (var i = 0; i < o.features.length; i++) {
			var f = o.features.get(i)
			if (f.feature !== null && names.contains(f.feature)) {
				error("Duplicate field in object declaration", f, FLYPackage.Literals::FEAUTURE_NAME__FEATURE)
			} else if (f.feature !== null) {
				names.add(f.feature)
			}
			
			if (f.value instanceof VariableLiteral) {
				var v = f.value as VariableLiteral
				if (v.variable.right instanceof DeclarationObject) {
					var dec = v.variable.right as DeclarationObject
					if (FLYDomainObjectValidator.listEnvironment.contains(dec.features.get(0).value_s)) {
						error("Cannot insert an environment variable as object value", f, FLYPackage.Literals::FEAUTURE_NAME__FEATURE)
					}
				}
			}
		}
	}
	
	@Check
	def checkArrayDefinition(ArrayDefinition o) {
		for (var i = 0; i < o.indexes.length; i++) {
			var idx = o.indexes.get(i)
			if (idx.value.typeFor !== FlyTypeProvider::intType
				|| idx.value instanceof UnaryOperation
				|| (idx.value as NumberLiteral).value < 1
			) {
				error("Invalid array definition: indexes must be positive integer", idx, FLYPackage.Literals::INDEX__VALUE)
			}
		}
	}
	
	@Check
	def checkArrayInit(ArrayInit o) {
		if (o === null || o.values === null || o.values.length == 0)
			return
			
		var  dimension = getArrayDimension(o.values.get(0))
		
		var ArrayList<FlyType> types = new ArrayList<FlyType>
		for (var i = 0; i < o.values.length; i++) {
			var tmp = checkArrayInitHelper(o.values.get(i) as ArrayValue, 1, dimension)
			types.add(tmp)
		}
		
		var different_types = false
		var all_empty = false
		
		if (types.length == 1) {
			if (types.get(0) === null || types.get(0) === FlyTypeProvider::unknownType)
				all_empty = true
		} else if (types.length > 1) {
			if (types.get(0) === null) {
				different_types = true
			} else {				
				all_empty = types.get(0) === FlyTypeProvider::unknownType ? true : false
				for (var i = 1; i < types.length; i++) {
					if (all_empty && types.get(i) !== FlyTypeProvider::unknownType)
						all_empty = false
					if (types.get(i) === null || types.get(i) !== types.get(i - 1))
						different_types = true
				}
			}
		}
		
		if (different_types)
			error("Invalid array initialization: all element must be of the same type", o.eContainer, FLYPackage.Literals::VARIABLE_DECLARATION__RIGHT)
		if (all_empty)
			error("Invalid array initialization: can not initialize empty vector", o.eContainer, FLYPackage.Literals::VARIABLE_DECLARATION__RIGHT)
			
	}
	
	def private FlyType checkArrayInitHelper(ArrayValue o, int layer, int depth) {
		if (layer > depth) {
			return null
		}
		
		if (o instanceof ArithmeticExpression) {
			if (layer == depth)			
				return (o as ArithmeticExpression).typeFor
			return null
		}
		
		var FlyType type = null
		
		for (var i = 0; i < o.values.length; i++) {
			var tmp = checkArrayInitHelper(o.values.get(i) as ArrayValue, layer + 1, depth)
			if (i == 0 && tmp !== null) {
				type = tmp
			} else if (tmp !== type || tmp === null) {
				return null
			}
		}
		
		if (o.values.length > 0)
			return type
		else
			return FlyTypeProvider::unknownType
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