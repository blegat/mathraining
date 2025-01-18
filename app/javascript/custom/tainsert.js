var Insert = {
  insert: function(text1, text2, contenu) {
    var ta = document.getElementById(contenu);

    if (document.selection) {

      var str = document.selection.createRange().text;
      ta.focus();

      var sel = document.selection.createRange();
      
      if (text2 != "")
      {
        sel.text = text1 + sel.text + text2;
      }
      else
      {
        sel.text = sel.text + text1;
      }
    }
    else if (ta.selectionStart | ta.selectionStart == 0)
    {
      if (ta.selectionEnd > ta.value.length) { ta.selectionEnd = ta.value.length; }

      var firstPos = ta.selectionStart;
      var secondPos = ta.selectionEnd + text1.length;

      ta.value = ta.value.slice(0, firstPos) + text1 + ta.value.slice(firstPos);
      ta.value = ta.value.slice(0, secondPos) + text2 + ta.value.slice(secondPos);

      ta.selectionStart = firstPos + text1.length;
      ta.selectionEnd = secondPos;
      ta.focus();
    }
    else
    { // Opera (not sure this is working!?)
      var sel = document.hop.contenu;

      var instances = countInstances(text1, text2);
      if (instances % 2 != 0 && text2 != ""){ sel.value = sel.value + text2; }
      else { sel.value = sel.value + text1; }
    }
    ta.dispatchEvent(new Event('input')); // To trigger the update of Preview
  }
}

/* Does not work on Safari
class InsertClass extends HTMLAnchorElement {
  constructor() { super(); }
  connectedCallback() {
  this.addEventListener("click", e => {
      e.preventDefault();
      var l = "";
      if (this.hasAttribute("data-insert-left")) {
        l = this.dataset.insertLeft.replaceAll('\\n', '\n');
      }
      var r = "";
      if (this.hasAttribute("data-insert-right")) {
        r = this.dataset.insertRight.replaceAll('\\n', '\n');
      }
      var f = "MathInput";
      if (this.hasAttribute("data-postfix")) {
        f = "MathInput" + this.dataset.postfix;
      }
      Insert.insert(l, r, f);
      return false;
    });
  }
}

customElements.define("insert-onclick", InsertClass, { extends: "a" });
*/

export default Insert
