import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:lemon_lib/src/annontation/annotation.dart';
import 'package:lemon_lib/src/annontation/write_utils.dart';
import 'package:source_gen/source_gen.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:built_collection/src/list.dart';


class CodeGenerator extends GeneratorForAnnotation<Controller> {
  @override
  generateForAnnotatedElement(Element element, ConstantReader annotation,
      BuildStep buildStep) {


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


    final emitter = new DartEmitter();
    return new DartFormatter().format('${buffer.toString()}\n ${classBuilder.accept(emitter)}');
  }


}

class RequestGenerator extends GeneratorForAnnotation<Root> {


  @override
  dynamic generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    return null;
  }
}


class ClassCollection{
  String classes;
}

