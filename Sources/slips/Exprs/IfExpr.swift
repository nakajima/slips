//
//  IfExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public protocol IfExpr: Expr {
	var condition: any Expr { get }
	var consequence: any Expr { get }
	var alternative: any Expr { get }
}

public struct IfExprSyntax: IfExpr {
	public let condition: any Expr
	public let consequence: any Expr
	public let alternative: any Expr

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: Visitor {
		visitor.visit(self, scope)
	}
}
