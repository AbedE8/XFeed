

import "package:flutter/material.dart";
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'main.dart'; //for currentuser & google signin instance
import 'models/user.dart';

class EditProfilePage extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  // File imageFile;
  changeProfilePhoto(BuildContext parentContext) async {
    var imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
    uploadFile(imageFile, (downloadImg) async {
      print("user uploadphoto cb has been called");
      await Firestore.instance
          .collection("users")
          .document(currentUserModel.id)
          .updateData({'profile_pic_url': downloadImg});
          // currentUserModel = downloadImg;
          currentUserModel.setUserPhoto(downloadImg);
    });
  }

  applyChanges() {
    Firestore.instance
        .collection('users')
        .document(currentUserModel.id)
        .updateData({
      "username": nameController.text,
      "bio": bioController.text,
    });
  }

  Widget buildTextField({String name, TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Text(
            name,
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: name,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Firestore.instance
            .collection('users')
            .document(currentUserModel.id)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Container(
                alignment: FractionalOffset.center,
                child: CircularProgressIndicator());

          User user = User.fromDocument(snapshot.data);

          nameController.text = user.displayName;
          bioController.text = user.bio;

          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                child: CircleAvatar(
                  backgroundImage: NetworkImage(currentUserModel.photoUrl),
                  radius: 50.0,
                ),
              ),
              FlatButton(
                  onPressed: () async{
                    await changeProfilePhoto(context);
                  },
                  child: Text(
                    "Change Photo",
                    style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold),
                  )),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: <Widget>[
                    buildTextField(name: "Name", controller: nameController),
                    buildTextField(name: "Bio", controller: bioController),
                  ],
                ),
              ),
              Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: MaterialButton(
                      onPressed: () => {_logout(context)},
                      child: Text("Logout")))
            ],
          );
        });
  }

  void _logout(BuildContext context) async {
    print("logout");
    await auth.signOut();
    await FBlogin_a.logOut();


    currentUserModel = null;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }
}
