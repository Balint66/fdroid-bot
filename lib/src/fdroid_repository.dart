import 'dart:io';

import 'package:frdiod_server_bot/frdiod_server_bot.dart';
import 'package:git/git.dart';

class FDroidRepository {
  final FDroid fDroid = FDroid();
  final String path;
  final String releaseRepository;
  final GithubAPI api;

  FDroidRepository(this.path, this.releaseRepository, this.api);

  Future<void> initRepository() async {
    var repoDirectory = Directory('$path/repo');
    var indexXML = File('$path/index.xml');
    if (!(await indexXML.exists()) && !(await repoDirectory.exists())) {
      if (await GitDir.isGitDir(path)) {
        var gitDir = await GitDir.fromExisting(path);
        await gitDir.runCommand(['pull']);
      } else {
        await api.clone(path);
      }
    }
  }

  Future<bool> getLatestApk() async {
    var release = await api.fetchLatestRelease(releaseRepository);
    var asset = release['assets'][0];
    var name = asset['name'];
    var idFile = File('$path/id.tx');
    var id = await idFile.exists() ? await idFile.readAsString() : null;
    var apk = File('$path/repo/$name');
    if (await apk.exists() && id == release['id']) {
      return false;
    }
    var data =
        await api.fetchAttachement(Uri.parse(asset['browser_download_url']));
    await apk.writeAsBytes(data);
    await idFile.writeAsString(release['id']);
    return true;
  }

  Future<void> updateRepository() async {
    await fDroid.updateRepository(
        path: path, pretty: true, useDateFromApk: true, verbose: true);
  }

  Future<void> pushUpdate() async {
    var gitDir = await GitDir.fromExisting(path);
    await api.push(gitDir);
  }

  Future<void> updateLoop() => Future.doWhile(() async {
        await Future.delayed(Duration(minutes: 30));
        var downloaded = await getLatestApk();
        if (downloaded) {
          await updateRepository();
          await pushUpdate();
        }

        return true;
      });
}
