//
//  DefExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public protocol DefExpr: Expr {
	var name: Token { get }
	var value: any Expr { get }
}

public struct DefExprSyntax: DefExpr {
	public let name: Token
	public let value: any Expr

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) -> V.Value {
		visitor.visit(self, scope)
	}
}
