var Info = {
  actual: false,
  toggle: function() {
    var inf = $("#information");
    if(this.actual) {
      inf.animate({height:0}, 500);
    }
    else {
      var autoHeight = inf.css('height', 'auto').height();
      inf.height(0).animate({height:autoHeight}, 500, function(){
        inf.height('auto');
      });
    }
    this.actual = !this.actual;
    return false;
  }
}

/* Does not work on Safari
class InfoClass extends HTMLButtonElement {
  constructor() { super(); }
  connectedCallback() {
  this.addEventListener("click", e => {
      e.preventDefault();
      Info.toggle();
      return false;
    });
  }
}

customElements.define("info-onclick", InfoClass, { extends: "button" });
*/

export default Info
