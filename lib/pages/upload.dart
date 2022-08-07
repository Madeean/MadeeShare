import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:madee_share/models/user_model.dart';
import 'package:madee_share/pages/home.dart';
import 'package:madee_share/widgets/progress.dart';
import 'package:image/image.dart' as Im;
import 'package:uuid/uuid.dart';

class Upload extends StatefulWidget {
  final UserModel currentUser;
  Upload({required this.currentUser});

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload>
    with AutomaticKeepAliveClientMixin<Upload> {
  TextEditingController locationController = TextEditingController();
  TextEditingController captionController = TextEditingController();
  PickedFile? selectFile;
  File? file;
  bool isUploading = false;
  String postId = Uuid().v4();
  final ImagePicker pick = ImagePicker();

  handleTakePhoto() async {
    Navigator.pop(context);
    selectFile = (await pick.getImage(
      source: ImageSource.camera,
      maxHeight: 675,
      maxWidth: 960,
    ));
    if (selectFile != null) {
      setState(() {
        this.file = File(selectFile!.path);
      });
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Upload(currentUser: currentUser!)));
    }
  }

  handleChooseFromGallery() async {
    Navigator.pop(context);
    selectFile = await pick.getImage(source: ImageSource.gallery);
    setState(() {
      this.file = File(selectFile!.path);
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

  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image? imageFile = Im.decodeImage(file!.readAsBytesSync());
    final compressedImageFile = File('$path/img_$postId.jpg')
      ..writeAsBytesSync(Im.encodeJpg(imageFile!, quality: 85));

    setState(() {
      file = compressedImageFile;
    });
  }

  Future<String> uploadImage(imageFile) async {
    UploadTask uploadTask =
        storageRef.child("post_$postId.jpg").putFile(imageFile);
    TaskSnapshot storageSnap = await uploadTask;
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  createPostInFirestore(
      {required String mediaUrl,
      required String location,
      required String description}) {
    postRef.doc(widget.currentUser.id).collection("userPosts").doc(postId).set({
      "postId": postId,
      "ownerId": widget.currentUser.id,
      "username": widget.currentUser.username,
      "mediaUrl": mediaUrl,
      "description": description,
      "location": location,
      "timestamp": timestamp,
      "likes": {},
    });
  }

  handleSubmit() async {
    setState(() {
      isUploading = true;
    });
    await compressImage();
    String mediaUrl = await uploadImage(file);
    createPostInFirestore(
      mediaUrl: mediaUrl,
      location: locationController.text,
      description: captionController.text,
    );
    captionController.clear();
    locationController.clear();
    setState(() {
      file = null;
      isUploading = false;
      postId = Uuid().v4();
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
              onTap: isUploading ? null : () => handleSubmit(),
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
          isUploading ? linearProgress() : Text(""),
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
                      image: FileImage(file!),
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
                controller: captionController,
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
                controller: locationController,
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
              onPressed: getUserLocation,
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

  getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark placemark = placemarks[0];
    String completeAddress =
        '${placemark.subThoroughfare} ${placemark.thoroughfare}, ${placemark.subLocality} ${placemark.locality}, ${placemark.subAdministrativeArea}, ${placemark.administrativeArea} ${placemark.postalCode}, ${placemark.country}';

    String formattedAddress = " ${placemark.locality}, ${placemark.country}";
    locationController.text = formattedAddress;
  }

  get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return file == null ? buildSplashScreen() : buildUplaodedForm();
  }
}
