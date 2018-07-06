"use strict";

//Toggle navigation

var openNav = document.querySelector(".open-nav");
var closeNav = document.querySelector(".close-nav");
var asideNav = document.querySelector(".aside-nav-container")
var bodyOverlay = document.querySelector(".body-overlay");

openNav.addEventListener("click", function(){
	asideNav.classList.add("active");
	bodyOverlay.classList.add("active");
});
closeNav.addEventListener("click", function(){
	asideNav.classList.remove('active'),
	bodyOverlay.classList.remove('active')
});

//Split Screen Portfolio

let previews = {};
document.querySelectorAll(".portfolio-previews > div").forEach(
	function(element) {
		previews[element.getAttribute('data-portfolio-preview')] = element;
	}
)
document.querySelectorAll('.portfolio-links ul li').forEach(
	function(element) {
		element.addEventListener('mouseover', function(e) {
			let selectedIndex = element.getAttribute("data-portfolio-link");

			document.querySelector('.portfolio-links .active').classList.remove("active");
			element.childNodes[0].classList.add("active");

			document.querySelector('.portfolio-previews .active').classList.remove("active");
			previews[selectedIndex].classList.add("active");
		})
	}
)



