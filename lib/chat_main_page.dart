import 'package:Xfeedm/main.dart';
import 'package:Xfeedm/profile_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'chat.dart';
import 'image_post.dart';
import 'models/user.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPage createState() => new _ChatPage();
}

class _ChatPage extends State<ChatPage> {
  TextStyle boldStyle = TextStyle(
    color: Colors.black,
    fontWeight: FontWeight.bold,
  );
  Widget buildItem(BuildContext context, UserInChatList user) {
    // String userID = document.documentID;
    // DocumentSnapshot snap =
    //     await Firestore.instance.collection('users').document(userID).get();
    // User user = User.fromDocument(snap);
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: CachedNetworkImageProvider(user.user.photoUrl),
        backgroundColor: Colors.grey,
      ),
      title: GestureDetector(
        child: Text(user.user.username, style: boldStyle),
        onTap: () {
          openProfile(context, user.user.id);
        },
      ),
      onTap: () {
        print("chat has been pressed");
        Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
        Chat(userToChatWith: user.user)));
      },
      subtitle: Text(user.lastMessage),
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
        appBar: new AppBar(
          title: Text(
            "Chat",
            style: TextStyle(
                fontFamily: "Billabong", color: Colors.black, fontSize: 35.0),
          ),
          backgroundColor: Colors.white,
        ),
        body: StreamBuilder(
            stream: Firestore.instance
                .collection('chat')
                .document(currentUserModel.id)
                .collection('user_chats')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container(
                    alignment: FractionalOffset.center,
                    child: Text("No Chats", style: TextStyle(fontSize: 20)));
              }
              //Widget s =  buildItem(context, snapshot.data.documents[index]);
              // return ListView.builder(
              //   padding: EdgeInsets.all(10.0),
              //   itemBuilder: (context, index) async=>
              //      await buildItem(context, snapshot.data.documents[index]),
              //   itemCount: snapshot.data.documents.length,
              // );
              return Container(
                  child: FutureBuilder(
                      future: buildUserChatData(snapshot.data.documents),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          List<UserInChatList> users = snapshot.data;

                          return ListView.builder(
                            itemBuilder: (context, index) {
                              return buildItem(context, users[index]);
                            },
                            itemCount: users.length,
                          );
                        }
                        return Container();
                      }));
            }));
  }

  buildUserChatData(var usersInChatDocuments) async {
    print("buildUserChatData: num of users in chat " +
        usersInChatDocuments.length.toString());
    List<UserInChatList> usersData = new List();
    for (DocumentSnapshot item in usersInChatDocuments) {
      print("adding item " + item.documentID.length.toString());
      User user = await User.fromID(item.documentID.toString());
      String chatGroupId = getChatGroupId(currentUserModel.id, user.id);
      String msgToShow;
      var lastMsg = await Firestore.instance
                  .collection('messages')
                  .document(chatGroupId)
                  .collection(chatGroupId)
                  .orderBy('timestamp', descending: true)
                  .limit(1)
                  .getDocuments();
      if(lastMsg.documents[0]['type'] == 0){
        msgToShow = lastMsg.documents[0]['content'];
      }else if(lastMsg.documents[0]['type'] == 1){
        msgToShow = 'photo';
      }else{
        msgToShow ='emoji';
      }

      usersData.add(UserInChatList(user,msgToShow));
    }
    return usersData;
  }
}
