'use strict'

import 'phoenix_html'

// Toggle navigation
var html = document.querySelector('html')
var body = document.querySelector('body')
var openNav = document.querySelector('.open-nav')
var closeNav = document.querySelector('.close-nav')
var asideNav = document.querySelector('.aside-nav-container')
var bodyOverlay = document.querySelector('.body-overlay')

function addClasses () {
  html.classList.add('noscroll')
  body.classList.add('noscroll')
  asideNav.classList.add('active')
  bodyOverlay.classList.add('active')
}

function removeClasses () {
  html.classList.remove('noscroll')
  body.classList.remove('noscroll')
  asideNav.classList.remove('active')
  bodyOverlay.classList.remove('active')
}

openNav.addEventListener('click', addClasses)
bodyOverlay.addEventListener('click', removeClasses)
closeNav.addEventListener('click', removeClasses)

// Split Screen Portfolio

let previews = {}
document.querySelectorAll('.portfolio-previews > div').forEach(
  function (element) {
    previews[element.getAttribute('data-portfolio-preview')] = element
  }
)
document.querySelectorAll('.portfolio-links ul li').forEach(
  function (element) {
    element.addEventListener('mouseover', function (e) {
      let selectedIndex = element.getAttribute('data-portfolio-link')

      document.querySelector('.portfolio-links .active').classList.remove('active')
      element.childNodes[0].classList.add('active')

      document.querySelector('.portfolio-previews .active').classList.remove('active')
      previews[selectedIndex].classList.add('active')
    })
  }
)
