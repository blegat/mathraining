var Clue = {
  open: [],
  
  toggle: function(id) {
    var el = $("#indice" + id);
    if(this.open.includes(id)) {
      this.open.splice(this.open.indexOf(id)); // Remove id from this.open
      el.animate({height:0}, 300);
    }
    else {
      this.open.push(id);
      var autoHeight = el.css('height', 'auto').height();
      el.height(0).animate({height:autoHeight}, 300, function(){
        el.height('auto');
      });
    }
    return false;
  }
}
