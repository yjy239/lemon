import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/src/builder/build_step.dart';

import 'package:lemon_lib/src/annontation/annotation_builder.dart';
import 'package:lemon_lib/src/request.dart';


import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:built_collection/src/list.dart';
import 'package:source_gen/source_gen.dart';


class Writer{

  static const String  clientName = "_client";
  static const String get = "GET";
  static const String post = "POST";
  static const String put = "PUT";
  static const String delete = "DELETE";
  static const String head = "HEAD";
  static const String headers = "Headers";
  static const String patch = "PATCH";
  static const String extra = "EXTRA";
  static const String body = "Body";
  static const String path = "Path";
  static String formBodyContentType = "application/x-www-form-urlencoded";

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
          annotation.paramsElements[it.name] = it;

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
    return parseRequest(annotation);
  }


  static TypeChecker typeChecker(Type type) => new TypeChecker.fromRuntime(type);

  static Code parseRequest(Annotation annotation){
    Map paramsMap =  annotation.paramMap;
    Map headers = annotation.headers;
    List<String> bodyList = annotation.body;
    List extras = annotation.extra;
    String method = annotation.method;
    final blocks = <Code>[];
    MethodElement element = annotation.element;
    Map<String,ParameterElement> paths = annotation.paths;
    Map fieldMap = annotation.fieldMap;
    List<String> pendingFieldMap = annotation.pendingFieldMap;


    if((fieldMap?.length>0||pendingFieldMap?.length>0)&&bodyList?.length>0){
      throw Exception("only be set one of @Field/@FieldMap and @Body  on request(${annotation.methodUrl})");
    }


    DartType returnType = element?.returnType;


    //先生成headers,接着生成paramMap，最后生成list按照顺序注入
    blocks.add(literalMap(headers).assignVar("headers").statement);


    if(extras.length > 1){
      throw Exception("extra is only set once on request(${annotation.methodUrl})");
    }

    blocks.add(literalMap(new Map()).assignVar("_data").statement);

    
   if(bodyList.length > 1){
     throw Exception("body is only set once on request(${annotation.methodUrl})");
   }else if(bodyList.length == 1){

     ParameterElement parameterElement = annotation.paramsElements[bodyList[0]];


     if(parameterElement.type.name == "Map"){
       blocks.add(Code("_data.addAll( ${bodyList[0]});"));
     }else{
       throw Exception("@Body can only be set Map type on request(${annotation.methodUrl})");
     }

   }

   blocks.add(literalMap(paramsMap).assignVar("_params").statement);
   blocks.add(literalMap(fieldMap).assignVar("_fieldMap").statement);

    if(!annotation.isFormUrlEncoded&&
        (fieldMap.isNotEmpty||annotation.pendingFieldMap.isNotEmpty)){
      throw Exception("if want to use Field or FieldMap,please add @FormUrlEncoded on request(${annotation.methodUrl})");
    }


    if(annotation.pendingParamsMap.length > 0){
      annotation.pendingParamsMap.forEach((String s){
        blocks.add(Code("_params.addAll($s);"));
      });
    }

    //生成Url
    blocks.add(Code("String baseUrl = ${clientName}.baseUrl;"));
    blocks.add(Code("HttpUrl url = HttpUrl.get(baseUrl);"));
    //获取get中的url
    String url= "${annotation.methodUrl}";
    paths.forEach((key,value){
      url = url.replaceFirst("{${key}}", "\${${value.name}}");
    });


    blocks.add(Code("bool isHttp = \"${url}\".startsWith(\"http\")||\"${url}\".startsWith(\"https\");"));

    blocks.add(Code("url = !isHttp ? url.encodedPath(\"${url}\"):url;"));

    blocks.add(Code("_params.forEach((name,value){\n url.addQueryParameter(name, value);\n});"));




    blocks.add(Code("Request request = new Request().uri(url);"));

    blocks.add(Code("headers..forEach((name,value){\n request.addHeader(name, value);\n});"));

    //生成extra
    blocks.add(Code("DefaultExtra defaultExtra = new DefaultExtra();"));
    if(extras.length == 1){
//      blocks.add(Code("if(${extras[0]} is Extra){\n"
//          "request.extra = ${extras[0]};\n"
//          "}else{\n"));
      if(extras.length > 0){
        extras.forEach((value){
          blocks.add(Code("defaultExtra.extra.add(${value});"));
        });
      }


//      blocks.add(Code("\n}"));

    }

    String contentType;
    if(annotation.isFormUrlEncoded){
      contentType = formBodyContentType;
      blocks.add(Code("_data.addAll(_fieldMap);"));
      if(pendingFieldMap.length > 0){
        pendingFieldMap.forEach((fieldMap){
          blocks.add(Code("_data.addAll(${fieldMap});"));
        });
      }
      blocks.add(Code("defaultExtra.contentType = \"${contentType}\";"));
    }

    blocks.add(Code("request.extra = defaultExtra;"));

    if(method == get){
      blocks.add(Code("request.get();"));
    }else if(method == post){
      blocks.add(Code("request.post(_data);"));
    }else if(method == put){
      blocks.add(Code("request.put(_data);"));
    }else if(method == delete){
      blocks.add(Code("request.delete(_data);"));
    }else if(method == head){
      blocks.add(Code("request.head();"));
    }else if(method == path){
      blocks.add(Code("request.patch(_data);"));
    }

    if(returnType.isDartAsyncFuture){
      blocks.add(Code("return await ${clientName}.newCall(request).enqueueFuture();"));
    }else{
      blocks.add(Code("await ${clientName}.newCall(request).enqueue();"));
    }

    return Block.of(blocks);

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
        annotation.methodUrl = metadata?.getField("url")?.toStringValue();
      }else if(metadata?.type?.name == "Headers"){
        annotation.headers.addAll(metadata?.getField("map")?.toMapValue());
      }else if(metadata?.type?.name == "FormUrlEncoded"){
        annotation.isFormUrlEncoded = true;
      }
    }
    return annotation;
  }

  static Annotation parseMethodParams(Annotation annotation,
      List<ParameterElement> parameterList){

    for(ParameterElement parameterElement in parameterList){
      ElementAnnotation meta = parameterElement?.metadata[0];
      DartObject metadata =meta.computeConstantValue();
      if(metadata?.type?.name == "Query"){
        String query =metadata?.getField("name")?.toStringValue();
        annotation.paramMap["$query"] = "\${${parameterElement.name}}";
      }else if(metadata?.type?.name == "QueryMap"){
        annotation.pendingParamsMap.add("${parameterElement.name}");
      }else if(metadata.type.name == "Field"){
        String field = metadata?.getField("name")?.toStringValue();
        annotation.fieldMap["$field"] = "\${${parameterElement.name}}";
      }else if(metadata.type.name == "FieldMap"){
        annotation.pendingFieldMap.add("${parameterElement.name}");
      }else if(metadata.type.name == body){
        annotation.body.add("${parameterElement.name}");
      }else if(metadata.type.name == extra){
        annotation.extra.add("${parameterElement.name}");
      }else if(metadata.type.name == path){
        String path = metadata?.getField("url")?.toStringValue();
        annotation.paths[path] = parameterElement;
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