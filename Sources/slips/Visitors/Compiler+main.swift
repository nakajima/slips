//
//  Compiler+main.swift
//  Slips
//
//  Created by Pat Nakajima on 7/25/24.
//

import LLVM

extension Compiler {
	// TODO: This could probably go into the LLVM package?
	func main(in builder: LLVM.Builder, body: () -> any LLVM.IRValue) {
		let mainType = LLVM.FunctionType(
			name: "main",
			returnType: .i32,
			parameterTypes: [],
			isVarArg: false
		)

		let environment = LLVM.Function.Environment(name: "main")
		let main = LLVM.Function(type: mainType, environment: environment)

		var retval: (any LLVM.IRValueRef)?

		builder.define(main, parameterNames: [], environment: environment) {
			retval = body() as? LLVM.IRValueRef
		}

		builder.emit(return: .raw(retval!.ref))
	}
}
