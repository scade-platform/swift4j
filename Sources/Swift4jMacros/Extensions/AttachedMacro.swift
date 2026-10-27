//
//  AttachedMacro.swift
//  Java
//
//  Created by Grigory Markin on 23.07.26.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

import SwiftSyntaxExtensions

extension AttachedMacro {
  static func booleanArgument(named expectedName: String,
                              in attribute: AttributeSyntax,
                              defaultValue: Bool
  ) throws -> Bool {

    guard case let .argumentList(arguments) = attribute.arguments else {
      return defaultValue
    }

    guard let argument = arguments.first(where: {
      $0.label?.text == expectedName
    }) else {
      return defaultValue
    }

    guard let literal = argument.expression.as(BooleanLiteralExprSyntax.self) else {
      throw JvmMacrosError.message("'\(expectedName)' must be a Boolean literal: true or false", attribute)
    }

    return literal.literal.tokenKind == .keyword(.true)
  }
}
