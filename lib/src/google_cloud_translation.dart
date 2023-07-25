import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_cloud_translation/src/models/translation_model.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart';

export 'package:google_cloud_translation/src/models/translation_model.dart';

class Translation {
  /// The Google cloud translation token associated with your project.
  /// create it here https://console.cloud.google.com/apis/api/translate.googleapis.com/credentials
  final String _apiKey;

  /// We can inject the client required, useful for testing
  Client http = Client();

  static const String _baseUrl =
      'https://translation.googleapis.com/v3/projects';

  /// Returns the value of the token in google.
  String get apiKey => _apiKey;

  /// If this is not null, any error will be sent to this function, otherwise `debugPrint` will be used.
  final void Function(Object error)? _onError;

  /// Provides an instance of this class.
  /// The instance of the class created with this constructor will send the events on the fly.
  /// Also, if a request returns an error, this will be logged but the text will be lost.
  /// [token] is the token associated with your project.
  /// [onError] is a callback function that will be executed in case there is an error, otherwise `debugPrint` will be used.
  /// [prefsKey] key to use in the SharedPreferences. If you leave it empty a default name will be used.
  Translation({
    required String apiKey,
    void Function(Object)? onError,
  })  : _apiKey = apiKey,
        _onError = onError;

  /// Sends a request to translate.
  /// [text] text to translate.
  /// [to] to what language translate.
  Future<TranslationModel> translate(
      {required List<String> text, required String to}) async {
    return _translateText(text: text, to: to);
  }

  /// Proxies the error to the callback function provided or to standard `debugPrint`.
  void _onErrorHandler(Object? error, String message) {
    final errorCallback = _onError;
    if (errorCallback != null) {
      errorCallback(error ?? message);
    } else {
      debugPrint(message);
    }
  }

  Future<TranslationModel> _translateText(
      {required List<String> text, required String to}) async {
    Map<String, dynamic> requestPayload = {
      'contents': text,
      'targetLanguageCode': to,
    };

    final response = await http.post(
      Uri.parse(
          '$_baseUrl/your_project/locations/global:translateText?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestPayload),
    );

    if (response.statusCode == 200) {
      try {
        final body = json.decode(response.body);
        final translations = body['translations'] as List;

        List<String> translatedTexts = [];
        List<String> detectedSourceLanguages = [];

        for (var item in translations) {
          translatedTexts.add(HtmlUnescape().convert(item['translatedText']));
          detectedSourceLanguages.add(item['detectedSourceLanguage']);
        }

        return TranslationModel(
          translatedTexts: translatedTexts,
          detectedSourceLanguages: detectedSourceLanguages,
        );
      } on Exception catch (e) {
        _onErrorHandler('error parsing answer', e.toString());
        throw Exception();
      }
    } else {
      _onErrorHandler('${response.statusCode}', response.body);
      throw Exception();
    }
  }
}
