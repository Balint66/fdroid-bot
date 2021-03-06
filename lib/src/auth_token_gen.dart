import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'jwt_gen.dart';

class AuthTokenGen {
  final JWTGen _jwtgen;
  final HttpClient _client;
  final String _user;
  final String _repo;
  String _token;
  Timer _timer;
  AuthTokenGen(this._jwtgen, this._client, this._user, this._repo);

  Future<String> produce() async {
    if (_token == null) {
      //Setup the request here for installations
      var request = await _client
          .getUrl(Uri.https('api.github.com', 'app/installations'));
      request.headers.add('Accept', 'application/vnd.github.v3+json');
      request.headers.add('Authorization', 'Bearer ' + _jwtgen.produce());

      //Get the response and get the installation id
      var response = await request.close();
      var bodys = await response
          .transform(Utf8Decoder())
          .fold<String>('', (p, c) => p + c);
      var bodyj = json.decode(bodys);

      List<Map<String, dynamic>> body;

      if (bodyj is List<Map<String, dynamic>>) {
        body.addAll(bodyj);
      } else if (bodyj is Map<String, dynamic>) {
        body = [bodyj];
      } else {
        throw 'THE RESPONSE WAS INVALID! MAYBE THE API CHANGED?';
      }

      //filter for the user
      body.removeWhere((item) =>
          item['account'] == null ||
          item['account']['url'] == null ||
          !(item['account']['url'].toString()).contains(_user));
      if (body.isEmpty) {
        throw 'THERE IS NO ASSOCIATED USER WITH THE ISSUER! MAYBE THE BOT IS NOT INSTALLED?';
      }
      var url = body.first['access_tokens_url'] as String;

      //Now getting the installation token. This expires every hour. (POST must be used!)
      request = await _client.postUrl(Uri.tryParse(url));
      request.headers.add('Accept', 'application/vnd.github.v3+json');
      request.headers.add('Authorization', 'Bearer ${_jwtgen.produce()}');

      //let github do here the filtering
      request.write(json.encode(<String, dynamic>{
        'repositories': <String>[_repo]
      }));

      //Get response for the token
      response = await request.close();
      bodys = await response
          .transform(Utf8Decoder())
          .fold<String>('', (p, c) => p + c);

      //Setup the token and the timer
      bodyj = json.decode(bodys);
      if (!bodyj['repositories'] is List<Map<String, dynamic>> ||
          (bodyj['repositories'] as List<Map<String, dynamic>>).isEmpty) {
        throw 'THE BOT DOES NOT HAVE PERMISSION FOR THE REPOSITORY!';
      }
      _token = bodyj['token'];
      _timer = Timer(Duration(hours: 1), () {
        _token = null;
      });
    }

    //Return the saved token
    return _token;
  }
}
