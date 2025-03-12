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
  Init: function (s) {
    if (s == undefined) {
      s = "";
    }
    this.preview = document.getElementById("MathPreview" + s);
    this.buffer = document.getElementById("MathBuffer" + s);
    this.input = document.getElementById("MathInput" + s);
    this.stop = document.getElementById("stop" + s);
    this.safe = true;
    this.bbcode = true;
    this.hiddentext = true;
    this.indice = false;
  },

  //
  //  Say if 'safe' preview (for users with bbcode) must be used or not
  //
  SetSafe: function (v) {
    this.safe = v;
  },

  //
  //  Say if bbcode must be processed or not (in LaTeX chapter we don't allow bbcode)
  //
  SetBBCode: function (v) {
    this.bbcode = v;
  },
  
  //
  //  Say if [hide="Texte caché"]...[/hide] must be processed or not
  //
  SetHiddenText: function (v) {
    this.hiddentext = v;
  },
  
  //
  //  Say if 'indice' must be processed or not (only for questions)
  //
  SetIndice: function (v) {
    this.indice = v;
  },

  //
  //  Switch the buffer and preview, and display the right one.
  //  (We use visibility:hidden rather than display:none since
  //  the results of running MathJax are more accurate that way.)
  //
  SwapBuffers: function () {
    var buffer = this.preview, preview = this.buffer;
    this.buffer = buffer; this.preview = preview;
    var oldHeight = buffer.offsetHeight;
    var oldScroll = $(window).scrollTop();
    buffer.classList.add("hidden-latex");
    preview.classList.remove("hidden-latex");
    var newHeight = preview.offsetHeight; // Must be done after removing hidden-latex!
    if (Math.abs(newHeight - oldHeight) > 1) {
      window.scrollTo(0, oldScroll+newHeight-oldHeight);
    }
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
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
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
    
    var text = this.input.value
    if (this.safe) {
      // The following should be similar to what we have in bbcode (in application_helper.rb)
      text = text.
      replace(/&/g, '&amp;').
      replace(/</g, '&lt;').
      replace(/>/g, '&gt;').
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
    }
    else {
      // The following should be similar to what we have in htmlise (in application_helper.rb)
      text = text.
      replace(/&/g, '&amp;').
      replace(/</g, '&lt;').
      replace(/>/g, '&gt;').
      replace(/\\\][ \r]*\n/g, '\\\] ').
      replace(/\$\$[ \r]*\n/g, '$$$ ').
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
      replace(/&lt;center&gt;(.*?)&lt;\/center&gt;/gsmi, '<center>$1</center>').
      replace(/&lt;img (.*?)\/&gt;/gsmi, '<img $1/>').
      replace(/&lt;a (.*?)&gt;(.*?)&lt;\/a&gt;/gsmi, '<a $1>$2</a>').
      replace(/&lt;div (.*?)&gt;(.*?)&lt;\/div&gt;/gsmi, '<div $1>$2</div>').
      replace(/&lt;span (.*?)&gt;(.*?)&lt;\/span&gt;/gsmi, '<span $1>$2</span>').
      replace(/\n/g, '<br/>')
    
      if (this.indice) {
        text = text.
        replace(/&lt;indice&gt;(.*?)&lt;\/indice&gt;/gsmi, '<indice>$1</indice>').
        replace(/<\/indice>[ \r]*<br\/>/g, '</indice>').
        replace(/<indice>(.*?)<\/indice>/g, "<div class='clue-bis'><div><a href='#' onclick='return false;' class='btn btn-light'>Indice</a></div><div id='indice0' class='clue-hide' style='height:auto;!important;'><div class='clue-content'>$1</div></div></div>")
      }
    }
    
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
    if (this.needUpdate) {
      this.CreatePreview();
    }
  },
  
  MyUpdate: function() {
  LeavingForm.SetChangesDone();
  if (this.stop.checked) {
    this.Update();
  }
}

};

//
//  Cache a callback to the CreatePreview action
//
Preview.callback = MathJax.Callback(["CreatePreview", Preview]);
Preview.callback.autoReset = true;  // make sure it can run more than once

export default Preview
