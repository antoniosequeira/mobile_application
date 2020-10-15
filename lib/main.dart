import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:recycler_mobile/helpers/model.dart';
import 'package:recycler_mobile/screens/login.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';


Future<void> main() async => runApp(new App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyApp(),
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  File _image;
  List _recognitions;
  double _imageHeight;
  double _imageWidth;
  bool _busy = false;
  PermissionStatus _status;


  Future _askPermission() async {
    PermissionHandler().requestPermissions([PermissionGroup.camera]).then(_onStatusRequested);
  }

  //Method that deals with the image pick of the phone library
  Future _predictImagePicker() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() {
      _busy = true;
    });
    _predictImage(image);
  }

  //Method that deals with the image taken from the camera
  Future _onStatusRequested(Map<PermissionGroup, PermissionStatus> value) async {
    final status = value[PermissionGroup.camera];
    if (status == PermissionStatus.granted) {
      var image = await ImagePicker.pickImage(source: ImageSource.camera);
      //If there was a problem saving the image, we want to return out of this method without predicting the image
      if (image == null) return;
      
      setState(() {
        _busy = true;
      });
      
      _predictImage(image);
      GallerySaver.saveImage(image.path, albumName: 'recycler');    
    } else {
      _updateStatus(status);
    }
  }

  //Method that deals with the prediction of the image
  Future _predictImage(File image) async {
    if (image == null) return;

    await _ssdMobileNet(image);

    new FileImage(image)
        .resolve(new ImageConfiguration())
        .addListener(ImageStreamListener((ImageInfo info, bool _) {
      setState(() {
        _imageHeight = info.image.height.toDouble();
        _imageWidth = info.image.width.toDouble();
      });
    }));

    setState(() {
      _image = image;
      _busy = false;
    });
  }

  //Method that calls the recognition of the image
  Future _recognizeImage(File image) async {
    var recognitions = await Model.runModelOnImage(
      path: image.path,
      numResults: 6,
      threshold: 0.05,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    setState(() {
      _recognitions = recognitions;
    });
  }

  Future _ssdMobileNet(File image) async {
    var recognitions = await Model.detectObjectOnImage(
      path: image.path,
      numResultsPerClass: 1,
    );
    // var imageBytes = (await rootBundle.load(image.path)).buffer;
    // img.Image oriImage = img.decodeJpg(imageBytes.asUint8List());
    // img.Image resizedImage = img.copyResize(oriImage, 300, 300);
    // var recognitions = await Tflite.detectObjectOnBinary(
    //   binary: imageToByteListUint8(resizedImage, 300),
    //   numResultsPerClass: 1,
    // );
    setState(() {
      _recognitions = recognitions;
    });
  }

  _updateStatus(PermissionStatus value) {
    if (value != _status) {
      setState(() {
        _status = value;
      });
    }
  }

  List<Widget> renderBoxes(Size screen) {
    if (_recognitions == null) return [];
    if (_imageHeight == null || _imageWidth == null) return [];

    double factorX = screen.width;
    double factorY = _imageHeight / _imageWidth * screen.width;
    Color blue = Color.fromRGBO(37, 213, 253, 1.0);
    return _recognitions.map((re) {
      return Positioned(
        left: re["rect"]["x"] * factorX,
        top: re["rect"]["y"] * factorY,
        width: re["rect"]["w"] * factorX,
        height: re["rect"]["h"] * factorY,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            border: Border.all(
              color: blue,
              width: 2,
            ),
          ),
          child: Text(
            "${re["detectedClass"]} ${(re["confidenceInClass"] * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              background: Paint()..color = blue,
              color: Colors.white,
              fontSize: 12.0,
            ),
          ),
        ),
      );
    }).toList();
  }

  Future _loadModel() async {
    Model.close();
    
    var dir = await getExternalStorageDirectory();
    String modelpath = "${dir.path}/mobilenet/ssd_mobilenet.tflite";
    String labelspath = "${dir.path}/mobilenet/ssd_mobilenet.txt";
    bool assets = false;
    
    //By default the app will be shipped with this base model, if no other model is found then this one is to be used
    if(!await File(modelpath).exists() || !await File(labelspath).exists() ){
      modelpath = 'assets/ssd_mobilenet.tflite';
      labelspath = 'assets/ssd_mobilenet.txt';
      assets = true;
    }    

    try {
      String res;
      res = await Model.loadModel(
            model: modelpath,
            labels: labelspath,
            numThreads: 1, // defaults to 1
            isAsset: assets // defaults to true, set to false to load resources outside assets
          );
      print(res);
    } on PlatformException {
      print('Failed to load model.');
    }
  }

  @override
  void initState() {
    super.initState();

    _busy = true;

    _loadModel().then((val) {
      setState(() {
        _busy = false;
      });
    });

    PermissionHandler()
        .checkPermissionStatus(PermissionGroup.camera)
        .then(_updateStatus);
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    List<Widget> stackChildren = [];

    stackChildren.add(Positioned(
        top: 0.0,
        left: 0.0,
        width: size.width ,
        child: _image == null ? Align(
          alignment: Alignment.center,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Please take a photo or choose one from the library to classify it')
          )
        ) 
          : Image.file(_image),
      ));

    stackChildren.addAll(renderBoxes(size));

    if (_busy) {
      stackChildren.add(const Opacity(
        child: ModalBarrier(dismissible: false, color: Colors.grey),
        opacity: 0.3,
      ));
      stackChildren.add(const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Recycler Mobile App', ),
        ),
        body: Stack(
          children: stackChildren,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              FloatingActionButton(
                heroTag: 'btn1',
                onPressed: _predictImagePicker,
                tooltip: 'Pick Image',
                child: Icon(Icons.image),
              ),
              FloatingActionButton(
                heroTag: 'btn2',
                onPressed: _askPermission,
                tooltip: 'Take Photo',
                child: Icon(Icons.camera),
              ),
              FloatingActionButton(
                heroTag: 'btn3',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Login()),
                  );
                },
                tooltip: 'Menu',
                child: Icon(Icons.menu),
              )
            ],
          ),
        ));
  }
}

