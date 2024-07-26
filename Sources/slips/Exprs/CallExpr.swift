//
//  CallExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public protocol CallExpr: Expr {
	var op: Token { get }
	var args: [any Expr] { get }
}

public struct CallExprSyntax: CallExpr {
	public let op: Token
	public let args: [Expr]

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) -> V.Value {
		visitor.visit(self, scope)
	}
}
