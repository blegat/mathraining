var LeavingForm = {
  //
  // Initialize stuff to ask confirmation before leaving the page
  //
  Init: function (s) {
    if (s == undefined)
      s = "";
    this.input = document.getElementById("MathInput" + s);
    
    this.input.form.onsubmit = function() {
      LeavingForm.SetFormSubmitting();
    };
    
    window.formSubmitting = false;
    window.originalText = this.input.value
    window.changesDone = false;
    
    window.onload = function() {
      window.addEventListener("beforeunload", LeavingForm.AskConfirmationIfNeeded);
    };
  },
  
  //
  // Specify that we are submitting a form, to avoid the warning when sending the form
  //
  SetFormSubmitting: function() {
    window.formSubmitting = true;
  },
  
  //
  // Specify that changes were done in the text
  //
  SetChangesDone: function() {
    window.changesDone = (window.originalText != this.input.value);
  },
  
  //
  // Ask confirmation if leaving the page with some changes
  //
  AskConfirmationIfNeeded: function(e) {
    if (window.formSubmitting || !window.changesDone) {
      return undefined;
    }
    
    var msg = 'Attention ! Vous perdrez votre texte en quittant cette page.';
    (e || window.event).returnValue = msg;
    return msg;
  }
};

export default LeavingForm
