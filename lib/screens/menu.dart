import 'package:flutter/material.dart';
import 'package:provider_architecture/provider_architecture.dart';
import 'package:recycler_mobile/api_requests/model.dart';

class Menu extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Menu"),
      ),
      body: Center(
        child: ListView(
              children: <Widget>[
                BodyWidget(),
              ],
        ),
      ),
    );
  }
}

class BodyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<Model>.withConsumer(
      viewModel: Model(),
      builder: (context, model, child) => Center(
        child: Column(
        children: <Widget>[
          Container(
            height: 50,
              margin: EdgeInsets.fromLTRB(0, 20, 0, 20),
              padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: RaisedButton(
                textColor: Colors.white,
                color: Colors.blue,
                child: Text('Download Model'),
                onPressed: () {
                  model.startDownloading();
                },
              )),
          Center(
            child: LinearProgressIndicator(
              value: model.downloadProgress,
            ),
          ),
          Container(
            height: 50,
              margin: EdgeInsets.fromLTRB(0, 20, 0, 20),
              padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: RaisedButton(
                textColor: Colors.white,
                color: Colors.blue,
                child: Text('Upload Photos'),
                onPressed: () {
                  model.startUploading();
                },
              )),
          Center(
            child: LinearProgressIndicator(
              value: model.uploadProgress,
            ),
          ),
        ],
      ),
      )
    );
  }
}