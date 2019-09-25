import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:source_gen/source_gen.dart';

class Writer{
  static void writeBegin(StringBuffer buffer,ClassElement element){
     buffer.write(" class ${element.name}Impl extends ${element.name}{\n");
  }


  static void writeImport(StringBuffer buffer,BuildStep buildStep,ClassElement classElement){
    if (buildStep.inputId.path.contains('lib/')) {
      buffer.write(
          "import 'package:${buildStep.inputId.package}/${buildStep.inputId.path.replaceFirst('lib/', '')}';\n");
    } else {
      buffer.write("import '${buildStep.inputId.path}';\n");
    }

    List<ImportElement>  imports = classElement.library.imports;
    for(ImportElement e in imports){
      buffer.write("import '${e.uri}';\n");
    }

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