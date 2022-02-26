package org.xtext.typing

import java.util.ArrayList
import java.util.Arrays
import java.util.List
import org.xtext.fLY.DeclarationObject
import org.xtext.fLY.VariableFunction
import org.xtext.fLY.MathFunction

class FlyMethodProvider {
	
	public static val emptyList = new ArrayList<String>()
	public static val queryMethods = Arrays.asList("execute")
	public static val randomMethods = Arrays.asList("nextBoolean", "nextDouble", "nextInt")
	public static val channelMethods = Arrays.asList("close")
	public static val dataframeMethods = Arrays.asList("exportHeader", "export")
	
	def dispatch List<String> methodsFor(VariableFunction l) {
		var v = l.target
		if (v.right instanceof DeclarationObject) {
			return methodsFor(v.right as DeclarationObject)
		}
		
		return emptyList
	}
	
	def dispatch List<String> methodsFor(DeclarationObject d) {			
		if (d.features.length > 0 && d.features.get(0).feature == "type") {
			switch d.features.get(0).value_s {
				case "query": {
					return queryMethods
				}
				case "random": {
					return randomMethods
				}
				case "channel": {
					return channelMethods
				}
				case "dataframe": {
					return dataframeMethods
				}
			}
		}
		
		return emptyList
	}
	
//	def dispatch List<String> methodsFor(MathFunction f) {
//
//		var ret = new ArrayList<String>()
//
//		for (var i = 0; i < Math.methods.length; i++) {
//			ret.add(Math.methods.get(i).name)
//		}
//
//		return ret
//	}
}