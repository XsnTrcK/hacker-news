(() => {
  var atEndX = false;
  var atBeginningX = true;
  var scrollHandled = false;

  const handleXScroll = () => {
    const scrollPositionX = window.innerWidth + window.scrollX;
    if (scrollPositionX >= document.body.scrollWidth) {
      scrollHandled = true;
      setTimeout(() => scrollHandled = false, 1500);
      if (atEndX) {
        window.FLUTTER_CHANNEL.postMessage('nextPage');
      }
      atEndX = !atEndX;
    } else if (window.scrollX <= 0) {
      scrollHandled = true;
      setTimeout(() => scrollHandled = false, 1500);
      if (atBeginningX) {
        window.FLUTTER_CHANNEL.postMessage('previousPage')
      }
      atBeginningX = !atBeginningX;
    }
  }
  
  window.onscroll = () => {
    if (scrollHandled || window.scrollX === 0) return;
    
    if (window.scrollX > 0 && atBeginningX) {
      atBeginningX = false;
    }
    handleXScroll();
  };
})()
