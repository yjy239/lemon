import 'dart:io';

import 'package:dio/dio.dart';




class HttpUrl {

  String _scheme;
  String _host;
  int _port;
  List<String> pathSegments = new List();
  Map<String,String> queryParameters = new Map();
  String _fragment;
  String _path;
  String _query;
  String userInfo;

  HttpUrl();

  HttpUrl scheme(String scheme){
    if (scheme == null) {
      throw new FormatException("scheme == null");
    } else if (scheme.toLowerCase() == "http") {
      this._scheme = "http";
    } else if (scheme.toLowerCase() == "https") {
      this._scheme = "https";
    } else {
      throw new FormatException("unexpected scheme: " + scheme);
    }
    return this;
  }


  HttpUrl host(String host) {
    if (host == null) throw new FormatException("host == null");
    this._host = host;
    return this;
  }

  HttpUrl port(int port) {
    if (port <= 0 || port > 65535) {
      throw new FormatException("unexpected port: ${port}" );
    }
    this._port = port;
    return this;
  }


  HttpUrl addPathSegment(String pathSegment) {
    if (pathSegment == null) {
      throw new FormatException("pathSegment == null");
    }
    pathSegments.add(Uri.encodeComponent(pathSegment));
    return this;
  }

  HttpUrl addEncodedPathSegment(String encodedPathSegment) {
    if (encodedPathSegment == null) {
      throw new FormatException("encodedPathSegment == null");
    }
    pathSegments.add(encodedPathSegment);
    return this;
  }


  HttpUrl setPathSegment(int index, String pathSegment) {
    if (pathSegment == null) throw new FormatException("pathSegment == null");
    if (isDot(pathSegment) || isDotDot(pathSegment)) {
      throw new FormatException("unexpected path segment: " + pathSegment);
    }

    pathSegments.replaceRange(index,index+1, [Uri.encodeComponent(pathSegment)]);
    return this;
  }

  HttpUrl setEncodedPathSegment(int index, String encodedPathSegment) {
    if (encodedPathSegment == null) {
      throw new FormatException("encodedPathSegment == null");
    }

    pathSegments.replaceRange(index,index+1, [encodedPathSegment]);
    if (isDot(encodedPathSegment) || isDotDot(encodedPathSegment)) {
      throw new FormatException("unexpected path segment: " + encodedPathSegment);
    }
    return this;
  }


  HttpUrl encodedPath(String encodedPath) {
    if (encodedPath == null) throw new FormatException("encodedPath == null");
    if (!encodedPath.startsWith("/")) {
      throw new FormatException("unexpected encodedPath: " + encodedPath);
    }
    _path = encodedPath;
    return this;
  }



  HttpUrl removePathSegment(int index) {
    pathSegments.remove(index);
    if (pathSegments.isEmpty) {
      pathSegments.add(""); // Always leave at least one '/'.
    }
    return this;
  }

  HttpUrl query(String query) {
    _query ??= Uri.encodeComponent(query);
    return this;
  }

  HttpUrl encodedQuery(String encodedQuery) {
    _query ??= encodedQuery;
    return this;
  }



  HttpUrl addQueryParameter(String name, String value){
    queryParameters[Uri.encodeComponent(name)] = Uri.encodeComponent(value);
    return this;
  }


  HttpUrl addEncodedQueryParameter(String name, String value){
    queryParameters[name] = value;
    return this;
  }

  HttpUrl setQueryParameter(String name, String value) {
    queryParameters[Uri.encodeComponent(name)] = Uri.encodeComponent(value);
    return this;
  }


  HttpUrl setEncodedQueryParameter(String name, String value) {
    queryParameters[Uri.encodeComponent(name)] = Uri.encodeComponent(value);
    return this;
  }

  HttpUrl removeAllQueryParameters(String name) {
    if (name == null) throw new FormatException("name == null");
    queryParameters?.clear();
    return this;
  }


  HttpUrl fragment(String fragment) {
    _fragment ??= Uri.encodeComponent(fragment);
    return this;
  }

  HttpUrl encodedFragment(String encodedFragment) {
    _fragment ??= encodedFragment;
    return this;
  }





  Uri build(){
    return Uri(scheme: _scheme,host: _host,port: _port,
      path: _path,pathSegments: pathSegments,
        query: _query,queryParameters: queryParameters,fragment: _fragment,userInfo: userInfo);
  }

  HttpUrl parse(String input){
    Uri uri = Uri.parse(input);
    _scheme = uri.scheme;
    _host = uri.host;
    _port = uri.port;
    pathSegments = uri.pathSegments;
    _path = uri.path;
    queryParameters = uri.queryParameters;
    _query = uri.query;
    _fragment= uri.fragment;
    userInfo = uri.userInfo;
  }


  static HttpUrl get(String url) {
    return new HttpUrl().parse(url);
  }




  bool isDot(String input) {
    return input == "." || input.toLowerCase() == "%2e";
  }

  bool isDotDot(String input) {
    return input==".."
        || input.toLowerCase() == "%2e."
        || input.toLowerCase() == ".%2e"
        || input.toLowerCase() == "%2e%2e";
  }

}


abstract class Extra{

}

class DefaultExtra extends Extra{
  List<dynamic> extra = new List();
}



class Request{
   HttpUrl _url;
   String _method;
   Headers _headers = new Headers();
   dynamic _body;
   Extra extra;


   Request uri(HttpUrl url) {
     if (url == null) throw new FormatException("url == null");
     this._url = url;
     return this;
   }

   Request transformHttpUrl(String url) {
     if (url == null) throw new FormatException("url == null");
     return uri(HttpUrl.get(url));
   }


   Request transformUriToHttpUrl(Uri url) {
     if (url == null) throw new FormatException("url == null");
     return uri(HttpUrl.get(url.toString()));
   }

   HttpUrl url(){
     return _url;
   }

   dynamic body(){
     return _body;
   }

   String method(){
     return _method;
   }

   Headers header(){
     return _headers;
   }

   Request setHeader(String name, String value){
     _headers.set(name, value);
     return this;
   }

   Request addHeader(String name, String value) {
     _headers.add(name, value);
     return this;
   }

   Request removeHeader(String name) {
     _headers.removeAll(name);
     return this;
   }


   Request setHeaders(Headers headers) {
     this._headers = headers;
     return this;
   }

   Request get() {
     return setMethod("GET", null);
   }

   Request head() {
     return setMethod("HEAD", null);
   }

   Request post(dynamic body) {
     return setMethod("POST", body);
   }

   Request delete(dynamic body) {
     return setMethod("DELETE", body);
   }


   Request put(dynamic body) {
     return setMethod("PUT", body);
   }

   Request patch(dynamic body) {
     return setMethod("PATCH", body);
   }

   Request setMethod(String method, dynamic body) {
     if (method == null) throw new FormatException("method == null");
     if (method.length == 0) throw new FormatException("method.length() == 0");
     if (body != null && !permitsRequestBody(method)) {
       throw new FormatException("method " + method + " must not have a request body.");
     }
     if (body == null && requiresRequestBody(method)) {
       throw new FormatException("method " + method + " must have a request body.");
     }
     this._method = method;
     this._body = body;
     return this;
   }

   static bool permitsRequestBody(String method) {
     return !(method == "GET" || method=="HEAD");
   }

   static bool requiresRequestBody(String method) {
     return method == "POST"
         || method == "PUT"
         || method == "PATCH"
         || method == "PROPPATCH"// WebDAV
         || method =="REPORT";   // CalDAV/CardDAV (defined in WebDAV Versioning)
   }



}