var Preview = {
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
  Init: function () {
    this.preview = document.getElementById("MathPreview");
    this.buffer = document.getElementById("MathBuffer");
    this.input = document.getElementById("MathInput");
    this.stop = document.getElementById('stop');
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
    if (this.mjRunning)
    {
      this.needUpdate = true;
      return;
    }
    var text = this.input.value.replace(/<hr>[ \r]*\n/g,'<hr>').replace(/\][ \r]*\n/g,'\] ').replace(/\$\$[ \r]*\n/g,'$$$ ').replace(/<\/h2>[ \r]*\n/g,'</h2>').replace(/<\/h3>[ \r]*\n/g,'</h3>').replace(/<\/h4>[ \r]*\n/g,'</h4>').replace(/<\/ol>[ \r]*\n/g, '</ol>').replace(/\n[ \r]*<\/ol>/g, '</ol>').replace(/<\/ul>[ \r]*\n/g, '</ul>').replace(/\n[ \r]*<\/ul>/g, '</ul>').replace(/\n(\040)*<li>/g, '<li>').replace(/<evidence>[ \r]*\n/g, '<evidence>').replace(/<\/evidence>[ \r]*\n/g, '</evidence>').replace(/<evidence>/g, '<div class="evidence">').replace(/<\/evidence>/g, '</div>').replace(/<result>[ \r]*\n/g, '<result>').replace(/<\/result>[ \r]*\n/g, '</result>').replace(/<proof>[ \r]*\n/g, '<proof>').replace(/<\/proof>[ \r]*\n/g, '</proof>').replace(/<remark>[ \r]*\n/g, '<remark>').replace(/<\/remark>[ \r]*\n/g, '</remark>').replace(/<statement>[ \r]*\n/g, '<statement>').replace(/<\/indice>[ \r]*\n/g, '</indice>').replace(/\n/g, '<br/>').replace(/<result>(.*?)<statement>(.*?)<\/result>/g, "<div class='result-title'>$1</div><div class='result-content'>$2</div>").replace(/<proof>(.*?)<statement>(.*?)<\/proof>/g, "<div class='proof-title'>$1</div><div class='proof-content'>$2</div>").replace(/<remark>(.*?)<statement>(.*?)<\/remark>/g, "<div class='remark-title'>$1</div><div class='remark-content'>$2</div>").replace(/<indice>(.*?)<\/indice>/g, "<div class='clue-bis'><div><a href='#' onclick='return false;' class='btn btn-default btn-grey'>Indice</a></div><div id='indice0' class='clue-hide' style='height:auto;!important;'><div class='clue-content'>$1</div></div></div>")
    
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
    if(this.needUpdate)
    this.CreatePreview();
  },
  
  MyUpdate: function() {
  if (this.stop.checked){
    this.Update();
  }
}

};

//
//  Cache a callback to the CreatePreview action
//
Preview.callback = MathJax.Callback(["CreatePreview",Preview]);
Preview.callback.autoReset = true;  // make sure it can run more than once
