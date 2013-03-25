  function countInstances(open,closed) 
  { 
     var opening = document.hop.contenu.value.split(open); 
     var closing = document.hop.contenu.value.split(closed); 
     return opening.length + closing.length - 2; 
  } 

  function TAinsert(text1,text2,contenu) 
  { 

     var ta = document.getElementById(contenu); 

     if (document.selection) { 
	
        var str = document.selection.createRange().text; 
        ta.focus(); 
		  
        var sel = document.selection.createRange(); 
        if (text2!="") 
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
        var secondPos = ta.selectionEnd+text1.length; 
       
        ta.value=ta.value.slice(0,firstPos)+text1+ta.value.slice(firstPos); 
        ta.value=ta.value.slice(0,secondPos)+text2+ta.value.slice(secondPos); 
         
        ta.selectionStart = firstPos+text1.length; 
        ta.selectionEnd = secondPos; 
        ta.focus(); 
     } 
     else 
     { // Opera 
        var sel = document.hop.contenu; 
       
        var instances = countInstances(text1,text2); 
        if (instances%2 != 0 && text2 != ""){ sel.value = sel.value + text2; } 
        else{ sel.value = sel.value + text1; } 
     }  
  }
