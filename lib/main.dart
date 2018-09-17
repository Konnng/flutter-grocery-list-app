import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:validator/validator.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import "package:node_shims/js.dart"; 
import 'package:badge/badge.dart';

import 'grocery_item.dart';
import 'db.dart';

Db db = new Db();

void main() async {
  await db.checkDbFileExists;  

  runApp(new GrocelyListApp());
}

class GroceryList extends StatefulWidget {
  @override
  createState() => new GroceryListState();
}

class GroceryListState extends State<GroceryList> {
  final GlobalKey<FormState> _formGroceryAdd = new GlobalKey<FormState>();
  final GlobalKey<FormState> _formGroceryBatchAdd = new GlobalKey<FormState>();

  List<GroceryItem> _groceryItems = [];
  String _totalItems = '';
  GroceryItem _formGroceryData = new GroceryItem();
  String _formBatchGroceryData = '';
  BuildContext _context;

  void _showSnackBar(String text) {
    Scaffold.of(this._context).showSnackBar(SnackBar(content: new Text(text)));
  }

  void _addGroceryItem(String title, int amount) {
    setState(() { 
      this._groceryItems.add(new GroceryItem(title: title, amount: amount, purchased: false));
      this._groceryListSort();
      this._updateItemCount();

      this._saveDb();
    });
  }

  void _addGroceryItemObject(GroceryItem item) {
    setState(() { 
      this._groceryItems.add(item);
      this._groceryListSort();
      this._updateItemCount();

      this._saveDb();
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

      this._saveDb();
    });
  }

  void _removeGroceryItem(int index) {
    setState(() { 
      this._groceryItems.removeAt(index); 
      this._updateItemCount();

      this._saveDb();
    });
  }

  void _removeGroceryList() {
    setState(() { 
      this._groceryItems.clear();
      this._updateItemCount();

      this._saveDb();
    });
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

  void _updateItemCount() {
    this._totalItems = (this._groceryItems.length != 0 ? this._groceryItems.length : '').toString();
  }

  void _saveDb() {
      db.data['data'] = this._groceryItems.map((item) => item.toMap()).toList();

      debug(db.data);

      db.writeDb();
  }

  bool _saveGroceryForm([ dynamic item = false ]) {
    var grocery;

    if (!this._formGroceryAdd.currentState.validate()) {
      return false;
    }
    
    this._formGroceryAdd.currentState.save();

    grocery = this._formGroceryData;

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

  bool _saveGroceryBatchForm() {
    Iterable<GroceryItem> groceryList;
    if (!this._formGroceryBatchAdd.currentState.validate()) {
      return false;
    }

    this._formGroceryBatchAdd.currentState.save();

    groceryList = this._formBatchGroceryData.split('\n').where((item) => item.toString().trim().isNotEmpty).map((item) {
      List<String> groceryData = item.split(':').map((item) => item.toString().trim()).toList();

      GroceryItem grocery = new GroceryItem(title: groceryData[0]);
      if (groceryData.length > 1) {
        grocery.amount = isNumeric(groceryData.last) ? int.parse(groceryData.last) : 1;
      } else {
        grocery.amount = 1;
      }

      return grocery;
    });

    groceryList.forEach((GroceryItem item) {
      this._addGroceryItemObject(item);
    });

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

  void _pushAddBatchScreen() {
    Navigator.of(context).push(
      new MaterialPageRoute(
        builder: (context) {
          return new Scaffold(
            appBar: new AppBar(
              title: new Text('Add new Grocery List'),
              actions: <Widget>[
                  new IconButton(
                    icon: new Icon(Icons.delete),
                    tooltip: 'Clear Grocery List',
                    onPressed: () {
                      this._promptRemoveGroceryBatchList();
                    },
                  ),
              ]
            ),
            body: new Container(
              padding: const EdgeInsets.all(5.0),
              child: this._buildGroceryBatchFormComponent()
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

  void _promptRemoveGroceryBatchList() {
    // TODO: add check to not show prompt if list is empty.
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
                this._formGroceryBatchAdd.currentState.reset();
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

  Form _buildGroceryBatchFormComponent() {
    return new Form(
      key: this._formGroceryBatchAdd,
      child: new ListView(
        children: <Widget>[
          new Container(
            child: new Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // TODO: find a way to show text label in the top, if the field isn't focused
                new TextFormField(
                  maxLines: 20,
                  autofocus: true,
                  decoration: new InputDecoration(
                    labelText: 'Item List',
                    hintText: 'Enter a grocery list',
                    contentPadding: const EdgeInsets.all(16.0)
                  ),
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Please enter at least one grocery item';
                    }
                  },
                  onSaved: (value) {
                    this._formBatchGroceryData = value;
                  },
                ),
                new Padding(
                  padding: new EdgeInsets.all(8.0),
                  child: new Text(
                    'One item per line. Use ":" to specifcy the amount.\n' +
                    'Example:\n' +
                    'Potatoes:12\n' +
                    'Tomatoes:6',
                    style: new TextStyle(fontSize: 12.0, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
          new Container(
            child: new ButtonBar(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                new RaisedButton(
                  child: new Text('Add Items'),
                  color: Theme.of(context).primaryColor,
                  textColor: Colors.white,
                  elevation: 4.0,
                  onPressed: () {
                    if (this._saveGroceryBatchForm()) {
                      Navigator.pop(context);
                    }
                  },
                ),
                new RaisedButton(
                  child: new Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ] 
            ),
          ),
        ]
      )
    );
  }

  // WIDGETS --------------------------------------------------------------------------------------

  @override
  initState() {
    super.initState();

    db.readDb().then((db) {
      List data = db['data'].map((item) { 
        GroceryItem grocery = new GroceryItem(); 

        grocery.id = item['id'];
        grocery.uuid = item['uuid'];
        grocery.title = item['title'];
        grocery.purchased = !!item['purchased'];
        grocery.amount = item['amount'];

        return grocery;
      }).toList();

      setState(() {
        this._groceryItems = List.from(data);

        this._groceryListSort();
        this._updateItemCount();
      });
    });

    // new Future<String>.delayed(new Duration(seconds: 5), () => '["123", "456", "789"]').then((String value) {
    //   setState(() {
    //     data = json.decode(value);
    //   });
    // });
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
    Color itemColor = !item.purchased ? Theme.of(context).textTheme.title.color : Colors.black45;

    return new Slidable(
      delegate: new SlidableDrawerDelegate(),
      actionExtentRatio: 0.25,
      child: new Container(
        color: Colors.white,
        child: new CheckboxListTile(
          title: new Text(
            item.title,
            style: new TextStyle(color: itemColor)
          ),
          subtitle: new Text('Amount: ${item.amount}'),
          value: item.purchased,
          onChanged: (bool value) {
            setState(() { 
              item.markAsPurchased(value); 
              if (value) {
                itemColor = Colors.black45;
                this._removeGroceryItem(index);
                this._addGroceryItemObject(item);
              } else {
                itemColor = Theme.of(context).textTheme.title.color;
                this._removeGroceryItem(index);
                int newIndex;

                if (this._groceryItems.isNotEmpty) {
                  for (newIndex = 0; newIndex < this._groceryItems.length; newIndex++) {
                    if (this._groceryItems[newIndex].purchased) {
                      newIndex;
                      break;
                    }
                  }
                } else {
                  newIndex = 0;
                }

                splice(
                  this._groceryItems, 
                  newIndex, 
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

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('My Grocery List'),
        leading: new Padding(
          padding: EdgeInsets.fromLTRB(15.0, 10.0, 0.0, 0.0),
          child: this._totalItems.isNotEmpty ? 
            Badge.before(
              value: this._totalItems.padLeft(2, '0'),
              child: new Text(''),
              color: Colors.white,
              textStyle: new TextStyle( color: Theme.of(context).primaryColor ),
              borderColor: Colors.transparent,
            ) : 
            null,
        ),
        actions: <Widget>[
            new IconButton(
              icon: new Icon(Icons.delete),
              tooltip: 'Clear Grocery List',
              onPressed: () {
                this._promptRemoveGroceryList();
              },
            ),
        ]
      ),
      body: Builder(
        builder: (context) {
          this._context = context;
          this._updateItemCount();

          return this._buildGroceryList();
        }
      ),
      floatingActionButton: new GestureDetector(
        onLongPress: _pushAddBatchScreen,
        onTap: _pushAddScreen,
        child: new FloatingActionButton(
          onPressed: null,
          child: new Icon(Icons.add)
        ),
      )
    );
  }
}

// /WIDGETS ---------------------------------------------------------------------------------------

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