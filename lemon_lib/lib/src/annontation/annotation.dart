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
  const Field(this.name);
}

class Body{
  const Body();
}

class Query{
  final String name;
  const Query(this.name);
}

class QueryMap{
  const QueryMap();
}

class Root{
  const Root();
}

class FormUrlEncoded{
  const FormUrlEncoded();
}

class EXTRA{
  const EXTRA();
}