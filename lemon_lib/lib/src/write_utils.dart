import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:source_gen/source_gen.dart';

class Writer{
  static StringBuffer writeBegin(ClassElement element){
    return new StringBuffer(""" class ${element.name}Impl{ """);
  }

  static void writeMethod(StringBuffer buffer,MethodElement element){
    if(element == null){
      return;
    }
    var returnType = element.returnType;
    var methodName = element.name;
    buffer.write("${returnType} ${methodName}(");

    List<ParameterElement> parameterList= element.parameters;
    for(int i = 0;i< parameterList.length;i++){
      ParameterElement parameterElement = parameterList[i];
      writeParameters(buffer, parameterElement,(i == parameterList.length - 1));
    }

    buffer.write("){}");
  }

  static void writeParameters(StringBuffer buffer,ParameterElement parameterElement,bool isEnd){
    var type = parameterElement.type;
    var name = parameterElement.name;
    if(!isEnd){
      buffer.write("""${type} ${name},""");
    }else{
      buffer.write("""${type} ${name}""");
    }
  }



  static void writeEnd(StringBuffer buffer){
    buffer.write("""\n}""");
  }

}