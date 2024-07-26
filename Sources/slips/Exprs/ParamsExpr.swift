//
//  ParamsExpr.swift
//
//
//  Created by Pat Nakajima on 7/24/24.
//

public protocol ParamsExpr: Expr {
	var names: [String] { get }
}

public struct ParamsExprSyntax: ParamsExpr {
	public var names: [String]

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: Visitor {
		visitor.visit(self, scope)
	}
}
