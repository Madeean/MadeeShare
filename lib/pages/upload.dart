import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_network_flutter/models/user.dart';

class Upload extends StatefulWidget {
  final User currentUser;
  Upload({this.currentUser});

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  PickedFile selectFile;
  File file;
  final ImagePicker pick = ImagePicker();

  handleTakePhoto() async {
    Navigator.pop(context);
    PickedFile selectFile = (await pick.getImage(
      source: ImageSource.camera,
      maxHeight: 675,
      maxWidth: 960,
    ));
    setState(() {
      this.file = File(selectFile.path);
      print(this.file);
    });
  }

  handleChooseFromGallery() async {
    Navigator.pop(context);
    PickedFile selectFile = await pick.getImage(source: ImageSource.gallery);
    setState(() {
      this.file = File(selectFile.path);
      print(this.file);
    });
  }

  selectImage(parentContext) {
    return showDialog(
      context: parentContext,
      builder: (context) {
        return SimpleDialog(
          title: Text("create post"),
          children: [
            SimpleDialogOption(
              child: Text('photo with camera'),
              onPressed: handleTakePhoto,
            ),
            SimpleDialogOption(
              child: Text('photo from gallery'),
              onPressed: handleChooseFromGallery,
            ),
            SimpleDialogOption(
              child: Text('cancel'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  Container buildSplashScreen() {
    return Container(
      color: Theme.of(context).colorScheme.secondary.withOpacity(0.6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/upload.svg',
            height: 260,
          ),
          Padding(
            padding: EdgeInsets.only(top: 20),
            child: TextButton(
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: Colors.deepOrange,
              ),
              onPressed: () => selectImage(context),
              child: Text(
                'Upload image',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  clearImage() {
    setState(() {
      file = null;
    });
  }

  Scaffold buildUplaodedForm() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white70,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: clearImage,
        ),
        centerTitle: true,
        title: Text(
          'Caption Post',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(top: 16, right: 20),
            child: GestureDetector(
              onTap: () => print('pressed'),
              child: Text(
                'Post',
                style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          Container(
            height: 220,
            width: MediaQuery.of(context).size.width * 0.8,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: FileImage(file),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 10.0),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(
                widget.currentUser.photoUrl,
              ),
            ),
            title: Container(
              width: 250,
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Write a caption",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(
              Icons.pin_drop,
              color: Colors.orange,
              size: 35,
            ),
            title: Container(
              width: 250,
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Where was this photo taken",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Container(
            width: 200,
            height: 100,
            alignment: Alignment.center,
            child: TextButton.icon(
              onPressed: () => print('get loc'),
              icon: Icon(
                Icons.my_location,
                color: Colors.white,
              ),
              label: Text(
                'Use Current Location',
                style: TextStyle(color: Colors.white),
              ),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                backgroundColor: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return file == null ? buildSplashScreen() : buildUplaodedForm();
  }
}
