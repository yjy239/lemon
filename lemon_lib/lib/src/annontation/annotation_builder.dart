import 'package:analyzer/dart/element/element.dart';

class Annotation{
  Map<String,ParameterElement> paramsElements = new Map();
  String method;
  String methodUrl;
  Map paramMap = new Map();
  Map fieldMap= new Map();
  List<String> pendingParamsMap = new List();
  List<String> pendingFieldMap = new List();
  Map headers = new Map();
  List<String> body = new List();
  MethodElement element;
  List<String> extra = new List();
  Map<String,ParameterElement> paths = new Map();
  bool isFormUrlEncoded = false;

}

class ClassCollection{

}