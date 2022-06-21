import 'dart:developer';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class DownloaderScreen extends StatefulWidget {
  const DownloaderScreen({Key? key}) : super(key: key);

  @override
  State<DownloaderScreen> createState() => _DownloaderScreenState();
}

class _DownloaderScreenState extends State<DownloaderScreen> {
  TextEditingController urlController = TextEditingController();

  // List<int> _2160p = [401];
  // List<int> _1440p = [400];
  // List<int> _1080p = [137, 399];
  // List<int> _720p = [136, 398];
  // List<int> _480p = [135, 397];
  // List<int> _360p = [134, 396];
  // List<int> _240p = [133, 395];
  // List<int> _144p = [160, 394];

  final List<int> _audioTags = [139, 140];

  int _vQuality = 397;

  static const platform = MethodChannel('a.gautham/getUri');

  int dProgress = 0;

  ProgressDialog? pr;

  var yt = YoutubeExplode();

  Future<String> getCachePath() async {
    var p = await getExternalCacheDirectories();

    if (p == null) {
      var d = await getExternalStorageDirectory();
      return d!.path;
    }

    return p.first.path;
  }

  Future<String> getFilesPath() async {
    var d = await getExternalStorageDirectory();
    return d!.path;
  }

  Future<String> getFileName(String videoId, String subType) async {
    // Get video metadata.
    var videoFile = await yt.videos.get(videoId);

    // Compose the file name removing the not-allowed characters.
    return '${videoFile.title}.$subType'
        .replaceAll(r'\', '')
        .replaceAll('/', '')
        .replaceAll('*', '')
        .replaceAll('?', '')
        .replaceAll('"', '')
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('|', '')
        .replaceAll('  ', ' ');
  }

  Future convertAudio(File file) async {
    log('Converting Audio');

    String? audioInPath = await FFmpegKitConfig.getSafParameterForRead(
        await platform.invokeMethod('getFileUri', {"path": file.path}));

    DateTime dateTime = DateTime.now();

    File oFile = File(
        '${await getCachePath()}/Converted_Audio_${dateTime.millisecondsSinceEpoch}.mp3');

    String? audioOutPath = await FFmpegKitConfig.getSafParameterForWrite(
        await platform.invokeMethod('getFileUri', {"path": oFile.path}));

    await FFmpegKit.execute(
            '-i $audioInPath -vn -ac 2 -ar 44100 -ab 320k -f mp3 $audioOutPath')
        .then((session) async {
      final state = await session.getState();
      final startTime = session.getStartTime();
      final endTime = await session.getEndTime();
      final duration = await session.getDuration();

      log('$state\n$startTime\n$endTime\n$duration');

      session.getAllLogs().then((value) {
        for (var v in value) {
          log(v.getMessage());
        }
        return null;
      });
    });

    pr!.update(value: 50);

    return oFile;
  }

  Future<File> downloadVideo() async {
    log('Downloading Video...');
    String id = _getYoutubeVideoIdByURL() ?? 'Dpp1sIL1m5Q';

    // Get the video manifest.
    var manifest = await yt.videos.streamsClient.getManifest(id);
    var streams = manifest.videoOnly;

    var videoF = streams.last;

    for (var s in streams) {
      if (s.codec.mimeType == 'video/mp4' && s.tag == _vQuality) {
        videoF = s;
      }
    }

    var audioStream = yt.videos.streamsClient.get(videoF);

    String fileName = await getFileName(id, videoF.container.name);

    String cPath = await getCachePath();
    var file = File('$cPath/Video_Only_$fileName');
    log('File Name: ${path.basename(file.path)}');

    // Delete the file if exists.
    if (file.existsSync()) {
      file.deleteSync();
    }

    // Open the file in writeAppend.
    var fileStream = file.openWrite(mode: FileMode.writeOnlyAppend);

    // Track the file download status.
    var len = videoF.size.totalBytes;
    var count = 0;

    await for (final data in audioStream) {
      // Keep track of the current downloaded data.
      count += data.length;

      // Calculate the current progress.
      var progress = ((count / len) * 100).ceil();

      pr!.update(value: 50 + (progress ~/ 4));

      // Write to file.
      fileStream.add(data);
    }
    await fileStream.close();

    log('COMPLETED::');
    return file;
  }

  Future<File> downloadAudio() async {
    log('Downloading Audio...');
    String id = _getYoutubeVideoIdByURL() ?? 'Dpp1sIL1m5Q';

    // Get the video manifest.
    var manifest = await yt.videos.streamsClient.getManifest(id);
    var streams = manifest.audioOnly;

    var audio = streams.first;

    for (var s in streams) {
      if (s.codec.subtype == 'mp4') {
        if (s.tag == _audioTags.last) {
          audio = s;
        } else {
          audio = s;
        }
      }
    }

    var audioStream = yt.videos.streamsClient.get(audio);

    String fileName = await getFileName(id, audio.container.name);

    String cPath = await getCachePath();
    var file = File('$cPath/Audio_Only_$fileName');
    log('Audio File Name: ${path.basename(file.path)}');

    // Delete the file if exists.
    if (file.existsSync()) {
      file.deleteSync();
    }

    // Open the file in writeAppend.
    var fileStream = file.openWrite(mode: FileMode.writeOnlyAppend);

    // Track the file download status.
    var len = audio.size.totalBytes;
    var count = 0;

    await for (final data in audioStream) {
      // Keep track of the current downloaded data.
      count += data.length;

      // Calculate the current progress.
      int progress = ((count / len) * 100).ceil();

      pr!.update(value: progress ~/ 4);

      // Write to file.
      fileStream.add(data);
    }

    // Close the file.
    await fileStream.close();

    log('COMPLETED::');
    return file;
  }

  void download() async {
    String videoId = _getYoutubeVideoIdByURL() ?? 'Dpp1sIL1m5Q';

    pr = ProgressDialog(context: context);
    pr!.show(
      max: 100,
      msg: 'Downloading...',
      progressType: ProgressType.normal,
    );

    String n = await getFileName(videoId, 'mp4');

    pr!.update(value: 0, msg: 'Downloading $n');

    File aFile = await downloadAudio();
    File aConvertedFile = await convertAudio(aFile);

    File vFile = await downloadVideo();

    log('Mux Started...');

    String outPath = await getFilesPath();

    String? audioInPath = await FFmpegKitConfig.getSafParameterForRead(
        await platform
            .invokeMethod('getFileUri', {"path": aConvertedFile.path}));
    String? videoInPath = await FFmpegKitConfig.getSafParameterForRead(
        await platform.invokeMethod('getFileUri', {"path": vFile.path}));

    File oFile = File('$outPath/$n');

    log('OutFile Path: $oFile');
    if (oFile.existsSync()) {
      oFile.deleteSync();
    }

    // String? audioOutPath = await FFmpegKitConfig.getSafParameterForWrite('$outPath/${basename(aPath)}');
    String? videoOutPath = await FFmpegKitConfig.getSafParameterForWrite(
        await platform.invokeMethod('getFileUri', {"path": oFile.path}));

    pr!.update(value: 90, msg: 'Converting!');

    await FFmpegKit.execute(
            '-i $videoInPath -i $audioInPath -c:v copy -c:a aac $videoOutPath')
        .then((session) async {
      final state = await session.getState();
      final startTime = session.getStartTime();
      final endTime = await session.getEndTime();
      final duration = await session.getDuration();

      log('$state\n$startTime\n$endTime\n$duration');

      session.getAllLogs().then((value) {
        for (var v in value) {
          log(v.getMessage());
        }
        return null;
      });
    });

    // Cleanup Cache
    var cDir = await getExternalCacheDirectories();
    if (cDir!.first.existsSync()) {
      pr!.update(value: 99);
      await cDir.first.list().forEach((element) {
        if (element.existsSync()) {
          element.deleteSync();
        }
      });
    }

    if (pr!.isOpen()) {
      pr!.close();
    }
  }

  String? _getYoutubeVideoIdByURL() {
    return YoutubePlayer.convertUrlToId(urlController.text);
  }

  void getVideoQuality() async {
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12))),
        builder: (context) => StatefulBuilder(builder: (context, state) {
              return FutureBuilder<List>(
                  future: getVideoDetails(),
                  builder: (context, snap) {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: snap.hasError
                          ? Center(
                              child: Text(
                                'Something went wrong!\nPlease Check Logs',
                                style: Theme.of(context).textTheme.headline6,
                              ),
                            )
                          : snap.hasData
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  decoration: const BoxDecoration(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(12))),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(
                                        height: 20,
                                      ),
                                      Center(
                                        child: Container(
                                          height: 5,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              5,
                                          decoration: const BoxDecoration(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(50)),
                                              color: Colors.lightBlue),
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 40,
                                      ),
                                      Text(
                                        snap.data![0].toString(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle1,
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      FutureBuilder(
                                          builder: (context, snapshot) {
                                        return GridView.count(
                                          crossAxisCount: 3,
                                          childAspectRatio: 2,
                                          shrinkWrap: true,
                                          children: (snap.data![1]
                                                  as List<Map<String, dynamic>>)
                                              .map((Map<String, dynamic> e) =>
                                                  Container(
                                                    margin: const EdgeInsets
                                                            .symmetric(
                                                        horizontal: 6,
                                                        vertical: 4),
                                                    decoration:
                                                        const BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius.all(
                                                                    Radius
                                                                        .circular(
                                                                            6)),
                                                            color: Colors
                                                                .lightBlue),
                                                    child: InkWell(
                                                      onTap: () {
                                                        _vQuality = e['tag'];
                                                        Navigator.of(context)
                                                            .pop();
                                                        download();
                                                      },
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            '${e['quality']}',
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .subtitle2!
                                                                .copyWith(
                                                                    color: Colors
                                                                        .white),
                                                          ),
                                                          const SizedBox(
                                                            height: 5,
                                                          ),
                                                          Text(
                                                            '~(${(e['size'] as FileSize).totalMegaBytes.toStringAsFixed(2)} Mb)',
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .caption!
                                                                .copyWith(
                                                                    color: Colors
                                                                        .white),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ))
                                              .toList(),
                                        );
                                      }),
                                      const SizedBox(
                                        height: 40,
                                      ),
                                    ],
                                  ))
                              : const Center(
                                  child: CircularProgressIndicator(),
                                ),
                    );
                  });
            }));

    // print(availableQuality);
  }

  Future<List> getVideoDetails() async {
    // Get the video manifest.

    String id = _getYoutubeVideoIdByURL() ?? 'Dpp1sIL1m5Q';

    List<Map<String, dynamic>> availableQuality = [];

    // Get the video manifest.
    var manifest = await yt.videos.streamsClient.getManifest(id);
    var streams = manifest.videoOnly;

    var tempForVideoName = streams.first;

    for (var s in streams) {
      if (s.codec.subtype == 'mp4') {
        tempForVideoName = s;

        // print(s);
        // print(s.qualityLabel);

        bool c = false;
        for (var element in availableQuality) {
          c = false;
          if (element['quality'] == s.qualityLabel) {
            c = true;
            break;
          }
        }

        if (!c) {
          availableQuality
              .add({'quality': s.qualityLabel, 'size': s.size, 'tag': s.tag});
        }
      }
    }

    String f = await getFileName(id, tempForVideoName.container.name);

    return [f, availableQuality];
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  hintText: 'Enter Url',
                  focusedBorder: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                  onPressed: () {
                    getVideoQuality();
                  },
                  child: const Text('Download')),
            ],
          ),
        ),
      ),
    );
  }
}
