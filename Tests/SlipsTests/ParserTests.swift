//
//  ParserTests.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import Slips
import Testing

struct ParserTests {
	func parse(_ source: String) -> [Expr] {
		let lexer = Lexer(source)
		var parser = Parser(lexer)
		let result = parser.parse()

		#expect(parser.errors.isEmpty)

		for (token, message) in parser.errors {
			print("Error at \(token): \(message)")
		}

		return result
	}

	@Test("Basic expr") func expr() {
		if let ast = parse("(+ 1 2)")[0] as? CallExpr {
			#expect(type(of: ast) == CallExpr.self)
			#expect(ast.op.lexeme == "+")
		} else {
			print("nope")
		}
	}

	@Test("def expr") func def() {
		let ast = parse("(def sum (+ x y))")[0] as! DefExpr
		#expect(ast.name.lexeme == "sum")
	}

	@Test("multiple statements") func multiple() {
		let ast = parse("""
		(1)
		(2)
		(def sum (+ x y))
		""")[2] as! DefExpr
		#expect(ast.name.lexeme == "sum")
	}

	@Test("if expr") func ifexpr() {
		let ast = parse("""
		(if true 1 2)
		""")[0] as! IfExpr
		#expect(ast.condition.description == "true")
		#expect(ast.consequence.description == "1")
		#expect(ast.alternative.description == "2")
	}

	@Test("func expr") func funcexpr() {
		let ast = parse("""
		(x y in (+ x y))
		""")[0] as! FuncExpr
		#expect(ast.params.description == "x y")
		#expect(ast.description == "(x y in (+ x y))")
	}

	@Test("func expr can find its captured values") func funcCaptures() {
		let ast = parse("""
		(def x (y in (z in (+ y z))))
		(def add (x 1))
		(add 2)
		""")

		let fn = (ast[0] as! DefExpr).value as! FuncExpr

		print("sup")
	}
}
