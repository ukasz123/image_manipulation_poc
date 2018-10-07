import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Image Manipulation',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Flutter Image Manipulation Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File _image;

  img.Image _currentImage;

  img.Image _originalImage;

  double originalWidth;

  Uint8List _previewBytes;

  Uint8List _currentBytes;

  StreamController<bool> _progressStream;

  @override
  void initState() {
    super.initState();
    _progressStream = StreamController();
  }

  @override
    void dispose() {
      _progressStream.close();
      super.dispose();

    }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    originalWidth = MediaQuery.of(context).size.width * 0.25;
  }

  @override
  Widget build(BuildContext context) {
    Widget image = _currentBytes != null
        ? Image.memory(_currentBytes)
        : Placeholder();
    Widget originalPreview = SizedBox(
        width: originalWidth,
        child: ConstrainedBox(
            constraints: BoxConstraints.tightFor(width: originalWidth),
            child: _originalImage != null
                ? Image.memory(_previewBytes)
                : Placeholder()));
    return new Scaffold(
      appBar: new AppBar(
        // Here we take the value from the MyomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: new Text(widget.title),
      ),
      body: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(child: image),
          ),
          Positioned(
            child: originalPreview,
            right: 16.0,
            top: 16.0,
          ),
          Center(child: StreamBuilder<bool>(
            initialData: false,
            stream: _progressStream.stream,
            builder: (context, snapshot) {
              if (snapshot.data){
                return SizedBox(width: 60.0, height: 60.0,child: CircularProgressIndicator());
              } else {
                return Container(width: 0.0, height: 0.0,);
              }
            },
          )
          ),
        ],
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _pickImage,
        tooltip: 'Pick image',
        child: new Icon(Icons.image),
      ),
      bottomNavigationBar: SizedBox(
          height: 48.0,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            IconButton(
              icon: Icon(Icons.rotate_90_degrees_ccw),
              onPressed: _rotateImage,
            ),
            IconButton(
              onPressed: _grayscale,
              icon: Icon(Icons.wb_cloudy),
            ),
            IconButton(
              onPressed: _sketchify,
              icon: Icon(Icons.lightbulb_outline),
            ),
          ])),
    );
  }

  _working(bool working) {
    _progressStream.sink.add(working);
  }

  Future _pickImage() async {
    final image = await ImagePicker.pickImage(source: ImageSource.camera);
    _working(true);
    final loadedImage =
        await image.readAsBytes().then((bytes) => img.decodeImage(bytes));

    final smallImage = await Future.microtask(
        () => img.copyResize(loadedImage, originalWidth.floor()));
    _currentBytes = await _encode(loadedImage);
    _previewBytes = await _encode(smallImage);
    setState(() {
      _working(false);
      _image = image;
      _currentImage = loadedImage;
      _originalImage = _currentImage;
    });
  }

  Future _rotateImage() async {
    _working(true);
    _currentImage =
        await _bg(() => img.copyRotate(_currentImage, 90));
        _currentBytes = await _encode(_currentImage);
    setState(() {
      _working(false);
    });
  }

  Future _grayscale() async {
    _working(true);
    _currentImage = await _bg(() => img.grayscale(_currentImage));
    _currentBytes = await _encode(_currentImage);
    _working(false);
    setState(() {});
  }

  Future _sketchify() async {
    _working(true);
    final grayscaled = await _bg(() => img.grayscale(_originalImage));
    final inverted = await _bg(() => img.invert(grayscaled));
    final blurred = await _bg(() => img.gaussianBlur(inverted, 4));
    final sketched = await _bg(() => _dodge(grayscaled, blurred));
    setState(() {
      _working(false);
      _currentImage = sketched;
    });
  }
}

Future<T> _bg<T>(FutureOr<T> computation()) => Future.sync(computation);

_dodge(img.Image src, img.Image desc) {
  var s = src.getBytes();
  var d = desc.getBytes();
  assert(s.length == d.length);
  for (int i = 0, len = s.length; i < len; i++) {
    if (i % 4 == 3) {
      continue;
    }
    if (d[i] == 255) {
      s[i] = 255;
    } else {
      s[i] = _clamp255((s[i] * 255 / (255 - d[i])).floor());
    }
  }
  return src;
}

int _clamp255(int i) => i > 255 ? 255 : i;

Future<Uint8List> _encode(img.Image src ) =>  Future.microtask(
        () => Uint8List.fromList(img.encodePng(src)));