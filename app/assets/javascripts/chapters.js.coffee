# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

linkOld = (canvasContext, x1, y1) ->
  canvasContext.beginPath()
  canvasContext.arc(x1, y1, 100, Math.PI * 0/2, Math.PI * 2/2)
  canvasContext.lineWidth = 12
  canvasContext.lineCap = 'round'
  canvasContext.strokeStyle = 'rgba(255, 127, 0, 0.5)'
  canvasContext.stroke()

link = (canvasContext, x1, y1, x2, y2) ->
  canvasContext.moveTo(x1, y1)
  canvasContext.lineTo(x2, y2)
  canvasContext.lineWidth = 12
  canvasContext.lineCap = 'round'
  canvasContext.strokeStyle = 'rgba(255, 127, 0, 0.5)'
  canvasContext.stroke()


#$(document).ready ->
$ ->
  canvasContext = document.getElementById("prerequisite-canvas").getContext("2d")

  canvasContext.strokeText("Test",140,120); 
  link(canvasContext, 450, 110, 200, 100)
  link(canvasContext, 350, 210, 100, 200)
