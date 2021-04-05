import 'dart:io';

import 'fdroid.dart';
import 'github_api.dart';
import 'package:git/git.dart';

class FDroidRepository {
  final FDroid fDroid;
  final String path;
  final String releaseRepository;
  final GithubAPI api;
  final bool verbose;

  FDroidRepository(this.path, this.releaseRepository, this.api,
      {this.verbose = false})
      : fDroid = FDroid(verb: verbose);

  Future<void> initRepository() async {
    if (verbose) {
      print('Starting init');
    }
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
    if (verbose) {
      print('Ending init');
    }
  }

  Future<bool> getLatestApk() async {
    if (verbose) {
      print('Starting apk download');
    }
    var release = await api.fetchLatestRelease(releaseRepository);
    var asset = release['assets'][0];
    var name = asset['name'];
    var idFile = File('$path/id.tx');
    var id = await idFile.exists() ? await idFile.readAsString() : null;
    var apk = File('$path/repo/$name');
    if (await apk.exists() && id == release['id']) {
      if (verbose) {
        print('error while downloading');
      }
      return false;
    }
    var data =
        await api.fetchAttachement(Uri.parse(asset['browser_download_url']));
    await apk.create();
    await apk.writeAsBytes(data);
    if (!await idFile.exists()) {
      await idFile.create();
    }
    await idFile.writeAsString(release['id'].toString());
    if (verbose) {
      print('Ending apk download');
    }
    return true;
  }

  Future<void> updateRepository() async {
    await fDroid.updateRepository(
        path: path,
        pretty: true,
        useDateFromApk: true,
        verbose: true,
        nosign: true);
  }

  Future<void> pushUpdate() async {
    if (verbose) {
      print('Starting update');
    }
    var gitDir = await GitDir.fromExisting(path);
    await api.push(gitDir);
    if (verbose) {
      print('Ending update');
    }
  }

  Future<void> updateLoop() => Future.doWhile(() async {
        if (verbose) {
          print('loop');
        }
        var downloaded = await getLatestApk();
        if (downloaded) {
          await updateRepository();
          await pushUpdate();
        }
        await Future.delayed(Duration(minutes: 30));
        return true;
      });
}
