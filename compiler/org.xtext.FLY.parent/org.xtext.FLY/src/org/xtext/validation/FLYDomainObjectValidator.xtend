package org.xtext.validation

import java.util.ArrayList
import java.util.Arrays
import java.util.HashMap
import java.util.List
import org.eclipse.xtext.validation.Check
import org.xtext.fLY.DeclarationObject
import org.xtext.fLY.FLYPackage
import org.xtext.fLY.VariableDeclaration

class FLYDomainObjectValidator extends AbstractFLYValidator {
	
	public static ArrayList<String> listEnvironment = new ArrayList(Arrays.asList("aws","aws-debug","azure","smp"));
	public static ArrayList<String> awsEnvAttrs = new ArrayList(Arrays.asList("type", "profile", "access_id_key", "secret_access_key", "region", "language", "nthread", "memory", "seconds"))
	public static ArrayList<String> azureEnvAttrs = new ArrayList(Arrays.asList("type", "client_id", "tenant_id", "secret_key", "subscription_id", "region", "language", "nthread", "seconds"))
	
	@Check
	def checkVariableDeclaration(VariableDeclaration dec) {
		if (dec.right instanceof DeclarationObject){
			checkDeclarationObject(dec)			
		}
	}
	
	@Check
	def checkCapitalizedEnvironment(VariableDeclaration dec) {
		if (dec.right !== null && dec.right instanceof DeclarationObject) {
			var right = (dec.right as DeclarationObject)
			if (right.features.length > 0 && right.features.get(0).feature == "type" && listEnvironment.contains(right.features.get(0).value_s)) {
				if (Character.isLowerCase(dec.name.charAt(0)))
					warning("Usually environment vars are capitalized", FLYPackage.Literals::VARIABLE_DECLARATION__NAME, FLYValidationErrors.WARNING_UNCAPITALIZE_ENVIRONMENT, dec.name)
			}
		}
	}
	
	def private checkDeclarationObject(VariableDeclaration variable) {
		var dec = (variable.right as DeclarationObject)
		if (dec.features.get(0).feature != "type"){
			error("Missing type attribute",FLYPackage.Literals::VARIABLE_DECLARATION__RIGHT,FLYValidationErrors.MISSING_ATTR)
		}
		
		if (dec.features.get(0).value_s.nullOrEmpty){
			error("Attribute type must be a non-empty String",FLYPackage.Literals::VARIABLE_DECLARATION__RIGHT,FLYValidationErrors.WRONG_ATTR_TYPE)
		}
		
		var type = dec.features.get(0).value_s
		if (listEnvironment.contains(type)) {
			checkEnvironment(dec)
			checkInvalidOnClause(variable)
		} else if(type.equals("channel")) {
			checkChannelDeclaration(variable)
		} else if(type.equals("random")) {
			checkRandomDeclaration(dec)
			checkInvalidOnClause(variable)
		} else if(type.equals("file")) {
			checkFileDeclaration(dec)
			checkFileEnvironment(variable)
		} else if(type.equals("dataframe")) {
			checkDataframeDeclaration(variable)
		} else if(type == "query") {
			checkQueryDeclaration(dec)
			checkInvalidOnClause(variable)
		} else if(type == "sql") {
			checkSQLEnvironment(variable)			
		} else {
			error("Wrong type attribute.", FLYPackage.Literals::VARIABLE_DECLARATION__RIGHT, FLYValidationErrors.WRONG_ATTR_TYPE)
		}
	}

	def checkSQLEnvironment(VariableDeclaration v) {
		val smpAttrs = Arrays.asList("type", "db_name", "username", "password")
		val awsAttrs = Arrays.asList("type", "instance", "db_name", "username", "password")
		val azureAttrs = Arrays.asList("type", "resource_group", "instance", "db_name", "username", "password")
		
		var List<String> attrs = null
		var List<String> optAttrs = Arrays.asList()
		if (!v.onCloud) {
			attrs = smpAttrs
			optAttrs = Arrays.asList("endpoint")
		} else {
			var env = v.environment.get(0)
			if (!(env.right instanceof DeclarationObject)) {
				error("Error in SQL declaration: invalid environment", FLYPackage.Literals::VARIABLE_DECLARATION__ENVIRONMENT)
				return				
			}
			
			switch ((env.right as DeclarationObject).features.get(0).value_s) {
				case "aws": {
					attrs = awsAttrs
				}
				case "azure": {
					attrs = azureAttrs
				}
				case "smp": {
					attrs = smpAttrs
					optAttrs = Arrays.asList("endpoint")
				}
				default: {
					error("Error in SQL declaration: invalid environment", FLYPackage.Literals::VARIABLE_DECLARATION__ENVIRONMENT)
					return	
				}
			}
		}
		
		var dec = v.right as DeclarationObject
		
		for (var i = 0; i < attrs.length; i++) {
			var expected = attrs.get(i)
			if (dec.features.length <= i) {
				error(String.format("Error in SQL declaration: expected attribute `%s` in position `%d`", expected, i),
					FLYPackage.Literals::VARIABLE_DECLARATION__RIGHT,
					FLYValidationErrors.WRONG_SQL_DECLARATION)
				return
			}
			var actual = dec.features.get(i).feature
			
			if (actual != expected) {
				error(String.format("Error in SQL declaration: expected attribute `%s` in position `%d` instead of `%s`", expected, i, actual),
					FLYPackage.Literals::VARIABLE_DECLARATION__RIGHT,
					FLYValidationErrors.WRONG_SQL_DECLARATION)
				return
			}
		}
		
		for (var i = attrs.length; i < attrs.length + optAttrs.length; i++) {
			var expected = optAttrs.get(i - attrs.length)
			if (dec.features.length > i) {
				var actual = dec.features.get(i).feature
				
				if (actual != expected) {
					error(String.format("Error in SQL declaration: optional attribute `%s` in position `%d` instead of `%s`", expected, i, actual),
						FLYPackage.Literals::VARIABLE_DECLARATION__RIGHT,
						FLYValidationErrors.WRONG_SQL_DECLARATION)
					return
				}
			}
		}
	}
	
	def private checkQueryDeclaration(DeclarationObject o) {
		val ERRMSG = "Error in query declaration: "
		var expectedAttrs = Arrays.asList("type", "query_type", "connection", "statement")
		
		for (var i = 0; i < expectedAttrs.length; i++) {
			if (i >= o.features.length) {
				error(ERRMSG + String.format("expected attribute `%s` at position %d", expectedAttrs.get(i), i),
					FLYPackage.Literals::VARIABLE_DECLARATION__RIGHT, 
					FLYValidationErrors.WRONG_QUERY_ATTRIBUTES
				)
				return
			}
			
			if (o.features.get(i).feature != expectedAttrs.get(i)) {
				error(ERRMSG + String.format("found attribute `%s` at position %d instead of `%s`", o.features.get(i).feature, i, expectedAttrs.get(i)),
					FLYPackage.Literals::VARIABLE_DECLARATION__RIGHT, 
					FLYValidationErrors.WRONG_QUERY_ATTRIBUTES
				)
				return
			}
		}
		
		if (o.features.length > expectedAttrs.length) {
			warning("Warning in query declaration: unnecessary attributes specified",
				FLYPackage.Literals::VARIABLE_DECLARATION__RIGHT, 
				FLYValidationErrors.WRONG_QUERY_ATTRIBUTES
			)
		}
		
		val queryTypes = Arrays.asList("value", "update")
		if (!queryTypes.contains(o.features.get(1).value_s)) {
			error(ERRMSG + "you must use a valid query type " + queryTypes,
				o.features.get(1),
				FLYPackage.Literals::DECLARATION_FEATURE__VALUE_S,
				FLYValidationErrors.WRONG_QUERY_TYPE
			)
		}
		
		if (o.features.get(2).value_f === null
			|| !(o.features.get(2).value_f.right instanceof DeclarationObject)
			|| (o.features.get(2).value_f.right as DeclarationObject).features.get(0).value_s != "sql"
		) {
			error(ERRMSG + "you must use a valid sql connection",
				o.features.get(2),
				FLYPackage.Literals::DECLARATION_FEATURE__VALUE_F,
				FLYValidationErrors.WRONG_QUERY_ATTR
			)
		}
		
		if (o.features.get(3).value_s.isNullOrEmpty) {
			error(ERRMSG + "the query's statement can't be empty",
				o.features.get(3),
				FLYPackage.Literals::DECLARATION_FEATURE__VALUE_S,
				FLYValidationErrors.WRONG_QUERY_ATTR
			)
		} else if (!isQueryStatementValid(o.features.get(1).value_s, o.features.get(3).value_s)) {
			error(ERRMSG + "the query's doesn't match with the query type",
				o.features.get(3),
				FLYPackage.Literals::DECLARATION_FEATURE__VALUE_S,
				FLYValidationErrors.WRONG_QUERY_ATTR
			)
		}
	}
	
	def private boolean isQueryStatementValid(String operation, String query) {
		var regex = ""
		switch (operation) {
			case "value": {
				regex = "^SELECT (\\*|\\w+) FROM (\\w+).*$"
			}
			case "update": { 
				regex = "^(INSERT|UPDATE|DELETE) .*$"
			}
			default:
				return false
		}
		return query.matches(regex)
	}
	
	def private checkDataframeDeclaration(VariableDeclaration variable) {		
		val ERROR = "Error in Dataframe declaration: "
		val WARNING = "Warning in Dataframe declaration: "
		
		var dec = (variable.right as DeclarationObject)
		
		val mandatory_attrs = Arrays.asList("type", "name", "source")
		
		for (var i = 1; i < mandatory_attrs.length; i++) {
			var expected = mandatory_attrs.get(i)
			if (i >= dec.features.length) {
				error(ERROR + String.format("expected attribute '%s' in position %d", expected, i), 
					FLYPackage.Literals::VARIABLE_DECLARATION__RIGHT, FLYValidationErrors.DATAFRAME_DECLARATION_ERROR)
				return 
			}
			
			var actual = dec.features.get(i).feature
			if (actual != expected) {
				error(ERROR + String.format("expected attribute '%s' in position %d instead of '%s'", expected, i, actual), 
					FLYPackage.Literals::VARIABLE_DECLARATION__RIGHT, FLYValidationErrors.DATAFRAME_DECLARATION_ERROR)
				return 
			}
		}
		
		var name = dec.features.get(1).value_s
		if (name.isNullOrEmpty) {
			error(ERROR + "attribute 'name' must be a non-empty string", 
					FLYPackage.Literals::VARIABLE_DECLARATION__RIGHT, FLYValidationErrors.DATAFRAME_DECLARATION_ERROR)
		}
		var source = dec.features.get(2)
		
		if (source.value_s.isNullOrEmpty) {
			if (source.value_f === null	|| !checkIfHasType(source.value_f, "file")) {
				error(ERROR + "'source' attribute must be a non-empty string or a valid File variable", 
					FLYPackage.Literals::VARIABLE_DECLARATION__RIGHT, FLYValidationErrors.DATAFRAME_EMPTY_SOURCE_QUERY)
				return 
			}
			if (dec.features.length > 3 && dec.features.get(3).feature != "query") {
				error(ERROR + String.format("expected 'query' instead of %s", dec.features.get(3).feature), 
					FLYPackage.Literals::VARIABLE_DECLARATION__RIGHT, FLYValidationErrors.DATAFRAME_EMPTY_SOURCE_QUERY)
				return 
			}
			if (dec.features.length > 4) {
				warning(WARNING + "unnecessary attributes specified", 
					FLYPackage.Literals::VARIABLE_DECLARATION__RIGHT, FLYValidationErrors.DATAFRAME_UNNECESSARY_ATTRS)
			}
		} else {
			if (dec.features.length > 3 && dec.features.get(3).feature != "sep") {
				error(ERROR + String.format("expected 'sep' instead of %s", dec.features.get(3).feature), 
					FLYPackage.Literals::VARIABLE_DECLARATION__RIGHT, FLYValidationErrors.DATAFRAME_INVALID_OPTIONAL_ATTRS)
				return 
			}
			if (dec.features.length > 4 && dec.features.get(4).feature != "header") {
				error(ERROR + String.format("expected 'header' instead of %s", dec.features.get(3).feature), 
					FLYPackage.Literals::VARIABLE_DECLARATION__RIGHT, FLYValidationErrors.DATAFRAME_INVALID_OPTIONAL_ATTRS)
				return 
			}
			if (dec.features.length > 5) {
				warning(WARNING + "unnecessary attributes specified", 
					FLYPackage.Literals::VARIABLE_DECLARATION__RIGHT, FLYValidationErrors.DATAFRAME_UNNECESSARY_ATTRS)
			}
		}
		
		if (variable.onCloud) {
			if (variable.environment.length > 1) {
				warning(WARNING + "only the first environment will be evaluated", FLYPackage.Literals::VARIABLE_DECLARATION__ON_CLOUD, FLYValidationErrors.DATAFRAME_UNNECESSARY_ENVIRONMENT)
			}
			
			var env = variable.environment.get(0)
			var cloud_env = env.right as DeclarationObject
			
			if (cloud_env.features.length < 1 
				|| cloud_env.features.get(0).feature != "type" 
				|| cloud_env.features.get(0).value_s == "smp"
				|| !listEnvironment.contains(cloud_env.features.get(0).value_s)
				) {
				error(ERROR + "you must specify a cloud based environment", FLYPackage.Literals::VARIABLE_DECLARATION__ENVIRONMENT, FLYValidationErrors.DATAFRAME_INVALID_ENVIRONMENT)
			}
		}
	}
	
	def private checkFileDeclaration(DeclarationObject dec) {
		if (dec.features.length < 2) {
			error("Invalid File declaration: you must specify the path", FLYPackage.Literals::VARIABLE_DECLARATION__RIGHT, FLYValidationErrors.FILE_DECLARATION_ERROR)
		} else if (dec.features.get(1).feature != "path") {
			error(String.format("Invalid File declaration: expected attribute 'path' instead than '%s'", dec.features.get(1).feature), FLYPackage.Literals::VARIABLE_DECLARATION__RIGHT, FLYValidationErrors.FILE_DECLARATION_ERROR)
		} else if (dec.features.get(1).value_s.isNullOrEmpty && dec.features.get(1).value_f === null) {
			error("Invalid File declaration: the attribute 'path' must be a string or a variable", FLYPackage.Literals::VARIABLE_DECLARATION__RIGHT, FLYValidationErrors.FILE_DECLARATION_ERROR)
		} else if (dec.features.length == 3) {
			if (dec.features.get(2).feature != "sep") {
				warning("Unnecessary attribute in File declaration", FLYPackage.Literals::VARIABLE_DECLARATION__RIGHT, FLYValidationErrors.FILE_UNNECESSARY_ATTRIBUTES)
			}
		} else if (dec.features.length > 3) {
			warning("Unnecessary attribute in File declaration", FLYPackage.Literals::VARIABLE_DECLARATION__RIGHT, FLYValidationErrors.FILE_UNNECESSARY_ATTRIBUTES)
		}
	}
	
	def private checkFileEnvironment(VariableDeclaration dec) {
		if (dec.onCloud) {
			if (dec.environment.length > 1) {
				warning("Warning in File declaration: only the first environment will be evaluated",
					FLYPackage.Literals::VARIABLE_DECLARATION__ON_CLOUD, FLYValidationErrors.FILE_UNNECESSARY_ENVIRONMENT)
			}
			
			var env = (dec.environment.get(0).right as DeclarationObject)
			if (env.features == 0 || env.features.get(0).feature != "type" 
				|| env.features.get(0).value_s.isNullOrEmpty
				|| !listEnvironment.contains(env.features.get(0).value_s) 
				|| env.features.get(0).value_s == "smp"
			) {
				error("Invalid File declaration: you must specify a cloud based environment", FLYPackage.Literals::VARIABLE_DECLARATION__ENVIRONMENT, FLYValidationErrors.FILE_INVALID_ENVIRONMENT)
			}
		}
	} 
	
	def private checkRandomDeclaration(DeclarationObject dec) {
		if (dec.features.length > 1) {
			warning("Unnecessary attributes in random variable declaration", FLYPackage.Literals::VARIABLE_DECLARATION__ON_CLOUD, FLYValidationErrors.UNNECESSARY_RANDOM_ATTRIBUTES)
		}
	}
	
	def private checkInvalidOnClause(VariableDeclaration dec) {
		if (dec.onCloud) {
			error("Invalid 'on' keyword", FLYPackage.Literals::VARIABLE_DECLARATION__ON_CLOUD, FLYValidationErrors.INVALID_ON_KEYWORD)
		}
	}
	
	def private checkChannelDeclaration(VariableDeclaration dec) {
		if (!dec.onCloud) {
			error("Channel error: you must specify an environment", FLYPackage.Literals::VARIABLE_DECLARATION__RIGHT, FLYValidationErrors.CHANNEL_DECLARATION_ERROR)
		}
		var env = dec.environment.get(0)
		if (env.right === null || !(env.right instanceof DeclarationObject)
			|| (env.right as DeclarationObject).features.length < 1
			|| (env.right as DeclarationObject).features.get(0).feature != "type"
			|| !listEnvironment.contains((env.right as DeclarationObject).features.get(0).value_s)) {
			
			error("Channel error: the specified variable is not environment", FLYPackage.Literals::VARIABLE_DECLARATION__ENVIRONMENT, FLYValidationErrors.CHANNEL_DECLARATION_ERROR)
			return
		}
		
		if (dec.environment.length > 1) {
			warning("Channel warning: only the first environment will be evaluated", FLYPackage.Literals::VARIABLE_DECLARATION__ENVIRONMENT, FLYValidationErrors.CHANNEL_UNNECESSARY_ENVIONMENTS, env.name)
		}
		
		if ((dec.right as DeclarationObject).features.length > 1) {
			warning("Channel warning: unnecessary attributes", FLYPackage.Literals::VARIABLE_DECLARATION__RIGHT, FLYValidationErrors.CHANNEL_UNNECESSARY_ATTRS)
		}
	}
	
	def private checkEnvironment(DeclarationObject right){
		var type = right.features.get(0).value_s
		
		if(type.equals("smp")){
			checkSMPEnvironment(right)
		} else if(type.equals("aws") || type.equals("aws-debug")){
			checkAWSEnvironment(right)
		} else if(type.equals("azure")){
			checkAzureEnvironment(right)
		}
	}
	
	def private checkSMPEnvironment(DeclarationObject right) {
		val ENVERROR = "Error in local environment declaration: "
		
		if (right.features.length < 2 || !right.features.get(1).feature.equals("nthread")) {
			error(ENVERROR + "missing argument nthread", FLYPackage.Literals::VARIABLE_DECLARATION__RIGHT, FLYValidationErrors.WRONG_SMP_DECLARATION)
			return
		} else if (!right.features.get(1).value_s.isNullOrEmpty || right.features.get(1).value_t <= 2) {
			error(ENVERROR + "nthread must be an integer greater than 2", FLYPackage.Literals::VARIABLE_DECLARATION__RIGHT, FLYValidationErrors.WRONG_ATTR)
			return
		}
		
		if(right.features.length!=2){
			warning("Warning in local environment declaration: only two arguments are needed.", FLYPackage.Literals::VARIABLE_DECLARATION__RIGHT, FLYValidationErrors.WRONG_SMP_DECLARATION)
		}
	}
	
	def private checkAzureEnvironment(DeclarationObject right) {
		val ENVERROR = "Error in Azure environment declaration: "
		val ENVWARNING = "Warning in Azure environment declaration: "
		val meta = FLYPackage.Literals::VARIABLE_DECLARATION__RIGHT
		
		var mins = new HashMap<String, Integer>()
		var maxs = new HashMap<String, Integer>()
		mins.put("nthread", 3); maxs.put("nthread", 1000)
		mins.put("seconds", 1); maxs.put("seconds", 600)
		
		for (var i = 1; i < azureEnvAttrs.length; i++) {
			var expected = azureEnvAttrs.get(i)
			if (i >= right.features.length) {
				error(ENVERROR + String.format("Expected attribute %s in position %d", expected, i), meta, FLYValidationErrors.WRONG_AZURE_DECLARATION)
				return
			}
			var feature = right.features.get(i)
			
			if (!expected.equals(feature.feature)) {
				error(ENVERROR + String.format("expected attribute %s in position %d instead of %s", expected, i, feature.feature), meta, FLYValidationErrors.WRONG_AZURE_DECLARATION)
				return
			} else if (!mins.keySet().contains(feature.feature) && feature.value_s.isNullOrEmpty) {
				error(ENVERROR + String.format("attribute %s must be non-empty string", expected), meta, FLYValidationErrors.WRONG_AZURE_ATTR)
			} else if (mins.keySet().contains(feature.feature)) {
				if (!feature.value_s.isNullOrEmpty || feature.value_t < mins.get(feature.feature) || feature.value_t > maxs.get(feature.feature)) {
					error(ENVERROR + String.format("%s must be an integer between %d and %d", expected, mins.get(feature.feature), maxs.get(feature.feature)), meta, FLYValidationErrors.WRONG_AWS_ATTR)
				}
			}
		}
		
		if (right.features.length > azureEnvAttrs.length) {
			warning(ENVWARNING + "unecessary attributes", meta, FLYValidationErrors.UNNECESSARY_AZURE_ATTRS)
		}
	}
	
	def private checkAWSEnvironment(DeclarationObject right) {
		val ENVERROR = "Error in AWS environment declaration: "
		val ENVWARNING = "Warning in AWS environment declaration: "
		val meta = FLYPackage.Literals::VARIABLE_DECLARATION__RIGHT
		
		var mins = new HashMap<String, Integer>()
		var maxs = new HashMap<String, Integer>()
		mins.put("nthread", 3); maxs.put("nthread", 1000)
		mins.put("memory", 128); maxs.put("memory", 3008)
		mins.put("seconds", 1); maxs.put("seconds", 900)
		
		for (var i = 1; i < awsEnvAttrs.length; i++) {
			var expected = awsEnvAttrs.get(i)
			if (i >= right.features.length) {
				error(ENVERROR + String.format("Expected attribute %s in position %d", expected, i), meta, FLYValidationErrors.WRONG_AWS_DECLARATION, expected)
				return
			}
			var feature = right.features.get(i)
			
			if (!expected.equals(feature.feature)) {
				error(ENVERROR + String.format("expected attribute %s in position %d instead of %s", expected, i, feature.feature), meta, FLYValidationErrors.WRONG_AWS_DECLARATION)
				return
			} else if (!mins.keySet().contains(feature.feature) && feature.value_s.isNullOrEmpty) {
				error(ENVERROR + String.format("attribute %s must be non-empty string", expected), meta, FLYValidationErrors.WRONG_AWS_ATTR)
			} else if (mins.keySet().contains(feature.feature)) {
				if (!feature.value_s.isNullOrEmpty || feature.value_t < mins.get(feature.feature) || feature.value_t > maxs.get(feature.feature)) {
					error(ENVERROR + String.format("%s must be an integer between %d and %d", expected, mins.get(feature.feature), maxs.get(feature.feature)), meta, FLYValidationErrors.WRONG_AWS_ATTR)
				}
			}
		}
		
		if (right.features.length > awsEnvAttrs.length) {
			warning(ENVWARNING + "unecessary attributes", meta, FLYValidationErrors.UNNECESSARY_AWS_ATTRS)
		}
	}	
	
	def private checkIfHasType(VariableDeclaration variable, String type) {
		if (variable.right !== null && variable.right instanceof DeclarationObject) {
			var dec = (variable.right as DeclarationObject)
			if (dec.features.length > 0 && dec.features.get(0).feature == "type" && dec.features.get(0).value_s == type)
				return true
		}
		return false
	}
	

	
}
