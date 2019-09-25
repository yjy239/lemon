import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:source_gen/source_gen.dart';
import 'package:build/build.dart';

import 'annonation.dart';
import 'write_utils.dart';



class CodeGenerator extends GeneratorForAnnotation<Controller> {
  @override
  generateForAnnotatedElement(Element element, ConstantReader annotation,
      BuildStep buildStep) {
    print(buildStep);

    if(element.kind != ElementKind.CLASS){
      return null;
    }

    ClassElement classElement = element as ClassElement;

    StringBuffer buffer = new StringBuffer();
    Writer.writeImport(buffer,buildStep,classElement);

    Writer.writeBegin(buffer,classElement);

    for(MethodElement method in classElement.methods){

      Writer.writeMethod(buffer, method);

    }

    Writer.writeEnd(buffer);


    return buffer.toString();
  }


}