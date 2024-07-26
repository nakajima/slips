//
//  Compiler.swift
//
//
//  Created by Pat Nakajima on 7/24/24.
//

import LLVM

public struct Compiler: Visitor {
	public class Context {
		var counter: Int = 0
		var environment: LLVM.Function.Environment = .init(name: "main")

		init(counter: Int = 0, environment: LLVM.Function.Environment = .init(name: "main")) {
			self.counter = counter
			self.environment = environment
		}

		func newEnvironment(for name: String, withBuilder builder: LLVM.Builder) -> Context {
			Context(
				counter: counter,
				environment: LLVM.Function.Environment(builder: builder, name: name, parent: environment)
			)
		}

		func nextCount() -> Int {
			counter += 1
			return counter
		}
	}

	let source: String
	let module: LLVM.Module
	let builder: LLVM.Builder

	public init(_ source: String) {
		self.source = source
		self.module = LLVM.Module(name: "main", in: .global)
		self.builder = LLVM.Builder(module: module)
	}

	public func run() -> Slips.Value {
		let lexer = Lexer(source)
		var parser = Parser(lexer)
		let parsed = parser.parse()

		let context = Context().newEnvironment(for: "main", withBuilder: builder)

		main(in: builder) {
			var lastReturn: (any LLVM.IR)?

			for expr in parsed {
				lastReturn = expr.accept(self, context)
			}

			if let lastReturnPointer = lastReturn as? any LLVM.StoredPointer {
				return builder.load(pointer: lastReturnPointer)
			}

			return lastReturn as! any LLVM.IRValue
		}

		if let int = LLVM.JIT().execute(module: module) {
			return .int(int)
		} else {
			return .error("Nope.")
		}
	}

	public func visit(_ expr: CallExpr, _ context: Context) -> any LLVM.EmittedValue {
		if case let .defined(functionPointer) = context.environment.get(expr.op.lexeme) {
			return builder.call(functionPointer, with: expr.args.map { $0.accept(self, context) }, in: context.environment)
		} else if expr.op.lexeme == "call" {
			// Get the callable thing
			let callable = expr.args[0]
			let emittedCallable = callable.accept(self, context) as! LLVM.EmittedFunctionValue

			let args = expr.args[1 ..< expr.args.count]
			return builder.call(emittedCallable, with: args.map { $0.accept(self, context) }, in: context.environment)
		} else {
			builder.dump()
			fatalError("No support for calling anonmous functions yet")
		}
	}

	public func visit(_ expr: DefExpr, _ context: Context) -> any LLVM.EmittedValue {
		let value = expr.expr.accept(self, context)

		switch value {
		case let value as LLVM.EmittedIntValue:
			let stackValue = builder.store(stackValue: value, name: expr.name.lexeme)
			context.environment.define(expr.name.lexeme, as: stackValue)
		case let value as LLVM.EmittedFunctionValue:
			let stackValue = builder.store(stackValue: value, name: expr.name.lexeme)
			context.environment.define(expr.name.lexeme, as: stackValue)
		default:
			fatalError()
		}

		return value
	}

	public func visit(_ expr: ErrorExpr, _: Context) -> any LLVM.EmittedValue {
		fatalError(expr.message)
	}

	public func visit(_ expr: LiteralExpr, _: Context) -> any LLVM.EmittedValue {
		switch expr.value {
		case let .int(int):
			builder.emit(constant: LLVM.IntType.i8.constant(int))
		case let .bool(bool):
			builder.emit(constant: LLVM.IntType.i1.constant(bool ? 1 : 0))
		default:
			fatalError()
		}
	}

	public func visit(_ expr: VarExpr, _ context: Context) -> any LLVM.EmittedValue {
		if let binding = context.environment.get(expr.name) {
			switch binding {
			case let .defined(pointer):
				return builder.load(pointer: pointer)
			case let .parameter(value):
				return value
			case let .capture(index, type):
				// If it's a capture, then we need to look up the value from the environment
				// that gets passed in at call time
				return builder.loadCapture(expr.name, at: index, as: type, environmentName: context.environment.name)
			}

		} else {
			fatalError("undefined variable: \(expr.name)")
		}
	}

	public func visit(_ expr: AddExpr, _ context: Context) -> any LLVM.EmittedValue {
		let lhs = expr.lhs.accept(self, context) as! LLVM.EmittedIntValue
		let rhs = expr.rhs.accept(self, context) as! LLVM.EmittedIntValue

		return builder.binaryOperation(
			.add,
			lhs,
			rhs
		)
	}

	public func visit(_ expr: IfExpr, _ context: Context) -> any LLVM.EmittedValue {
		builder.branch {
			expr.condition.accept(self, context)
		} consequence: {
			expr.consequence.accept(self, context)
		} alternative: {
			expr.alternative.accept(self, context)
		}
	}

	public func visit(_ expr: FuncExpr, _ context: Context) -> any LLVM.EmittedValue {
		let name = expr.name
		let params = expr.params.names.map { _ in LLVM.IntType.i32 }
		let context = context.newEnvironment(for: name, withBuilder: builder)

		let functionType = LLVM.FunctionType(
			name: name,
			returnType: getTypeOf(expr: expr.body.last!, context: context),
			parameterTypes: params,
			isVarArg: false
		)

		let function = LLVM.Function(type: functionType, environment: context.environment)

		return builder.define(function, parameterNames: expr.params.names, environment: context.environment) {
			var lastReturn: (any LLVM.EmittedValue)?
			for expr in expr.body {
				lastReturn = expr.accept(self, context)
			}

			if let lastReturn {
				builder.emit(return: lastReturn)
			} else {
				builder.emitVoidReturn()
			}

		}
	}

	public func visit(_: ParamsExpr, _: Context) -> any LLVM.EmittedValue {
		fatalError()
	}
}
