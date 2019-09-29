import 'dart:io';

class HttpUrl{
  static final List<String> HEX_DIGITS =
  ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'];
  static final String USERNAME_ENCODE_SET = " \"':;<=>@[]^`{}|/\\?#";
  static final String PASSWORD_ENCODE_SET = " \"':;<=>@[]^`{}|/\\?#";
  static final String PATH_SEGMENT_ENCODE_SET = " \"<>^`{}|/\\?#";
  static final String PATH_SEGMENT_ENCODE_SET_URI = "[]";
  static final String QUERY_ENCODE_SET = " \"'<>#";
  static final String QUERY_COMPONENT_REENCODE_SET = " \"'<>#&=";
  static final String QUERY_COMPONENT_ENCODE_SET = " !\"#\$&'(),/:;<=>?@[]\\^`{|}~";
  static final String QUERY_COMPONENT_ENCODE_SET_URI = "\\^`{|}";
  static final String FORM_ENCODE_SET = " \"':;<=>@[]^`{}|/\\?#&!\$(),~";
  static final String FRAGMENT_ENCODE_SET = "";
  static final String FRAGMENT_ENCODE_SET_URI = " \"#<>\\^`{|}";

  /** Either "http" or "https". */
  String scheme;

  /** Decoded username. */
  String username;

  /** Decoded password. */
  String password;

  /** Canonical hostname. */
  String host;

  /** Either 80, 443 or a user-specified port. In range [1..65535]. */
  int port;

  /**
   * A list of canonical path segments. This list always contains at least one element, which may be
   * the empty string. Each segment is formatted with a leading '/', so if path segments were ["a",
   * "b", ""], then the encoded path would be "/a/b/".
   */
  List<String> pathSegments;

  /**
   * Alternating, decoded query names and values, or null for no query. Names may be empty or
   * non-empty, but never null. Values are null if the name has no corresponding '=' separator, or
   * empty, or non-empty.
   */
  List<String> queryNamesAndValues;

  /** Decoded fragment. */
  String fragment;

  /** Canonical URL. */
  String url;

//  HttpUrl(Builder builder) {
//    this.scheme = builder.scheme;
//    this.username = percentDecode(builder.encodedUsername, false);
//    this.password = percentDecode(builder.encodedPassword, false);
//    this.host = builder.host;
//    this.port = builder.effectivePort();
//    this.pathSegments = percentDecode(builder.encodedPathSegments, false);
//    this.queryNamesAndValues = builder.encodedQueryNamesAndValues != null
//        ? percentDecode(builder.encodedQueryNamesAndValues, true)
//        : null;
//    this.fragment = builder.encodedFragment != null
//        ? percentDecode(builder.encodedFragment, false)
//        : null;
//    this.url = builder.toString();
//    IOSink sink = new IOSink(null);
//
//  }



}
