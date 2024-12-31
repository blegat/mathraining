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
    
    var text = this.input.value.
    replace(/</g,'&lt;').
    replace(/>/g,'&gt;').
    replace(/&lt;b&gt;(.*?)&lt;\/b&gt;/gsmi, '<b>$1</b>').
    replace(/&lt;u&gt;(.*?)&lt;\/u&gt;/gsmi, '<u>$1</u>').
    replace(/&lt;i&gt;(.*?)&lt;\/i&gt;/gsmi, '<i>$1</i>').
    replace(/&lt;hr&gt;/g, '<hr>').
    replace(/<hr>[ \r]*\n/g,'<hr>').
    replace(/&lt;h2&gt;(.*?)&lt;\/h2&gt;/gsmi, '<h2>$1</h2>').
    replace(/&lt;h3&gt;(.*?)&lt;\/h3&gt;/gsmi, '<h3>$1</h3>').
    replace(/&lt;h4&gt;(.*?)&lt;\/h4&gt;/gsmi, '<h4>$1</h4>').
    replace(/&lt;h5&gt;(.*?)&lt;\/h5&gt;/gsmi, '<h5>$1</h5>').
    replace(/\n[ \r]*<h2>/g,'<h2 class="mt-3">').
    replace(/\n[ \r]*<h3>/g,'<h3 class="mt-3">').
    replace(/\n[ \r]*<h4>/g,'<h4 class="mt-3">').
    replace(/\n[ \r]*<h5>/g,'<h5 class="mt-3">').
    replace(/<\/h2>[ \r]*\n/g,'</h2>').
    replace(/<\/h3>[ \r]*\n/g,'</h3>').
    replace(/<\/h4>[ \r]*\n/g,'</h4>').
    replace(/<\/h5>[ \r]*\n/g,'</h5>').
    replace(/&lt;ol&gt;/gsmi, '<ol>').
    replace(/&lt;ol (.*?)&gt;/gsmi, '<ol $1>').
    replace(/&lt;ul&gt;/gsmi, '<ul>').
    replace(/&lt;ul (.*?)&gt;/gsmi, '<ul $1>').
    replace(/&lt;li&gt;/gsmi, '<li>').
    replace(/&lt;li (.*?)&gt;/gsmi, '<li $1>').
    replace(/&lt;\/ol&gt;/gsmi, '</ol>').
    replace(/&lt;\/ul&gt;/gsmi, '</ul>').
    replace(/&lt;\/li&gt;/gsmi, '</li>').
    replace(/<ol/g, '<ol class="my-1"').
    replace(/<ul/g, '<ul class="my-1"').
    replace(/<\/ol>[ \r]*\n/g, '</ol>').
    replace(/\n[ \r]*<\/ol>/g, '</ol>').
    replace(/<\/ul>[ \r]*\n/g, '</ul>').
    replace(/\n[ \r]*<\/ul>/g, '</ul>').
    replace(/\n[ \r]*<li/g, '<li').
    replace(/&lt;result&gt;(.*?)&lt;statement&gt;(.*?)&lt;\/result&gt;/gsmi, '<result>$1<statement>$2</result>').
    replace(/&lt;proof&gt;(.*?)&lt;statement&gt;(.*?)&lt;\/proof&gt;/gsmi, '<proof>$1<statement>$2</proof>').
    replace(/&lt;remark&gt;(.*?)&lt;statement&gt;(.*?)&lt;\/remark&gt;/gsmi, '<remark>$1<statement>$2</remark>').
    replace(/<result>[ \r]*\n/g, '<result>').
    replace(/<\/result>[ \r]*\n/g, '</result>').
    replace(/<proof>[ \r]*\n/g, '<proof>').
    replace(/<\/proof>[ \r]*\n/g, '</proof>').
    replace(/<remark>[ \r]*\n/g, '<remark>').
    replace(/<\/remark>[ \r]*\n/g, '</remark>').
    replace(/<statement>[ \r]*\n/g, '<statement>').
    replace(/<result>(.*?)<statement>(.*?)<\/result>/gsmi, "<div class='result-title'>$1</div><div class='result-content'>$2</div>").
    replace(/<proof>(.*?)<statement>(.*?)<\/proof>/gsmi, "<div class='proof-title'>$1</div><div class='proof-content'>$2</div>").
    replace(/<remark>(.*?)<statement>(.*?)<\/remark>/gsmi, "<div class='remark-title'>$1</div><div class='remark-content'>$2</div>").
    replace(/&lt;indice&gt;(.*?)&lt;\/indice&gt;/gsmi, '<indice>$1</indice>').
    replace(/<\/indice>[ \r]*\n/g, '</indice>').
    replace(/<indice>(.*?)<\/indice>/g, "<div class='clue-bis'><div><a href='#' onclick='return false;' class='btn btn-light'>Indice</a></div><div id='indice0' class='clue-hide' style='height:auto;!important;'><div class='clue-content'>$1</div></div></div>").
    replace(/&lt;center&gt;(.*?)&lt;\/center&gt;/gsmi, '<center>$1</center>').
    replace(/&lt;img (.*?)\/&gt;/gsmi, '<img $1/>').
    replace(/&lt;a (.*?)&gt;(.*?)&lt;\/a&gt;/gsmi, '<a $1>$2</a>').
    replace(/&lt;div (.*?)&gt;(.*?)&lt;\/div&gt;/gsmi, '<div $1>$2</div>').
    replace(/&lt;span (.*?)&gt;(.*?)&lt;\/span&gt;/gsmi, '<span $1>$2</span>').
    replace(/\n/g, '<br/>')
    
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

export default Preview
