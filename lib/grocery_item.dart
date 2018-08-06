class GroceryItem {
  String title;
  bool purchased = false;
  int id = 0;
  int amount;
  int uuid;

  void markAsPurchased(bool purchased) {
    this.purchased = purchased;
  }

  void reset() {
    this.id = 0;
    this.title = '';
    this.purchased = false;
    this.amount = 0;
    this.uuid = 0;
  }

  Map toMap() {
    Map map = { 
      'id': this.id, 
      'title': this.title, 
      'amount': this.amount, 
      'purchased': this.purchased, 
      'uuid': this.uuid,
    };
    
    return map;
  }

  GroceryItem({ this.title, this.purchased, this.amount }) {
    this.id = 0;
    this.uuid = this.hashCode;
    if (this.purchased == null) {
      this.purchased = false;
    }
    if (this.amount == null) {
      this.amount = 1;
    }
  }
}