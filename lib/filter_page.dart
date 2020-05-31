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
  static final int minAge = 18;
  static final int maxAge = 70;
  @override
  _Filter createState() => new _Filter(this.pref);
}

class _Filter extends State<FilterPosts> {
  _Filter(this.userPref);

  List<FeedCategory> categories = FeedCategory.categories;
  List<FeedCategory> genders = FeedCategory.genders;
  RangeValues _rangeValue;
  RangeLabels _rangeLabels;
  final UserPreference userPref;
  FilterMapController _filterMapController =
      new FilterMapController(null, null);
  List<bool> _tappedCategory;
  List<String> _chosedCategories;
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
   _rangeLabels = new RangeLabels(
      userPref.min_age.toInt().toString(), userPref.max_age.toInt().toString());
  }


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
            Row(
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: Padding(
                      child: Text("${_rangeLabels.start}"),
                      padding: EdgeInsets.only(
                        left: 18,
                      )),
                ),
                Expanded(
                  flex: 8,
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
                          min: FilterPosts.minAge.toDouble(),
                          max: FilterPosts.maxAge.toDouble(),
                          values: _rangeValue,
                          labels: _rangeLabels,
                          onChanged: (RangeValues values) {
                            setState(() {
                              _rangeValue = values;
                              _rangeLabels = new RangeLabels(
                                  values.start.toInt().toString(),
                                  values.end.toInt().toString());
                            });
                          }),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                      child: Text("${_rangeLabels.end}"),
                      padding: EdgeInsets.only(
                        right: 16,
                      )),
                )
              ],
            ),
            Padding(
              padding: EdgeInsets.all( 10),
            )
          ],
        ));
  }

}
