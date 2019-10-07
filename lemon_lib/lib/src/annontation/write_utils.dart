import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/src/builder/build_step.dart';

import 'package:lemon_lib/src/annontation/annotation_builder.dart';
import 'package:lemon_lib/src/request.dart';


import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:built_collection/src/list.dart';
import 'package:source_gen/source_gen.dart';


class Writer{

  static const String  clientName = "client";
  static const String get = "GET";
  static const String post = "POST";
  static const String put = "PUT";
  static const String delete = "DELETE";
  static const String head = "HEAD";
  static const String headers = "Headers";
  static const String extra = "EXTRA";
  static const String body = "Body";

  static void writeBegin(StringBuffer buffer,ClassElement element){
     buffer.write(" class ${element.name}Impl implement ${element.name}{\n");
  }

  static String getClassName(ClassElement element){
    return """${element.name}Impl""";
  }



  static Field getClient() => Field((m) => m
      ..name= clientName
      ..type = refer("LemonClient","import 'package:lemon_lib/lemon.dart'"));

  static Constructor getConstructor() => Constructor((c) {
    c.requiredParameters.add(Parameter((p) => p
      ..name = clientName
      ..toThis = true));

    final block = [
      Code("this.${clientName} = ${clientName};")
    ];

    c.body = Block.of(block);
  });

  static Iterable<Method> parseMethods(ClassElement element){
    return element.methods.map((MethodElement methodElement){
      Annotation annotation = new Annotation();
      List<ElementAnnotation> methodMetas= methodElement.metadata;
      annotation = parseMethodMetaData(annotation,methodMetas);
      List<ParameterElement> parameterList = methodElement.parameters;
      annotation = parseMethodParams(annotation, parameterList);
      annotation.element = methodElement;



      return annotation;
    }).map((Annotation annotation){
      Method method = new Method((builder){
        builder..name = annotation?.element?.name
            ..modifier = MethodModifier.async
            ..annotations = ListBuilder([CodeExpression(Code('override'))]);

        builder.requiredParameters.addAll(annotation.
        element.parameters.where((params){

          return params.isRequiredPositional || params.isRequiredNamed;
        }).map((it){
          return Parameter((paramsBuilder)=>
          paramsBuilder..name = it.name
          ..named = it.isNamed);
        }));

        builder.optionalParameters.addAll(annotation.
        element.parameters.where((params){

          return params.isOptional ;
        }).map((it){
          return Parameter((paramsBuilder)=>
          paramsBuilder..name = it.name
            ..named = it.isNamed
          ..defaultTo = it.defaultValueCode == null?
          null:Code(it.defaultValueCode));
        }));

        builder.body = getMethod(annotation);
        
      });

      return method;
    });
  }


  static Code getMethod(Annotation annotation){
    String method = annotation.method;
    print("method:${method}");
    return parseRequest(annotation);
//    switch(method){
//      case get:
//
//        break;
//      case post:
//      case put:
//      case delete:
//      case head:
//      return parseRequest(annotation);
//        break;
//
//    }
    return null;
  }

  static TypeChecker _typeChecker(Type type) => new TypeChecker.fromRuntime(type);

  static Code parseRequest(Annotation annotation){
    Map paramsMap =  annotation.paramMap;
    Map headers = annotation.headers;
    List<String> bodys = annotation.body;
    List extras = annotation.extra;
    final blocks = <Code>[];

    //先生成extra,接着生成paramMap，最后生成list按照顺序注入
    if(extras.length > 0){
      blocks.add(Code("DefaultExtra defaultExtra = new DefaultExtra();\n"));

      extras.forEach((value){
        blocks.add(Code("defaultExtra.extra.add(${value});\n"));
      });
    }

    
   if(bodys.length > 1){
     throw Exception("body is only set once");
   }else if(bodys.length == 1){
     blocks.add(Code("var _data = ${bodys[0]};"));
   }

    blocks.add(literalMap(paramsMap).assignVar("params").statement);

    if(annotation.pendingParamsMap.length > 0){
      annotation.pendingParamsMap.forEach((String s){
        blocks.add(Code("params.addAll($s);"));
      });
    }

    //生成Url




    return Block.of(blocks);



  }

  static Code parseBodyRequest(Annotation annotation){

  }

  static String getCurrentImport(BuildStep buildStep,ClassElement classElement){
    if (buildStep.inputId.path.contains('lib/')) {

          return "package:${buildStep.inputId.package}/${buildStep.inputId.path.replaceFirst('lib/', '')}";
    } else {
      return  "${buildStep.inputId.path}";
    }

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

    buffer.write("import 'package:lemon_lib/lemon.dart';\n");

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

    writeMethodBody(buffer,element,parameterList);

  }

  static void writeMethodBody(StringBuffer buffer,MethodElement element,
      List<ParameterElement> parameterList){
    buffer.write("""){\n""");

    List<ElementAnnotation> methodMetas= element.metadata;
    Annotation annotation = new Annotation();
    annotation = parseMethodMetaData(annotation,methodMetas);
    annotation = parseMethodParams(annotation, parameterList);

    writeAnnotation(buffer, annotation);


    buffer.write(""""\n}\n""");
  }

  static writeAnnotation(StringBuffer buffer,Annotation annotation){
    buffer.write("");
  }


  static Annotation parseMethodMetaData(Annotation annotation,
      List<ElementAnnotation> methodMetas){
    for(ElementAnnotation meta in methodMetas){
      DartObject metadata = meta.computeConstantValue();
      if(metadata?.type?.name == "POST"
          ||metadata?.type?.name == "PUT"
          ||metadata?.type?.name == "DELETE"
          ||metadata?.type?.name == "HEAD"
          ||metadata?.type?.name == "GET"){
        annotation.method = metadata?.type?.name;
      }else if(metadata?.type?.name == "Headers"){
        annotation.headers.addAll(metadata?.getField("map")?.toMapValue());
      }
    }
    return annotation;
  }

  static Annotation parseMethodParams(Annotation annotation,
      List<ParameterElement> parameterList){

    for(ParameterElement parameterElement in parameterList){
      ElementAnnotation meta = parameterElement?.metadata[0];
      DartObject metadata =meta.computeConstantValue();
      if(annotation.method =="GET"){
        if(metadata?.type?.name == "Query"){
          String query =metadata?.getField("name")?.toStringValue();
          annotation.paramMap["$query"] = "\${${parameterElement.name}}";
        }else if(metadata?.type?.name == "QueryMap"){
          annotation.pendingParamsMap.add("${parameterElement.name}");
        }
      }else if(annotation.method == "POST"
          ||annotation.method == "PUT"
          ||annotation.method == "DELETE"
          ||annotation.method == "HEAD"){
        if(metadata.type.name == "Field"){
          String field = metadata?.getField("name")?.toStringValue();
          annotation.paramMap["$field"] = "\${${parameterElement.name}}";
        }else if(metadata.type.name == "FieldMap"){
          annotation.pendingParamsMap.add("${parameterElement.name}");
        }else if(metadata.type.name == body){
          annotation.body.add("${parameterElement.name}");
        }
      }

      if(metadata.type.name == extra){
        annotation.extra.add("${parameterElement.name}");
      }

    }


    return annotation;
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