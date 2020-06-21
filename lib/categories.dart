import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

class FeedCategory {
  static int brightness = 200;
  final String _name;
  final Icon _icon;
  final Color _color;
  FeedCategory(this._name, this._icon, this._color);
  static List<FeedCategory> categories = [
    FeedCategory("resturant", Icon(Icons.restaurant), Colors.green[brightness]),
    FeedCategory("bar", Icon(Icons.local_bar), Colors.pink[brightness]),
    FeedCategory("gym", Icon(Icons.fitness_center), Colors.cyan[brightness]),
    FeedCategory("night_club", Icon(Icons.audiotrack), Colors.purple[brightness]),
    FeedCategory("casino", Icon(Icons.casino), Colors.yellow[brightness]),
    FeedCategory("cafe", Icon(Icons.local_cafe), Colors.orange[brightness]),
    FeedCategory("food", Icon(Icons.fastfood), Colors.red[brightness]),
    FeedCategory("info", Icon(Icons.info), Colors.blue[50]),
  ];
  static getAllCategoriesNames() {
    List<String> result = new List();
    for (var item in categories) {
      result.add(item.getName());
    }
    return result;
  }

  static List<String> genderNames = ["female", "male"];
  static List<FeedCategory> genders = <FeedCategory>[
    FeedCategory(genderNames[0], Icon(Icons.pregnant_woman), Colors.grey),
    FeedCategory(genderNames[1], Icon(Icons.person), Colors.grey)
  ];

  static List<Widget> buildCategories(List<FeedCategory> categories_to_build,
      List<bool> tapped, Function onTapCategorey) {
    List<Widget> result = new List(categories_to_build.length);
    for (int i = 0; i < categories_to_build.length; i++) {
      result[i] = Container(
          height: 30,
          // width: 60,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.blue[100])),
          // color: Colors.white,
          // padding: EdgeInsets.all(3),
          // color: Colors.white,
          child: ChoiceChip(
            // shape:  CircleBorder(),
            // shadowColor: Colors.red,
            backgroundColor: Colors.transparent,
            // disabledColor: Colors.white,
            selectedColor: categories_to_build[i].getColor(),
            label: Text(categories_to_build[i].getName()),
            avatar: CircleAvatar(
              radius: 15,
              child: categories_to_build[i].getIcon(),
            ),
            selected: tapped[i],
            onSelected: (bool newValue) {
              onTapCategorey(newValue, i);
            },
          ));
    }
    return result;
  }

  String getName() {
    return _name;
  }

  Icon getIcon() {
    return _icon;
  }

  Color getColor() {
    return _color;
  }

  @override
  String toString() {
    return _name;
  }

  static List<Widget> buildCirculeCategore(List<String> categoriesName) {
    
    List<Widget> result = new List(categoriesName.length);
    for (var i = 0; i < categoriesName.length; i++) {
      FeedCategory currentCat = getCategoryFromName(categoriesName[i]);
      result[i] = CircleAvatar(
          backgroundColor: currentCat.getColor(), 
          child: currentCat.getIcon(),
          radius: 15,);
    }
    return result;
  }

  static FeedCategory getCategoryFromName(String name) {
    for (var item in FeedCategory.categories) {
      if (item._name.compareTo(name) == 0) {
        return item;
      }
    }
  }
}
