// Fonction pour subjects/show
var Rolling = {
  actual: null,
  rollingTime: 1000,
  
  hideActual: function() {
    if(this.actual != null) {
      $("#form" + this.actual).animate({height:'0px'}, this.rollingTime);
      var el = $("#the" + this.actual);
      var autoHeight = el.css('height', 'auto').height();
      el.height(0).animate({height:autoHeight}, this.rollingTime, function(){el.height('auto');});
      this.actual = null;
    }
    return false;
  },

  develop: function(m) {
    this.hideActual();
    this.actual = m;
    $("#the" + m).animate({height:'0px'}, this.rollingTime);
    var el = $("#form" + m);
    var autoHeight = el.css('height', 'auto').height();
    el.height(0).animate({height:autoHeight}, this.rollingTime, function(){
      el.height('auto');
      var body = $('body,html');
      var yyy = document.getElementById("form" + m).offsetTop - 50;
      body.animate({scrollTop:yyy}, this.rollingTime/2);
      PreviewSafe.Init(m);
      PreviewSafe.Update();
    });
    return false;
  },

  develop_quick: function(m) {
    this.actual = m;
    $("#the" + m).height(0);
    $("#form" + m).height('auto');
    var body = $('body,html');
    MathJax.Hub.Queue(function () {
      var yyy = document.getElementById("form" + m).offsetTop - 40;
      body.scrollTop(yyy);
      PreviewSafe.Init(m);
      PreviewSafe.Update();
    });
  },

  showus: function(m) {
    var body = $('body,html');
    MathJax.Hub.Queue(function () {
      var yyy = document.getElementById("the" + m).offsetTop - 40;
      body.scrollTop(yyy);
    });
  }
};

export default Rolling
