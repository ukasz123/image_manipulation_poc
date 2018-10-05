import 'dart:async';
import 'dart:io';

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

  @override
  Widget build(BuildContext context) {
    Widget image = _currentImage != null ? Image.memory(
          img.encodePng(_currentImage)
        ) : Placeholder();
    return new Scaffold(
      appBar: new AppBar(
        // Here we take the value from the MyomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: new Text(widget.title),
      ),
      body: new Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: image,
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _pickImage,
        tooltip: 'Pick image',
        child: new Icon(Icons.image),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Future _pickImage() async {
    final image = await ImagePicker.pickImage(source: ImageSource.camera);

    final loadedImage = await image.readAsBytes().then((bytes) => img.decodeImage(bytes));

    setState(() {
      _image = image;
      _currentImage = loadedImage;
    });
  }
}
