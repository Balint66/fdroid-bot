import 'dart:convert';
import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'jwt_gen.dart';
import 'package:git/git.dart';

import 'auth_token_gen.dart';

class GithubAPI {
  final _client;
  final AuthTokenGen _authGen;
  final String repository;
  final String user;

  GithubAPI._(this.repository, this.user, String issuer, RSAPrivateKey key,
      HttpClient client)
      : _authGen = AuthTokenGen(JWTGen(issuer, key), client, user, repository),
        _client = client;

  factory GithubAPI(
          String repository, String user, String issuer, RSAPrivateKey key,
          {HttpClient client}) =>
      GithubAPI._(repository, user, issuer, key, client ?? HttpClient());

  Future<Map<String, dynamic>> fetchLatestRelease(String repository) async {
    var request = await _client.getUrl(Uri(
        scheme: 'https',
        host: 'api.github.com',
        path: 'repos/$repository/releases/latest'));
    var response = await request.close();
    var body = await response
        .transform(Utf8Decoder())
        .fold<String>('', (previousValue, element) => previousValue + element);
    return json.decode(body);
  }

  Future<void> push(GitDir gitDir) async {
    var token = await _authGen.produce();
    await gitDir.runCommand(['add', '--all']);
    await gitDir.runCommand(
        ['commit', '-m', 'update at ' + DateTime.now().toIso8601String()]);
    await gitDir.runCommand([
      'push',
      'https://x-access-token:$token@github.com/$user/$repository',
      'master'
    ]);
  }

  Future<GitDir> clone(String directory) async {
    var result = await runGit(
        ['clone', 'https://github.com/$user/$repository', directory]);
    if (result.exitCode != 0) {
      print('Unable to clone repository: $repository');
      print(result.stderr);
      throw result.stderr;
    }

    return GitDir.fromExisting(directory);
  }

  Future<List<int>> fetchAttachement(Uri uri) async {
    var request = await _client.getUrl(uri);
    var response = await request.close();
    var body = await response.fold(<int>[], (List<int> previous, element) {
      previous.addAll(element);
      return previous;
    });
    return body;
  }
}
