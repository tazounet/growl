var wrapper = document.getElementById('wrapper');
var icon = document.getElementById('icon');

icon.addEventListener('load', function() {

    wrapper.style.opacity = window.growlOpacity;
    wrapper.style.webkitAnimationName = "pop";
});