$(function(){
  reticle = {}

  reticle.show = function(){
    $('.reticle-wrapper').fadeIn(250);
  };

  reticle.updateColor = function(color) {
    $("#circle").css("background", color || "rgb(255, 255, 255)")
  };

  reticle.hide = function() {
    $('.reticle-wrapper').fadeOut(250);
  };



  window.addEventListener('message', function(event) {
    switch(event.data.display) {
      case 'reticleShow':
		    reticle.show(event.data.mode);
      	break;
      case 'reticleHide':
		    reticle.hide(event.data);
      	break;
      case 'reticleColor':
		    reticle.updateColor(event.data.color);
      	break;
    }
  });
});