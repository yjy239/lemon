import 'package:lemon_lib/lemon.dart';


void main(){
  HttpUrl url  = HttpUrl();
  print("\n${url.scheme("http").build()}\n");
  url.host("www.baidu.com");
  url.encodedPath("/abc/asc");
  url.queryParameters["aa"] = "bb";
  url.fragment("123");
  print("\n${url.build()}\n");

  print("${Uri.encodeComponent("/:#\& +")}\n");

  HttpUrl u = HttpUrl.get("https://www.baidu.com/aaa");

  print("${u.build().scheme}\n");
  print("${u.build().host}\n");
  print("${u.build().pathSegments}\n");


}