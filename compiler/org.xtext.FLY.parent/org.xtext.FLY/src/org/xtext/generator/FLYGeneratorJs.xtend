package org.xtext.generator

import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.xtext.fLY.FunctionDefinition
import org.xtext.fLY.BlockExpression
import org.xtext.fLY.Expression
import java.util.List
import java.util.HashMap
import org.xtext.fLY.VariableDeclaration
import org.xtext.fLY.ChannelSend
import org.xtext.fLY.NameObjectDef
import org.xtext.fLY.ArithmeticExpression
import org.xtext.fLY.DeclarationObject
import org.xtext.fLY.IfExpression
import org.xtext.fLY.ForExpression
import org.xtext.fLY.WhileExpression
import org.xtext.fLY.Assignment
import org.xtext.fLY.PrintExpression
import org.xtext.fLY.CastExpression
import org.xtext.fLY.ChannelReceive
import org.xtext.fLY.NameObject
import org.xtext.fLY.IndexObject
import org.xtext.fLY.VariableLiteral
import org.xtext.fLY.RangeLiteral
import org.xtext.fLY.BinaryOperation
import org.xtext.fLY.UnaryOperation
import org.xtext.fLY.PostfixOperation
import org.xtext.fLY.ParenthesizedExpression
import org.xtext.fLY.NumberLiteral
import org.xtext.fLY.BooleanLiteral
import org.xtext.fLY.FloatLiteral
import org.xtext.fLY.StringLiteral
import org.xtext.fLY.VariableFunction
import org.xtext.fLY.TimeFunction
import org.xtext.fLY.MathFunction
import org.xtext.fLY.DatTableObject
import org.xtext.fLY.RequireExpression
import org.xtext.fLY.NativeExpression
import org.xtext.fLY.FlyFunctionCall
import org.xtext.fLY.ArrayDefinition
import org.xtext.fLY.ConstantDeclaration
import org.xtext.fLY.LocalFunctionCall
import org.xtext.fLY.ArrayInit
import org.xtext.fLY.ArrayValue
import org.eclipse.emf.common.util.EList
import java.util.HashSet
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtend.lib.macro.declaration.Declaration
import org.xtext.fLY.DeclarationFeature
import java.util.ArrayList
import java.util.Arrays
import org.xtext.fLY.FunctionReturn


class FLYGeneratorJs extends AbstractGenerator {
	
	String name= ""
	String env = ""
	String language = ""
	int memory = 0
	int nthread = 0
	int time = 0
	FunctionDefinition root = null
	HashMap<String, FunctionDefinition> functionCalled = null
	Resource resourceInput
	String env_name=""
	var id_execution = null
	var user = ""
	HashMap<String, HashMap<String, String>> typeSystem = null
	boolean isLocal;
	boolean isAsync;
	var list_environment = new ArrayList<String>(Arrays.asList("smp","aws","aws-debug","azure"));
	
	
	def generateJS(Resource input, IFileSystemAccess2 fsa, IGeneratorContext context,String name_file, FunctionDefinition func, 
		VariableDeclaration environment, HashMap<String, HashMap<String, String>> scoping, long id,boolean local,boolean async){
		this.name=name_file
		this.root = func
		this.typeSystem=scoping
		this.resourceInput = input
		this.id_execution = id
		this.env_name = environment.name
		if(!local){
			this.env = (environment.right as DeclarationObject).features.get(0).value_s
			this.user = (environment.right as DeclarationObject).features.get(1).value_s
			this.language = (environment.right as DeclarationObject).features.get(5).value_s
			this.nthread = (environment.right as DeclarationObject).features.get(6).value_t
			this.memory = (environment.right as DeclarationObject).features.get(7).value_t
			this.time = (environment.right as DeclarationObject).features.get(8).value_t
		}else{
			this.env="smp"
			this.nthread = (environment.right as DeclarationObject).features.get(1).value_t
			this.language = (environment.right as DeclarationObject).features.get(2).value_s
		}
		functionCalled = new HashMap<String, FunctionDefinition>();
		for (element : input.allContents.toIterable.filter(FunctionDefinition)
			.filter[it.name != root.name]
			.filter[it.body.expressions.toList.filter(NativeExpression).length>0]) {

			functionCalled.put(element.name,element)
		}
		this.isAsync = async
		this.isLocal = local 
		doGenerate(input,fsa,context) 
	}
	
	def channelsNames(BlockExpression exps,String env) {

		var names = new HashSet<String>();		
		val chRecvs = resourceInput.allContents
				.filter[it instanceof ChannelReceive]
				.filter[functionContainer(it) === root.name]
				.filter[((it as ChannelReceive).target.environment.get(0).right as DeclarationObject).features.get(0).value_s.contains(env)] 
				.map[it as ChannelReceive]
				.map[it.target as VariableDeclaration]
				
				.map[it.name]
		val chSends = resourceInput.allContents
				.filter[it instanceof ChannelSend]
				.filter[functionContainer(it) === root.name]
				.filter[((it as ChannelSend).target.environment.get(0).right as DeclarationObject).features.get(0).value_s.contains(env)] 
				.map[it as ChannelSend]
				.map[it.target as VariableDeclaration]
				.map[it.name]
				
		while(chRecvs.hasNext()) {
			names.add(chRecvs.next())
		}
		while(chSends.hasNext()) {
			names.add(chSends.next())
		}
		
		return names.toArray()
	}
	
	def functionContainer(EObject e) {
		var parent = e.eContainer
		if (parent === null) {
			return ""
		} else if (parent instanceof FunctionDefinition) {
			return (parent as FunctionDefinition).name
		} else {
			return functionContainer(parent)
		}
	}
	
	override doGenerate(Resource input, IFileSystemAccess2 fsa, IGeneratorContext context) {
		//fsa.generateFile(name + ".js", input.compileJS(root, env));
	if (this.isLocal) {
		fsa.generateFile(root.name + ".js", input.compileJavaScript(root.name, true))	
	}else {
		if(env.equals("aws-debug"))
				fsa.generateFile("docker-compose-script.sh",input.compileDockerCompose())
			fsa.generateFile(root.name +"_"+ env_name +"_deploy.sh", input.compileScriptDeploy(root.name, false))
			fsa.generateFile(root.name +"_"+ env_name + "_undeploy.sh", input.compileScriptUndeploy(root.name, false))
		}
	}
	
	def CharSequence compileJavaScript(Resource resource, String string, boolean local)
	'''
		«generateLocalBodyJs(root.body,root.parameters,name,env, local)»
	'''
	
	def generateLocalBodyJs(BlockExpression expression, EList<Expression> list, String string, String string2, boolean b) {
		'''
			var __dataframe = require("dataframe-js").DataFrame;
			export.main = async => {
				
			}
		'''
	}
	
	def CharSequence compileJS(Resource resource, FunctionDefinition func, String env) '''
		«generateBodyJs(resource,func.body,func.parameters,func.name,env)»
	'''
	
	def generateBodyJs(Resource resource,BlockExpression exps,List<Expression> parameters, String name, String env) {
		
		'''
			«IF env.contains("aws")»
			var __AWS = require("aws-sdk");
			
				«IF env.equals("aws")»
					var __sqs = new __AWS.SQS();
					var __rds = new __AWS.RDS();
				«ELSE»
				__AWS.config.update({
				    accessKeyId: "dummy",
				    secretAccessKey: "dummy",
				    region:"us-east-1",
				    logger: process.stdout
				})
				var __sqs = new __AWS.SQS({endpoint: "http://192.168.0.1:4576"});
				«ENDIF»
			let __params;
			let __data;
			«ENDIF»
			
			«IF env.equals("azure")»
			var __azure = require("azure-storage");
			var __queueSvc = __azure.createQueueService("'${storageName}'", "'${storageKey}'");
			var __axios = require("axios");
			var __qs = require("qs");
			«ENDIF»
			var __util = require("util");
			var __dataframe = require("dataframe-js").DataFrame;
			var __mysql = require("mysql");
			var __nosql = require("mongodb");
			var __fs = require("fs")
			var __parse = require("csv-parse");
			
			«FOR req: exps.expressions.filter(RequireExpression)»
			
			«ENDFOR»
			
			
			«FOR exp : resource.allContents.toIterable.filter(ConstantDeclaration)»
				«generateConstantDefinition(exp,name)»
			«ENDFOR»
			
			«IF env.contains("aws")»
			exports.handler = async (event,context) => {
			«ELSEIF env == "azure"»
				module.exports = async function (context, req) {
					let __scope = "https://management.azure.com/.default";
									
					let __urlToken ="https://login.microsoftonline.com/" + "'${tenant}'" + "/oauth2/v2.0/token";
					
					const __postData = {
					  grant_type: "client_credentials",
					  client_id: "'${user}'",
					  client_secret: "'${secret}'",
					  scope: __scope
					};
					
					__axios.defaults.headers.post["Content-Type"] = "application/x-www-form-urlencoded";
					
					var __reqToken = await __axios.post(__urlToken, __qs.stringify(__postData));
					    
					var __token = __reqToken.data.access_token;
			«ENDIF»
			
				
				«FOR exp : parameters»
					«IF env.contains("aws")»
						«IF typeSystem.get(name).get((exp as VariableDeclaration).name).equals("Table")»
							var __data_«(exp as VariableDeclaration).name» = await new __dataframe(event.data);
							var «(exp as VariableDeclaration).name» = __data_«(exp as VariableDeclaration).name».toArray();
						«ELSEIF  typeSystem.get(name).get((exp as VariableDeclaration).name).contains("Array")»
							var __«(exp as VariableDeclaration).name»_length = event.data[0].portionLength;
							var __portionIndex = event.data[0].portionIndex;
							var __portionDisplacement = event.data[0].portionDisplacement;
							var __«(exp as VariableDeclaration).name»_values = event.data[0].portionValues;
							
							«(exp as VariableDeclaration).name» = [];
							for (var __i = 0;__i < __«(exp as VariableDeclaration).name»_length; __i++) {
								«(exp as VariableDeclaration).name»[__i] = __«(exp as VariableDeclaration).name»_values[__i];
							}
						«ELSEIF  typeSystem.get(name).get((exp as VariableDeclaration).name).contains("Matrix")»
							var __«(exp as VariableDeclaration).name»_matrix = event.data[0]
							var __«(exp as VariableDeclaration).name»_rows = event.data[0].portionRows;
							var __«(exp as VariableDeclaration).name»_cols = event.data[0].portionCols;
							var __portionIndex = event.data[0].portionIndex;
							var __portionDisplacement = event.data[0].portionDisplacement;
							var __«(exp as VariableDeclaration).name»_values = event.data[0].portionValues;
							var __index = 0;
							«(exp as VariableDeclaration).name» = [];
							for (var __i = 0;__i < __«(exp as VariableDeclaration).name»_rows; __i++) {
								«(exp as VariableDeclaration).name»[__i] = [];
								for (var __j = 0;__j < __«(exp as VariableDeclaration).name»_cols; __j++) {
									«(exp as VariableDeclaration).name»[__i][__j] = __«(exp as VariableDeclaration).name»_values[__index].value;
									__index+=1;
								}
							}
						«ELSE»
							var «(exp as VariableDeclaration).name» = event.data;
						«ENDIF»
					«ELSEIF env.contains("azure")»
						«IF typeSystem.get(name).get((exp as VariableDeclaration).name).equals("Table")»
							var __«(exp as VariableDeclaration).name» = await new __dataframe((req.query.data || (req.body && req.body.data)));
							var «(exp as VariableDeclaration).name» = __«(exp as VariableDeclaration).name».toArray();
						«ELSEIF  typeSystem.get(name).get((exp as VariableDeclaration).name).contains("Array")»
							var __data = await new Object((req.query.data || (req.body && req.body.data)))[0];

							var __«(exp as VariableDeclaration).name»_length = __data.portionLength;
							var __portionIndex = __data.portionIndex;
							var __portionDisplacement = __data.portionDisplacement;
							var __«(exp as VariableDeclaration).name»_values = __data.portionValues;
							
							«(exp as VariableDeclaration).name» = [];
							for (var __i = 0;__i < __«(exp as VariableDeclaration).name»_length; __i++) {
								«(exp as VariableDeclaration).name»[__i] = __«(exp as VariableDeclaration).name»_values[__i];
							}
						«ELSEIF  typeSystem.get(name).get((exp as VariableDeclaration).name).contains("Matrix")»
							var __data = await new Object((req.query.data || (req.body && req.body.data)))[0];

							var __«(exp as VariableDeclaration).name»_rows = __data.portionRows;
							var __«(exp as VariableDeclaration).name»_cols = __data.portionCols;
							var __portionIndex = __data.portionIndex;
							var __portionDisplacement = __data.portionDisplacement;
							var __«(exp as VariableDeclaration).name»_values = __data.portionValues;
							var __index = 0;
							«(exp as VariableDeclaration).name» = [];
							for (var __i = 0;__i < __«(exp as VariableDeclaration).name»_rows; __i++) {
								«(exp as VariableDeclaration).name»[__i] = [];
								for (var __j = 0;__j < __«(exp as VariableDeclaration).name»_cols; __j++) {
									«(exp as VariableDeclaration).name»[__i][__j] = __«(exp as VariableDeclaration).name»_values[__index].value;
									__index+=1;
								}
							}
						«ELSE»
							var «(exp as VariableDeclaration).name» = (req.query.data || (req.body && req.body.data));
						«ENDIF»
					«ENDIF»
				«ENDFOR»
				«FOR exp : exps.expressions»
					«generateJsExpression(exp,name)»
				«ENDFOR»
				«FOR exp : exps.expressions»
					«IF (exp instanceof VariableDeclaration)»
						«IF ((exp as VariableDeclaration).right instanceof DeclarationObject)»
							«IF (((exp as VariableDeclaration).right as DeclarationObject).features.get(0).value_s.equals("sql"))»
								await «(exp as VariableDeclaration).name».end(function(err){});
							«ENDIF»
							«IF (((exp as VariableDeclaration).right as DeclarationObject).features.get(0).value_s.equals("nosql"))»
							    await __«(exp as VariableDeclaration).name»Client.close();
							«ENDIF»
						«ENDIF»
					«ENDIF»
				«ENDFOR»
				«IF !this.isAsync»
					«IF env.contains("aws")»
						__data = await __sqs.getQueueUrl({ QueueName: "termination-'${function}'-'${id}'"}).promise();
									
						__params = {
							MessageBody : JSON.stringify("terminate"),
							QueueUrl : __data.QueueUrl
						};
									
						__data = await __sqs.sendMessage(__params).promise();
					«ELSEIF env == "azure"»
						await (__util.promisify(__queueSvc.createMessage).bind(__queueSvc))("termination-'${function}'-'${id}'", "terminate");
					«ENDIF»
					
				«ENDIF»
			}
		'''
	}
	
	def generateConstantDefinition(ConstantDeclaration exp,String scope) {
		var s = ''''''
		if (exp.right instanceof NameObjectDef) {
			typeSystem.get(scope).put(exp.name, "HashMap")
			s += '''const «exp.name» = {'''
			var i = 0;
			for (f : (exp.right as NameObjectDef).features) {
				if (f.feature != null) {
					typeSystem.get(scope).put(exp.name + "." + f.feature,
						valuateArithmeticExpression(f.value, scope))
					s = s + '''«f.feature»:«generateJsArithmeticExpression(f.value,scope)»'''
				} else {
					typeSystem.get(scope).put(exp.name + "[" + i + "]",
						valuateArithmeticExpression(f.value, scope))
					s = s + '''«i»:«generateJsArithmeticExpression(f.value,scope)»'''
					i++
				}
				if (f != (exp.right as NameObjectDef).features.last) {
					s += ''','''
				}
			}
			s += '''}'''

		} else if(exp.right instanceof ArrayDefinition ){ 
			var type_decl =(exp.right as ArrayDefinition).type
			if((exp.right as ArrayDefinition).indexes.length==1){ //mono-dimensional
				typeSystem.get(scope).put(exp.name, "Array_"+type_decl)
				s+='''
					const «exp.name» = [];
				'''		
			}else if((exp.right as ArrayDefinition).indexes.length==2){ //bi-dimensional
				var col = generateJsArithmeticExpression((exp.right as ArrayDefinition).indexes.get(1).value,scope)
				typeSystem.get(scope).put(exp.name, "Matrix_"+type_decl+"_"+col)
				s+='''
					const «exp.name» = [];
					for(var i_«exp.name»=0; i_«exp.name»<«col»; i_«exp.name»++) {
					    «exp.name»[i_«exp.name»] = [];
					    for(var j_«exp.name»=0; j_«exp.name»<«col»; j_«exp.name»++) {
					        «exp.name»[i_«exp.name»][j_«exp.name»] = undefined;
					    }
					}
				'''	
			}else if((exp.right as ArrayDefinition).indexes.length==3){ // three-dimentional
			var col = generateJsArithmeticExpression((exp.right as ArrayDefinition).indexes.get(1).value,scope)
			var dep = generateJsArithmeticExpression((exp.right as ArrayDefinition).indexes.get(2).value,scope)
				typeSystem.get(scope).put(exp.name, "Matrix_"+type_decl+"_"+col+"_"+dep)
				//TO DO
			}
			
		} else if(exp.right instanceof ArrayInit){
			if(((exp.right as ArrayInit).values.get(0) instanceof NumberLiteral) ||
					((exp.right as ArrayInit).values.get(0) instanceof StringLiteral) ||
					((exp.right as ArrayInit).values.get(0) instanceof FloatLiteral)
				){ //array init
					var real_type = valuateArithmeticExpression((exp.right as ArrayInit).values.get(0) as ArithmeticExpression,scope)

					typeSystem.get(scope).put(exp.name,"Array_"+real_type)
					return '''
						const «exp.name» = [«FOR e: (exp.right as ArrayInit).values»«generateJsArithmeticExpression(e as ArithmeticExpression,scope)»«IF e != (exp.right as ArrayInit).values.last »,«ENDIF»«ENDFOR»]
					'''
				} else if ((exp.right as ArrayInit).values.get(0) instanceof ArrayValue){ //matrix 2d
					if(((exp.right as ArrayInit).values.get(0) as ArrayValue).values.get(0) instanceof NumberLiteral ||
						((exp.right as ArrayInit).values.get(0) as ArrayValue).values.get(0) instanceof StringLiteral ||
						((exp.right as ArrayInit).values.get(0) as ArrayValue).values.get(0) instanceof FloatLiteral){
						var real_type = valuateArithmeticExpression(((exp.right as ArrayInit).values.get(0) as ArrayValue).values.get(0) as ArithmeticExpression,scope)
						var col = (((exp.right as ArrayInit).values.get(0) as ArrayValue).values.get(0) as ArrayValue).values.length
						typeSystem.get(scope).put(exp.name,"Matrix_"+real_type+"_"+col)
						var ret = '''const «exp.name» = ['''
						for (e : (exp.right as ArrayInit).values){
							ret+='''['''
							for(e1: (e as ArrayValue).values){
								ret+=generateJsArithmeticExpression(e1 as ArithmeticExpression,scope)
								if(e1!= (e as ArrayValue).values.last){
									ret+=''','''
								}
							}
							ret+=''']'''
							if (e !=  (exp.right as ArrayInit).values.last){
								ret+=''','''
							}
						}
						ret+=''']'''
						return ret
					}else if (((exp.right as ArrayInit).values.get(0) as ArrayValue).values.get(0) instanceof ArrayValue){ //matrix 3d
						if ((((exp.right as ArrayInit).values.get(0) as ArrayValue).values.get(0) as ArrayValue).values.get(0) instanceof NumberLiteral ||
							(((exp.right as ArrayInit).values.get(0) as ArrayValue).values.get(0) as ArrayValue).values.get(0) instanceof StringLiteral ||
							(((exp.right as ArrayInit).values.get(0) as ArrayValue).values.get(0) as ArrayValue).values.get(0) instanceof FloatLiteral ){
							var real_type = valuateArithmeticExpression((((exp.right as ArrayInit).values.get(0) as ArrayValue).values.get(0) as ArrayValue).values.get(0) as ArithmeticExpression,scope)
							var col = (((exp.right as ArrayInit).values.get(0) as ArrayValue).values.get(0) as ArrayValue).values.length
							var dep = ((((exp.right as ArrayInit).values.get(0) as ArrayValue).values.get(0) as ArrayValue).values.get(0) as ArrayValue).values.length
							typeSystem.get(scope).put(exp.name,"Matrix_"+real_type+"_"+col+"_"+dep)
							var ret = '''const «exp.name» = ['''
							for (e : (exp.right as ArrayInit).values){
								ret+='''['''
								for(e1: (e as ArrayValue).values){
									ret+='''['''
									for(e2: ((e1 as ArrayValue).values)){
										ret+=generateJsArithmeticExpression(e2 as ArithmeticExpression,scope)
										if(e2!= (e1 as ArrayValue).values.last){
											ret+=''','''
										}
									}
									ret+=''']'''
									if(e1!= (e as ArrayValue).values.last){
										ret+=''','''
									}
								}
								ret+=''']'''
								if (e !=  (exp.right as ArrayInit).values.last){
									ret+=''','''
								}
							}
							ret+=''']'''
							return ret	
						}
					}
					
				}
		} else {
			s += '''
				const «exp.name» = «generateJsArithmeticExpression(exp.right as ArithmeticExpression,scope)»;
			'''
		}
		return s
	}

	def generateJsExpression(Expression exp, String scope) {
		var s = ''''''
		if (exp instanceof ChannelSend) {
			s += '''
			«IF env.contains("aws")»
				__data = await __sqs.getQueueUrl({ QueueName: "«exp.target.name»-'${id}'"}).promise();
				
				«IF exp.expression instanceof CastExpression && (exp.expression as CastExpression).type.equals("Array")»
					__params = {
						MessageBody : JSON.stringify({'portionValues': «generateJsArithmeticExpression(exp.expression,scope)», 
												'portionLength': «generateJsArithmeticExpression(exp.expression,scope)».length,
												'portionIndex': __portionIndex,
												'portionDisplacement': __portionDisplacement}),
						QueueUrl : __data.QueueUrl
					};
				«ELSEIF  exp.expression instanceof CastExpression && (exp.expression as CastExpression).type.equals("Matrix")»
					__params = {
						MessageBody : JSON.stringify({'portionValues': «generateJsArithmeticExpression(exp.expression,scope)», 
												'portionRows': «generateJsArithmeticExpression(exp.expression,scope)».length,
												'portionCols': «generateJsArithmeticExpression(exp.expression,scope)»[0].length,
												'portionIndex':  __portionIndex,
												'portionDisplacement': __portionDisplacement}),
						QueueUrl : __data.QueueUrl
					};
				«ELSE»
					__params = {
						MessageBody : JSON.stringify(«generateJsArithmeticExpression(exp.expression,scope)»),
						QueueUrl : __data.QueueUrl
					};
				«ENDIF»
				
				__data = await __sqs.sendMessage(__params).promise();
			«ELSEIF env == "azure"»
				«IF exp.expression instanceof CastExpression && (exp.expression as CastExpression).type.equals("Array")»
					await (__util.promisify(__queueSvc.createMessage).bind(__queueSvc))("«exp.target.name»-'${id}'", JSON.stringify({'portionValues': «generateJsArithmeticExpression(exp.expression,scope)», 
																	'portionLength': «generateJsArithmeticExpression(exp.expression,scope)».length,
																	'portionIndex':  __portionIndex,
																	'portionDisplacement': __portionDisplacement}));
				«ELSEIF exp.expression instanceof CastExpression && (exp.expression as CastExpression).type.equals("Matrix")»
					await (__util.promisify(__queueSvc.createMessage).bind(__queueSvc))("«exp.target.name»-'${id}'", JSON.stringify({'portionValues': «generateJsArithmeticExpression(exp.expression,scope)», 
																	'portionRows': «generateJsArithmeticExpression(exp.expression,scope)».length,
																	'portionCols': «generateJsArithmeticExpression(exp.expression,scope)»[0].length,
																	'portionIndex':  __portionIndex,
																	'portionDisplacement': __portionDisplacement}));
				«ELSE»
					await (__util.promisify(__queueSvc.createMessage).bind(__queueSvc))("«exp.target.name»-'${id}'", JSON.stringify(«generateJsArithmeticExpression(exp.expression,scope)»));
				«ENDIF»
			«ENDIF»
			'''
		} else if (exp instanceof ChannelReceive) {
			//TODO handle receive things on channel
		} else if (exp instanceof VariableDeclaration) {
			if (exp.typeobject.equals("var")) {
				if (exp.right instanceof NameObjectDef) {
					typeSystem.get(scope).put(exp.name, "HashMap")
					s += '''var «exp.name» = {'''
					var i = 0;
					for (f : (exp.right as NameObjectDef).features) {
						if (f.feature != null) {
							typeSystem.get(scope).put(exp.name + "." + f.feature,
								valuateArithmeticExpression(f.value, scope))
							s = s + '''«f.feature»:«generateJsArithmeticExpression(f.value,scope)»'''
						} else {
							typeSystem.get(scope).put(exp.name + "[" + i + "]",
								valuateArithmeticExpression(f.value, scope))
							s = s + '''«i»:«generateJsArithmeticExpression(f.value,scope)»'''
							i++
						}
						if (f != (exp.right as NameObjectDef).features.last) {
							s += ''','''
						}
					}
					s += '''}'''

				} else if(exp.right instanceof ArrayDefinition ){  // TODO: check and complete
					var type_decl =(exp.right as ArrayDefinition).type
					if((exp.right as ArrayDefinition).indexes.length==1){ //mono-dimensional
						typeSystem.get(scope).put(exp.name, "Array_"+type_decl)
						s+='''
							var «exp.name» = [];
						'''	
					}else if((exp.right as ArrayDefinition).indexes.length==2){ //bi-dimensional
						var col = generateJsArithmeticExpression((exp.right as ArrayDefinition).indexes.get(1).value,scope)
						typeSystem.get(scope).put(exp.name, "Matrix_"+type_decl+"_"+col)
						s+='''
							var «exp.name» = [];
							for(var i_«exp.name»=0; i_«exp.name»<«col»; i_«exp.name»++) {
							    «exp.name»[i_«exp.name»] = [];
							    for(var j_«exp.name»=0; j_«exp.name»<«col»; j_«exp.name»++) {
							        «exp.name»[i_«exp.name»][j_«exp.name»] = undefined;
							    }
							}
						'''	
					}else if((exp.right as ArrayDefinition).indexes.length==3){ // three-dimentional
					var col = generateJsArithmeticExpression((exp.right as ArrayDefinition).indexes.get(1).value,scope)
					var dep = generateJsArithmeticExpression((exp.right as ArrayDefinition).indexes.get(2).value,scope)
						typeSystem.get(scope).put(exp.name, "Matrix_"+type_decl+"_"+col+"_"+dep)
						//TO DO
					}				
				}else if(exp.right instanceof ArrayInit){
						if(((exp.right as ArrayInit).values.get(0) instanceof NumberLiteral) ||
					((exp.right as ArrayInit).values.get(0) instanceof StringLiteral) ||
					((exp.right as ArrayInit).values.get(0) instanceof FloatLiteral)){ //array init
						var real_type = valuateArithmeticExpression((exp.right as ArrayInit).values.get(0) as ArithmeticExpression,scope)
	
						typeSystem.get(scope).put(exp.name,"Array_"+real_type)
						return '''
							var «exp.name» = [«FOR e: (exp.right as ArrayInit).values»«generateJsArithmeticExpression(e as ArithmeticExpression,scope)»«IF e != (exp.right as ArrayInit).values.last »,«ENDIF»«ENDFOR»]
						'''
					} else if ((exp.right as ArrayInit).values.get(0) instanceof ArrayValue){ //matrix 2d
						if(((exp.right as ArrayInit).values.get(0) as ArrayValue).values.get(0) instanceof NumberLiteral ||
							((exp.right as ArrayInit).values.get(0) as ArrayValue).values.get(0) instanceof StringLiteral ||
							((exp.right as ArrayInit).values.get(0) as ArrayValue).values.get(0) instanceof FloatLiteral){
							var real_type = valuateArithmeticExpression(((exp.right as ArrayInit).values.get(0) as ArrayValue).values.get(0) as ArithmeticExpression,scope)
							var col = (((exp.right as ArrayInit).values.get(0) as ArrayValue).values.get(0) as ArrayValue).values.length
							typeSystem.get(scope).put(exp.name,"Matrix_"+real_type+"_"+col)
							var ret = '''var «exp.name» = ['''
							for (e : (exp.right as ArrayInit).values){
								ret+='''['''
								for(e1: (e as ArrayValue).values){
									ret+=generateJsArithmeticExpression(e1 as ArithmeticExpression,scope)
									if(e1!= (e as ArrayValue).values.last){
										ret+=''','''
									}
								}
								ret+=''']'''
								if (e !=  (exp.right as ArrayInit).values.last){
									ret+=''','''
								}
							}
							ret+=''']'''
							return ret
						}else if (((exp.right as ArrayInit).values.get(0) as ArrayValue).values.get(0) instanceof ArrayValue){ //matrix 3d
							if ((((exp.right as ArrayInit).values.get(0) as ArrayValue).values.get(0) as ArrayValue).values.get(0) instanceof NumberLiteral ||
								(((exp.right as ArrayInit).values.get(0) as ArrayValue).values.get(0) as ArrayValue).values.get(0) instanceof StringLiteral ||
								(((exp.right as ArrayInit).values.get(0) as ArrayValue).values.get(0) as ArrayValue).values.get(0) instanceof FloatLiteral ){
								var real_type = valuateArithmeticExpression((((exp.right as ArrayInit).values.get(0) as ArrayValue).values.get(0) as ArrayValue).values.get(0) as ArithmeticExpression,scope)
								var col = (((exp.right as ArrayInit).values.get(0) as ArrayValue).values.get(0) as ArrayValue).values.length
								var dep = ((((exp.right as ArrayInit).values.get(0) as ArrayValue).values.get(0) as ArrayValue).values.get(0) as ArrayValue).values.length
								typeSystem.get(scope).put(exp.name,"Matrix_"+real_type+"_"+col+"_"+dep)
								var ret = '''var «exp.name» = ['''
								for (e : (exp.right as ArrayInit).values){
									ret+='''['''
									for(e1: (e as ArrayValue).values){
										ret+='''['''
										for(e2: ((e1 as ArrayValue).values)){
											ret+=generateJsArithmeticExpression(e2 as ArithmeticExpression,scope)
											if(e2!= (e1 as ArrayValue).values.last){
												ret+=''','''
											}
										}
										ret+=''']'''
										if(e1!= (e as ArrayValue).values.last){
											ret+=''','''
										}
									}
									ret+=''']'''
									if (e !=  (exp.right as ArrayInit).values.last){
										ret+=''','''
									}
								}
								ret+=''']'''
								return ret	
							}
						}
						
					}	
				} else if(exp.right instanceof DeclarationObject){
					var type = (exp.right as DeclarationObject).features.get(0).value_s
					switch (type) {						
						case "file":{
							typeSystem.get(scope).put(exp.name, "File")
							var path = "";
							if((exp.right as DeclarationObject).features.get(1).value_f!=null){
								path = (exp.right as DeclarationObject).features.get(1).value_f.name
							}else{
								path = (exp.right as DeclarationObject).features.get(1).value_s.replaceAll('"', '\"');
							}
							if(env == "azure"){
								return '''
									var «exp.name»Client = containerClient.getBlobClient(«path»);
									var «exp.name» = await «exp.name»Client.download();
								'''
							}
							
						}case "dataframe": {
							typeSystem.get(scope).put(exp.name, "Table")
							var url = "";
							var path = (exp.right as DeclarationObject).features.get(2).value_s
							var region = "";
							if ((exp as VariableDeclaration).onCloud){
								region = ((exp as VariableDeclaration).environment.get(0).right as DeclarationObject).features.get(4).value_s
							}
							if ((exp as VariableDeclaration).onCloud && (exp.environment.get(0).right as DeclarationObject).features.get(0).value_s.equals("aws") && ! (path.contains("https://")))
								url = "https://'${function}${id}'.s3." + region + ".amazonaws.com/bucket-'${id}'/" + path
							else if ((exp as VariableDeclaration).onCloud && (exp.environment.get(0).right as DeclarationObject).features.get(0).value_s.equals("azure") && ! (path.contains("https://")))
								url = "https://'${storageName}'.blob.core.windows.net/bucket-"+id_execution+ "/" + path
							else if ((exp as VariableDeclaration).onCloud && (exp.environment.get(0).right as DeclarationObject).features.get(0).value_s.equals("aws-debug") && ! (path.contains("https://")))
							url = "https://http://192.168.0.1:4572/bucket-'${id}'/" + path
							else
								url = path

							s += '''
								var __«exp.name» = await __dataframe.fromCSV("«url»")
								var «exp.name» = __«exp.name».toArray()
							'''
						}
						case "sql":{
							if (exp.onCloud && (exp.environment.get(0).right as DeclarationObject).features.get(0).value_s.contains("aws")){
								var instance = ((exp.right as DeclarationObject).features.get(1) as DeclarationFeature).value_s
								var db_name = ((exp.right as DeclarationObject).features.get(2) as DeclarationFeature).value_s
								var user_name = ((exp.right as DeclarationObject).features.get(3) as DeclarationFeature).value_s
								var password = ((exp.right as DeclarationObject).features.get(4) as DeclarationFeature).value_s
								return '''
									var __params_«exp.name» = {
									  DBInstanceIdentifier: "«instance»"
									};
									
									const __getEndpoint_«exp.name» = __util.promisify(__rds.describeDBInstances).bind(__rds);
									
									var __instances_«exp.name» = await __getEndpoint_«exp.name»(__params_«exp.name»);
									
									var __endpoint_«exp.name» = __instances_«exp.name».DBInstances[0].Endpoint.Address;
									
									var «exp.name» = __mysql.createConnection({
									  	host: __endpoint_«exp.name»,
									  	user: "«user_name»",
									  	password: "«password»",
									  	database: "«db_name»"
									});
									
									'''	 					
							} else if (exp.onCloud && (exp.environment.get(0).right as DeclarationObject).features.get(0).value_s.contains("azure")){
								var resource_group = ((exp.right as DeclarationObject).features.get(1) as DeclarationFeature).value_s
								var instance = ((exp.right as DeclarationObject).features.get(2) as DeclarationFeature).value_s
								var db_name = ((exp.right as DeclarationObject).features.get(3) as DeclarationFeature).value_s
								var user_name = ((exp.right as DeclarationObject).features.get(4) as DeclarationFeature).value_s
								var password = ((exp.right as DeclarationObject).features.get(5) as DeclarationFeature).value_s 
								return 
								'''
									var __url«exp.name» = "https://management.azure.com/subscriptions/" + "'${subscription}'" 
									+ "/resourceGroups/" + "«resource_group»"
									+ "/providers/Microsoft.DBforMySQL/servers/" + "«instance»"
									+ "?api-version=2017-12-01"
									
									const config = {
										method: "get",
										headers: {
										Authorization: "Bearer " + __token,
										Accept: "application/json"
										}
									}
									
									var __res«exp.name» = await __axios.get(__url«exp.name», config);

									var __endpoint«exp.name» = __res«exp.name».data.properties.fullyQualifiedDomainName;

									var «exp.name» = __mysql.createConnection({
										host: __endpoint«exp.name»,
										user: "«user_name»",
										password: "«password»",
										database: "«db_name»",
										port: 3306,
										ssl:true
									});
								'''	 					
							} else {
								var db_name = ((exp.right as DeclarationObject).features.get(1) as DeclarationFeature).value_s
								var user_name = ((exp.right as DeclarationObject).features.get(2) as DeclarationFeature).value_s
								var password = ((exp.right as DeclarationObject).features.get(3) as DeclarationFeature).value_s
								var endpoint = ""
								if (((exp.right as DeclarationObject).features.size) > 4)
									endpoint = (exp.right as DeclarationObject).features.get(4).value_s
								else endpoint = "localhost"
								return '''
								var «exp.name» = __mysql.createConnection({
								  	host: "«endpoint»",
								  	user: "«user_name»",
								  	password: "«password»",
								  	database: "«db_name»"
								});
								'''	 
							}
						}
						case "nosql":{
						    if(exp.onCloud && (exp.environment.get(0).right as DeclarationObject).features.get(0).value_s.contains("azure")){
						        var resourceGroup = ((exp.right as DeclarationObject).features.get(1) as DeclarationFeature).value_s
						        var instance = ((exp.right as DeclarationObject).features.get(2) as DeclarationFeature).value_s
						        var database = ((exp.right as DeclarationObject).features.get(3) as DeclarationFeature).value_s
						        var collection = ((exp.right as DeclarationObject).features.get(4) as DeclarationFeature).value_s 
						        return '''
						        var __url_«exp.name» = "https://management.azure.com/subscriptions/" + "'${subscription}'" 
						            + "/resourceGroups/" + "«resourceGroup»"
						            + "/providers/Microsoft.DocumentDB/databaseAccounts/" + "«instance»"
						            + "/listConnectionStrings?api-version=2021-03-01-preview"
						        
						        let __endpoint_«exp.name»;
						        
						        await __axios.post(__url_nosql, { }, {
						            headers: { 
						                "Authorization": "Bearer " + __token,
						                "Accept": "application/json"
						            }})
						            .then((response) => {
						                __endpoint_«exp.name» = response.data.connectionStrings[0].connectionString;
						            })
						            .catch((error) => {
						                console.log(error);
						            })
						        
						        const __«exp.name»Client = new __nosql.MongoClient(
						            __endpoint_«exp.name»,
						            { useUnifiedTopology: true }
						        );
						        
						        await __«exp.name»Client.connect();
						        
						        const «exp.name» = __«exp.name»Client.db("«database»").collection("«collection»");
						        
						        '''
						    } else {
						        var database = ((exp.right as DeclarationObject).features.get(2) as DeclarationFeature).value_s
						        var collection = ((exp.right as DeclarationObject).features.get(3) as DeclarationFeature).value_s
						        return '''
						        const __«exp.name»Client = new __nosql.MongoClient(
						            "«IF((exp.right as DeclarationObject).features.get(1).value_s.nullOrEmpty)
						            »" + «((exp.right as DeclarationObject).features.get(1) as DeclarationFeature).value_f.name» + "«
						            ELSE
						            »«((exp.right as DeclarationObject).features.get(1) as DeclarationFeature).value_s»«
						            ENDIF»",
						            { useUnifiedTopology: true }
						        );
						        
						        await __«exp.name»Client.connect();
						                                        
						        const «exp.name» = __«exp.name»Client.db("«database»").collection("«collection»");
						        
						        '''
						    }
						}
						case "query":{
							var connection = (((exp.right as DeclarationObject).features.get(2) as DeclarationFeature).value_f as VariableDeclaration)	
						    var databaseType = (connection.right as DeclarationObject).features.get(0).value_s
						    if(databaseType.equals("sql")) {
						        return '''
						        var «exp.name» = «
						        IF ((exp.right as DeclarationObject).features.get(3) as DeclarationFeature).value_s.nullOrEmpty
						        »«((exp.right as DeclarationObject).features.get(3) as DeclarationFeature).value_f.name»«
						        ELSE
						        »"«((exp.right as DeclarationObject).features.get(3) as DeclarationFeature).value_s»"«
						        ENDIF»;
						        '''	 
						    } else if(databaseType.equals("nosql")) {
						        var query_type = ((exp.right as DeclarationObject).features.get(1) as DeclarationFeature).value_s
						        var collection = (exp.right as DeclarationObject).features.get(2).value_f.name						
						        if(query_type.equals("select")) {
						            typeSystem.get(scope).put(exp.name, "List <Table>")
						            return '''
						            const «exp.name» = async () => {
						            
						                let features = [];
						                let objects = [];
						                
						                await «collection».find(JSON.parse(«IF((exp.right as DeclarationObject).features.get(3).value_s.nullOrEmpty)
						                »«((exp.right as DeclarationObject).features.get(3) as DeclarationFeature).value_f.name»«
						                ELSE
						                »"«((exp.right as DeclarationObject).features.get(3) as DeclarationFeature).value_s.replace("\\$", "$")»"«
						                ENDIF»)).forEach((object) => {
						                    
						                    const keys = Object.keys(object);
						                    const n = features.length;
						                    let i;
						                    
						                    for(i = 0; i < n; ++i)
						                        if(!(JSON.stringify(features[i]) !== JSON.stringify(keys)))
						                            break;
						                    
						                    if(i === n) {
						                        features.push(keys);
						                        const __array = [];
						                        __array.push(object);
						                        objects.push(__array);
						                    } else
						                        objects[i].push(object);
						                    
						                });
						                
						                let tables = [];
						                
						                for(i = 0; i < features.length; ++i)
						                    tables.push(new __dataframe(
						                        objects[i],
						                        features[i]
						                    ));
						                    
						                return tables;
						            }
						            
						            '''
						        } if(query_type.equals("insert")) {
						            if(((exp.right as DeclarationObject).features.get(3) as DeclarationFeature).value_s.nullOrEmpty) {
						                if((((exp.right as DeclarationObject).features.get(3) as DeclarationFeature).value_f as VariableDeclaration).right instanceof DeclarationObject) {
						                    var variables = (((exp.right as DeclarationObject).features.get(3) as DeclarationFeature).value_f as VariableDeclaration).right as DeclarationObject
						                    if(variables.features.get(0).value_s.equals("file")) {
						                        if((exp.right as DeclarationObject).features.size() == 6) {
						                            var from = ((exp.right as DeclarationObject).features.get(4) as DeclarationFeature).value_s
						                            var to = ((exp.right as DeclarationObject).features.get(5) as DeclarationFeature).value_s
						                            return '''
						                            const «exp.name» = async () => {
						                                
						                                let i = 0;
						                                let features;
						                                let objects = [];
						                                
						                                await new Promise((resolve) => {
						                                
						                                    __fs.createReadStream(«IF
						                                    (variables.features.get(1).value_s.nullOrEmpty)»«variables.features.get(1).value_f.name»«
						                                    ELSE»"«variables.features.get(1).value_s»"«ENDIF»)
						                                    .pipe(__parse())
						                                    .on("data", (row) => {
						                                        if(i == 0) {
						                                            features = row;
						                                            ++i;
						                                        } else if(i >= «from» && i <= «to») {
						                                            let object = { };
						                                            for([index, value] of features.entries())
						                                                object[features[index]] = row[index];
						                                            objects.push(object);
						                                            ++i;
						                                        } else if(i < «from»)
						                                            ++i;
						                                    })
						                                    .on("end", () => {
						                                        resolve();
						                                    });
						                                });
						                                
						                                return objects;
						                            }
						                            
						                            '''
						                        } else {
						                            return '''
						                            const «exp.name» = async () => {
						                                
						                                let i = 0;
						                                let features;
						                                let objects = [];
						                                
						                                await new Promise((resolve) => {
						                                
						                                    __fs.createReadStream(«IF
						                                    (variables.features.get(1).value_s.nullOrEmpty)»«variables.features.get(1).value_f.name»«
						                                    ELSE»"«variables.features.get(1).value_s»"«ENDIF»)
						                                    .pipe(__parse())
						                                    .on("data", (row) => {
						                                        if(i == 0) {
						                                            features = row;
						                                            ++i;
						                                        } else {
						                                            let object = { };
						                                            for([index, value] of features.entries())
						                                                object[features[index]] = row[index];
						                                            objects.push(object);
						                                            ++i;
						                                        }
						                                    })
						                                    .on("end", () => {
						                                        resolve();
						                                    });
						                                });
						                                
						                                return objects;
						                            }
						                            
						                            '''
						                        }
						                    }
						                } else {
						                    return '''
						                    let «exp.name»;
						                    if(«((exp.right as DeclarationObject).features.get(3) as DeclarationFeature).value_f.name».charAt(0) === "[")
						                        «exp.name» = JSON.parse(«((exp.right as DeclarationObject).features.get(3) as DeclarationFeature).value_f.name»);
						                    else
						                        «exp.name» = JSON.parse("[" + «((exp.right as DeclarationObject).features.get(3) as DeclarationFeature).value_f.name» + "]");
						                    
						                    '''
						                }
						            } else {
						                return '''
						                let «exp.name»;
						                if("«((exp.right as DeclarationObject).features.get(3) as DeclarationFeature).value_s»".charAt(0) === "[")
						                    «exp.name» = JSON.parse("«((exp.right as DeclarationObject).features.get(3) as DeclarationFeature).value_s»");
						                else
						                    «exp.name» = JSON.parse("[" + "«((exp.right as DeclarationObject).features.get(3) as DeclarationFeature).value_s»" + "]");
						                    
						                '''
						            }
						        } else {
						            if((exp.right as DeclarationObject).features.size() == 4) {
						                return '''
						                const «exp.name» = JSON.parse(«IF
						                ((exp.right as DeclarationObject).features.get(3).value_s.nullOrEmpty)»«(exp.right as DeclarationObject).features.get(3).value_f.name»«
						                ELSE»"«(exp.right as DeclarationObject).features.get(3).value_s.replace("\\$", "$")»"«ENDIF»);
						                
						                '''
						            } else 
						                return '''
						                const «exp.name»Filter = JSON.parse(«IF
						                ((exp.right as DeclarationObject).features.get(3).value_s.nullOrEmpty)»«(exp.right as DeclarationObject).features.get(3).value_f.name»«
						                ELSE»"«(exp.right as DeclarationObject).features.get(3).value_s.replace("\\$", "$")»"«ENDIF»);
						                
						                const «exp.name» = JSON.parse(«IF
						                ((exp.right as DeclarationObject).features.get(4).value_s.nullOrEmpty)»«(exp.right as DeclarationObject).features.get(4).value_f.name»«
						                ELSE»"«(exp.right as DeclarationObject).features.get(4).value_s.replace("\\$", "$")»"«ENDIF»);
						                
						                '''				
						        }								
						    }
						} case "distributed-query": {
						    var query_type = ((exp.right as DeclarationObject).features.get(1) as DeclarationFeature).value_s
						    if(query_type.equals("select")) {
						        typeSystem.get(scope).put(exp.name, "List <Table>")
						        var ret = ''''''
						        ret += '''
						        const «exp.name» = async () => {
						        
						            let features = [];
						            let objects = [];
						        '''

						        for(i : 3 ..< (exp.right as DeclarationObject).features.size)
						        ret += '''
						        
						            await «((exp.right as DeclarationObject).features.get(i) as DeclarationFeature).value_f.name».find(JSON.parse(«IF((exp.right as DeclarationObject).features.get(2).value_s.nullOrEmpty)
						        »«((exp.right as DeclarationObject).features.get(2) as DeclarationFeature).value_f.name»«
						            ELSE
						        »"«((exp.right as DeclarationObject).features.get(2) as DeclarationFeature).value_s.replace("\\$", "$")»"«
						        ENDIF»)).forEach((object) => {
						                
						                const keys = Object.keys(object);
						                const n = features.length;
						                let i;
						                
						                for(i = 0; i < n; ++i)
						                    if(!(JSON.stringify(features[i]) !== JSON.stringify(keys)))
						                        break;
						                    
						                if(i === n) {
						                    features.push(keys);
						                    const __array = [];
						                    __array.push(object);
						                    objects.push(__array);
						                } else
						                    objects[i].push(object);
						                
						            });
						        '''

						        ret += '''
						            let tables = [];
						                
						            for(i = 0; i < features.length; ++i)
						                tables.push(new __dataframe(
						                    objects[i],
						                    features[i]
						                ));
						            
						            return tables;
						        }
						        '''

						        return ret;

						    } else if(query_type.equals("insert")) {
						        if(((exp.right as DeclarationObject).features.get(2) as DeclarationFeature).value_s.nullOrEmpty) {
						            if((((exp.right as DeclarationObject).features.get(2) as DeclarationFeature).value_f as VariableDeclaration).right instanceof DeclarationObject) {
						                var variables = (((exp.right as DeclarationObject).features.get(2) as DeclarationFeature).value_f as VariableDeclaration).right as DeclarationObject
						                if(variables.features.get(0).value_s.equals("file")) {
						                    var ret = ''''''
						                    ret += '''
						                    const «exp.name» = async () => {
						                    
						                        let i = 0;
						                        let features;
						                        let objects = [];
						                                
						                        await new Promise((resolve) => {
						                    
						                            __fs.createReadStream(«IF
						                            (variables.features.get(1).value_s.nullOrEmpty)»«variables.features.get(1).value_f.name»«
						                            ELSE»"«variables.features.get(1).value_s»"«ENDIF»)
						                            .pipe(__parse())
						                            .on("data", (row) => {
						                                if(i == 0) {
						                                    features = row;
						                                    ++i;
						                                } else {
						                                    let object = { };
						                                    for([index, value] of features.entries())
						                                        object[features[index]] = row[index];
						                                    objects.push(object);
						                                    ++i;
						                                }
						                            })
						                            .on("end", () => {
						                                resolve();
						                            });
						                        });
						                    
						                        return objects;
						                    }
						                    
						                    '''

						                    return ret;
						                }
						            } else {
						                return '''
						                let «exp.name»;
						                if(«((exp.right as DeclarationObject).features.get(2) as DeclarationFeature).value_f.name».charAt(0) === "[")
						                    «exp.name» = JSON.parse(«((exp.right as DeclarationObject).features.get(2) as DeclarationFeature).value_f.name»);
						                else
						                    «exp.name» = JSON.parse("[" + «((exp.right as DeclarationObject).features.get(2) as DeclarationFeature).value_f.name» + "]");
						                
						                '''
						            }
						        } else {
						            return '''
						            let «exp.name»;
						            if("«((exp.right as DeclarationObject).features.get(2) as DeclarationFeature).value_s»".charAt(0) === "[")
						                «exp.name» = JSON.parse("«((exp.right as DeclarationObject).features.get(2) as DeclarationFeature).value_s»");
						            else
						                «exp.name» = JSON.parse("[" + "«((exp.right as DeclarationObject).features.get(2) as DeclarationFeature).value_s»" + "]");
						                
						            '''
						        }
						    } else if(query_type.equals("update") || query_type.equals("replace")) {
						        return '''
						        const «exp.name»Filter = JSON.parse(«IF
						        ((exp.right as DeclarationObject).features.get(2).value_s.nullOrEmpty)»«(exp.right as DeclarationObject).features.get(2).value_f.name»«
						        ELSE»"«(exp.right as DeclarationObject).features.get(2).value_s.replace("\\$", "$")»"«ENDIF»);
						        
						        const «exp.name» = JSON.parse(«IF
						        ((exp.right as DeclarationObject).features.get(3).value_s.nullOrEmpty)»«(exp.right as DeclarationObject).features.get(3).value_f.name»«
						        ELSE»"«(exp.right as DeclarationObject).features.get(3).value_s.replace("\\$", "$")»"«ENDIF»);
						        '''
						    } else if(query_type.equals("delete")) {
						        var ret = ''''''
						        ret += '''
						        const «exp.name»Delete = JSON.parse(«IF
						        ((exp.right as DeclarationObject).features.get(2).value_s.nullOrEmpty)»«(exp.right as DeclarationObject).features.get(2).value_f.name»«
						        ELSE»"«(exp.right as DeclarationObject).features.get(2).value_s.replace("\\$", "$")»"«ENDIF»);
						        
						        const «exp.name» = async () => {
						            
						            let count = 0;
						            '''

						        for(i : 3 ..< (exp.right as DeclarationObject).features.size)			
						            ret += '''
						            
						                count += (await «(exp.right as DeclarationObject).features.get(i).value_f.name».deleteMany(«exp.name»Delete)).deletedCount;
						            '''

						        ret += '''
						            
						            return new Promise((resolve, reject) => {
						                resolve(count);
						            });
						            
						        }
						        '''

						        return ret
						    }
						}
						default: {
							
						}
					}
					
				} else if(exp.right instanceof VariableFunction){
					s += '''
						var «exp.name» = «generateJsVariableFunction((exp.right as VariableFunction), true, scope)»
					'''
				} else {
					s += '''
						var «exp.name» = «generateJsArithmeticExpression(exp.right as ArithmeticExpression,scope)»
					'''
				}

			}
		} else if (exp instanceof IfExpression) {
			s += '''
				if(«generateJsArithmeticExpression(exp.cond,scope)»)
					«generateJsExpression(exp.then,scope)» 
				«IF exp.^else != null»
				else
					«generateJsExpression(exp.^else,scope)»
				«ENDIF»
			'''
		} else if (exp instanceof ForExpression) {
			s += '''
				«generateJsForExpression(exp,scope)»
			'''
		} else if (exp instanceof WhileExpression) {
			s += '''
				«generateJsWhileExpression(exp,scope)»
			'''
		} else if (exp instanceof BlockExpression) {
			s += '''
				«generateJsBlockExpression(exp,scope)»
			'''
		} else if (exp instanceof Assignment) {
			s += '''
				«generateJsAssignmentExpression(exp,scope)»
			'''
		} else if (exp instanceof PrintExpression) {
			s += '''
				console.log(«generateJsArithmeticExpression(exp.print,scope)») 
			'''
		} else if(exp instanceof NativeExpression){
			s+='''
				«generateJsNativeExpression(exp)»
			'''
		} else if(exp instanceof PostfixOperation){
			s+='''
				«generateJsArithmeticExpression(exp.variable,scope)»«exp.feature»
			'''
		} else if(exp instanceof VariableFunction){
			s+='''
				«generateJsVariableFunction(exp, true, scope)»
			'''
		} else if(exp instanceof FunctionDefinition){
			
			val fd = (exp as FunctionDefinition)
			val name = fd.name
			val params = fd.parameters.map[it as VariableDeclaration].map[it.name]
			val body = fd.body as BlockExpression
			
			s += '''
				«name» = async («String.join(", ", params)») =>
					«generateJsBlockExpression(body, scope)»
				
			'''
			
		}else if (exp instanceof FunctionReturn) {
			val fr = (exp as FunctionReturn)
			s += '''return «generateJsArithmeticExpression(fr.expression, scope)»'''
		}
		else if(exp instanceof LocalFunctionCall){
			s += exp.target.name + "("
			if (exp.input != null) {
				for (input : exp.input.inputs) {
					s += generateJsArithmeticExpression(input, scope)
					if (input != exp.input.inputs.last) {
						s += ","
					}
				}
			}
			s += ")"
			}
		return s
	}
	
	def generateJsNativeExpression(NativeExpression expression) { 
		var i=0;
		var lines = expression.code.split("\n");
		var num_tabs = 0 
		while(lines.get(1).charAt(i).equals('\t')){
			num_tabs++; 
			i++;
		}
		i=0
		var ret = new StringBuilder()
		for (i=1; i< lines.length-1;i++){
			ret.append('''«lines.get(i).substring(num_tabs)»''')
			ret.append("\n")
		}
		return ret.toString
	}

	def generateJsAssignmentExpression(Assignment assignment, String scope) {
		if (assignment.feature != null) {
			if (assignment.value instanceof CastExpression &&
				((assignment.value as CastExpression).target instanceof ChannelReceive)) {
				if ((((assignment.value as CastExpression).target as ChannelReceive).target.environment.get(0).
					right as DeclarationObject).features.get(0).value_s.equals("aws")) { // aws environment
						return '''
							__data = await __sqs.getQueueUrl({ QueueName: "«((assignment.value as CastExpression).target as ChannelReceive).target.name»-'${id}'}").promise();
							__data = await __sqs.sendMessage({QueueUrl : __data.QueueUrl }).promise();
							«generateJsArithmeticExpression(assignment.feature,scope)» «assignment.op» __data.Messages[0].Body
						'''
				} else if ((((assignment.value as CastExpression).target as ChannelReceive).target.environment.get(0).
					right as DeclarationObject).features.get(0).value_s.equals("azure"))  { // azure environment
						return '''
							var __msg = await (__util.promisify(__queueSvc.getMessages).bind(__queueSvc))("«((assignment.value as CastExpression).target as ChannelReceive).target.name»-'${id}'}");
							«generateJsArithmeticExpression(assignment.feature,scope)» «assignment.op» __msg[0].messageText;
						'''
				} else { // other environment 
					
				}

			} else if (assignment.value instanceof ChannelReceive) {
				if (((assignment.value as ChannelReceive).target.environment.get(0).right as DeclarationObject).features.
					get(0).value_s.equals("aws")) { // aws environment
					return '''
					__data = await __sqs.getQueueUrl({ QueueName: "«((assignment.value as CastExpression).target as ChannelReceive).target.name»-'${id}'"}).promise();
					__data = await __sqs.sendMessage({QueueUrl : __data.QueueUrl }).promise();
					«generateJsArithmeticExpression(assignment.feature,scope)» «assignment.op» __data.Messages[0].Body
					'''
				} else if ((((assignment.value as CastExpression).target as ChannelReceive).target.environment.get(0).
					right as DeclarationObject).features.get(0).value_s.equals("azure"))  { // azure environment
						return '''
							var __msg = await (__util.promisify(__queueSvc.getMessages).bind(__queueSvc))("«((assignment.value as CastExpression).target as ChannelReceive).target.name»-'${id}'}");
							«generateJsArithmeticExpression(assignment.feature,scope)» «assignment.op» __msg[0].messageText;
						'''
				} else { // other environment
					return '''
						
					'''
				}
			} else {
				return '''
					«generateJsArithmeticExpression(assignment.feature,scope)» «assignment.op» «generateJsArithmeticExpression(assignment.value,scope)» 
				'''
			}
		}
		if (assignment.feature_obj !== null) {
			if (assignment.feature_obj instanceof NameObject) {
				typeSystem.get(scope).put(
					((assignment.feature_obj as NameObject).name as VariableDeclaration).name + "." +
						(assignment.feature_obj as NameObject).value,
					valuateArithmeticExpression(assignment.value, scope))
				return '''
					«((assignment.feature_obj as NameObject).name as VariableDeclaration).name»["«(assignment.feature_obj as NameObject).value»"] = «generateJsArithmeticExpression(assignment.value,scope)» 
				'''
			}
			if (assignment.feature_obj instanceof IndexObject) {
				if(typeSystem.get(scope).get((assignment.feature_obj as IndexObject).name.name).contains("Array")){
					return '''
						«(assignment.feature_obj as IndexObject).name.name»[«generateJsArithmeticExpression((assignment.feature_obj as IndexObject).indexes.get(0).value,scope)»] = «generateJsArithmeticExpression(assignment.value,scope)»
					'''
				} else if(typeSystem.get(scope).get((assignment.feature_obj as IndexObject).name.name).contains("Matrix")){
					return '''«generateJsArithmeticExpression(assignment.feature_obj,scope)» =  «generateJsArithmeticExpression(assignment.value,scope)»'''
				}else{
					typeSystem.get(scope).put(
						((assignment.feature_obj as IndexObject).name as VariableDeclaration).name + "[" +
							generateJsArithmeticExpression((assignment.feature_obj as IndexObject).indexes.get(0).value,scope) + "]",
						valuateArithmeticExpression(assignment.value, scope))
					return '''
						«((assignment.feature_obj as IndexObject).name as VariableDeclaration).name»[«generateJsArithmeticExpression((assignment.feature_obj as IndexObject).indexes.get(0).value,scope)»] = «generateJsArithmeticExpression(assignment.value,scope)» 
					'''
						
				}
			}
		}
	}

	def generateJsWhileExpression(WhileExpression exp, String scope) {
		'''
			while(«generateJsArithmeticExpression(exp.cond,scope)»)
				«generateJsExpression(exp.body,scope)»
		'''
	}

	def generateJsForExpression(ForExpression exp, String scope) {
		if (exp.object instanceof CastExpression) {
			if ((exp.object as CastExpression).type.equals("Dat")) {
				if(exp.index.indices.length==1){
					return '''
						for(var __«(exp.index.indices.get(0) as VariableDeclaration).name» in «((exp.object as CastExpression).target as VariableLiteral).variable.name»»){
							
							var «(exp.index.indices.get(0) as VariableDeclaration).name» = «(exp.index.indices.get(0) as VariableDeclaration).name»[__«(exp.index.indices.get(0) as VariableDeclaration).name»];
							«IF exp.body instanceof BlockExpression»
								«FOR e: (exp.body as BlockExpression).expressions»
									«generateJsExpression(e,scope)»
								«ENDFOR»
							«ELSE»
								«generateJsExpression(exp.body,scope)»
							«ENDIF»
						}
					'''
				}else{
					return ''''''
				}	
			} else if ((exp.object as CastExpression).type.equals("Object")) {
				if(exp.index.indices.length==1){
					return '''
					for(__key in «((exp.object as CastExpression).target as VariableLiteral).variable.name» ){
						var «(exp.index.indices.get(0) as VariableDeclaration).name» = {k:__key, v:«((exp.object as CastExpression).target as VariableLiteral).variable.name»[__key]} 
						«IF exp.body instanceof BlockExpression»
							«FOR e: (exp.body as BlockExpression).expressions»
								«generateJsExpression(e,scope)»
							«ENDFOR»
						«ELSE»
							«generateJsExpression(exp.body,scope)»	
						«ENDIF»
					}
				'''
				}else{
					return ''''''
				}	
			}
		} else if (exp.object instanceof RangeLiteral) {
			if(exp.index.indices.length==1){
				return '''
				var «(exp.index.indices.get(0) as VariableDeclaration).name»;
				for(«(exp.index.indices.get(0) as VariableDeclaration).name» = «IF (exp.object as RangeLiteral).value_l1 == null» «(exp.object as RangeLiteral).value1»«ELSE»«(exp.object as RangeLiteral).value_l1.name»«ENDIF» ;«(exp.index.indices.get(0) as VariableDeclaration).name» < «IF (exp.object as RangeLiteral).value_l2 == null» «(exp.object as RangeLiteral).value2»«ELSE»«(exp.object as RangeLiteral).value_l2.name»«ENDIF»; «(exp.index.indices.get(0)as VariableDeclaration).name»++)
				«IF exp.body instanceof BlockExpression»
					«generateJsBlockExpression(exp.body as BlockExpression,scope)»
				«ELSE»
					«generateJsExpression(exp.body,scope)»
				«ENDIF»
			'''
			}else{
				return ''''''
			}
		} else if (exp.object instanceof VariableLiteral) {
			if (((exp.object as VariableLiteral).variable.typeobject.equals('var') &&
				((exp.object as VariableLiteral).variable.right instanceof NameObjectDef) ) ||
				typeSystem.get(scope).get((exp.object as VariableLiteral).variable.name).equals("HashMap")) {
				if(exp.index.indices.length==1){
					return '''
						for(__key in «(exp.object as VariableLiteral).variable.name» ){
							var «(exp.index.indices.get(0) as VariableDeclaration).name» = {k:__key, v:«(exp.object as VariableLiteral).variable.name»[__key]}
							«IF exp.body instanceof BlockExpression»
								«FOR e: (exp.body as BlockExpression).expressions»
									«generateJsExpression(e,scope)»
								«ENDFOR»
							«ELSE»
								«generateJsExpression(exp.body,scope)»	
							«ENDIF»
						}
					'''
				}else{
					return ''''''
				}	
			} else if (typeSystem.get(scope).get((exp.object as VariableLiteral).variable.name).equals("Table")) {
				if(exp.index.indices.length==1){
					return '''
						for(var __«(exp.index.indices.get(0) as VariableDeclaration).name» in «(exp.object as VariableLiteral).variable.name» ){
							var «(exp.index.indices.get(0) as VariableDeclaration).name» = «(exp.object as VariableLiteral).variable.name»[__«(exp.index.indices.get(0) as VariableDeclaration).name»]
							«IF exp.body instanceof BlockExpression»
								«FOR e: (exp.body as BlockExpression).expressions»
									«generateJsExpression(e,scope)»
								«ENDFOR»
							«ELSE»
								«generateJsExpression(exp.body,scope)»
							«ENDIF»
						}
					'''
				}else{
					return ''''''
				}
			} else if(typeSystem.get(scope).get((exp.object as VariableLiteral).variable.name).equals("List <Table>")) {
			    typeSystem.get(scope).put((exp.index.indices.get(0) as VariableDeclaration).name, "Table");
			    return '''
			    for(let «(exp.index.indices.get(0) as VariableDeclaration).name» of «(exp.object as VariableLiteral).variable.name») {
			        «(exp.index.indices.get(0) as VariableDeclaration).name» = «(exp.index.indices.get(0) as VariableDeclaration).name».toArray();
			        «IF exp.body instanceof BlockExpression»
			            «FOR e: (exp.body as BlockExpression).expressions»
			                «generateJsExpression(e,scope)»
			            «ENDFOR»
			        «ELSE»
			            «generateJsExpression(exp.body,scope)»
			        «ENDIF»
			    }
			    '''
			}else if (typeSystem.get(scope).get((exp.object as VariableLiteral).variable.name).equals("File")) {
					return '''
						const __«(exp.index.indices.get(0) as VariableDeclaration).name» = readline.createInterface({
							input: «(exp.object as VariableLiteral).variable.name».readableStreamBody,
							crlfDelay: Infinity
						});
						for await (const «(exp.index.indices.get(0) as VariableDeclaration).name» of __«(exp.index.indices.get(0) as VariableDeclaration).name») {
							«IF exp.body instanceof BlockExpression»
								«FOR e: (exp.body as BlockExpression).expressions»
									«generateJsExpression(e,scope)»
								«ENDFOR»
							«ELSE»
								«generateJsExpression(exp.body,scope)»
							«ENDIF»
						}
						
					'''
				
			} else if(typeSystem.get(scope).get((exp.object as VariableLiteral).variable.name).equals("String[]")){
					if(exp.index.indices.length==1){
						return '''
							for(var __«(exp.index.indices.get(0) as VariableDeclaration).name»=0; __«(exp.index.indices.get(0) as VariableDeclaration).name»<«(exp.object as VariableLiteral).variable.name».length ; __«(exp.index.indices.get(0) as VariableDeclaration).name»++){
								var «(exp.index.indices.get(0) as VariableDeclaration).name» = «(exp.object as VariableLiteral).variable.name»[__«(exp.index.indices.get(0) as VariableDeclaration).name»]
								«IF exp.body instanceof BlockExpression»
									«FOR e: (exp.body as BlockExpression).expressions»
										«generateJsExpression(e,scope)»
									«ENDFOR»
								«ELSE»
									«generateJsExpression(exp.body,scope)»
								«ENDIF»
							}
						'''
					}else
						return''''''
			} else if(typeSystem.get(scope).get((exp.object as VariableLiteral).variable.name).contains("Array")){
					var name = (exp.object as VariableLiteral).variable.name;
				
					return '''
						for(var «(exp.index.indices.get(0) as VariableDeclaration).name» = 0;«(exp.index.indices.get(0) as VariableDeclaration).name» < «name».length;«(exp.index.indices.get(0) as VariableDeclaration).name»++){
							«IF exp.body instanceof BlockExpression»
								«FOR e: (exp.body as BlockExpression).expressions»
									«generateJsExpression(e,scope)»
								«ENDFOR»
							«ELSE»
								«generateJsExpression(exp.body,scope)»
							«ENDIF»
						}
					'''
			} else if(typeSystem.get(scope).get((exp.object as VariableLiteral).variable.name).contains("Matrix")){
					var name = (exp.object as VariableLiteral).variable.name;
					var index_row = (exp.index.indices.get(0) as VariableDeclaration).name
					var index_col = (exp.index.indices.get(1) as VariableDeclaration).name

					return  '''
						for(var «index_row»=0;«index_row»<«name».length;«index_row»++){
							for(var «index_col»=0;«index_col»<«name»[0].length;«index_col»++){
								«IF exp.body instanceof BlockExpression»
									«FOR e: (exp.body as BlockExpression).expressions»
										«generateJsExpression(e,scope)»
									«ENDFOR»
								«ELSE»
									«generateJsExpression(exp.body,scope)»
								«ENDIF»
							}
						}
					'''
			}
		} 
	}

	def generateJsBlockExpression(BlockExpression block, String scope) {
		return '''
			{
				«FOR exp : block.expressions»
					«generateJsExpression(exp,scope)»
				«ENDFOR»
			}
		'''
	}

	def generateJsArithmeticExpression(ArithmeticExpression exp,String scope) {
		if (exp instanceof BinaryOperation) {
			if (exp.feature.equals("and"))
				return '''«generateJsArithmeticExpression(exp.left,scope)» && «generateJsArithmeticExpression(exp.right,scope)»'''
			else if (exp.feature.equals("or"))
				return '''«generateJsArithmeticExpression(exp.left,scope)» || «generateJsArithmeticExpression(exp.right,scope)»'''
			else
				return '''«generateJsArithmeticExpression(exp.left,scope)» «exp.feature» «generateJsArithmeticExpression(exp.right,scope)»'''
		} else if (exp instanceof UnaryOperation) {
			if(exp.feature == "not")
				return '''! («generateJsArithmeticExpression(exp.operand,scope)»)'''
			else	
				return '''«exp.feature» «generateJsArithmeticExpression(exp.operand,scope)»'''
		} else if (exp instanceof ParenthesizedExpression) {
			return '''(«generateJsArithmeticExpression(exp.expression,scope)»)'''
		} else if (exp instanceof NumberLiteral) {
			return '''«exp.value»'''
		} else if (exp instanceof BooleanLiteral) {
			return '''«exp.value»'''
		} else if (exp instanceof FloatLiteral) {
			return '''«exp.value»'''
		}
		if (exp instanceof StringLiteral) {
			return '''"«exp.value»"'''
		} else if (exp instanceof VariableLiteral) {
			return '''«exp.variable.name»'''
		} else if (exp instanceof VariableFunction) {
			if ((exp.target.right instanceof DeclarationObject)  && (exp.target.right as DeclarationObject).features.get(0).value_s.equals("random")) {
				return '''Math.random()'''
			} else if(exp.feature.equals("containsKey")){
				return '''«generateJsArithmeticExpression(exp.expressions.get(0),scope)» in «exp.target.name»'''
			} else {
				var s = ""
				if(exp.feature.equals("length")){
					s = exp.target.name + "." + exp.feature
				} else {
					s = exp.target.name + "." + exp.feature + "("
					for (e : exp.expressions) {
						s += generateJsArithmeticExpression(e, scope)
						if (e != exp.expressions.last()) {
							s += ","
						}
					}
					s += ")"
				}
				
			return s
			}
			
		} else if (exp instanceof TimeFunction){
			if(exp.value != null){
				return '''(process.hrtime(«exp.value.name»))'''
			}else{
				return '''(process.hrtime())'''	
			}
		} else if (exp instanceof NameObject) {
			return '''«(exp.name as VariableDeclaration).name».«exp.value»'''
		} else if (exp instanceof IndexObject) {
			if( exp.indexes.length == 1 ){
				return '''«(exp.name as VariableDeclaration).name»[«generateJsArithmeticExpression(exp.indexes.get(0).value,scope)»]'''
			} else if(exp.indexes.length == 2){
				var i = generateJsArithmeticExpression(exp.indexes.get(0).value,scope)
				var j = generateJsArithmeticExpression(exp.indexes.get(1).value,scope)
				return '''«(exp.name as VariableDeclaration).name»[«i»][«j»]'''
			}else{
				//return '''«(exp.name as VariableDeclaration).name»[«generateJsArithmeticExpression(exp.indexes.get(0).value)»,«generateJsArithmeticExpression(exp.indexes.get(1).value)»,«generateJsArithmeticExpression(exp.indexes.get(2).value)»]'''
			}
		} else if (exp instanceof CastExpression) {
			return '''«generateJsArithmeticExpression(exp.target,scope)»'''
		} else if (exp instanceof MathFunction) {
			return '''Math.«exp.feature»(«FOR par: exp.expressions» «generateJsArithmeticExpression(par,scope)» «IF !par.equals(exp.expressions.last)»,«ENDIF»«ENDFOR»)'''
		}else if(exp instanceof LocalFunctionCall){
			var s=''''''
			s += "await "
			s += exp.target.name + "("
			if (exp.input != null) {
				for (input : exp.input.inputs) {
					s += generateJsArithmeticExpression(input, scope)
					if (input != exp.input.inputs.last) {
						s += ","
					}
				}
			}
			s += ")"
			return s
		}else{
			return ''''''
		}
	}

	def String valuateArithmeticExpression(ArithmeticExpression exp, String scope) {
		if (exp instanceof NumberLiteral) {
			return "Integer"
		} else if (exp instanceof BooleanLiteral) {
			return "Boolean"
		} else if (exp instanceof StringLiteral) {
			return "String"
		} else if (exp instanceof FloatLiteral) {
			return "Double"
		} else if (exp instanceof VariableLiteral) {
			val variable = exp.variable
			if (variable.typeobject.equals("dat")) {
				return "Table"
			} else if (variable.typeobject.equals("channel")) {
				return "Channel"
			} else if (variable.typeobject.equals("var")) {
				if (variable.right instanceof NameObjectDef) {
					return "HashMap"
				} else if (variable.right instanceof ArithmeticExpression) {
					return valuateArithmeticExpression(variable.right as ArithmeticExpression, scope)
				}else{
					return typeSystem.get(scope).get(variable.name) // if it's a parameter of a FunctionDefinition
				}
			}
			return "variable"
		} else if (exp instanceof NameObject) {
			return typeSystem.get(scope).get(exp.name.name + "." + exp.value)
		} else if (exp instanceof IndexObject) {
			if(typeSystem.get(scope).get(exp.name.name).contains("Array") ||typeSystem.get(scope).get(exp.name.name).contains("Matrix")){
				return typeSystem.get(scope).get(exp.name.name).split("_").get(1)
			}
			else{
				return typeSystem.get(scope).get(exp.name.name + "[" + generateJsArithmeticExpression(exp.indexes.get(0).value,scope) + "]")
			}
		} else if (exp instanceof DatTableObject) {
			return "Table"
		}
		if (exp instanceof UnaryOperation) {
			if (exp.feature.equals("!"))
				return "Boolean"
			return valuateArithmeticExpression(exp.operand, scope)
		}
		if (exp instanceof BinaryOperation) {
			var left = valuateArithmeticExpression(exp.left, scope)
			var right = valuateArithmeticExpression(exp.right, scope)
			if (exp.feature.equals("+") || exp.feature.equals("-") || exp.feature.equals("*") ||
				exp.feature.equals("/")) {
				if (left.equals("String") || right.equals("String"))
					return "String"
				else if (left.equals("Double") || right.equals("Double"))
					return "Double"
				else
					return "Integer"
			} else
				return "Boolean"
		} else if (exp instanceof CastExpression) {
			if (exp.type.equals("Object")) {
				return "HashMap"
			}
			if (exp.type.equals("String")) {
				return "String"
			}
			if (exp.type.equals("Integer")) {
				return "Integer"
			}
			if (exp.type.equals("Float")) {
				return "Double"
			}
			if (exp.type.equals("Dat")) {
				return "Table"
			}
			if (exp.type.equals("Date")) {
				return "LocalDate"
			}
		} else if (exp instanceof ParenthesizedExpression) {
			return valuateArithmeticExpression(exp.expression, scope)
		}
		if (exp instanceof MathFunction) {
			if (exp.feature.equals("round")) {
				return "Integer"
			} else {
				for (el : exp.expressions) {
					if (valuateArithmeticExpression(el, scope).equals("Double")) {
						return "Double"
					}
				}
				return "Integer"
			}
		} else if (exp instanceof TimeFunction){
			return "Long"
		}else if (exp instanceof VariableFunction) {
			if (exp.target.typeobject.equals("var")) {
				if (exp.feature.equals("split")) {
					return "String[]"
				} else if (exp.feature.contains("indexOf") || exp.feature.equals("length") || exp.feature.equals("rowCount") || exp.feature.equals("colCount")) {
					return "Integer"
				} else if (exp.feature.equals("concat") || exp.feature.equals("substring") ||
					exp.feature.equals("toLowerCase") || exp.feature.equals("toUpperCase")
					|| exp.feature.equals("deepToString")) {
					return "String"
				} else {
					return "Boolean"
				}
			} else if (exp.target.typeobject.equals("random")) {
				if (exp.feature.equals("nextBoolean")) {
					return "Boolean"
				} else if (exp.feature.equals("nextDouble")) {
					return "Double"
				} else if (exp.feature.equals("nextInt")) {
					return "Integer"
				}
			} else if (exp.target.typeobject.equals("query")){
				var queryType = (exp.target.right as DeclarationObject).features.get(1).value_s
				var typeDatabase = (((exp.target.right as DeclarationObject)
					.features.get(2).value_f as VariableDeclaration).right as DeclarationObject).features.get(0).value_s
				if(typeDatabase.equals("sql")) {
					if (queryType.equals("query")){
						return "Table"
					} else {
						return "int"
					}	
				} else {
					if(queryType.equals("select")){
						return "List <Table>"
					} else {
						return "long"
					}
				}
			}
		} else {
			return "Object"
		}
	}
	
	def generateJsVariableFunction(VariableFunction expression, Boolean t, String scope) {
		if (expression.target.right instanceof DeclarationObject) {
			var type = (expression.target.right as DeclarationObject).features.get(0).value_s
			
			switch (type){
				case "query":{
					var queryType = (expression.target.right as DeclarationObject).features.get(1).value_s
				    if(expression.feature.equals("execute")){
				        var connection = (expression.target.right as DeclarationObject).features.get(2).value_f.name
				        var databaseType = ((((expression.target.right as DeclarationObject).features.get(2) as DeclarationFeature)
				            .value_f as VariableDeclaration).right as DeclarationObject).features.get(0).value_s
				        if(databaseType.equals("sql")) {
				            if (queryType.equals("value")){
				                return '''
				                JSON.stringify(
				                    await (__util.promisify(«connection».query).bind(«connection»))(
				                «IF(expression.target.right as DeclarationObject).features.get(3).value_s.nullOrEmpty»
				                    «(expression.target.right as DeclarationObject).features.get(3).value_f.name»
				                «ELSE» 
				                    "«(expression.target.right as DeclarationObject).features.get(3).value_s»"
				                «ENDIF»
				                    )
				                ).match(/[+-]?\d+(?:\.\d+)?/g);
				            ''' 
				            } else {
				                return '''
				                await (__util.promisify(«connection».query).bind(«connection»))(
				                «IF(expression.target.right as DeclarationObject).features.get(3).value_s.nullOrEmpty»
				                    «(expression.target.right as DeclarationObject).features.get(3).value_f.name»
				                «ELSE» 
				                    "«(expression.target.right as DeclarationObject).features.get(3).value_s»"
				                «ENDIF»
				                );
				                ''' 
				            }
				        } else if(databaseType.equals("nosql")) {
				            if(queryType.equals("insert")) {
				                if((expression.target.right as DeclarationObject).features.get(3).value_s.nullOrEmpty) {
				                    if((expression.target.right as DeclarationObject).features.get(3).value_f.right instanceof DeclarationObject)
				                        return '''
				                        await «connection».insertMany((await «expression.target.name»()));
				                        
				                        '''
				                    else 
				                        return '''
				                        await «connection».insertMany(«expression.target.name»);
				                        
				                        '''
				                } else 
				                    return '''
				                    await «connection».insertMany(«expression.target.name»);
				                    
				                    '''
				            } else if(queryType.equals("select")) {
				                return '''
				                (await «expression.target.name»());
				                
				                '''
				            } else if(queryType.equals("delete")) {
				                return '''
				                (await «connection».deleteMany(«expression.target.name»)).deletedCount
				                
				                '''
				            } else if(queryType.equals("update")) {
				                return '''
				                (await «connection».updateMany(«expression.target.name»Filter, «expression.target.name»));
				                
				                '''
				            } else if(queryType.equals("replace")) {
				                return '''
				                (await «connection».replaceOne(«expression.target.name»Filter, «expression.target.name»));
				                
				                '''
				            }
				        }
				    }
				} case "distributed-query": {
				    var queryType = (expression.target.right as DeclarationObject).features.get(1).value_s
				    if(expression.feature.equals("execute")){
				        if(queryType.equals("insert")) {
				            if((expression.target.right as DeclarationObject).features.get(2).value_s.nullOrEmpty) {
				                if((expression.target.right as DeclarationObject).features.get(2).value_f.right instanceof DeclarationObject) {
				                    var ret = ''''''
				                    for(i : 3 ..< (expression.target.right as DeclarationObject).features.size)					
				                        ret += '''
				                        await «((expression.target.right as DeclarationObject).features.get(i) as DeclarationFeature).value_f.name».insertMany((await «expression.target.name»()));
				                        '''
				                    ret += '''
				                    '''
				                    return ret
				                } else {
				                    var ret = ''''''
				                    for(i : 3 ..< (expression.target.right as DeclarationObject).features.size)					
				                        ret += '''
				                        await «((expression.target.right as DeclarationObject).features.get(i) as DeclarationFeature).value_f.name».insertMany(«expression.target.name»);
				                        '''
				                    ret += '''
				                    '''
				                    return ret
				                }
				            } else {
				                var ret = ''''''
				                for(i : 3 ..< (expression.target.right as DeclarationObject).features.size)					
				                    ret += '''
				                    await «((expression.target.right as DeclarationObject).features.get(i) as DeclarationFeature).value_f.name».insertMany(«expression.target.name»);
				                    '''
				                ret += '''
				                '''
				                return ret
				            }
				        } else if(queryType.equals("select")) {
				            return '''
				            (await «expression.target.name»());
				            
				            '''
				        } else if(queryType.equals("update")) {
				            var ret = ''''''
				            for(i : 4 ..< (expression.target.right as DeclarationObject).features.size)					
				                ret += '''
				                (await «((expression.target.right as DeclarationObject).features.get(i) as DeclarationFeature).value_f.name».updateMany(«expression.target.name»Filter, «expression.target.name»));
				                '''
				            ret += '''
				            '''
				            return ret
				        } else if(queryType.equals("replace")) {
				            var ret = ''''''
				            for(i : 4 ..< (expression.target.right as DeclarationObject).features.size)					
				                ret += '''
				                (await «((expression.target.right as DeclarationObject).features.get(i) as DeclarationFeature).value_f.name».replaceOne(«expression.target.name»Filter, «expression.target.name»));
				                '''
				            ret += '''
				            '''
				            return ret							
				        } else if(queryType.equals("delete")) {
				            return '''
				            await «expression.target.name»().then((val) => { return val; });
				            
				            '''
				        }
				    }
				}					
				default :{
					return generateJsArithmeticExpression(expression, scope)
				}
			}
		}else if (expression.target.right instanceof ArrayInit ){
								
			if(((expression.target.right as ArrayInit).values.get(0) instanceof NumberLiteral) ||
					((expression.target.right as ArrayInit).values.get(0) instanceof StringLiteral) ||
					((expression.target.right as ArrayInit).values.get(0) instanceof FloatLiteral)
				){ //array mono-dimensional	
					if(expression.feature.equals("length")){
						var s = expression.target.name + "." + expression.feature
						return s
					} else if (expression.feature.equals("deepToString")){
						var s = expression.target.name
						return s
					} else if (expression.feature.equals("setType")){
						return  '''console.log("The function setType is ineffective: the array in nodejs does not need a type")'''
					} else if (expression.feature.equals("getPortionIndex") || expression.feature.equals("getPortionIndex")){
						//The array is not a portion, so it returns -1
						return "-1;"
					} else {
						var s = expression.target.name + "." + expression.feature + "("
						for (exp : expression.expressions) {
							s += generateJsArithmeticExpression(exp, scope)
							if (exp != expression.expressions.last()) {
								s += ","
							}
						}
						s += ")"
						return s
					}
				} else if ((expression.target.right as ArrayInit).values.get(0) instanceof ArrayValue){ //matrix 2d
					if(expression.feature.equals("rowCount")){ //num of rows
						var s = expression.target.name + ".length"
						return s
					} else if (expression.feature.equals("colCount")){ //num of cols
						var s = expression.target.name + "[0].length"
						return s
					} else if (expression.feature.equals("deepToString")){ //matrix to string
						var s = expression.target.name
						return s
					} else if (expression.feature.equals("setType")){
						return  '''console.log("The function setType is ineffective: the matrix in nodejs does not need a type")'''
					} else if (expression.feature.equals("getPortionDisplacement") || expression.feature.equals("getPortionIndex")){
						//The matrix is not a portion, so it returns -1
						return "-1;"
					} else {
						var s = expression.target.name + "." + expression.feature + "("
						for (exp : expression.expressions) {
							s += generateJsArithmeticExpression(exp, scope)
							if (exp != expression.expressions.last()) {
								s += ","
							}
						}
						s += ")"
						return s
					}	
				}
				
		} else if ( (expression.target instanceof VariableDeclaration &&
				(typeSystem.get(scope).get((expression.target as VariableDeclaration).name).contains("Array"))) ||
					(expression.target instanceof ConstantDeclaration &&
				(typeSystem.get(scope).get((expression.target as ConstantDeclaration).name).contains("Array")))
					) { //Array variable					
					
					if(expression.feature.equals("length")){
						var s = expression.target.name + "." + expression.feature
						return s
					} else if (expression.feature.equals("deepToString")){ //array to string
						var s = expression.target.name
						return s
					} else if (expression.feature.equals("setType")){
						return  '''console.log("The function setType is ineffective: the array in nodejs does not need a type")'''
					} else if (expression.feature.equals("getPortionDisplacement")){
						return "__portionDisplacement"
					} else if (expression.feature.equals("getPortionIndex")){
						return "__portionIndex"
					} else {
						var s = expression.target.name + "." + expression.feature + "("
						for (exp : expression.expressions) {
							s += generateJsArithmeticExpression(exp, scope)
							if (exp != expression.expressions.last()) {
								s += ","
							}
						}
						s += ")"
						return s
					}
		} else if ( (expression.target instanceof VariableDeclaration &&
				(typeSystem.get(scope).get((expression.target as VariableDeclaration).name).contains("Matrix"))) ||
					(expression.target instanceof ConstantDeclaration &&
				(typeSystem.get(scope).get((expression.target as ConstantDeclaration).name).contains("Matrix")))
					) { //Matrix variable
					if(expression.feature.equals("rowCount")){
						var s = expression.target.name + ".length"
						return s
					} else if (expression.feature.equals("colCount")){
						var s = expression.target.name + "[0].length"
						return s
					} else if (expression.feature.equals("deepToString")){ //matrix to string
						var s = expression.target.name
						return s
					} else if (expression.feature.equals("setType")){
						return  '''console.log("The function setType is ineffective: the matrix in nodejs does not need a type")'''					
					} else if (expression.feature.equals("getPortionDisplacement")){
						return "__portionDisplacement"
					} else if (expression.feature.equals("getPortionIndex")){
						return "__portionIndex"
					} else {
						var s = expression.target.name + "." + expression.feature + "("
						for (exp : expression.expressions) {
							s += generateJsArithmeticExpression(exp, scope)
							if (exp != expression.expressions.last()) {
								s += ","
							}
						}
						s += ")"
						return s
					}
		}else{
			return generateJsArithmeticExpression(expression, scope)
		}
	}
	
	def CharSequence compileScriptDeploy(Resource resource, String name, boolean local){
		switch this.env {
		   case "aws": AWSDeploy(resource,name,local,false)
		   case "aws-debug": AWSDebugDeploy(resource,name,local,true)
		   case "azure": AzureDeploy(resource,name,local)
		   default: this.env+" not supported"
  		}
	} 
	
	def CharSequence AWSDeploy(Resource resource, String name, boolean local, boolean debug)
	'''
		#!/bin/bash
		
		if [ $# -eq 0 ]
		  then
		    echo "No arguments supplied. ./aws_deploy.sh <user profile> <function_name> <id_function_execution>"
		    exit 1
		fi
		
		user=$1
		function=$2
		id=$3
		
		echo "Checking that aws-cli is installed"
		which aws
		if [ $? -eq 0 ]; then
		      echo "aws-cli is installed, continuing..."
		else
		      echo "You need aws-cli to deploy this lambda. Google 'aws-cli install'"
		      exit 1
		fi
		
		echo '{
				"Version": "2012-10-17",
				"Statement": [
					{
						"Effect": "Allow",
						"Action": [
							"sqs:DeleteMessage",
							"sqs:GetQueueAttributes",
							"sqs:ReceiveMessage",
							"sqs:SendMessage",
							"sqs:*"
						],
						"Resource": "*" 
					},
					{
					"Effect": "Allow",
					"Action": [
						"s3:*"
					],
					"Resource": "*" 
										},
					{
						"Effect":"Allow",
						"Action": [
							"logs:CreateLogGroup",
							"logs:CreateLogStream",
							"logs:PutLogEvents"
						],
						"Resource": "*"
					},
					{
					    "Effect": "Allow",
					    "Action": "rds:*",
					    "Resource": "*"
					},
					{
					    "Effect": "Allow",
					    "Action": ["rds:Describe*"],
					    "Resource": "*"
					}
				]
			}' > policyDocument.json
		
		echo '{
					"Version": "2012-10-17",
					"Statement": [
						{
							"Effect": "Allow",
							"Principal": {
								"Service": "lambda.amazonaws.com"
							},
							"Action": "sts:AssumeRole" 
						}
					]
				}' > rolePolicyDocument.json
		
		#create role policy
		
		echo "creation of role lambda-sqs-execution ..."
		
		role_arn=$(aws iam --profile ${user} get-role --role-name lambda-sqs-execution --query 'Role.Arn')
		
		if [ $? -ne 0 ]; then 
			role_arn=$(aws iam --profile ${user} create-role --role-name lambda-sqs-execution --assume-role-policy-document file://rolePolicyDocument.json --output json --query 'Role.Arn')
		fi
		
		echo "role lambda-sqs-execution created at ARN "$role_arn
		
		aws iam --profile ${user} put-role-policy --role-name lambda-sqs-execution --policy-name lambda-sqs-policy --policy-document file://policyDocument.json
		
		mkdir ${function}_lambda
				
		cd ${function}_lambda
		
		echo '«generateBodyJs(resource,root.body,root.parameters,name,env)»
				«FOR fd:functionCalled.values()»
					
				«generateJsExpression(fd, name)»
				
				«ENDFOR»
		' > ${function}.js
		
		echo "npm init..."
		npm init -y
		if [ $? -eq 0 ]; then
		    echo "..."
		else
		    echo "npm init failed"
		    exit 1
		fi
		
		echo " npm install aws-sdk "
		npm install aws-sdk
		if [ $? -eq 0 ]; then
		    echo "..."
		else
		    echo "npm install aws-sdk failed"
		    exit 1
		fi
		
		echo "npm install async"
		npm install async
		if [ $? -eq 0 ]; then
		    echo "..."
		else
		    echo "npm install async failed"
		    exit 1
		fi
		
		echo "npm install dataframe-js"
		npm install dataframe-js
		if [ $? -eq 0 ]; then
		    echo "..."
		else
		    echo "npm install dataframe-js failed"
		    exit 1
		fi
		
		echo "npm install util"
		npm install util
		if [ $? -eq 0 ]; then
		    echo "..."
		else
		    echo "npm install util failed"
		    exit 1
		fi
		
		echo "npm install mysql"
		npm install mysql
		if [ $? -eq 0 ]; then
		    echo "..."
		else
		    echo "npm install mysql failed"
		    exit 1
		fi
		
		echo "npm install axios"
		npm install axios
		if [ $? -eq 0 ]; then
		    echo "..."
		else
			echo "npm install axios failed"
			exit 1
		fi
		
		echo "npm install qs"
		npm install qs
		if [ $? -eq 0 ]; then
		    echo "..."
		else
		    echo "npm install qs failed"
		    exit 1
		fi
		
		echo "npm install mongodb@3.6.3"
		npm install mongodb@3.6.3
		if [ $? -eq 0 ]; then
		    echo "..."
		else
		    echo "npm install mongodb failed"
		    exit 1
		fi

		echo "npm install csv-parse"
		npm install csv-parse
		if [ $? -eq 0 ]; then
		    echo "..."
		else
		    echo "npm install csv-parse failed"
		    exit 1
		fi

		echo "npm install fs"
		npm install fs
		if [ $? -eq 0 ]; then
		    echo "..."
		else
		    echo "npm install fs failed"
		    exit 1
		fi
		
	«FOR req : resource.allContents.toIterable.filter(RequireExpression).filter[(environment.right as DeclarationObject).features.get(4).value_s.equals(language)]»
		echo "npm install «req.lib»"
		npm install «req.lib»"
		if [ $? -eq 0 ]; then
		    echo "..."
		else
		    echo "npm install «req.lib» failed"
		    exit 1
		fi
	«ENDFOR»
				
		echo ""
		echo "creating .zip file"
		
		zip -r -q -9 ../${function}_lambda.zip . 
		
		cd .. 
			
		#create the lambda function
		echo "creation of the lambda function"
		
		if [ $(wc -c < ${function}_lambda.zip) -lt 50000000 ]; then
			aws lambda --profile ${user} create-function --function-name ${function}_${id} --zip-file fileb://${function}_lambda.zip --handler ${function}.handler --runtime «language» --role ${role_arn//\"} --memory-size «memory» --timeout «time»
			
			while [ $? -ne 0 ]; do
				aws lambda --profile ${user} create-function --function-name ${function}_${id} --zip-file fileb://${function}_lambda.zip --handler ${function}.handler --runtime «language» --role ${role_arn//\"} --memory-size «memory» --timeout «time»
			done
		else
			echo "zip file too big, uploading it using s3"
			echo "creating bucket for s3"
			aws s3 --profile ${user} mb s3://${function,,}${id}bucket
			echo "s3 bucket created. uploading file"
			aws s3 --profile ${user} cp ${function}_lambda.zip s3://${function,,}${id}bucket --grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers
			echo "file uploaded, creating function"		
			
			echo "creation of the lambda function"
			aws lambda --profile ${user} create-function --function-name ${function}_${id} --code S3Bucket=""${function,,}""${id}"bucket",S3Key=""${function}"_lambda.zip" --handler ${function}.handler --runtime «language» --role ${role_arn//\"} --memory-size «memory» --timeout «time»			
		fi
		
		echo "lambda function created"
		
		# clear 
		rm -r ${function}_lambda/
		rm ${function}_lambda.zip
		rm rolePolicyDocument.json
		rm policyDocument.json
	
	'''
	
	def CharSequence AWSUndeploy(Resource resource, String name)'''
		#!/bin/bash
			
		if [ $# -eq 0 ]
		  then
		    echo "No arguments supplied. ./aws_deploy.sh <user_profile> <function_name> <id_function_execution>"
		    exit 1
		fi
		
		user=$1
		function=$2
		id=$3
		
		# delete termination queue
		
		echo "get termination-${function}-${id} queue-url"
		termination_queue_url=$(aws sqs --profile ${user} get-queue-url --queue-name termination-${function}-${id} --query 'QueueUrl')
		echo ${termination_queue_url//\"}
		
		echo "delete queue at url ${termination_queue_url//\"} "
		aws sqs --profile ${user} delete-queue --queue-url ${termination_queue_url//\"}
		
		# delete user queue
		«FOR res: resource.allContents.toIterable.filter(VariableDeclaration).filter[right instanceof DeclarationObject].filter[(it.right as DeclarationObject).features.get(0).value_s.equals("channel")]
		.filter[((it.environment.get(0) as VariableDeclaration).right as DeclarationObject).features.get(0).value_s.equals("aws")] »
			#get «res.name»_${id} queue-url
			
			echo "get «res.name»-${id} queue-url"
			queue_url=$(aws sqs --profile ${user} get-queue-url --queue-name «res.name»-${id} --query 'QueueUrl')
			echo ${queue_url//\"}
			
			echo "delete queue at url ${queue_url//\"} "
			aws sqs --profile ${user} delete-queue --queue-url ${queue_url//\"}
			
		«ENDFOR»

		«FOR  res: resource.allContents.toIterable.filter(FlyFunctionCall).filter[((it.environment as VariableDeclaration).right as DeclarationObject).features.get(0).value_s.equals("aws")]»
			#delete lambda function: «res.target.name»_${id}
			echo "delete lambda function: «res.target.name»_${id}"
			aws lambda --profile ${user} delete-function --function-name «res.target.name»_${id}
			
			# delete S3 bucket if existent
			functionLowerCase=${2,,}
			if aws s3 ls "s3://${functionLowerCase}${id}bucket" 2>&1 | grep -q 'An error occurred'
			then
			    echo "bucket does not exist, no need to delete it"
			else
			    echo "bucket exist, so it has to be deleted"
			    aws s3 rb s3://${functionLowerCase}${id}bucket --force
			fi
		«ENDFOR»
	'''
	
	def CharSequence AWSDebugDeploy(Resource resource, String name, boolean local, boolean debug)
		'''
		#!/bin/bash
		
		if [ $# -eq 0 ]
		  then
		    echo "No arguments supplied. ./aws-debug_deploy.sh <user_profile> <function_name> <id_function_execution>"
		    exit 1
		fi
		
		echo "Checking that aws-cli is installed"
		which aws
		if [ $? -eq 0 ]; then
		      echo "aws-cli is installed, continuing..."
		else
		      echo "You need aws-cli to deploy this lambda. Google 'aws-cli install'"
		      exit 1
		fi
		
		aws configure list --profile dummy_fly_debug
		if [ $? -eq 0 ]; then
			echo "dummy user found, continuing..."
		else
		     echo "creating dummy user..."
		     aws configure set aws_access_key_id dummy --profile dummy_fly_debug
		     aws configure set aws_secret_access_key dummy --profile dummy_fly_debug
		     aws configure set region us-east-1 --profile dummy_fly_debug
		     aws configure set output json --profile dummy_fly_debug
		     echo "dummy user created"
		fi
		
		user=$1
		function=$2
		id=$3
		
		echo '{
				"Version": "2012-10-17",
				"Statement": [
					{
						"Effect": "Allow",
						"Action": [
							"sqs:DeleteMessage",
							"sqs:GetQueueAttributes",
							"sqs:ReceiveMessage",
							"sqs:SendMessage",
							"sqs:*"
						],
						"Resource": "*" 
					},
					{
					"Effect": "Allow",
					"Action": [
						"s3:*"
					],
					"Resource": "*" 
										},
					{
						"Effect":"Allow",
						"Action": [
							"logs:CreateLogGroup",
							"logs:CreateLogStream",
							"logs:PutLogEvents"
						],
						"Resource": "*"
					}
				]
			}' > policyDocument.json
		
		echo '{
					"Version": "2012-10-17",
					"Statement": [
						{
							"Effect": "Allow",
							"Principal": {
								"Service": "lambda.amazonaws.com"
							},
							"Action": "sts:AssumeRole" 
						}
					]
				}' > rolePolicyDocument.json
		
		#create role policy
		
		echo "creation of role lambda-sqs-execution ..."
		
		role_arn=$(aws --endpoint-url=http://localhost:4593 iam --profile dummy_fly_debug get-role --role-name lambda-sqs-execution --query 'Role.Arn')
		
		if [ $? -ne 0 ]; then 
			role_arn=$(aws --endpoint-url=http://localhost:4593 iam --profile dummy_fly_debug create-role --role-name lambda-sqs-execution --assume-role-policy-document file://rolePolicyDocument.json --output json --query 'Role.Arn')
		fi
		
		echo "role lambda-sqs-execution created at ARN "$role_arn
		
		aws iam --endpoint-url=http://localhost:4593 --profile dummy_fly_debug put-role-policy --role-name lambda-sqs-execution --policy-name lambda-sqs-policy --policy-document file://policyDocument.json
		
		echo "Installing requirements"
		
		mkdir ${function}_lambda
				
		cd ${function}_lambda
		
		
		echo '«generateBodyJs(resource,root.body,root.parameters,name,env)»
		«FOR fd:functionCalled.values()»
			
		«generateJsExpression(fd, name)»
		
		«ENDFOR»
		' > ${function}.js
		
		echo "npm init..."
		npm init -y
		if [ $? -eq 0 ]; then
		    echo "..."
		else
		    echo "npm init failed"
		    exit 1
		fi
		
		echo "npm instal aws-sdk "
		npm install aws-sdk
		if [ $? -eq 0 ]; then
		    echo "..."
		else
		    echo "npm install aws-sdk failed"
		    exit 1
		fi
		
		echo "npm install async"
		npm install async
		if [ $? -eq 0 ]; then
		    echo "..."
		else
		    echo "npm install async failed"
		    exit 1
		fi
		
		echo "npm install dataframe-js"
		npm install dataframe-js
		if [ $? -eq 0 ]; then
		    echo "..."
		else
		    echo "npm install dataframe-js failed"
		    exit 1
		fi
		
		echo "npm install util"
		npm install util
		if [ $? -eq 0 ]; then
			echo "..."
		else
			echo "npm install util failed"
			exit 1
		fi
		
		echo "npm install mysql"
		npm install mysql
		if [ $? -eq 0 ]; then
		    echo "..."
		else
		    echo "npm install mysql failed"
		    exit 1
		fi
		
		echo "npm install axios"
		npm install axios
		if [ $? -eq 0 ]; then
		    echo "..."
		else
		    echo "npm install axios failed"
		    exit 1
		fi
		
		echo "npm install qs"
		npm install qs
		if [ $? -eq 0 ]; then
			echo "..."
		else
			echo "npm install qs failed"
			exit 1
		fi

		echo "npm install mongodb@3.6.3"
		npm install mongodb@3.6.3
		if [ $? -eq 0 ]; then
		    echo "..."
		else
		    echo "npm install mongodb failed"
		    exit 1
		fi

		echo "npm install csv-parse"
		npm install csv-parse
		if [ $? -eq 0 ]; then
		    echo "..."
		else
		    echo "npm install csv-parse failed"
		    exit 1
		fi

		echo "npm install fs"
		npm install fs
		if [ $? -eq 0 ]; then
		    echo "..."
		else
		    echo "npm install fs failed"
		    exit 1
		fi
		
		«FOR req : resource.allContents.toIterable.filter(RequireExpression).filter[(environment.right as DeclarationObject).features.get(4).value_s.equals(language)]»
			echo "npm install «req.lib»"
			npm install «req.lib»"
			if [ $? -eq 0 ]; then
			    echo "..."
			else
			    echo "npm install «req.lib» failed"
			    exit 1
			fi
		«ENDFOR»
		
		echo ""
		echo "creating .zip file"
		
		zip -r -q -9 ../${id}\_lambda.zip . 
		echo "zip created"
		
		cd .. 
			
		#create the lambda function
		echo "creation of the lambda function"
		
		if [ $(wc -c < ${id}_lambda.zip) -lt 50000000 ]; then
			aws --endpoint-url=http://localhost:4574 lambda --profile dummy_fly_debug create-function --function-name ${function}_${id} --zip-file fileb://${id}_lambda.zip --handler ${function}.handler --runtime «language» --role ${role_arn//\"} --memory-size «memory»
			
			while [ $? -ne 0 ]; do
				aws --endpoint-url=http://localhost:4574 lambda --profile dummy_fly_debug create-function --function-name ${function}_${id} --zip-file fileb://${id}_lambda.zip --handler ${function}.handler --runtime «language» --role ${role_arn//\"} --memory-size «memory»
			done
		else
			echo "zip file too big, uploading it using s3"
			echo "creating bucket for s3"
			aws --endpoint-url=http://localhost:4572 s3 --profile dummy_fly_debug mb s3://${function,,}${id}bucket
			echo "s3 bucket created. uploading file"
			aws --endpoint-url=http://localhost:4572 s3 --profile dummy_fly_debug cp ${id}_lambda.zip s3://${function,,}${id}bucket --grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers
			echo "file uploaded, creating function"
			aws --endpoint-url=http://localhost:4574 lambda --profile dummy_fly_debug create-function --function-name ${function}_${id} --code S3Bucket=""${function,,}""${id}"bucket",S3Key=""${id}"_lambda.zip" --handler ${function}.handler --runtime «language» --role ${role_arn//\"} --memory-size «memory»
			echo "lambda function created"
		fi
		
		echo "lambda function created"
		
		# clear 
		rm -r ${function}_lambda
		rm ${id}_lambda.zip
		rm rolePolicyDocument.json
		rm policyDocument.json
		'''

	def CharSequence compileDockerCompose(Resource resource)
	'''
		docker network create -d bridge --subnet 192.168.0.0/24 --gateway 192.168.0.1 flynet
		echo "
		version: '2.1'
		
		services:
		 localstack:
		   image: localstack/localstack:0.10.6
		   ports:
		     - '4567-4593:4567-4593'
		     - '\${PORT_WEB_UI-8080}:\${PORT_WEB_UI-8080}'
		   environment:
		     - SERVICES=\${SERVICES- s3, sqs, lambda, iam, cloud watch, cloud watch logs}
		     - DEBUG=\${DEBUG- 1}
		     - DATA_DIR=\${DATA_DIR- }
		     - PORT_WEB_UI=\${PORT_WEB_UI- }
		     - LAMBDA_EXECUTOR=\${LAMBDA_EXECUTOR- docker}
		     - KINESIS_ERROR_PROBABILITY=\${KINESIS_ERROR_PROBABILITY- }
		     - DOCKER_HOST=unix:///var/run/docker.sock
		     - HOSTNAME=192.168.0.1
		     - HOSTNAME_EXTERNAL=192.168.0.1
		     - LOCALSTACK_HOSTNAME=192.168.0.1
		   volumes:
		     - '\${TMPDIR:-/tmp/localstack}:/tmp/localstack'
		     - '/var/run/docker.sock:/var/run/docker.sock' "> docker-compose.yml
		     
		docker-compose up
	'''
	
	def CharSequence AWSDebugUndeploy(Resource resource, String string)
	'''
	#!/bin/bash
	
	docker-compose down				
	docker network rm flynet				
	'''
	
	def CharSequence AzureDeploy(Resource resource, String name, boolean local)
	'''
		#!/bin/bash
		
					
		if [ $# -ne 9 ]
		  then
		    echo "No arguments supplied. ./azure_deploy.sh <app-name> <function-name> <executionId> <clientId> <tenantId> <secret> <subscriptionId>  <storageName> <storageKey>"
		    exit 1
		fi
		
		app=$1
		function=$(echo "$2" | awk '{print tolower($0)}')
		id=$3
		user=$4
		tenant=$5
		secret=$6
		subscription=$7
		storageName=$8
		storageKey=$9
		
		echo "Checking that azure-cli is installed"
		which az
		if [ $? -eq 0 ]; then
		      echo "azure-cli is installed, continuing..."
		else
		      echo "You need azure-cli to deploy this function. Google 'azure-cli install'"
		      exit 1
		fi

		echo "Checking that Azure Function Core Tools is installed"
		which func
		if [ $? -eq 0 ]; then
		      echo "Azure Function Core Tools is installed, continuing..."
		else
		      echo "You need Azure Function Core Tools to deploy this function. Google 'Azure Function Core Tools install'"
		      exit 1
		fi		
		
		az login --service-principal -u ${user} -t ${tenant} -p ${secret}
		
		
		#Local function's local project
		echo "Creating function's local project"
		
		if [ ! -d ${app}${id} ]; then
			func init ${app}${id} --worker-runtime=node --no-source-control -n
			
			cd ${app}${id}
			
			rm -f host.json
			echo '{
			  "version": "2.0",
			  "logging": {
			    "applicationInsights": {
			      "samplingSettings": {
			        "isEnabled": true,
			        "excludedTypes": "Request"
			      }
			    }
			  },
			  "extensionBundle": {
			    "id": "Microsoft.Azure.Functions.ExtensionBundle",
			    "version": "[1.*, 2.0.0)"
			  }
			}' > host.json;
			

			rm -f package.json
			echo '{
				"name": "'${function}'",
			    "version": "1.0.0",
			    "main": "index.js",
			    "dependencies": {
			    	"azure-storage": "2.10.3",
			      	"async": "3.2.0",
				    "axios": "0.19.2",
				    "qs": "6.9.4",
				    "util": "0.12.3",
				    "dataframe-js": "1.4.3",
				    "mysql": "2.18.1",
				    "mongodb": "^3.6.6",
				    "csv": "^5.5.0",
				    "dataframe-js": "^1.4.4"
			  	},
				"devDependencies": {},
				"scripts": {
					"test": "echo \"Error: no test specified\" && exit 1"
				 },
				 "author": "",
				 "license": "ISC"
			}
			' > package.json;
			
		else
			cd ${app}${id}
		fi
		
		echo "Function's local project has been created"
		
		echo "Creating Function's folder and files..."
		
		mkdir ${function}
		cd ${function}
		
		
		echo '{
		  "bindings": [
		    {
		      "authLevel": "admin",
		      "type": "httpTrigger",
		      "direction": "in",
		      "name": "req",
		      "methods": [
		        "get",
		        "post"
		      ]
		    },
		    {
		      "type": "http",
		      "direction": "out",
		      "name": "res"
		    }
		  ]
		}' > function.json
		echo "function.json created"
		
		#Creating function's source file
		
		echo '«generateBodyJs(resource,root.body,root.parameters,name,env)»
				«FOR fd:functionCalled.values()»
					
				«generateJsExpression(fd, name)»
				
				«ENDFOR»
				' > index.js

		echo "index.js created"
		
		echo "Function's files have been created"
		
		#Routine to deploy on Azure
		cd ..
		
		echo "Fetching the function"
		until func azure functionapp fetch-app-settings ${app}${id}
		do
		    echo "Fetch attempt"
		done		
		
		npm install
		
		echo "Deploying the function"
		until func azure functionapp publish ${app}${id} --resource-group flyrg${id} --force -javascript --build-remote
		do
		    echo "Deploy attempt"
		done
		
				
		echo "Function deployed"
		
		az  logout
		
		cd ..
		rm -rf ${app}${id}
	'''
	
	def CharSequence AzureUndeploy(Resource resource, String string, boolean local)
	'''
	
	'''
	
	
	
	def CharSequence compileScriptUndeploy(Resource resource, String name, boolean local){
		switch this.env {
			   case "aws": AWSUndeploy(resource,name)
			   case "aws-debug": AWSDebugUndeploy(resource,name)
			   case "azure": AzureUndeploy(resource,name,local)
			   default: this.env+" not supported"
	  		}
	} 
}