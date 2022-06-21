import 'dart:developer';

import 'package:downloader_try1/screens/downloader/downloader_screen.dart';
import 'package:downloader_try1/screens/history/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'G-Downloader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Home(),
    );
  }
}

enum Menu { share, contact, update }

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  late AnimationController controller;
  late Animation<Offset> offset;

  static const List<Widget> _widgetOptions = <Widget>[
    DownloaderScreen(),
    HistoryScreen()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();

    controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));

    offset = Tween<Offset>(begin: Offset.zero, end: const Offset(0.0, 1.0))
        .animate(controller);

    controller.forward();

    controller.addStatusListener((status) {
      switch (controller.status) {
        case AnimationStatus.completed:
          Future.delayed(const Duration(milliseconds: 500), () {
            controller.reverse();
          });
          break;
        case AnimationStatus.dismissed:
          Future.delayed(const Duration(milliseconds: 2000), () {
            controller.forward();
          });
          break;
        default:
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<Menu>(
              icon: const Icon(
                Icons.more_vert_outlined,
                color: Colors.black,
              ),
              onSelected: (Menu item) async {
                String releaseUrl =
                    'https://github.com/GauthamAsir/g_downloader/releases';

                if (item == Menu.share) {
                  Share.share(
                      'Hey, have a look on my new application to Download You-Tube videos fast and in high quality without any ADs.\n\n$releaseUrl');

                  return;
                }

                if (item == Menu.contact) {
                  try {
                    await launchUrl(Uri(path: 't.me/mellow04', scheme: 'https'),
                        mode: LaunchMode.externalApplication);
                  } catch (e) {
                    log(e.toString());
                  }
                  return;
                }

                try {
                  await launchUrl(
                      Uri(
                          path: 'github.com/GauthamAsir/g_downloader/releases',
                          scheme: 'https'),
                      mode: LaunchMode.externalApplication);
                } catch (e) {
                  log(e.toString());
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<Menu>>[
                    PopupMenuItem<Menu>(
                      value: Menu.update,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.update_outlined,
                            color: Colors.purple[700],
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          const Text('Update'),
                        ],
                      ),
                    ),
                    PopupMenuItem<Menu>(
                      value: Menu.contact,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.contact_support_outlined,
                            color: Colors.blueAccent[700],
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          const Text('Contact'),
                        ],
                      ),
                    ),
                    PopupMenuItem<Menu>(
                      value: Menu.share,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.share_outlined,
                            color: Colors.green[700],
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          const Text('Share'),
                        ],
                      ),
                    ),
                  ])
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                          begin: const Offset(1, 0), end: const Offset(0, 0))
                      .animate(animation),
                  child: child,
                );
              },
              child: _widgetOptions.elementAt(_selectedIndex),
            ),
          ),
          SlideTransition(
            position: offset,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(5)),
                  color: Colors.lightBlue[800]),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Developed by Gautham',
                    style: Theme.of(context)
                        .textTheme
                        .subtitle2!
                        .copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.file_download_outlined),
            label: 'Downloader',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.lightBlueAccent[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
