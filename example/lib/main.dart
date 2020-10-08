import 'package:flutter/material.dart';
import 'package:flutter_fft/flutter_fft.dart';

void main() => runApp(Application());

class Application extends StatefulWidget {
  @override
  ApplicationState createState() => ApplicationState();
}

class ApplicationState extends State<Application> with WidgetsBindingObserver {
  FftResult result;
  bool isRecording = false;

  FlutterFft flutterFft = new FlutterFft();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    flutterFft.onRecorderStateChanged.listen((data) {
      setState(() => result = data);
    }, onError: (e) => print(e));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    /// Stop when entering the background
    if (state != AppLifecycleState.resumed) {
      flutterFft.stopRecorder();
    }
  }

  void _toggleRecording() async {
    if (flutterFft.getIsRecording) {
      await flutterFft.stopRecorder();
    } else {
      await flutterFft.startRecorder();
    }

    setState(() => isRecording = flutterFft.getIsRecording);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Simple flutter fft example",
      theme: ThemeData.dark(),
      color: Colors.blue,
      home: Scaffold(
        floatingActionButton: FloatingActionButton(
          child: Icon(isRecording ? Icons.pause : Icons.play_arrow),
          onPressed: _toggleRecording,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // If the plugin is recording
                if (isRecording) ...[
                  Value("Current note:", "${result?.note ?? '-'}"),
                  Value("Current octave:", "${result?.octave ?? '-'}"),
                  Value("Current frequency:", "${result?.frequency?.toStringAsFixed(2) ?? '-'}"),
                  Value("Is on pitch:", "${result?.isOnPitch?.toString() ?? '-'}"),
                ],

                // If not recording
                if (!isRecording)
                  Text(
                    "Not recording",
                    style: TextStyle(fontSize: 35),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Value extends StatelessWidget {
  final String label;
  final String value;

  final style = TextStyle(fontSize: 20);

  Value(this.label, this.value, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }
}
