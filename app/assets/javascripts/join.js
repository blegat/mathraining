// Fonction pour les pièces jointes
var Joint = {
  postfixes: [],
  nextids: [],
  add: function(postfix) {

    if(postfix == undefined)
    {
      postfix = ""
    }

    //Create an input type dynamically.
    var element = document.createElement("input");
    var element2 = document.createElement("input");
    
    //Find next id for this postfix
    var index = this.postfixes.indexOf(postfix);
    var id = 1;
    if(index == -1)
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

    element2.setAttribute("type", "hidden");
    element2.setAttribute("name", "hidden"+postfix+"_"+id);
    element2.setAttribute("value", "ok");

    span = document.getElementById("spanFiles"+postfix);
    
    var br = document.createElement("br");

    if(id == 1)
    {      
      span.innerHTML = "<p style='margin-top:10px;'>Types de fichier autorisés : zip, pdf, doc, gif, jpg, png, bmp, txt.<br/>Taille maximale autorisée : 1 Mo par fichier, 5 Mo au total.<br/><b>(Pensez à compresser vos fichiers s'ils sont trop volumineux !)</b></p>";
    }

    //Append the element in page (in span).
    span.appendChild(element2);
    span.appendChild(element);
    span.appendChild(br);
  }
};
