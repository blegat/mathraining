var ShowHideCode = {
  showCode: function(id) {
    document.getElementById("anormal" + id).style.display = 'block';
    document.getElementById("normal" + id).style.display = 'none';
  },
  
  hideCode: function(id) {
    document.getElementById("normal" + id).style.display = 'block';
    document.getElementById("anormal" + id).style.display = 'none';
  }
}

class ShowCodeClass extends HTMLAnchorElement {
  constructor() { super(); }
  connectedCallback() {
  this.addEventListener("click", e => {
      e.preventDefault();
      ShowHideCode.showCode(this.dataset.textId);
      return false;
    });
  }
}

class HideCodeClass extends HTMLAnchorElement {
  constructor() { super(); }
  connectedCallback() {
  this.addEventListener("click", e => {
      e.preventDefault();
      ShowHideCode.hideCode(this.dataset.textId);
      return false;
    });
  }
}

customElements.define("showcode-onclick", ShowCodeClass, { extends: "a" });
customElements.define("hidecode-onclick", HideCodeClass, { extends: "a" });
