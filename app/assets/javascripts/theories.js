// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
// You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
//= require markdown.converter
//= require markdown.sanitizer
//= require markdown.editor
//= require mathjax-editing.js

/*function update_preview() {
  var content = $('#theory_content').val();
  var converter = new Showdown.converter();
  var render = converter.makeHtml(content);
  $('#preview').empty().append(render);
}

$(document).ready(function() {
  update_preview();
  $('#theory_content').keyup(function() {
    update_preview();
  });
});*/
$(document).ready(function () {
  var converter = Markdown.getSanitizingConverter();
  //Markdown.Extra.init(converter);
  var editor = new Markdown.Editor(converter);
  mathjaxEditing.prepareWmdForMathJax(editor,
    '',
    [['$']]);
  editor.run();
});
