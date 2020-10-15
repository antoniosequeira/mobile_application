import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Model extends ChangeNotifier {
  double _progress = 0;
  get downloadProgress => _progress;
  get uploadProgress => _progress;
  final _baseURL = 'https://recycler-api.herokuapp.com';
  final _uploadEndpoint = '/model/upload/';
  final _downloadEndpoint = '/model/download/';

  void startDownloading() async {
    _progress = null;
    notifyListeners();
    final _url = _baseURL + _downloadEndpoint;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token');

    final url = _url;
    final request = Request('GET', Uri.parse(url));
    request.headers.addAll({"Authentication":token});

    final StreamedResponse response = await Client().send(request);

    final contentLength = response.contentLength;
  
    _progress = 0;
    notifyListeners();

    List<int> bytes = [];

    var dir = await getExternalStorageDirectory();
    var knockDir = await new Directory('${dir.path}/mobilenet').create(recursive: true);

    final file = File("${knockDir.path}/mobilenet.tflite");
    response.stream.listen(
      (List<int> newBytes) {
        bytes.addAll(newBytes);
        final downloadedLength = bytes.length;
        _progress = downloadedLength / contentLength;
        notifyListeners();
      },
      onDone: () async {
        _progress = 0;
        notifyListeners();
        await file.writeAsBytes(bytes);
      },
      onError: (e) {
        print(e);
      },
      cancelOnError: true,
    );
  }

  void startUploading() async {

    var dir = await getExternalStorageDirectory();
    final imagesDirectory = Directory('${dir.path}/Pictures');
    List<FileSystemEntity> _images;
    _images = imagesDirectory.listSync(recursive: true, followLinks: false);

    for (var image in _images){
      fileUpload(image.path);
    }
    
  }

  void fileUpload(String file) async {
    if (file == null) return;

    String fileName = file.split("/").last;

    File fileFinal = new File(file);

    final _url = _baseURL + _uploadEndpoint;

    var fileContent = fileFinal.readAsBytesSync();
    var fileContentBase64 = base64.encode(fileContent);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token');
  
    await post(_url,
      headers: <String, String>{
        'Authentication': token,
      },
      body: {
        "filename": fileName,
        "file": fileContentBase64,
      }).then((res) {
       print(res.statusCode);
      }).catchError((err) {
        print(err);
      }
    );
  }
}