import 'dart:io';

import 'http_url.dart';


class Extra{

}


class Request{
   Uri url;
   String method;
   HttpHeaders headers;
   dynamic body;
   Extra extra;

}