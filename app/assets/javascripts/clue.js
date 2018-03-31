var Clue = {
  open: new Set(),
  
  toggle: function(id) {
    var el = $("#indice" + id);
    if(this.open.has(id)) {
      this.open.delete(id);
      el.animate({height:0}, 300);
    }
    else {
      this.open.add(id);
      var autoHeight = el.css('height', 'auto').height();
      el.height(0).animate({height:autoHeight}, 300, function(){
        el.height('auto');
      });
    }
    return false;
  }
}
