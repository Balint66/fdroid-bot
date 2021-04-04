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
  final bool verbose;

  GithubAPI._(this.repository, this.user, String issuer, RSAPrivateKey key,
      HttpClient client, this.verbose)
      : _authGen = AuthTokenGen(JWTGen(issuer, key), client, user, repository),
        _client = client;

  factory GithubAPI(
          String repository, String user, String issuer, RSAPrivateKey key,
          {HttpClient client, bool verbose}) =>
      GithubAPI._(repository, user, issuer, key, client ?? HttpClient(), verbose);

  Future<Map<String, dynamic>> fetchLatestRelease(String repository) async {
    if(verbose){
      print('Starting release fetch');
    }
    var request = await _client.getUrl(Uri(
        scheme: 'https',
        host: 'api.github.com',
        path: 'repos/$repository/releases/latest'));
    var response = await request.close();
    var body = await response
        .transform(Utf8Decoder())
        .fold<String>('', (String previousValue, String element) => previousValue + element);
    if(verbose){
      print('Ending release fetch');
    }
    return json.decode(body);
  }

  Future<void> push(GitDir gitDir) async {
    if(verbose){
      print('Starting push');
    }
    var token = await _authGen.produce();
    await gitDir.runCommand(['add', '--all']);
    await gitDir.runCommand(
        ['commit', '-m', 'update at ' + DateTime.now().toIso8601String()]);
    await gitDir.runCommand([
      'push',
      'https://x-access-token:$token@github.com/$user/$repository',
      'master'
    ]);
    if(verbose){
      print('Ending push');
    }
  }

  Future<GitDir> clone(String directory) async {
    if(verbose){
      print('Starting clone');
    }
    var result = await runGit(
        ['clone', 'https://github.com/$user/$repository', directory]);
    if (result.exitCode != 0) {
      print('Unable to clone repository: $repository');
      print(result.stderr);
      throw result.stderr;
    }

    if(verbose){
      print('Ending clone');
    }

    return GitDir.fromExisting(directory);
  }

  Future<List<int>> fetchAttachement(Uri uri) async {
    if(verbose){
      print('Starting attachement fetch');
    }
    var request = await _client.getUrl(uri);
    var response = await request.close();
    var body = await response.fold<List<int>>(<int>[], (List<int> previous, List<int> element) {
      previous.addAll(element);
      return previous;
    });
    if(verbose){
      print('Ending attachement fetch');
    }
    return body;
  }
}
