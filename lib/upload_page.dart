import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'categories.dart';
import 'filter_page.dart';
import 'main.dart';
import 'dart:io';
import 'location.dart';
import 'package:geocoder/geocoder.dart';
import 'package:http/http.dart' as http;
import "package:google_maps_webservice/places.dart";
import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'filter_page.dart';
import 'package:flutter_google_places/flutter_google_places.dart';

class Uploader extends StatefulWidget {
  final File imageFile;
  Uploader({this.imageFile});
  _Uploader createState() => _Uploader(file: this.imageFile);
}

class _Uploader extends State<Uploader> {
  File file;
  //Strings required to save address
  Address address;
  Map<int, List<Map<String, dynamic>>> googleNearbyPlaces = Map();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  bool uploading = false;
  bool locationTapped = false;
  List<FeedCategory> categories = FeedCategory.categories;
  List<FeedCategory> genders = FeedCategory.genders;
  List<bool> _tappedGenders;
  List<bool> _tappedCategories;
  int numTappedCategories = 0;
  int numTappedGenders = 2; //on by default
  Set<String> _chosedCat = new Set();
  Set<String> _chosedGender = new Set.from(FeedCategory.genderNames);
  RangeValues _rangeValue;
  RangeLabels _rangeLabels;
  int _ageStart = FilterPosts.minAge.toInt();
  int _ageEnd = FilterPosts.maxAge.toInt();
  Coordinates
      coordinate; //= new Coordinates(32.0807735, 34.7740245); //TZINA location for testx
  String feature_name = "";
  List<String> suggestions;
  GlobalKey<AutoCompleteTextFieldState<String>> autoCompleteKey =
      new GlobalKey();
  SimpleAutoCompleteTextField textField;
  String currentText = "";
  num _max_return_near_places = 100;
  bool _valideLocation = true;
  int _placesWithenRadius = 500; //in meters
  static String kGoogleApiKey = "AIzaSyCIsdZDKCzkVb6pb9cb02_ec-Tih_1qhO4";
  GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);
  _Uploader({this.file});
  @override
  initState() {
    suggestions = new List();
    initPlatformState(); //method to call location
    super.initState();
    _tappedCategories = new List(categories.length);
    for (var i = 0; i < _tappedCategories.length; i++) {
      _tappedCategories[i] = false;
    }
    _tappedGenders = new List(genders.length);
    for (var j = 0; j < _tappedGenders.length; j++) {
      _tappedGenders[j] = true; //on by default
    }
    _rangeValue = new RangeValues(FilterPosts.minAge.toDouble(), FilterPosts.maxAge.toDouble());
    _rangeLabels = new RangeLabels(
        FilterPosts.minAge.toString(), FilterPosts.maxAge.toString());
    textField = SimpleAutoCompleteTextField(
      key: autoCompleteKey,
      decoration: new InputDecoration(
          hintText: "Where was this photo taken?",
          border: InputBorder.none,
          errorText:
              _valideLocation ? null : "insert location from suggestions "),
      controller: locationController,
      suggestions: suggestions,
      textChanged: (text) => updateText(text),
      clearOnSubmit: false,
      onFocusChanged: (hasFocus) {},
      textSubmitted: (text) => textSubmitted(text),
    );
  }

  updateText(text) async {
    currentText = text;
    if (validateUserLocationInput(text)) {
      setState(() {
        locationTapped = true;
        _valideLocation = true;
      });
    } else {
      setState(() {
        locationTapped = false;
        _valideLocation = false;
      });
    }
    print("updateText " + text);
    List<Map<String, dynamic>> data = await fetchDataAutocomplete(text);
    buildSuggestions(data, 'description');
  }

  buildSuggestions(List<Map<String, dynamic>> data, String parser) {
    suggestions.clear();
    for (var item in data) {
      if (!suggestions.contains(item[parser])) {
        print("adding  "+parser + item[parser]);
        suggestions.add(item[parser]);
      }
    }
    textField.updateSuggestions(suggestions);
  }

  Future<List<Map<String, dynamic>>> fetchDataAutocomplete(text) async {
    String url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?" +
            "input=" + text + //text to be completed
            "&types=establishment"+
            "&location=${coordinate.latitude},${coordinate.longitude}"+
            "&radius=" + _placesWithenRadius.toString() + "&strictbounds"+
            "&key=" + kGoogleApiKey;
    List<Map<String, dynamic>> data = await getDataFromUrl(url, 'predictions');
    print("recieved data length is " + data.length.toString());
    return data;
  }

  bool validateUserLocationInput(String text) {
    // String currentText = locationController.text;
    for (var item in suggestions) {
      if (item.compareTo(text) == 0) {
        return true;
      }
    }
    return false;
  }

  textSubmitted(text) {
    if (validateUserLocationInput(text)) {
      setState(() {
        locationTapped = true;
      });
    } else {
      setState(() {
        locationTapped = false;
        _valideLocation = false;
      });
    }
  }

  //method to get Location and save into variables
  initPlatformState() async {
    Address first = await getUserLocation();
    Coordinates latling = await getUserCordinate();
    googleNearbyPlaces[coordinate.hashCode] = null;
    coordinate = latling;
    // await getNearlocation(); //No need for nearby location due to autocomplete
    // suggestions.addAll(iterable)
    await getStreetLocation(latling);
    setState(() {
      address = first;
    });
  }
  getStreetLocation(Coordinates latling) async{
    String url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=${latling.latitude},${latling.longitude}&result_type=street_address"+
    "&key=AIzaSyCIsdZDKCzkVb6pb9cb02_ec-Tih_1qhO4";
    List<Map<String, dynamic>> data = await getDataFromUrl(url, 'results');
    print("recieved data length is " + data.length.toString());
    for (var item in data) {
      print("formatted addres "+item['formatted_address']);
    }
  }
  bool canPost() {
    return (locationTapped &&
        (numTappedCategories > 0) &&
        (numTappedGenders > 0)) && 
        !uploading;
  }

  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomPadding: false,
        appBar: AppBar(
          backgroundColor: Colors.white70,
          leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: clearImage),
          title: const Text(
            'Post to',
            style: const TextStyle(color: Colors.black),
          ),
          actions: <Widget>[
            FlatButton(
                onPressed: canPost() ? postImage : null,
                child: Text(
                  "Post",
                  style: TextStyle(
                      color: canPost() ? Colors.blueAccent : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 20.0),
                )),
          ],
        ),
        body: ListView(
          children: <Widget>[
            PostForm(
              imageFile: file,
              descriptionController: descriptionController,
              locationController: locationController,
              loading: uploading,
            ),
            Divider(), //scroll view where we will show location to users
            ListTile(
              leading: Icon(Icons.pin_drop),
              // title: textField,
              title: Container(
                width: 250.0,
                child: textField,
              ),
            ),
            Divider(),
            Padding(
                padding: EdgeInsets.all(10),
                child: Text("Category:",
                    style: TextStyle(fontSize: 18, color: Colors.grey))),
            Wrap(
                children: FeedCategory.buildCategories(
                    categories, _tappedCategories, onTappedCategory)),
            Divider(),
            Padding(
                padding: EdgeInsets.all(10),
                child: Text("Genders:",
                    style: TextStyle(fontSize: 18, color: Colors.grey))),
            Wrap(
                children: FeedCategory.buildCategories(
                    genders, _tappedGenders, onTappedGender)),

            Divider(),
            Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                "Age Range",
                style: TextStyle(color: Colors.grey, fontSize: 18),
              ),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: Padding(
                      child: Text("$_ageStart"),
                      padding: EdgeInsets.only(
                        left: 18,
                      )),
                ),
                Expanded(
                  flex: 9,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      RangeSlider(
                          min: FilterPosts.minAge.toDouble(),
                          max: FilterPosts.maxAge.toDouble(),
                          values: _rangeValue,
                          labels: _rangeLabels,
                          onChanged: (RangeValues values) {
                            setState(() {
                              _rangeValue = values;
                              _rangeLabels = new RangeLabels(
                                  values.start.toString(),
                                  values.end.toString());
                              _ageStart = values.start.toInt();
                              _ageEnd = values.end.toInt();
                            });
                          }),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                      child: Text("$_ageEnd"),
                      padding: EdgeInsets.only(
                        right: 16,
                      )),
                )
              ],
            ),
            Divider(),
            // Padding(
            //   padding: EdgeInsets.all(10),
            //   child: Text(
            //     "NearBy Places:",
            //     style: TextStyle(color: Colors.grey, fontSize: 18),
            //   ),
            // ),
            // (address == null)
            //     ? Container()
            //     : SingleChildScrollView(
            //         scrollDirection: Axis.horizontal,
            //         padding: EdgeInsets.only(right: 5.0, left: 5.0, top: 5),
            //         child: Container(
            //             child: FutureBuilder<Widget>(
            //           future: buildNearByLocations(),
            //           builder: (BuildContext context,
            //               AsyncSnapshot<Widget> snapshot) {
            //             if (snapshot.hasData) return snapshot.data;
            //             // return Container(child: CircularProgressIndicator());
            //             return Container();
            //           },
            //         )),
            //       ),
          ],
        ));
  }

  onTappedCategory(bool newValue, int index) {
    if (!newValue) {
      numTappedCategories--;
      setState(() {
        _tappedCategories[index] = newValue;
        _chosedCat.remove(categories[index].getName());
      });
    } else {
      numTappedCategories++;
      setState(() {
        _tappedCategories[index] = newValue;
        _chosedCat.add(categories[index].getName());
      });
    }
  }

  onTappedGender(bool newValue, int index) {
    if (!newValue) {
      numTappedGenders--;
      setState(() {
        _tappedGenders[index] = newValue;
        _chosedGender.remove(genders[index].getName());
      });
    } else {
      numTappedGenders++;
      setState(() {
        _tappedGenders[index] = newValue;
        _chosedGender.add(genders[index].getName());
      });
    }
  }
  // buildCategories() {
  //   List<Widget> result = new List(categories.length);
  //   for (int i = 0; i < categories.length; i++) {
  //     result[i] = Container(
  //         padding: EdgeInsets.all(3),
  //         child: ChoiceChip(
  //           label: Text(categories[i].getName()),
  //           avatar: CircleAvatar(
  //             child: categories[i].getIcon(),
  //           ),
  //           selected: _tappedCategories[i],
  //           onSelected: (bool newValue) {
  //             onTappedCategory(newValue, i);
  //           },
  //         ));
  //   }
  //   return result;
  // }

  //method to build buttons with location.
  buildLocationButton(String locationName) {
    if (locationName != null ?? locationName.isNotEmpty) {
      return InkWell(
        onTap: () {
          locationController.text = locationName;
          setState(() {
            locationTapped = true;
          });
        },
        child: Center(
          child: Container(
            //width: 100.0,
            height: 30.0,
            padding: EdgeInsets.only(left: 8.0, right: 8.0),
            margin: EdgeInsets.only(right: 3.0, left: 3.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: Center(
              child: Text(
                locationName,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  void clearImage() {
    setState(() {
      Navigator.pop(context);
    });
  }

  void postImage() {
    setState(() {
      uploading = true;
    });
    uploadImage(file).then((String data) {
      postToFireStore(
          mediaUrl: data,
          description: descriptionController.text,
          location: locationController.text,
          activity: _chosedCat,
          point: coordinate,
          genders: _chosedGender,
          ageRange: _rangeValue);
    }).then((_) {
      setState(() {
        // file = null;
        Navigator.pop(context);
        uploading = false;
        // controller.clearItems();
      });
    });
  }

  Future<Widget> buildNearByLocations() async {
    List<Widget> results = new List();
    int loc_to_str = coordinate.hashCode;
    int num_of_places = 0;
    List<Map<String, dynamic>> all_places = googleNearbyPlaces[loc_to_str];
    for (var item in all_places) {
      List<String> temp = item['types'].cast<String>();
      Set<String> as_a_set = temp.toSet();
      // print('first type is '+as_a_set.toString());
      Set<String> intersection = _chosedCat.intersection(as_a_set);
      if (intersection.isNotEmpty) {
        results.add(buildLocationButton(item['name']));
        num_of_places++;
      }
      if (num_of_places == _max_return_near_places) {
        break;
      }
    }
    return Row(
      children: results,
    );
  }

  getDataFromUrl(String url, String data_array) async {
    print("About to send request URL: " + url);
    final response = await http.get(url);
    Map<String, dynamic> json_data = json.decode(response.body);
    List<Map<String, dynamic>> list_data =
        json_data[data_array].cast<Map<String, dynamic>>();
    return list_data;
  }

  getNearlocation() async {
    int loc_to_str = coordinate.hashCode;

    if (googleNearbyPlaces[loc_to_str] == null) {
      String url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?' +
          'location=${coordinate.latitude},${coordinate.longitude}&rankby=distance&key=' +
          kGoogleApiKey;
      List<Map<String, dynamic>> list_data = await getDataFromUrl(url,'results');
      googleNearbyPlaces[loc_to_str] = list_data;
    } else {
      print("No need to send request to google");
    }
    List<Map<String, dynamic>> all_places = googleNearbyPlaces[loc_to_str];
    // buildSuggestions(all_places);
    print("got all_places " + all_places.length.toString());
  }
}

class PostForm extends StatefulWidget {
  final imageFile;
  final TextEditingController descriptionController;
  final TextEditingController locationController;
  final bool loading;

  _PostForm createState() => _PostForm(
        this.imageFile,
        this.descriptionController,
        this.locationController,
        this.loading,
      );
  PostForm({
    this.imageFile,
    this.descriptionController,
    this.loading,
    this.locationController,
  });
}

class _PostForm extends State<PostForm> {
  final imageFile;
  final TextEditingController descriptionController;
  final TextEditingController locationController;
  final bool loading;
  String currentText = "";
  _PostForm(this.imageFile, this.descriptionController, this.locationController,
      this.loading);
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        loading
            ? CircularProgressIndicator()
            : Padding(padding: EdgeInsets.only(top: 0.0)),
        Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            CircleAvatar(
              backgroundImage: NetworkImage(currentUserModel.photoUrl),
            ),
            Container(
              width: 250.0,
              child: TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                    hintText: "Write a caption...", border: InputBorder.none),
              ),
            ),
            Container(
              height: 45.0,
              width: 45.0,
              child: AspectRatio(
                aspectRatio: 487 / 451,
                child: Container(
                  decoration: BoxDecoration(
                      image: DecorationImage(
                    fit: BoxFit.fill,
                    alignment: FractionalOffset.topCenter,
                    image: FileImage(imageFile),
                  )),
                ),
              ),
            ),
          ],
        ),
        // Divider(),
        // ListTile(
        //   leading: Icon(Icons.pin_drop),
        //   // title: textField,
        //   title: Container(
        //     width: 250.0,
        //     child: textField,
        //     // child: TextField(
        //     //   controller: locationController,
        //     //   decoration: InputDecoration(
        //     //       hintText: "Where was this photo taken?",
        //     //       border: InputBorder.none),
        //     // ),
        //   ),
        // ),
      ],
    );
  }
}

Future<String> uploadImage(var imageFile) async {
  var uuid = Uuid().v1();
  StorageReference ref = FirebaseStorage.instance.ref().child("post_$uuid.jpg");
  StorageUploadTask uploadTask = ref.putFile(imageFile);

  String downloadUrl = await (await uploadTask.onComplete).ref.getDownloadURL();
  return downloadUrl;
}

void postToFireStore(
    {String mediaUrl,
    String location,
    String description,
    Set<String> activity,
    Coordinates point,
    Set<String> genders,
    RangeValues ageRange}) async {
  var req_body = jsonEncode(<String, dynamic>{
    'lng': "${point.longitude}",
    'lat': "${point.latitude}",
    'feature_name': location,
    'img_url': mediaUrl,
    'description': description,
    "uid": currentUserModel.id.toString(),
    "timestamp": DateTime.now().toUtc().toString(),
    "category": activity.toList(),
    "genders": genders.toList(),
    "min_age": ageRange.start.toInt(),
    "max_age": ageRange.end.toInt()
  });
  print('upload post with time '+DateTime.now().toUtc().toString());
  // print(req);
  final http.Response response = await http.post(
      'https://us-central1-xfeed-497fe.cloudfunctions.net/uploadPost',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: req_body);
}
