var ShowCode = {
  showAnormal: function(id) {
    document.getElementById("anormal" + id).style.display = 'inline';
    document.getElementById("normal" + id).style.display = 'none';
    return false;
  },
  
  showNormal: function(id) {
    document.getElementById("normal" + id).style.display = 'inline';
    document.getElementById("anormal" + id).style.display = 'none';
    return false;
  }
}
