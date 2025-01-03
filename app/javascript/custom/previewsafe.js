var PreviewSafe = {
  delay: 150,        // delay after keystroke before updating

  preview: null,     // filled in by Init below
  buffer: null,      // filled in by Init below

  timeout: null,     // store setTimout id
  mjRunning: false,  // true when MathJax is processing
  needUpdate: false, // true when MathJax needs to re-run
  oldText: null,     // used to check if an update is needed

  //
  //  Get the preview and buffer DIV's
  //
  Init: function (s) {
    if (s == undefined)
      s = "";
    this.preview = document.getElementById("MathPreview" + s);
    this.buffer = document.getElementById("MathBuffer" + s);
    this.input = document.getElementById("MathInput" + s);
    this.stop = document.getElementById("stop" + s);
    this.bbcode = true
    this.hiddentext = true
  },
  
  //
  //  Say if bbcode must be processed or not (in LaTeX chapter we don't allow bbcode)
  //
  SetBBCode: function (v) {
    this.bbcode = v
  },
  
  //
  //  Say if [hide="Texte caché"]...[/hide] must be processed or not
  //
  SetHiddenText: function (v) {
    this.hiddentext = v
  },

  //
  //  Switch the buffer and preview, and display the right one.
  //  (We use visibility:hidden rather than display:none since
  //  the results of running MathJax are more accurate that way.)
  //
  SwapBuffers: function () {
    var buffer = this.preview, preview = this.buffer;
    this.buffer = buffer; this.preview = preview;
    buffer.classList.add("hidden-preview");
    preview.classList.remove("hidden-preview");
  },

  //
  //  This gets called when a key is pressed in the textarea.
  //  We check if there is already a pending update and clear it if so.
  //  Then set up an update to occur after a small delay (so if more keys
  //    are pressed, the update won't occur until after there has been
  //    a pause in the typing).
  //  The callback function is set up below, after the Preview object is set up.
  //
  Update: function () {
    if (this.timeout) {clearTimeout(this.timeout)}
    this.timeout = setTimeout(this.callback,this.delay);
  },

  //
  //  Creates the preview and runs MathJax on it.
  //  If MathJax is already trying to render the code, return
  //  If the text hasn't changed, return
  //  Otherwise, indicate that MathJax is running, and start the
  //    typesetting.  After it is done, call PreviewDone.
  //
  CreatePreview: function () {
    Preview.timeout = null;
    if (this.mjRunning) {
      this.needUpdate = true;
      return;
    }

    // The following should be similar to what we have in bbcode (in application_helper.rb)
    var text = this.input.value.
    replace(/&/g, '&amp;').
    replace(/</g, '&lt').
    replace(/>/g, '&gt').
    replace(/"/g, '&quot;').
    replace(/'/g, '&#39;').
    replace(/\\\][ \r]*\n/g, '\\\] ').
    replace(/\$\$[ \r]*\n/g, '$$$ ')
    
    if (this.bbcode) { // false only for LaTeX chapter (that's why there is no such variable in method bbcode)
      text = text.
      replace(/\[b\]((.|\n)*?)\[\/b\]/gmi, '<b>$1</b>').
      replace(/\[u\]((.|\n)*?)\[\/u\]/gmi, '<u>$1</u>').
      replace(/\[i\]((.|\n)*?)\[\/i\]/gmi, '<i>$1</i>').
      replace(/\[url=(?:&quot;)?(.*?)(?:&quot;)?\](.*?)\[\/url\]/gmi, '<a target=\'blank\' href=\'$1\'>$2</a>');
      
      if (this.hiddentext) { // Only true for messages in Forum (no such variable in method bbcode because people could use <hide> in submissions before)
        var reg = /\[hide=(?:&quot;)?(.*?)(?:&quot;)?\][ \r\n]*((.|\n)*?)[ \r\n]*\[\/hide\]/gmi;
        while (reg.test(text)) {
          text = text.replace(/\[hide=(?:&quot;)?(.*?)(?:&quot;)?\][ \r\n]*((.|\n)*?)[ \r\n]*\[\/hide\]/gmi, "<div class='clue'><div><button onclick='return false;' class='btn btn-light'>$1</button></div><div class='clue-hide' style='height:auto;!important;'><div class='clue-content'>$2</div></div></div>");
        }
      }
      
      var smileys = [];
      for (let i = 1; i <= 9; i++) {
        smileys[i] = "<img src='" + document.getElementById("smiley" + i.toString() + "-img").getAttribute("src") + "' width='20px' height='20px' />";
      }
      text = text.
      replace(/\:\-\)/g,    smileys[1]).
      replace(/\:\-\(/g,    smileys[2]).
      replace(/\:\-[D]/g,   smileys[3]).
      replace(/\:\-[O]/g,   smileys[4]).
      replace(/\:\-[P]/g,   smileys[5]).
      replace(/\:&#39;\(/g, smileys[6]).
      replace(/\;\-\)/g,    smileys[7]).
      replace(/\:\-\|/g,    smileys[8]).
      replace(/[3]\:\[/g,   smileys[9]);
    }
    
    text = text.replace(/\n/g, '<br/>')

    if (text === this.oldtext) return;
    this.buffer.innerHTML = this.oldtext = text;
    this.mjRunning = true;
    this.needUpdate = false;
    MathJax.Hub.Queue(
      ["Typeset",MathJax.Hub,this.buffer],
      ["PreviewDone",this]
    );
  },

  //
  //  Indicate that MathJax is no longer running,
  //  and swap the buffers to show the results.
  //
  PreviewDone: function () {
    this.mjRunning = false;
    this.SwapBuffers();
    if(this.needUpdate) this.CreatePreview();
  },
  
  MyUpdate: function(){
  LeavingForm.SetChangesDone();
  if (this.stop.checked){
    this.Update();
  }
}

};

//
//  Cache a callback to the CreatePreview action
//
PreviewSafe.callback = MathJax.Callback(["CreatePreview", PreviewSafe]);
PreviewSafe.callback.autoReset = true;  // make sure it can run more than once

export default PreviewSafe
