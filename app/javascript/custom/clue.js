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
  }
}

class ClueClass extends HTMLButtonElement {
  constructor() { super(); }
  connectedCallback() {
  this.addEventListener("click", e => {
      e.preventDefault();
      Clue.toggle(this.dataset.textId);
      return false;
    });
  }
}

customElements.define("clue-onclick", ClueClass, { extends: "button" });
