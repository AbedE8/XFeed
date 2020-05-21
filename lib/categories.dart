import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

class FeedCategory {
  final String _name;
  final Icon _icon;

  FeedCategory(this._name, this._icon);
  static List<FeedCategory> categories = [
    FeedCategory("resturant", Icon(Icons.restaurant)),
    FeedCategory("bar", Icon(Icons.local_bar)),
    FeedCategory("gym", Icon(Icons.fitness_center)),
    FeedCategory("night_club", Icon(Icons.audiotrack)),
    FeedCategory("casino", Icon(Icons.casino)),
    FeedCategory("cafe", Icon(Icons.local_cafe)),
    FeedCategory("food", Icon(Icons.fastfood)),
  ];
  static getAllCategoriesNames(){
    List<String> result = new List();
    for (var item in categories) {
      result.add(item.getName());
    }
    return result;
  }
  static List<String> genderNames = ["female","male"];
  static List<FeedCategory> genders = <FeedCategory>[
    FeedCategory(genderNames[0], Icon(Icons.pregnant_woman)),
    FeedCategory(genderNames[1], Icon(Icons.person))
  ];
  
  static List<Widget> buildCategories(List<FeedCategory> categories_to_build, List<bool> tapped, Function onTapCategorey) {
    List<Widget> result = new List(categories_to_build.length);
    for (int i = 0; i < categories_to_build.length; i++) {
      result[i] = Container(
          padding: EdgeInsets.all(3),
          child: ChoiceChip(
            label: Text(categories_to_build[i].getName()),
            avatar: CircleAvatar(
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

  @override
  String toString() {
    return _name;
  }
}
