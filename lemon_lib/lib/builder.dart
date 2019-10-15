import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'src/generator.dart';

Builder codeGenerator(BuilderOptions options)=>
    LibraryBuilder(CodeGenerator(), generatedExtension: '.lemon.dart');

Builder mapGenerator(BuilderOptions options)=>
    LibraryBuilder(RequestMapGenerator(), generatedExtension: '.lemon_invalid.dart');