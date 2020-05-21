import 'package:Xfeedm/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'categories.dart';
import 'filter_map.dart';

class FilterPosts extends StatefulWidget {
  // This class is the configuration for the state. It holds the
  // values (in this case nothing) provided by the parent and used by the build
  // method of the State. Fields in a Widget subclass are always marked "final".
  FilterPosts(this.pref);
  final UserPreference pref;
  static final double minAge = 18;
  static final double maxAge = 70;
  @override
  _Filter createState() => new _Filter(this.pref);
}

class _Filter extends State<FilterPosts> {
  _Filter(this.userPref);

  List<FeedCategory> categories = FeedCategory.categories;
  List<FeedCategory> genders = FeedCategory.genders;
  RangeValues _rangeValue;
  RangeLabels _rangeLabels = new RangeLabels(
      FilterPosts.minAge.toString(), FilterPosts.maxAge.toString());
  int _ageStart = FilterPosts.minAge.toInt();
  int _ageEnd = FilterPosts.maxAge.toInt();
  final UserPreference userPref;
  FilterMapController _filterMapController =
      new FilterMapController(null, null);
  List<bool> _tappedCategory;
  List<String> _chosedCategories;
  // List<bool> _tappedGender;
  // List<String> _chosedGenders;
  @override
  Future<void> initState() {
    super.initState();

    print("creating filter based on userPref");
    _rangeValue = new RangeValues(
        userPref.min_age.toDouble(), userPref.max_age.toDouble());
    _tappedCategory = new List(categories.length);
    for (var i = 0; i < _tappedCategory.length; i++) {
      _tappedCategory[i] =
          userPref.categories.indexOf(categories[i].getName()) == -1
              ? false
              : true;
    }
    _chosedCategories = new List.from(userPref.categories);
    // _tappedGender = new List(genders.length);
    // for (var i = 0; i < genders.length; i++) {
    //   _tappedGender[i] =
    //       userPref.gender.indexOf(genders[i].getName()) == -1 ? false : true;
    // }
    // _chosedGenders = new List.from(userPref.gender);
  }

  // onTappedGender(bool newValue, int index) {
  //   if (!newValue) {
  //     setState(() {
  //       _tappedGender[index] = newValue;
  //       _chosedGenders.remove(genders[index].getName());
  //     });
  //   } else {
  //     setState(() {
  //       _tappedGender[index] = newValue;
  //       _chosedGenders.add(genders[index].getName());
  //     });
  //   }
  // }

  onTappedCategory(bool newValue, int index) {
    if (!newValue) {
      setState(() {
        _tappedCategory[index] = newValue;
        _chosedCategories.remove(categories[index].getName());
      });
    } else {
      setState(() {
        _tappedCategory[index] = newValue;
        _chosedCategories.add(categories[index].getName());
      });
    }
  }

  UserPreference createUserPref() {
    GeoPoint point;
    double radius;
    if (_filterMapController.center != null) {
      point = new GeoPoint(_filterMapController.center.latitude,
          _filterMapController.center.longitude);
    } else {
      point = userPref.location;
    }
    if (_filterMapController.radius == null) {
      radius = userPref.radious;
      print("radius is null putiing old radius " + radius.toString());
    } else {
      radius = _filterMapController.radius;
    }
    if (_chosedCategories.length > 0) {
      return UserPreference(
          categories: _chosedCategories,
          min_age: _rangeValue.start.toInt(),
          max_age: _rangeValue.end.toInt(),
          // gender: _chosedGenders,
          location: point,
          radious: radius);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          backgroundColor: Colors.white,
          title: Text(
            "Filter Feed",
            style: TextStyle(color: Colors.black),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, createUserPref());
            },
          ),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              flex: 60,
              child: FilterMap(userPref, _filterMapController),
            ),
            Column(
              children: <Widget>[
                Padding(
                  child: Text(
                    "Select Category",
                    style: TextStyle(fontSize: 18),
                  ),
                  padding: EdgeInsets.fromLTRB(16, 10, 16, 1),
                )
              ],
            ),
            Padding(
              padding: EdgeInsets.all(5),
            ),
            Wrap(
              children: FeedCategory.buildCategories(
                  categories, _tappedCategory, onTappedCategory),
            ),
            // Padding(
            //   padding: EdgeInsets.all(5),
            // ),
            Column(
              children: <Widget>[],
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
                      Padding(
                        padding: EdgeInsets.all(5),
                        child: Text(
                          "Age Range",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      RangeSlider(
                          min: FilterPosts.minAge,
                          max: FilterPosts.maxAge,
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
            Padding(
              padding: EdgeInsets.only(bottom: 10),
            )
          ],
        ));
  }
}
