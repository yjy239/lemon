import 'package:http_parser/src/media_type.dart';

class Url {
  final String url;
  const Url(this.url);
}

class POST {
  final String url;
  const POST({this.url});
}


class GET {
  final String url;
  const GET({this.url});
}

class PUT{
  final String url;
  const PUT({this.url});
}

class DELETE{
  final String url;
  const DELETE({this.url});
}

class Path{
  final String url;
  const Path(this.url);
}

class Controller{
  const Controller();
}

class Headers{
  final Map<String,dynamic> map;
  const Headers({this.map});
}

class Field{
  final String name;
  final bool encode;
  const Field(this.name,{this.encode = false});
}

class FieldMap{
  final bool encode;
  const FieldMap({this.encode = false});
}

class Body{
  const Body();
}

class Query{
  final String name;
  final bool encode;
  const Query(this.name,{this.encode = false});
}

class QueryMap{
  final bool encode;
  const QueryMap({this.encode = false});
}

class ROOT{
  const ROOT();
}

class FormUrlEncoded{
  const FormUrlEncoded();
}


class Multipart{
  final String name;
  const Multipart(this.name);
}

class EXTRA{
  const EXTRA();
}