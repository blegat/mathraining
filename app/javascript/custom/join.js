// Fonction pour les pièces jointes
var Joint = {
  postfixes: [],
  nextids: [],
  add: function(postfix) {

    if (postfix == undefined)
    {
      postfix = ""
    }

    //Create an input type dynamically.
    var element = document.createElement("input");
    var element2 = document.createElement("input");
    
    //Find next id for this postfix
    var index = this.postfixes.indexOf(postfix);
    var id = 1;
    if (index == -1)
    {
      this.postfixes.push(postfix)
      this.nextids.push(2)
    }
    else
    {
      id = this.nextids[index]
      this.nextids[index] = id+1
    }

    //Assign different attributes to the element.
    element.setAttribute("type", "file");
    element.setAttribute("name", "file"+postfix+"_"+id);
    element.setAttribute("class", "form-control mb-1");

    element2.setAttribute("type", "hidden");
    element2.setAttribute("name", "hidden"+postfix+"_"+id);
    element2.setAttribute("value", "ok");

    var div = document.getElementById("divFiles"+postfix);
    
    document.getElementById("allowedFiles"+postfix).style.display = 'block';
    
    //Append the element in page (in div).
    div.appendChild(element2);
    div.appendChild(element);
  }
};

/* Does not work on Safari
class JointClass extends HTMLInputElement {
  constructor() { super(); }
  connectedCallback() {
  this.addEventListener("click", e => {
      e.preventDefault();
      var postfix = "";
      if (this.hasAttribute("data-postfix")) {
        postfix = this.dataset.postfix;
      }
      Joint.add(postfix);
      return false;
    });
  }
}

customElements.define("joint-onclick", JointClass, { extends: "input" });
*/

export default Joint
