var ShowCode = {
  showAnormal: function(id) {
    document.getElementById("anormal" + id).style.display = 'block';
    document.getElementById("normal" + id).style.display = 'none';
    return false;
  },
  
  showNormal: function(id) {
    document.getElementById("normal" + id).style.display = 'block';
    document.getElementById("anormal" + id).style.display = 'none';
    return false;
  }
}
