import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'categories.dart';

class ActivityItem {
  const ActivityItem(this.name, this.icon);
  final String name;
  final Icon icon;

  static List<ActivityItem> activites = <ActivityItem>[
    const ActivityItem("Food", Icon(Icons.fastfood)),
    const ActivityItem("Party", Icon(Icons.audiotrack)),
    const ActivityItem("Sport", Icon(Icons.fitness_center)),
    const ActivityItem("Education", Icon(Icons.school))
  ];
  static ActivityItem getCategoryByName(String name) {
    for (var activ in activites) {
      if (activ.name == name) {
        return activ;
      }
    }
    return null;
  }

  // buildCategoryIcon(String text) {
  //   return Container(
  //     child: ChoiceChip(
  //       padding: EdgeInsets.all(10),
  //       label: Text(text),
  //       avatar: CircleAvatar(child: ActivityItem.getCategoryByName(text).icon),
  //       selected: null,
  //       onSelected: ,
  //     ),
  //   );
  // }
}

class FilterItems {
  const FilterItems(this.categories);
  final List<String> categories;
  void printSelectedCategories() {
    for (var item in categories) {
      print("category " + item);
    }
  }
}

class Filter extends StatefulWidget {
  // This class is the configuration for the state. It holds the
  // values (in this case nothing) provided by the parent and used by the build
  // method of the State. Fields in a Widget subclass are always marked "final".

  @override
  _Filter createState() => new _Filter();
}

class _Filter extends State<Filter> {
  static CategoryController categoryController = new CategoryController(10);
  static CategoryController genderController = new CategoryController(2);
  List<FeedCategory> categories = <FeedCategory>[
    FeedCategory("Food", Icon(Icons.fastfood), categoryController),
    FeedCategory("Sport", Icon(Icons.fitness_center), categoryController),
    FeedCategory("Party", Icon(Icons.audiotrack), categoryController),
    FeedCategory("Education", Icon(Icons.school), categoryController),
    FeedCategory("ALL", Icon(Icons.all_inclusive), categoryController),
  ];
  List<FeedCategory> genders = <FeedCategory>[
    FeedCategory("Female", Icon(Icons.pregnant_woman), genderController),
    FeedCategory("Male", Icon(Icons.person), genderController)
  ];
  static final double startAge = 18;
  static final double endAge = 70;
  RangeValues _rangeValue = new RangeValues(startAge, endAge);
  RangeLabels _rangeLabels =
      new RangeLabels(startAge.toString(), endAge.toString());
  int _start = startAge.toInt();
  int _end = endAge.toInt();
  double filterDistance = 0;
  // int dis = filterDistance.toInt();
  @override
  Widget build(BuildContext context) {
    var distance = filterDistance.toInt();

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
              Navigator.pop(
                  context,
                  categoryController.getNumCategories() > 0
                      ? new FilterItems(categoryController.getCategorisName())
                      : null);
              categoryController.clearItems();
            },
          ),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              flex: 60,
              child: Container(
                child: Center(
                  child: Text(
                    "Map",
                    style: TextStyle(fontSize: 40),
                  ),
                ),
              ),
            ),
            Column(
              children: <Widget>[
                Padding(
                  child: Text(
                    "Select Category",
                    style: TextStyle(fontSize: 18),
                  ),
                  padding: EdgeInsets.only(left: 16),
                )
              ],
            ),
            Padding(
              padding: EdgeInsets.all(5),
            ),
            Wrap(
              children: categories,
            ),
            // Padding(
            //   padding: EdgeInsets.all(5),
            // ),
            Column(
              children: <Widget>[
                Padding(
                  child: Text(
                    "Around me ",
                    style: TextStyle(fontSize: 18),
                  ),
                  padding: EdgeInsets.only(left: 16),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(left: 40),
                    ),
                    Expanded(
                      flex: 9,
                      child: CupertinoSlider(
                        value: filterDistance,
                        onChanged: (newDis) {
                          setState(() {
                            filterDistance = newDis;
                          });
                        },
                        min: 0,
                        max: 20,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                          child: Text("$distance Km"),
                          padding: EdgeInsets.only(
                            left: 16,
                          )),
                    )
                  ],
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: Padding(
                      child: Text("$_start"),
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
                          min: 18,
                          max: 70,
                          values: _rangeValue,
                          labels: _rangeLabels,
                          onChanged: (RangeValues values) {
                            setState(() {
                              _rangeValue = values;
                              _rangeLabels = new RangeLabels(
                                  values.start.toString(),
                                  values.end.toString());
                              _start = values.start.toInt();
                              _end = values.end.toInt();
                            });
                          }),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                      child: Text("$_end"),
                      padding: EdgeInsets.only(
                        right: 16,
                      )),
                )
              ],
            ),
            Padding(
              padding: EdgeInsets.all(5),
              child: Text(
                "Gender",
                style: TextStyle(fontSize: 18),
              ),
            ),
            Wrap(
              children: genders,
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 10),
            )
          ],
        ));
  }
}
