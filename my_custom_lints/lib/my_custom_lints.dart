import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

PluginBase createPlugin() => MyCustomLints();

class MyCustomLints extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [MyLintRule()];
}

class MyLintRule extends DartLintRule {
  MyLintRule() : super(code: _code);

  static const _code = LintCode(
      name: 'file_name_must_represent_class_name',
      problemMessage: 'File Name must be same as Class Name.',
      errorSeverity: ErrorSeverity.INFO,
      correctionMessage: 'Please name the class name as per the file name.');

  @override
  void run(CustomLintResolver resolver, ErrorReporter reporter, CustomLintContext context) async {
    final unit = await resolver.getResolvedUnitResult();

    final classes = unit.libraryElement.topLevelElements.toList();
    final fileNames = unit.libraryElement.librarySource.shortName;
    for (int i = 0; i < classes.length; i++) {
      String newString = fileNames.replaceAll(RegExp(r'\.dart$'), '');
      String fileName = newString.replaceAll(RegExp('_'), '');

      context.registry.addClassDeclaration((node) {
        if (node.declaredElement?.name != fileName) {
          reporter.reportErrorForOffset(_code, node.name.offset, node.name.length);
        }
      });

      context.registry.addConstructorReference((node) {
        if (node.constructorName != fileName) {
          reporter.reportErrorForOffset(_code, node.constructorName.offset, node.constructorName.length);
          // reporter.reportErrorForElement(_code, node.constructorN)
        }
      });
    }
  }

  @override
  List<Fix> getFixes() {
    return [ClassNameFix()];
  }
}

class ClassNameFix extends DartFix {
  @override
  void run(CustomLintResolver resolver, ChangeReporter reporter, CustomLintContext context, AnalysisError analysisError,
      List<AnalysisError> others) {
    context.registry.addClassDeclaration((node) {
      // if (!analysisError.sourceRange.intersects(node.name.sourceRange)) return;

      // We define one edit, giving it a message which will show-up in the IDE.
      final changeBuilder = reporter.createChangeBuilder(
        message: 'Make class name as per file name',
        // This represents how high-low should this quick-fix show-up in the list
        // of quick-fixes.
        priority: 1,
      );

      changeBuilder.addDartFileEdit((builder) {
        var fileNames = analysisError.source.shortName;
        String newString = fileNames.replaceAll(RegExp(r'\.dart$'), '');
        final list = newString.split('_');

        print("list.first ${list.first}");
        String fixName = (list[0][0].toUpperCase()) + list[0].substring(1) + list[1][0].toUpperCase() + list[1].substring(1);

        print('unit name ${node.name.sourceRange}');
        builder.addSimpleReplacement(analysisError.sourceRange, fixName);
        // }
      });
    });

    context.registry.addClassDeclaration((node) {
      // We define one edit, giving it a message which will show-up in the IDE.
      final changeBuilder = reporter.createChangeBuilder(
        message: 'This is message which will show up in Quick-Fix IDE Dialog',
        // This represents how high-low should this quick-fix show-up in the list
        // of quick-fixes.
        priority: 1,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleReplacement(analysisError.sourceRange, 'Your Fix');
        // }
      });
    });
  }
}
