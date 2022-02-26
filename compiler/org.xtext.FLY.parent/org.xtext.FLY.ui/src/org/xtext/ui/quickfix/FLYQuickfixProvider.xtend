package org.xtext.ui.quickfix

import org.eclipse.xtext.ui.editor.quickfix.DefaultQuickfixProvider
import org.eclipse.xtext.ui.editor.quickfix.Fix
import org.eclipse.xtext.validation.Issue
import org.eclipse.xtext.ui.editor.quickfix.IssueResolutionAcceptor
import org.xtext.validation.FLYValidationErrors

/**
 * Custom quickfixes.
 *
 * See https://www.eclipse.org/Xtext/documentation/310_eclipse_support.html#quick-fixes
 */
class FLYQuickfixProvider extends DefaultQuickfixProvider {
	
	@Fix(FLYValidationErrors.WRONG_AWS_DECLARATION)
	def correctAWSEnvDeclaration(Issue issue, IssueResolutionAcceptor acceptor) {
		acceptor.accept(issue, 'Declare AWS environment', 'Delcare an AWS environment variable', '') [
			context |
			val expected = "type=\"aws\", profile=\"<profile>\", access_id_key=\"<id>\", secret_access_key=\"<secret>\", region=\"<region>\", language=\"<language>\", nthread=4, memory=256, seconds=1"
			val xtextDocument = context.xtextDocument
			xtextDocument.replace(issue.offset + 1, issue.length - 2, expected)
		]
	}
	
	@Fix(FLYValidationErrors.WRONG_SMP_DECLARATION)
	def correctSMPEnvDeclaration(Issue issue, IssueResolutionAcceptor acceptor) {
		acceptor.accept(issue, 'Declare SMP environment', 'Delcare an SMP environment variable', '') [
			context |
			val expected = "type=\"smp\", nthread=3"
			val xtextDocument = context.xtextDocument
			xtextDocument.replace(issue.offset + 1, issue.length - 2, expected)
		]
	}
	
	@Fix(FLYValidationErrors.WRONG_AZURE_DECLARATION)
	def correctAzureEnvDeclaration(Issue issue, IssueResolutionAcceptor acceptor) {
		acceptor.accept(issue, 'Declare Azure environment', 'Delcare an Azure environment variable', '') [
			context |
			val expected = "type=\"azure\", client_id=\"<client>\", tenant_id=\"<tenant>\", secret_key=\"<secret>\", subscription_id=\"<subscription>\", region=\"<region>\", language=\"<language>\", nthread=3, seconds=1"
			val xtextDocument = context.xtextDocument
			xtextDocument.replace(issue.offset + 1, issue.length - 2, expected)
		]
	}
	
	@Fix(FLYValidationErrors.WARNING_UNCAPITALIZE_ENVIRONMENT)
	def capitalizeEnvironmentVars(Issue issue, IssueResolutionAcceptor acceptor) {
		acceptor.accept(issue, 'Capitalize', 'Capitalize the first letter', '') [
			context |
			val xtextDocument = context.xtextDocument
			var firstLetter = issue.getData().get(0).substring(0, 1)
			xtextDocument.replace(issue.offset, 1, firstLetter.toUpperCase())
		]
	}
	
	@Fix(FLYValidationErrors.CHANNEL_UNNECESSARY_ATTRS)
	def removeUnnecessaryChannelAttributes(Issue issue, IssueResolutionAcceptor acceptor) {
		acceptor.accept(issue, 'Remove unnecessary attributes', 'Remove unnecessary attributes', '') [
			context |
			val xtextDocument = context.xtextDocument
			xtextDocument.replace(issue.offset, issue.length, "[type=\"channel\"]")
		]
	}
	
	@Fix(FLYValidationErrors.CHANNEL_UNNECESSARY_ENVIONMENTS)
	def removeUnnecessaryChannelEnvironments(Issue issue, IssueResolutionAcceptor acceptor) {
		acceptor.accept(issue, 'Remove unnecessary environments', 'Remove unnecessary environments', '') [
			context |
			val xtextDocument = context.xtextDocument
			var env = issue.data.get(0)
			xtextDocument.replace(issue.offset, issue.length, "on " + env)
		]
	}
	
	@Fix(FLYValidationErrors.UNNECESSARY_RANDOM_ATTRIBUTES)
	def removeUnnecessaryRandomAttributes(Issue issue, IssueResolutionAcceptor acceptor) {
		acceptor.accept(issue, 'Remove unnecessary attributes', 'Remove random variable unnecessary attributes', '') [
			context |
			val xtextDocument = context.xtextDocument
			xtextDocument.replace(issue.offset, issue.length, "[type=\"random\"]")
		]
	}
	
	@Fix(FLYValidationErrors.FILE_DECLARATION_ERROR)
	def correctFileDeclaration(Issue issue, IssueResolutionAcceptor acceptor) {
		acceptor.accept(issue, 'Declare File variable', 'Declare a File type variable', '') [
			context |
			val xtextDocument = context.xtextDocument
			xtextDocument.replace(issue.offset, issue.length, "[type=\"file\", path=\"<file_path>\"]")
		]
	}
	
	@Fix(FLYValidationErrors.DATAFRAME_DECLARATION_ERROR)
	def correctDataframeDeclaration(Issue issue, IssueResolutionAcceptor acceptor) {
		acceptor.accept(issue, 'Declare Dataframe variable (1)', 
		'Declare a Dataframe type variable with string source', '') [
			context |
			val xtextDocument = context.xtextDocument
			xtextDocument.replace(issue.offset, issue.length, "[type=\"dataframe\", name=\"<name>\", source=\"<source>\"]")
		]
		
		acceptor.accept(issue, 'Declare Dataframe variable (2)', 
		'Declare a Dataframe type variable with string source and optional attributes', '') [
			context |
			val xtextDocument = context.xtextDocument
			val expected = "[type=\"dataframe\", name=\"<file_path>\", source=\"<source>\", sep=\"<separator>\", header=\"<header>\"]"
			xtextDocument.replace(issue.offset, issue.length, expected)
		]
		acceptor.accept(issue, 'Declare Dataframe variable (3)', 
		'Declare a Dataframe type variable with file source', '') [
			context |
			val xtextDocument = context.xtextDocument
			xtextDocument.replace(issue.offset, issue.length, "[type=\"dataframe\", name=\"<name>\", source=var_name]")
		]
		
		acceptor.accept(issue, 'Declare Dataframe variable (4)', 
		'Declare a Dataframe type variable with file source and optional attributes', '') [
			context |
			val xtextDocument = context.xtextDocument
			val expected = "[type=\"dataframe\", name=\"<file_path>\", source=var_name, query=\"<query>\"]"
			xtextDocument.replace(issue.offset, issue.length, expected)
		]
	}
}
















