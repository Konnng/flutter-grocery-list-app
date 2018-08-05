import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:validator/validator.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import "package:node_shims/js.dart"; 

import 'grocery_item.dart';

void main() => runApp(new GrocelyListApp());

class GroceryList extends StatefulWidget {
  @override
  createState() => new GroceryListState();
}

class GroceryListState extends State<GroceryList> {
  final GlobalKey<FormState> _formGroceryAdd = new GlobalKey<FormState>();

  List<GroceryItem> _groceryItems = [];
  GroceryItem _formGroceryData = new GroceryItem();
  BuildContext _context;

  void _addGroceryItem(String title, int amount) {
    setState(() { 
      this._groceryItems.add(new GroceryItem(title: title, amount: amount, purchased: false));
      this._groceryListSort();
    });
  }

  void _addGroceryItemObject(GroceryItem item) {
    setState(() { 
      this._groceryItems.add(item);
      this._groceryListSort();
    });
  }

  void _saveGroceryItem(GroceryItem item) {
    setState(() { 
      var index = this._groceryItems.indexWhere((v) { 
        return v.hashCode == item.hashCode;
      });
      if (index < 0) {
        return;
      }
      
      this._groceryItems[index] = item;
    });
  }

  void _removeGroceryItem(int index) {
    setState(() => this._groceryItems.removeAt(index));
  }

  void _removeGroceryList() {
    setState(() => this._groceryItems = []);
  }

  void _groceryListSort() {
    this._groceryItems.sort((a, b) {
        if (a.purchased && !b.purchased) {
          return 1;
        }
        if (!a.purchased && b.purchased) {
          return -1;
        }

        return 0;
      });
  }

  bool _saveGroceryForm([ dynamic item = false ]) {
    if (!this._formGroceryAdd.currentState.validate()) {
      return false;
    }

    var grocery = this._formGroceryData;

    this._formGroceryAdd.currentState.save();

    if (item is GroceryItem) {
      item.title = grocery.title;
      item.amount = grocery.amount;
      
      this._saveGroceryItem(item);
    } else {
      this._addGroceryItem(grocery.title, grocery.amount);
    }
    
    this._formGroceryData.reset();
    
    return true;
  }

  void _pushAddScreen() {
    Navigator.of(context).push(
      new MaterialPageRoute(
        builder: (context) {
          return new Scaffold(
            appBar: new AppBar(
              title: new Text('Add new Grocery Item')
            ),
            body: new Container(
              padding: const EdgeInsets.all(5.0),
              child: this._buildGroceryFormComponent()
            )
          );
        }
      )
    );
  }

  void _pushEditScreen(GroceryItem item) {
    Navigator.of(context).push(
      new MaterialPageRoute(
        builder: (context) {
          return new Scaffold(
            appBar: new AppBar(
              title: new Text('Add new Grocery Item')
            ),
            body: new Container(
              padding: const EdgeInsets.all(5.0),
              child: this._buildGroceryFormComponent(item)
            )
          );
        }
      )
    );
  }

  void _promptRemoveGroceryItem(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text('Delete this grocery item?'),
          actions: <Widget>[
            new FlatButton(
              child: new Text('CANCEL'),
              onPressed: () => Navigator.of(context).pop()
            ),
            new FlatButton(
              child: new Text('DELETE'),
              onPressed: () {
                _removeGroceryItem(index);
                Navigator.of(context).pop();
              }
            )
          ]
        );
      }
    );
  }

  void _promptRemoveGroceryList() {
    if (this._groceryItems.length == 0) {
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text('Delete the grocery list?'),
          actions: <Widget>[
            new FlatButton(
              child: new Text('CANCEL'),
              onPressed: () => Navigator.of(context).pop()
            ),
            new FlatButton(
              child: new Text('DELETE'),
              onPressed: () {
                _removeGroceryList();
                Navigator.of(context).pop();
              }
            )
          ]
        );
      }
    );
  }

  Form _buildGroceryFormComponent([dynamic item = false]) {
    return new Form(
      key: this._formGroceryAdd,
      child: new ListView(
        children: <Widget>[
          new TextFormField(
            initialValue: item is GroceryItem ? item.title : '',
            autofocus: true,
            decoration: new InputDecoration(
              labelText: 'Item',
              hintText: 'Enter a grocery item to buy',
              contentPadding: const EdgeInsets.all(16.0)
            ),
            validator: (value) {
              if (value.isEmpty) {
                return 'Please enter a grocery item';
              }
            },
            onSaved: (value) {
              this._formGroceryData.title = value;
            },
          ),
          new TextFormField(
            initialValue: item is GroceryItem ? item.amount.toString() : '',
            maxLength: 4,
            decoration: new InputDecoration(
              labelText: 'Amount',
              contentPadding: const EdgeInsets.all(16.0)
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value.isNotEmpty && !isNumeric(value)) {
                return 'Invalid amount. Use numbers only.';
              }
            },
            onSaved: (value) {
              if (value.isEmpty) {
                value = "1";
              }
              this._formGroceryData.amount = int.parse(value);
            },
          ),
          new Container(
            child: new ButtonBar(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                new RaisedButton(
                  child: new Text(item is GroceryItem ? 'Save Item' : 'Add Item'),
                  color: item is GroceryItem ? Colors.green  : Theme.of(context).primaryColor,
                  textColor: Colors.white,
                  elevation: 4.0,
                  onPressed: () {
                    if (this._saveGroceryForm(item)) {
                      if (item is GroceryItem) {
                        _showSnackBar('Item updated!');
                      }
                      Navigator.pop(context);
                    }
                  },
                ),
                new RaisedButton(
                  child: new Text('Cancel'),
                  onPressed: () {
                    this._formGroceryData.reset();
                    Navigator.pop(context);
                  },
                ),
              ] 
            ),
            margin: new EdgeInsets.only(
              top: 20.0
            ),
          ),
        ]
      )
    );
  }

  Widget _buildGroceryList() {
    return new ListView.builder(
      itemBuilder: (context, index) {
        if (index < this._groceryItems.length) {
          return _buildGroceryItem(this._groceryItems[index], index);
        }
      },
    );
  }

  Widget _buildGroceryItem(GroceryItem item, int index) {
    return new Slidable(
      delegate: new SlidableDrawerDelegate(),
      actionExtentRatio: 0.25,
      child: new Container(
        color: Colors.white,
        child: new CheckboxListTile(
          title: new Text(item.title),
          subtitle: new Text('Amount: ${item.amount}'),
          value: item.purchased,
          onChanged: (bool value) {
            setState(() { 
              item.markAsPurchased(value); 
              if (value) {
                item.oldIndex = index;
                this._removeGroceryItem(index);
                this._addGroceryItemObject(item);
              } else {
                this._removeGroceryItem(index);
                
                splice(
                  this._groceryItems, 
                  item.oldIndex, 
                  0, 
                  [ new GroceryItem(title: item.title, purchased: false, amount: item.amount) ]
                );
              }
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          //onTap: () => _markItemPurchased(index)
        )
      ),
      secondaryActions: <Widget>[
        new IconSlideAction(
          caption: 'Edit',
          color: Colors.black12,
          icon: Icons.edit,
          onTap: () {
            this._pushEditScreen(this._groceryItems[index]);
          },
        ),
        new IconSlideAction(
          caption: 'Delete',
          color: Colors.red,
          icon: Icons.delete,
          onTap: () {
            _promptRemoveGroceryItem(index);
          },
        ),
      ],
    );
  }

  void _showSnackBar(String text) {
    Scaffold.of(this._context).showSnackBar(SnackBar(content: new Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('My Grocery List'),
        actions: <Widget>[
            new IconButton(
              icon: new Icon(Icons.delete),
              tooltip: 'Action Tool Tip',
              onPressed: () {
                this._promptRemoveGroceryList();
              },
            ),
        ]
      ),
      body: Builder(
        builder: (context) {
          this._context = context;

          return this._buildGroceryList();
        }
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _pushAddScreen,
        tooltip: 'Add Item',
        child: new Icon(Icons.add)
      ),
    );
  }
}

class GrocelyListApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Grocery List',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new GroceryList(),
    );
  }
}

void debug(val) {
  debugPrint(new List.filled(50, "-").join());
  debugPrint('${val}');
  debugPrint(new List.filled(50, "-").join());
}