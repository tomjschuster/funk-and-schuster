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
