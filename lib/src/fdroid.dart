import 'dart:io';

class FDroid {
  final bool verb;

  FDroid({this.verb = false});

  Future<void> initRepository(
      {String workingDirectory,
      bool verbose = false,
      bool quite = false}) async {
    if (verb) {
      print('Starting fdroid init');
    }
    var options = ['init'];
    if (verbose) {
      options.add('-v');
    }
    if (quite) {
      options.add('-q');
    }
    var res = await Process.run('fdroid', options,
        workingDirectory: workingDirectory, runInShell: true);

    if (res.exitCode != 0) {
      print('An error happened while we were initalising! Check the logs!');
      print(res.stderr);
      throw res.stderr;
    }
    if (verb) {
      print('Ending fdroid init');
    }
  }

  Future<void> updateRepository(
      {String path,
      bool createMeta = false,
      bool verbose = false,
      bool quite = false,
      bool icons = false,
      bool pretty = false,
      bool clean = false,
      bool deleteUnknown = false,
      bool nosign = false,
      bool renameApks = false,
      bool useDateFromApk = false}) async {
    if (verb) {
      print('Starting fdroid update');
    }
    var options = ['update'];
    if (createMeta) {
      options.add('--create-metadata');
    }
    if (verbose) {
      options.add('--verbose');
    }
    if (quite) {
      options.add('--quit');
    }
    if (icons) {
      options.add('--icons');
    }
    if (pretty) {
      options.add('--pretty');
    }
    if (clean) {
      options.add('--clean');
    }
    if (deleteUnknown) {
      options.add('--delete-unknow');
    }
    if (nosign) {
      options.add('--nosign');
    }
    if (renameApks) {
      options.add('--rename-apks');
    }
    if (useDateFromApk) {
      options.add('--use-date-from-apk');
    }

    var res = await Process.run('fdroid', options,
        workingDirectory: path, runInShell: true);
    if (res.exitCode != 0) {
      print('An error happened while we were upgrading! Check the logs!');
      print(res.stderr);
      throw res.stderr;
    }
    if (verb) {
      print('Ending fdroid update');
    }
  }
}
