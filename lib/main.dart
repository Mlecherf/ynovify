import 'package:flutter/material.dart';

// Import our classes
import 'package:ynovify/models/palette.dart';
import 'package:ynovify/models/music.dart';
import 'package:ynovify/models/duration_state.dart';

// Import our libraries
import 'package:just_audio/just_audio.dart';
// ignore: depend_on_referenced_packages
import 'package:rxdart/rxdart.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';

// Core of the app
void main() {
  // Splash screen
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Run the app
  runApp(const MyApp());

  // Remove the Splash screen
  FlutterNativeSplash.remove();
}

// Define our music list

List<Music> myMusicList = [
  Music('A state of Trance', 'Armin', 'assets/album_a_state_of_trance.jpg',
      'https://codiceo.fr/mp3/armin.mp3'),
  Music('Civilisation', 'Orelsan', 'assets/orelsan.jpg',
      'https://codiceo.fr/mp3/civilisation.mp3')
];

// The class of the app
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // Build the app
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YNOVIFY',
      theme: ThemeData(
        primarySwatch: Palette.kToDark,
      ),
      home: const MyHomePage(title: 'Ynovify'),
    );
  }
}

// The only page that we have "HomePage"
class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// Extend tickerProviderStateMixin for audio playing
class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  // Define our properties
  int index = 0; // Index of our current music
  bool isPlaying = false; // Is the current music playing
  final _player = AudioPlayer(); // The audio player
  AnimationController?
      _animationController; // The controller of the pause / resume animation
  late Stream<DurationState>
      _durationState; // The duration state for the stream of the progress bar

// Init the song on the player
  Future<void> initSong(String urlSong) async {
    await _player.setUrl(myMusicList[index].urlSong);
  }

// Launched first
  @override
  void initState() {
    super.initState();
    // Call the initSong
    initSong(myMusicList[index].urlSong);
    // Define our animation controller for the resume / pause animation
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));

    // Define the duration state for the progress bar
    _durationState = Rx.combineLatest2<Duration, PlaybackEvent, DurationState>(
        _player.positionStream,
        _player.playbackEventStream,
        (position, playbackEvent) => DurationState(
              progress: position,
              buffered: playbackEvent.bufferedPosition,
              total: playbackEvent.duration!,
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.black,
        title: const Text("YNOVIFY"),
      ),
      backgroundColor: const Color.fromARGB(124, 24, 24, 47),
      body: Center(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 30),
            Container(
              width: 275,
              height: 275,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(myMusicList[index].imagePath),
                  fit: BoxFit.fill,
                ),
                color: Colors.white,
              ),
            ),
            Text(
              myMusicList[index].title,
              style: const TextStyle(color: Colors.white, fontSize: 25),
            ),
            const SizedBox(height: 30),
            Text(
              myMusicList[index].singer,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(height: 15),
            Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
              IconButton(
                  icon: const Icon(Icons.fast_rewind,
                      size: 40.0, color: Colors.white),
                  onPressed: () {
                    isPlaying = false;
                    _player.stop();
                    setState(() {
                      if (index > 0) {
                        index -= 1;
                      } else {
                        index = myMusicList.length - 1;
                      }
                      initSong(myMusicList[index].urlSong);
                    });
                  }),
              IconButton(
                  icon: AnimatedIcon(
                    icon: AnimatedIcons.play_pause,
                    progress: _animationController!,
                    color: Colors.white,
                    size: 40.0,
                  ),
                  onPressed: () {
                    setState(() {
                      isPlaying = !isPlaying;
                      isPlaying
                          ? _animationController?.forward()
                          : _animationController?.reverse();
                    });
                    if (isPlaying) {
                      //_player.setUrl(myMusicList[index].urlSong);
                      _player.play();
                    } else {
                      _player.stop();
                    }
                  }),
              IconButton(
                  icon: const Icon(Icons.fast_forward,
                      size: 40.0, color: Colors.white),
                  onPressed: () {
                    isPlaying = false;
                    _player.stop();
                    setState(() {
                      if (index < myMusicList.length - 1) {
                        index += 1;
                      } else {
                        index = 0;
                      }
                    });
                    initSong(myMusicList[index].urlSong);
                  }),
            ]),
            const SizedBox(height: 15),
            StreamBuilder<DurationState>(
              stream: _durationState,
              builder: (context, snapshot) {
                final durationState = snapshot.data;
                final progress = durationState?.progress ?? Duration.zero;
                final buffered = durationState?.buffered ?? Duration.zero;
                final total = durationState?.total ?? Duration.zero;
                return ProgressBar(
                  progress: progress,
                  buffered: buffered,
                  total: total,
                  onSeek: (duration) {
                    _player.seek(duration);
                  },
                  timeLabelTextStyle: const TextStyle(color: Colors.white),
                  timeLabelLocation: TimeLabelLocation.sides,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
