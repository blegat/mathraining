// Fonction pour les pièces jointes
var Joint = {
  i: 1,
  add: function() {

    //Create an input type dynamically.
    var element = document.createElement("input");
    var element2 = document.createElement("input");

    //Assign different attributes to the element.
    element.setAttribute("type", "file");
    element.setAttribute("name", "file"+this.i);
    
    element2.setAttribute("type", "hidden");
    element2.setAttribute("name", "hidden"+this.i);
    element2.setAttribute("value", "ok");
 
    var foo = document.getElementById("fooBar");
    var br = document.createElement("br");

    if(this.i == 1)
    {
      var avert = document.createElement("p");
      var bold = document.createElement("b");
      var text = document.createTextNode("Taille totale autorisée : 10 Mo. Type de fichiers autorisés : zip, pdf, doc, gif, jpg, png, bmp, txt.");
      bold.appendChild(text);
      avert.appendChild(bold);
      foo.appendChild(avert);
      foo.appendChild(br);
    }

    this.i = this.i+1;

    //Append the element in page (in span).
    foo.appendChild(element2);
    foo.appendChild(element);
    foo.appendChild(br);
  }
};
