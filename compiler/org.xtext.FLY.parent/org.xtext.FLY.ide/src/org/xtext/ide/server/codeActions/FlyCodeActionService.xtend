package org.xtext.ide.server.codeAction

import java.util.List
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EObject
import org.eclipse.lsp4j.CodeAction
import org.eclipse.lsp4j.CodeActionParams
import org.eclipse.lsp4j.Command
import org.eclipse.lsp4j.Position
import org.eclipse.lsp4j.Range
import org.eclipse.lsp4j.TextEdit
import org.eclipse.lsp4j.WorkspaceEdit
import org.eclipse.lsp4j.jsonrpc.messages.Either
import org.eclipse.xtext.ide.server.Document
import org.eclipse.xtext.ide.server.codeActions.ICodeActionService2
import org.xtext.fLY.Fly

class FlyCodeActionService implements ICodeActionService2 {

		
	override getCodeActions(Options options) {
		var root = options.resource.contents.head
		if (root instanceof Fly)
			createCodeActions(root, options.codeActionParams, options.document)
		 else
		 	emptyList
	}
	
	private def dispatch List<Either<Command, CodeAction>> createCodeActions(Fly fly, CodeActionParams params, Document document) {
		var result = <Either<Command,CodeAction>>newArrayList
		
		return result
	}
	
	private def matchesContext(String kind, CodeActionParams params) {
		if (params.context?.only === null)
			return true
		else 
			return params.context.only.exists[kind.startsWith(it)]
	}
	
	private def String getNewName(String prefix, List<? extends String> siblings) {
		for(var i = 0;; i++) {
			val currentName = prefix + i
			if (!siblings.exists[it == currentName])
				return currentName
		}
	}
		
	private def dispatch List<Either<Command, CodeAction>> createCodeActions(EObject element, CodeActionParams params, Document document) {
		return emptyList 
	}
	
	private def createInsertWorkspaceEdit(URI uri, Position position, String text) {
		new WorkspaceEdit => [
			changes = #{uri.toString -> #[ new TextEdit(new Range(position, position), text) ]}
		]
	}	
	
}