
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
    var text = document.getElementById("MathInput").value.replace(/<hr>[ \r]*\n/g,'<hr>').replace(/\][ \r]*\n/g,'\] ').replace(/\$\$[ \r]*\n/g,'$$$ ').replace(/<\/h2>[ \r]*\n/g,'</h2>').replace(/<\/h3>[ \r]*\n/g,'</h3>').replace(/<\/h4>[ \r]*\n/g,'</h4>').replace(/<\/ol>[ \r]*\n/g, '</ol>').replace(/\n[ \r]*<\/ol>/g, '</ol>').replace(/<\/ul>[ \r]*\n/g, '</ul>').replace(/\n[ \r]*<\/ul>/g, '</ul>').replace(/\n(\040)*<li>/g, '<li>').replace(/<evidence>[ \r]*\n/g, '<evidence>').replace(/<\/evidence>[ \r]*\n/g, '</evidence>').replace(/<evidence>/g, '<div class="evidence">').replace(/<\/evidence>/g, '</div>').replace(/\n/g, '<br/>');
    if (text === this.oldtext) return;
    this.buffer.innerHTML = this.oldtext = text;
    this.mjRunning = true;
    this.needUpdate = false;
    MathJax.Hub.Queue(
      ["Typeset",MathJax.Hub,this.buffer],
      ["PreviewDone",this]
    );
  },

  // var text = document.getElementById("MathInput").value.replace(/\n/g, '<br/>');


  //
  //  Indicate that MathJax is no longer running,
  //  and swap the buffers to show the results.
  //
  PreviewDone: function () {
    this.mjRunning = false;
    this.SwapBuffers();
    if(this.needUpdate)
    this.CreatePreview();
  }

};

//
//  Cache a callback to the CreatePreview action
//
Preview.callback = MathJax.Callback(["CreatePreview",Preview]);
Preview.callback.autoReset = true;  // make sure it can run more than once

function fakeupdate(){
  var stop = document.getElementById('stop');
  if (stop.checked){
    Preview.Update();
  }
}
