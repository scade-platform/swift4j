import SwiftSyntax
import SwiftParser

import SwiftSyntaxExtensions


class ClassGenerator: TypeGenerator<ClassDeclSyntax> {
  private var ctorGens: [CtorGenerator] = []
  private var hasCtors: Bool = false
  private var methodGens: [MethodGenerator] = []


  override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    if node.isExported && node.parentDecl?.isExported ?? true {
      methodGens.append(MethodGenerator(node, className: name))
    }
    return .skipChildren
  }

  override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
    if node.isExported && node.parentDecl?.isExported ?? true {
      ctorGens.append(CtorGenerator(node, className: name))
    }
    hasCtors = true
    return .skipChildren
  }
}


extension ClassGenerator: TypeGeneratorProtocol {
  func generate(with ctx: inout Context) -> String {
    let ctors: String
    if hasCtors {
      ctors = ctorGens.enumerated().map{$1.generate(with: &ctx, index: $0)}.joined(separator: "\n\n")
    } else {
      ctors =
"""
  public \(name)() {
    this(\(name).init());
  }
  private static native long init();
"""
    }

    let std_ctor_dtor: String
    if settings.javaVersion >= 9 {
      std_ctor_dtor =
"""
  private static final Cleaner cleaner = Cleaner.create();

  private static class Deinit implements Runnable {
      private final long _ptr;

      Deinit(long ptr) {
        _ptr = ptr;
      }

      public void run() {
        \(name).deinit(_ptr);
      }
  }

  private \(name)(long ptr) {
     _ptr = ptr;
     cleaner.register(this, new Deinit(_ptr));
  }
"""

    } else {
      std_ctor_dtor =
"""
  private \(name)(long ptr) {
     _ptr = ptr;
  }

  @Override
  public void finalize() {
    \(name).deinit(_ptr);
  }
"""
    }

    var class_init =
"""
  static {
    \((typeDecl.parents.first ?? typeDecl).typeName).class_init();
  }
"""

    if !nested {
      class_init +=
"""

  private static void class_init() {
    if(!class_initialized) {
      \(name)_class_init(\(name).class);
      class_initialized = true;
    }
  }
  private static boolean class_initialized = false;
  private static native void \(name)_class_init(Class<?> cls);
"""
    }

    return
"""
public \(nested ? "static" : "") class \(name) {

\(class_init)

  private final long _ptr;

\(std_ctor_dtor)

  private static native void deinit(long ptr);

\(ctors)

\(methodGens.map{$0.generate(with: &ctx)}.joined(separator: "\n\n"))

\(nestedTypeGens.map{$0.generate(with: &ctx)}.joined(separator: "\n\n"))
}
"""
  }
}
