import 'dart:io';
import 'dart:math' as math;

import 'package:downloader_try1/screens/video_player/video_player_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Future<Directory> getAllFiles() async {
    Directory? dir = await getExternalStorageDirectory();

    return dir!;
  }

  String getFileSize(String filepath, int decimals) {
    var file = File(filepath);
    int bytes = file.lengthSync();
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (math.log(bytes) / math.log(1024)).floor();
    return '${(bytes / math.pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Directory>(
          future: getAllFiles(),
          builder: (context, snap) {
            List<FileSystemEntity> filesList = [];

            if (snap.hasData) {
              filesList = snap.data!.listSync();
            }

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
                      ? filesList.isEmpty
                          ? Center(
                              child: Text(
                                'No Files Found!',
                                style:
                                    Theme.of(context).textTheme.headline6,
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: filesList.length,
                              itemBuilder: (context, index) {
                                FileSystemEntity f = filesList[index];

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: const BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                            offset: Offset(0, 4),
                                            color: Colors.black26,
                                            spreadRadius: 0.2,
                                            blurRadius: 10)
                                      ],
                                      color: Colors.white,
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(6))),
                                  child: ExpansionTile(
                                    title: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: InkWell(
                                        onTap: () {
                                          Navigator.of(context).push(
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      VideoPlayerScreen(
                                                          file: File(
                                                              f.path))));
                                        },
                                        child: Container(
                                          height: 56,
                                          width: 56,
                                          decoration: const BoxDecoration(
                                              color: Colors.black12,
                                              borderRadius:
                                                  BorderRadius.all(
                                                      Radius.circular(3))),
                                          child: Center(
                                            child: Icon(
                                              Icons
                                                  .video_collection_outlined,
                                              color: Colors.amber[800],
                                            ),
                                          ),
                                        ),
                                      ),
                                      title: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 6),
                                        child: Text(
                                          path.basename(f.path),
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle2,
                                        ),
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceBetween,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                DateFormat(
                                                        'dd MMM yyyy, h:m a')
                                                    .format(File(f.path)
                                                        .lastModifiedSync()),
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .caption,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 5,
                                            ),
                                            Text(
                                              getFileSize(f.path, 2),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .caption,
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          IconButton(
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) =>
                                                      AlertDialog(
                                                    title: const Text(
                                                        'Are you sure want to delete this file?'),
                                                    content: Text(
                                                      path.basename(f.path),
                                                      style:
                                                          Theme.of(context)
                                                              .textTheme
                                                              .caption,
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          child: const Text(
                                                              'No')),
                                                      TextButton(
                                                          onPressed: () {
                                                            f.deleteSync();
                                                            setState(() {});
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          child: const Text(
                                                              'Yes')),
                                                    ],
                                                  ),
                                                );
                                              },
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              )),
                                          IconButton(
                                              onPressed: () {
                                                showDialog(
                                                    context: context,
                                                    builder: (context) {
                                                      TextEditingController
                                                          fileNameController =
                                                          TextEditingController();

                                                      fileNameController
                                                              .text =
                                                          path
                                                              .basename(
                                                                  f.path)
                                                              .replaceAll(
                                                                  '.mp4',
                                                                  '');

                                                      return AlertDialog(
                                                        title: const Text(
                                                            'Rename File'),
                                                        content: TextField(
                                                          controller:
                                                              fileNameController,
                                                          decoration: const InputDecoration(
                                                              focusedBorder:
                                                                  OutlineInputBorder(),
                                                              enabledBorder:
                                                                  OutlineInputBorder(),
                                                              hintText:
                                                                  'Enter Name'),
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                              onPressed:
                                                                  () {
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                              },
                                                              child: const Text(
                                                                  'Cancel')),
                                                          TextButton(
                                                              onPressed:
                                                                  () {
                                                                f.renameSync(
                                                                    '${f.parent.path}/${fileNameController.text}.mp4');
                                                                setState(
                                                                    () {});
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                              },
                                                              child: const Text(
                                                                  'Rename')),
                                                        ],
                                                      );
                                                    });
                                              },
                                              icon: const Icon(
                                                Icons
                                                    .drive_file_rename_outline,
                                                color:
                                                    Colors.lightBlueAccent,
                                              )),
                                          IconButton(
                                              onPressed: () {
                                                Share.shareFiles([f.path],
                                                    text:
                                                        'Downloaded from YouTube using Gautham\'s Downloader App');
                                              },
                                              icon: const Icon(
                                                Icons.share_outlined,
                                                color: Colors.green,
                                              )),
                                        ],
                                      )
                                    ],
                                  ),
                                );
                              })
                      : const Center(
                          child: CircularProgressIndicator(),
                        ),
            );
          }),
    );
  }
}
