function showAnormal(id) {
    document.getElementById("anormal" + id).style.display = 'inline';
    document.getElementById("normal" + id).style.display = 'none';
    return false;
}
function showNormal(id) {
    document.getElementById("normal" + id).style.display = 'inline';
    document.getElementById("anormal" + id).style.display = 'none';
    return false;
}
