import 'package:http/http.dart' as http;
import 'package:image_downloader/image_downloader.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
// import 'package:image_picker_saver/image_picker_saver.dart';
import 'package:path/path.dart' as Path;
import 'package:Xfeedm/categories.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:geocoder/model.dart';
// import 'package:image_downloader/image_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'feed.dart';
import 'location.dart';
import 'upload_page.dart';
import 'dart:async';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_page.dart';
import 'search_page.dart';
import 'activity_feed.dart';
import 'create_account.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io' show Platform;
import 'models/user.dart';
import 'package:image_picker/image_picker.dart';
import 'filter_page.dart';


final auth = FirebaseAuth.instance;
final googleSignIn = GoogleSignIn();
// final ref = Firestore.instance.collection('insta_users');
final users_ref = Firestore.instance.collection('users');
final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
var FBlogin_a = FacebookLogin();

User currentUserModel;

Future<void> main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // after upgrading flutter this is now necessary

  // enable timestamps in firebase
  Firestore.instance.settings().then((_) {
    print('[Main] Firestore timestamps in snapshots set');
  }, onError: (_) => print('[Main] Error setting timestamps in snapshots'));
  runApp(Fluttergram());
}

Future<DocumentSnapshot> _ensureFBLoggedIn(BuildContext context) async {
  FacebookLoginResult facebookLoginResult =
      await FBlogin_a.logIn(['email', 'user_gender', 'user_birthday']);
  DocumentSnapshot userRecordReturn = null;
  switch (facebookLoginResult.status) {
    case FacebookLoginStatus.cancelledByUser:
      print("Cancelled");
      break;
    case FacebookLoginStatus.error:
      print("error");
      break;
    case FacebookLoginStatus.loggedIn:
      print("Logged In");
      final accessToken = facebookLoginResult.accessToken.token;
      final facebookAuthCred =
          FacebookAuthProvider.getCredential(accessToken: accessToken);
      final user = await auth.signInWithCredential(facebookAuthCred);
      userRecordReturn = await tryCreateUserRecordFB(context);

      // print("UserRecord : " +;
      break;
  }
  return userRecordReturn;
}

Future<DocumentSnapshot> _silentFBLogin(BuildContext context) async {
  FacebookAccessToken accessToken = await FBlogin_a.currentAccessToken;
  DocumentSnapshot userRecordReturn = null;
  if (accessToken == null) {
    print("No access token should register");
    return userRecordReturn;
  } else {
    print("access token is valid");
  }

  if (await auth.currentUser() == null && accessToken != null) {
    print("no authntication");
    final FacebookAccessToken accessToken = await FBlogin_a.currentAccessToken;
    final facebookAuthCred =
        FacebookAuthProvider.getCredential(accessToken: accessToken.token);
    await auth.signInWithCredential(facebookAuthCred);
  }
  userRecordReturn = await tryCreateUserRecordFB(context);
  return userRecordReturn;
}

Future<Null> _setUpNotifications() async {
  if (Platform.isIOS) {
    iOS_Permission();
  }
  _firebaseMessaging.getToken().then((token) {
    print("token is " + token);
    Firestore.instance
        .collection("users")
        .document(currentUserModel.id)
        .updateData({"notification_token": token});
  });

  _firebaseMessaging.configure(
    onMessage: (Map<String, dynamic> message) async {
      print('on message $message');
    },
    onResume: (Map<String, dynamic> message) async {
      print('on resume $message');
    },
    onLaunch: (Map<String, dynamic> message) async {
      print('on launch $message');
    },
  );
}

void iOS_Permission() {
  _firebaseMessaging.requestNotificationPermissions(
      IosNotificationSettings(sound: true, badge: true, alert: true));
  _firebaseMessaging.onIosSettingsRegistered
      .listen((IosNotificationSettings settings) {
    print("Settings registered: $settings");
  });
}

Future<void> _downloadImage(String photoURL) async {
// var response = await http
//           .get(photoURL);
  
//       debugPrint(response.statusCode.toString());
  
      // var filePath = await ImagePickerSaver.saveFile(
          // fileData: response.bodyBytes);
  
      // var savedFile= File.fromUri(Uri.file(filePath));
  var imageId = await ImageDownloader.downloadImage(photoURL);
  if (imageId == null) {
    print("image library doesnt work");
    return null;
  }
  var path = await ImageDownloader.findPath(imageId);
  var savedFile= File.fromUri(Uri.file(path));
  // var file = File(path);
  print("19191919191991919191919199191 " + savedFile.path.toString());
  // String image_path =  await uploadImage(file);
  // var uuid = Uuid().v1();
  //uploadFile(savedFile);
}

// TODO: implimint this window to get username/nickname from user instead of fb
Future<String> getNickname(var contexts) async {
  String userName = await Navigator.push(
    contexts,
    MaterialPageRoute(
        builder: (context) => Center(
              child: Scaffold(
                  appBar: AppBar(
                    leading: Container(),
                    title: Text('Fill out missing data',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                    backgroundColor: Colors.white,
                  ),
                  body: ListView(
                    children: <Widget>[
                      Container(
                        child: CreateAccount(),
                      ),
                    ],
                  )),
            )),
  );
  return userName;
}

void createNewUser(Map<String, dynamic> user_data, String photo_FB_URL,
    String userName) async {
  print("createNewUser: here id " + user_data['id']);
  await users_ref.document(user_data['id']).setData({
    "bio": "",
    "birthday": user_data['birthday'],
    "credit": 0,
    "email": user_data['email'],
    "first_name": user_data['first_name'],
    "gender": user_data['gender'],
    "last_name": user_data['last_name'],
    "post_distribution": 250,
    "profile_pic_url": photo_FB_URL,
    "registration_date": DateTime.now(),
    "username": userName,
    "cuLevel": "FIRST"
  });
  //After creating user record we should update user preference to default
  Coordinates current_cordinate = await getUserCordinate();

  await Firestore.instance
      .collection("post_preferences")
      .document(user_data['id'])
      .setData({
    "categories": FeedCategory.getAllCategoriesNames(),
    "radius": 1.0,
    "gender": FeedCategory.genderNames,
    "location":
        GeoPoint(current_cordinate.latitude, current_cordinate.longitude),
    "min_age": FilterPosts.minAge,
    "max_age": FilterPosts.maxAge
  });
}

Future<DocumentSnapshot> tryCreateUserRecordFB(BuildContext context) async {
  final FacebookAccessToken accessToken = await FBlogin_a.currentAccessToken;
  DocumentSnapshot userRecordReturn = null;

  if (accessToken == null) {
    print("No user token exist");
    return userRecordReturn;
  }
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String userID = prefs.getString("id");
  if (userID != null) {
    print("no need to send to FB, currentUserID is " + userID);
    userRecordReturn = await users_ref.document(userID).get();
    return userRecordReturn;
  }

  // print("token is " + accessToken.token);
  var httpClient = HttpClient();

  try {
    var request = await httpClient.getUrl(Uri.parse(
        'https://graph.facebook.com/v2.12/me?fields=name,first_name,last_name,email,gender,birthday,picture&access_token=${accessToken.token}'));
    var response = await request.close();
    if (response.statusCode == HttpStatus.ok) {
      String json = await response.transform(utf8.decoder).join();
      Map<String, dynamic> user_data = jsonDecode(json);
      String photo_FB_URL = user_data['picture']['data']['url'].toString();
      print("printing data " + user_data.toString());

      DocumentSnapshot userRecord =
          await users_ref.document(user_data['id']).get();
      
      if (userRecord.data == null) {
        print("no user record exists, time to create");
        String userName = await getNickname(context);
        await createNewUser(user_data, photo_FB_URL, userName);
        prefs.setString("id", user_data['id']);
        userRecord = await users_ref.document(user_data['id']).get();
      } else {
        //TODO : download user photo once registered and upload it
        // print("user phtot updated");
        // await users_ref
        //     .document(user_data['id'])
        //     .updateData({"profile_pic_url": photo_FB_URL});
      }
      userRecordReturn = userRecord;
      print("######user record created######");
    } else {
      print(
          'Error sending token to facebook: Http status ${response.statusCode} ');
    }
  } catch (exception) {
    print('Failed invoking the getFeed function. Exception: $exception');
  }

  return userRecordReturn;
}

updateCurrentUser(User currentUser, UserPreference pref) {
  //  DocumentSnapshot userRecord = await users_ref.document(userId).get();
  //  currentUserModel = await User.fromDocument(userRecord);
  //  await currentUser.setUserPref();
  currentUser.preferences = pref;
}

class Fluttergram extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fluttergram122',
      theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or press Run > Flutter Hot Reload in IntelliJ). Notice that the
          // counter didn't reset back to zero; the application is not restarted.
          primarySwatch: Colors.blue,
          buttonColor: Colors.pink,
          primaryIconTheme: IconThemeData(color: Colors.black)),
      home: HomePage(title: 'Xfeed'),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

PageController pageController;

class _HomePageState extends State<HomePage> {
  final int feedPage = 0;
  final int searchPage = 1;
  final int favoritePage = 2;
  final int profilePage = 3;
  bool triedSilentLogin = false;
  bool setupNotifications = false;
  File imageFile;
  bool showRegisterWithFB = false;
  bool loginFinished = false;
  Scaffold buildLoginPage() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 240.0),
          child: Column(
            children: <Widget>[
              Text(
                'Xfeed',
                style: TextStyle(
                    fontSize: 60.0,
                    fontFamily: "Billabong",
                    color: Colors.black),
              ),
              Padding(padding: const EdgeInsets.only(bottom: 100.0)),
              GestureDetector(
                onTap: login,
                child: Image.asset(
                  "assets/images/FB_image.png",
                  width: 255,
                  // height: 70,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  buildStartScreen() {
    print("building startScreen");
    return Scaffold(
        body: Container(
      alignment: FractionalOffset.center,
      child: Text(
        'Xfeed',
        style: TextStyle(
            fontSize: 60.0, fontFamily: "Billabong", color: Colors.black),
      ),
    ));
  }

  Scaffold buildHomeScreen() {
    return Scaffold(
      body: PageView(
        children: [
          Container(
            color: Colors.white,
            child: Feed(),
          ),
          Container(color: Colors.white, child: SearchPage()),
          Container(color: Colors.white, child: ActivityFeedPage()),
          Container(
              color: Colors.white,
              child: ProfilePage(
                userId: currentUserModel.id,
              )),
        ],
        controller: pageController,
        physics: NeverScrollableScrollPhysics(),
      ),
      floatingActionButton: Container(
          height: 65.0,
          width: 70.0,
          child: FloatingActionButton(
            onPressed: () async {
              var image = await ImagePicker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 1920,
                  maxHeight: 1200,
                  imageQuality: 80);

              setState(() {
                imageFile = image;
                imageFile == null
                    ? pageController.jumpToPage(
                        feedPage) //jump to feed page in case no image captured
                    : Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Uploader(
                                  imageFile: imageFile,
                                )));
              });
            },
            child: Icon(Icons.add),
          )),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        color: Colors.white,
        child: Container(
          height: 30,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              IconButton(
                iconSize: 30.0,
                padding: EdgeInsets.only(left: 28.0),
                icon: Icon(Icons.home),
                onPressed: () {
                  setState(() {
                    pageController.jumpToPage(feedPage);
                  });
                },
              ),
              IconButton(
                iconSize: 30.0,
                padding: EdgeInsets.only(right: 28.0),
                icon: Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    pageController.jumpToPage(searchPage);
                  });
                },
              ),
              IconButton(
                iconSize: 30.0,
                padding: EdgeInsets.only(left: 28.0),
                icon: Icon(Icons.star),
                onPressed: () {
                  setState(() {
                    pageController.jumpToPage(favoritePage);
                  });
                },
              ),
              IconButton(
                iconSize: 30.0,
                padding: EdgeInsets.only(right: 28.0),
                icon: Icon(Icons.person),
                onPressed: () {
                  setState(() {
                    pageController.jumpToPage(profilePage);
                  });
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print("building page");
    if (triedSilentLogin == false) {
      silentFBLogin(context);
    }

    if (setupNotifications == false && currentUserModel != null) {
      setUpNotifications();
    }

    if (showRegisterWithFB) {
      return buildLoginPage();
    } else if (loginFinished) {
      return buildHomeScreen();
    }
    return buildStartScreen();
  }

  void initCurrentUserModel(DocumentSnapshot userRecord) async {
    if (userRecord == null) {
      setState(() {
        showRegisterWithFB = true;
        triedSilentLogin = true;
      });
    } else {
      setState(() {
        currentUserModel = User.fromDocument(userRecord);
        triedSilentLogin = true;
        loginFinished = true;
        showRegisterWithFB = false;
        print("Showing Home Screen");
        // _downloadImage(currentUserModel.photoUrl);
      });
     await currentUserModel.setUserPref();
      Firestore.instance
      .collection('users')
      .document(currentUserModel.id)
      .snapshots()
      .listen((event) {
        print("user DB has been changed, creating new user");
        UserPreference pref = currentUserModel.preferences;
        currentUserModel = User.fromDocument(event);
        currentUserModel.setUserPrefSync(pref);
      });
    }
  }

  void login() async {
    _ensureFBLoggedIn(context)
        .then((userRecord) => initCurrentUserModel(userRecord));
  }

  void setUpNotifications() async {
    await _setUpNotifications();
    setState(() {
      setupNotifications = true;
    });
  }

  void silentFBLogin(BuildContext context) async {
    _silentFBLogin(context).then((value) => initCurrentUserModel(value));
  }

  @override
  void initState() {
    super.initState();
    pageController = PageController();
  }

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
  }
}
Future uploadFile(File imageFile, Function cbFunc) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = reference.putFile(imageFile);
    StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;

    storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
     cbFunc(downloadUrl);
    }, onError: (err) {
      print("file is  not image "+err.toString());
      // Fluttertoast.showToast(msg: 'This file is not an image');
    });
  }
