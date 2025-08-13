import 'dart:convert';
import 'package:crypto/crypto.dart';

String phash(List<int> data) {
  // Placeholder: MD5 as stand-in for perceptual hash
  return md5.convert(data).toString();
}
