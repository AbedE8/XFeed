import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FeedCategory extends StatefulWidget {
  FeedCategory(this.name, this.icon, this.controller);
  final String name;
  final Icon icon;
  final CategoryController controller;

  @override
  State<StatefulWidget> createState() {
    FeedCategoryState innerState =
        new FeedCategoryState(this.name, this.icon, this.controller);
    controller.addItem(innerState);
    return innerState;
  }
}

class CategoryController {
  CategoryController(this.numOfAllowedOptions);
  final int numOfAllowedOptions;
  // ValueListenable<int> currentSelectedItems = new ValueNotifier(0);
final currentSelectedItems = new ValueNotifier(0);
  
  List<FeedCategoryState> categories = new List<FeedCategoryState>();
  addItem(FeedCategoryState newItem) {
    categories.add(newItem);
  }

  int getNumCategories() {
    int result = 0;
    for (var item in categories) {
      if (item.isSelected()) {
        result += 1;
      }
    }
    
    return result;
  }
  clearItems(){
    categories.clear();
    currentSelectedItems.value = 0;
  }
  List<String> getCategorisName() {
    List<String> allSelected = new List<String>();
    for (var item in categories) {
      if (item.isSelected()) {
        allSelected.add(item.name);
      }
    }
    return allSelected;
  }

  incrementItemSelected() {
    currentSelectedItems.value += 1;
  }

  decrementItemSelected() {
    currentSelectedItems.value -= 1;
  }

  bool canSelect() {
    return currentSelectedItems.value < numOfAllowedOptions;
  }
  ValueListenable<int> getNumNotifier(){
    return currentSelectedItems;
  }
}

class FeedCategoryState extends State<FeedCategory> {
  FeedCategoryState(this.name, this.icon, this.controller);
  final CategoryController controller;
  final String name;
  final Icon icon;
  bool _tapped = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3),
      child: ChoiceChip(
        label: Text(name),
        avatar: CircleAvatar(
          child: icon,
        ),
        selected: _tapped,
        onSelected: (bool newValue) {
          if (newValue) {
            if (controller.canSelect()) {
              setState(() {
                _tapped = newValue;
              });
              controller.incrementItemSelected();
            }
          } else {
            setState(() {
              _tapped = newValue;
            });
            controller.decrementItemSelected();
          }
        },
      ),
    );
  }

  bool isSelected() {
    return _tapped;
  }

  String getCatName() {
    return name;
  }

  @override
  String toStringShort() {
    // TODO: implement toStringShort
    return "hello";
  }
}
