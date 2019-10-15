import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:lemon_lib/src/annontation/annotation.dart';
import 'package:lemon_lib/src/annontation/write_utils.dart';
import 'package:source_gen/source_gen.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:built_collection/src/list.dart';

final ClassCollection classCollection = new ClassCollection();

class CodeGenerator extends GeneratorForAnnotation<Controller> {
  @override
  generateForAnnotatedElement(Element element, ConstantReader annotation,
      BuildStep buildStep) {

    print("CodeGenerator");

    if(element.kind != ElementKind.CLASS){
      return null;
    }

    ClassElement classElement = element as ClassElement;

    StringBuffer buffer = new StringBuffer();
    Writer.writeImport(buffer,buildStep,classElement);

    final classBuilder = new Class((c) {
      c
        ..name = Writer.getClassName(element)
        ..fields.addAll([
          Writer.getClient()
        ])
        ..types
        ..constructors.addAll([Writer.getConstructor()])
        ..methods.addAll(Writer.parseMethods(element))
        ..implements = ListBuilder([refer(classElement.name)]);
    });

    classCollection.collect(classElement, annotation, buildStep);
    final emitter = new DartEmitter();
    return new DartFormatter().format('${buffer.toString()}\n ${classBuilder.accept(emitter)}');
  }


}

class RequestMapGenerator extends GeneratorForAnnotation<ROOT> {


  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    if(element.kind != ElementKind.CLASS){
      return null;
    }

    StringBuffer buffer = new StringBuffer();
    Writer.writeCollectImport(buffer, classCollection?.importList);

    final classBuilder = new Class((c) {
      c
        ..name = "InterfaceFactoryImpl"
        ..methods.add(Writer.FindRouterMethod(classCollection.routerMap))
        ..types
        ..implements = ListBuilder([refer("InterfaceFactory")]);
    });

    final emitter = new DartEmitter();
    return new DartFormatter().format('${buffer.toString()}\n ${classBuilder.accept(emitter)}');
  }
}


class ClassCollection{
  Map<String, String> routerMap =
  <String, String>{};
  List<String> importList = <String>[];

  void collect(ClassElement element, ConstantReader annotation, BuildStep buildStep){
    if (buildStep.inputId.path.contains('lib/')) {
      importList.add(
          "import 'package:${buildStep.inputId.package}/${buildStep.inputId.path.replaceFirst('lib/', '')}';\n");
      importList.add(
          "import 'package:${buildStep.inputId.package}/${buildStep.inputId.path.replaceFirst('lib/', '').replaceFirst(".dart", ".lemon.dart")}';\n");
    } else {
      importList.add("import '${buildStep.inputId.path}';\n");
      importList.add(
          "import 'package:${buildStep.inputId.path.replaceFirst(".dart", ".lemon.dart")}';\n");
    }

    //加载到路由表中
    routerMap["${element.name}"] = "${Writer.getClassName(element)}";
  }
}

