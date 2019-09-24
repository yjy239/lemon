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

    StringBuffer buffer = Writer.writeBegin(classElement);

    for(MethodElement method in classElement.methods){

      Writer.writeMethod(buffer, method);

    }

    Writer.writeEnd(buffer);

//      for (MethodElement e in (classElement.methods)) {
//        print("$e \n");
//        print("${e.name}");
//        List<ElementAnnotation> list = e.metadata;
//        for (ElementAnnotation ann in list) {
//          var metaData = ann.computeConstantValue();
//          var type = ann.runtimeType;
//
//          if (metaData?.type?.name == "Get") {
//            String url = metaData.getField("url").toStringValue();
//            print("Get url:${url}");
//          } else if (metaData?.type?.name == "Header") {
//            String url = metaData.getField("url").toStringValue();
//            print("Header url:${url}");
//          }
//        }
//      }
//


    return buffer.toString();
  }


}