package org.xtext.validation

class FLYValidationErrors {
	// General Declaration Object
	public static val WARNING_UNCAPITALIZE_ENVIRONMENT = "org.xtext.fly.UncapitalizedEnvironmentWarning"
	public static val INVALID_ON_KEYWORD = "org.xtext.fly.InvalidOnKeyword"
	public static val UNNECESSARY_RANDOM_ATTRIBUTES = "org.xtext.fly.UNNECESSARY_RANDOM_ATTRIBUTES"
	public static val INVALID_FILE_TYPE = "org.xtext.fly.InvalidFileType"
//	public static val FORWARD_REFERENCE = "org.text.fly.ForwardReference";
//	public static val WRONG_TYPE = "org.text.fly.WrongType";
//	public static val WRONG_ATTR = "org.text.fly.WrongAttribute"
//	public static val WRONG_VAL = "org.text.fly.WrongValue"
//	public static val DUPLCIATE_VAL = "org.text.fly.DuplicateValue"
//	public static val WRONG_RETURN = "org.text.fly.WrongReturn"
		
	// SMP Environment
	public static val WRONG_SMP_DECLARATION = "org.xtext.fly.WrongSMPDeclaration"
	public static val MISSING_ATTR = "org.text.fly.MissingAttribute"
	public static val WRONG_ATTR_TYPE = "org.text.fly.WrongAttributeType"
	public static val WRONG_ATTR = "org.text.fly.WrongAttribute"
	
	// AWS Environment
	public static val WRONG_AWS_DECLARATION = "org.xtext.fly.WrongAWSDeclaration"
	public static val UNNECESSARY_AWS_ATTRS = ""
	public static val WRONG_AWS_ATTR = ""
	public static val WRONG_AWS_NUM = ""
	public static val WRONG_AWS_CONC = ""
	public static val WRONG_AWS_MEM = ""
	public static val WRONG_AWS_TIME = ""
	
	// Azure Environment
	public static val WRONG_AZURE_DECLARATION = "org.xtext.fly.WrongAzureDeclaration"
	public static val WRONG_AZURE_NUM = ""
	public static val WRONG_AZURE_CONC = ""
	public static val WRONG_AZURE_TIME = ""
	public static val WRONG_AZURE_ATTR = ""
	public static val UNNECESSARY_AZURE_ATTRS = ""
	
	// Channels
	public static val CHANNEL_DECLARATION_ERROR = "org.xtext.fly.ChannelDeclarationError"
	public static val CHANNEL_UNNECESSARY_ATTRS = "org.xtext.fly.ChannelDeclarationWarning"
	public static val CHANNEL_UNNECESSARY_ENVIONMENTS = "org.xtext.fly.ChannelUnnecessaryEnvironments"
	
	// File
	public static val FILE_DECLARATION_ERROR = "org.xtext.fly.FileDeclarationError"
	public static val FILE_UNNECESSARY_ATTRIBUTES = "org.xtext.fly.FileUnnecessaryAttributes"
	public static val FILE_INVALID_ENVIRONMENT = "org.xtext.fly.FileInvalidEnvironment"
	public static val FILE_INVALID_PATH = "org.xtext.fly.FileInvalidPath"
	public static val FILE_UNNECESSARY_ENVIRONMENT = "org.xtext.fly.FileUnnecessaryEnvironment"
	
	// Dataframes
	public static val DATAFRAME_DECLARATION_ERROR = "org.xtext.fly.DataframeDeclarationError"
	public static val DATAFRAME_EMPTY_SOURCE_QUERY = "org.xtext.fly.DataframeEmptySourceQuery"
	public static val DATAFRAME_UNNECESSARY_ATTRS = "org.xtext.fly.DataframeUnnecessaryAttributes"
	public static val DATAFRAME_INVALID_OPTIONAL_ATTRS = "org.xtext.fly.DataframeInvalidOptionalAttributes"
	public static val DATAFRAME_INVALID_ENVIRONMENT = "org.xtext.fly.DataframeInvalidEnvironment"
	public static val DATAFRAME_UNNECESSARY_ENVIRONMENT = "org.xtext.fly.DataframeUnnecessaryEnvironment"
	
	// Operations
	public static val WRONG_OPERAND_TYPE = "org.xtext.fly.WrongOperandType"
	public static val WRONG_RETURN = "org.xtext.fly.WrongReturn"
	
	// For loop
	public static val WRONG_FOR_OBJECT_DECLARATION = "org.xtext.fly.WrongForObjectDeclaration"

	// Query Declaration
	public static val WRONG_QUERY_ATTRIBUTES = "org.xtext.fly.WrongQueryAttributes"
	public static val WRONG_QUERY_ATTR = "org.xtext.fly.WrongQueryAttr"
	public static val WRONG_QUERY_TYPE = "org.xtext.fly.WrongQueryType"
	
	// SQL Declaration
	public static val WRONG_SQL_DECLARATION = "org.xtext.fly.WrongSqlDeclaration"
}