import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String username;
  final String email;
  final String photoUrl;
  final String displayName;
  final String bio;

  UserModel(
      {required this.id,
      required this.username,
      required this.email,
      required this.photoUrl,
      required this.displayName,
      required this.bio});

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    return UserModel(
      id: doc['id'],
      email: doc['email'],
      username: doc['username'],
      photoUrl: doc['photoUrl'],
      displayName: doc['displayName'],
      bio: doc['bio'],
    );
  }
}
