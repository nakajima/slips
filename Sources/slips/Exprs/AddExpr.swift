//
//  AddExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public protocol AddExpr: Expr {
	var lhs: any Expr { get }
	var rhs: any Expr { get }
}

public struct AddExprSyntax: AddExpr {
	public let lhs: any Expr
	public let rhs: any Expr

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: Visitor {
		visitor.visit(self, scope)
	}
}
