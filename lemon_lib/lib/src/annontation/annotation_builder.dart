import 'package:analyzer/dart/element/element.dart';

class Annotation{
  String method;
  Map paramMap = new Map();
  List<String> pendingParamsMap = new List();
  Map headers = new Map();
  List<String> body = new List();
  MethodElement element;
  List<String> extra = new List();
}