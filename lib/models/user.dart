import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String email;
  final String id;
  final String photoUrl;
  final String username;
  final String displayName;
  final String bio;
  UserPreference preferences;
  User(
      {this.username,
      this.id,
      this.photoUrl,
      this.email,
      this.displayName,
      this.bio,
      this.preferences});

  Future<void> setUserPref() async {
    if (this.preferences == null) {
      UserPreference pref = await UserPreference.fromID(this.id);
      this.preferences = pref;
    }
  }

  factory User.fromDocument(DocumentSnapshot document) {
    return User(
        email: document['email'],
        username: document['username'],
        photoUrl: document['profile_pic_url'],
        id: document.documentID,
        displayName: document['first_name'],
        bio: document['bio'],
        preferences: null);
  }

  static Future<User> fromID(String userId) async {
    DocumentSnapshot user =
        await Firestore.instance.collection("users").document(userId).get();

    if (user.data == null) {
      print("uncorrect userid");
      return null;
    } else {
      return User(
          email: user.data['email'],
          username: user.data['username'],
          photoUrl: user.data['profile_pic_url'],
          id: userId,
          displayName: user.data['first_name'],
          bio: user.data['bio'],
          preferences: null);
    }
  }
}

class UserPreference {
  final int min_age;
  final int max_age;
  final List categories;
  // final List gender;
  final GeoPoint location;
  final double radious;

  const UserPreference(
      {this.min_age,
      this.max_age,
      // this.gender,
      this.categories,
      this.location,
      this.radious});

  static Future<UserPreference> fromID(String userId) async {
    DocumentSnapshot userPref = await Firestore.instance
        .collection("post_preferences")
        .document(userId)
        .get();
    UserPreference pref = UserPreference.fromDocument(userPref);
    return pref;
  }

  factory UserPreference.fromDocument(DocumentSnapshot document) {
    // print("run timetype "+cat.runtimeType.toString()+" age "+min_range.runtimeType.toString());
    return UserPreference(
        // gender: document['gender'],
        min_age: document['min_age'],
        max_age: document['max_age'],
        categories: document['categories'],
        radious: document['radius'].toDouble(),
        location: document['location']);
  }
  @override
  String toString() {
    // TODO: implement toString
    return "UserPreference: min_age: " +
        this.min_age.toString() +
        " max_age: " +
        this.max_age.toString() +
        " location lat: "+this.location.latitude.toString()+
        " location long: "+this.location.longitude.toString()+
        " categories: "+this.categories.toString()+
        " radius: "+this.radious.toString();
  }
}
