'use strict'

import 'phoenix_html'

// Toggle navigation
var html = document.querySelector('html')
var body = document.querySelector('body')
var homeLink = document.querySelector('.main-header .logo')
var openNavButton = document.querySelector('.open-nav')
var closeNavButton = document.querySelector('.close-nav')
var asideNav = document.querySelector('.aside-nav-container')
var bodyOverlay = document.querySelector('.body-overlay')
var asideNavLinks = document.querySelectorAll('.aside-nav-container a')
var claseNavButton = document.querySelector('.close-nav')

function onNavOpen () {
  html.classList.add('noscroll')
  body.classList.add('noscroll')
  asideNav.classList.add('active')
  bodyOverlay.classList.add('active')

  closeNavButton.tabIndex = 1
  for (let link of asideNavLinks) link.tabIndex = 1

  claseNavButton.focus()

  claseNavButton.addEventListener('keydown', e => {
    if (e.shiftKey && e.keyCode == 9) {
      e.preventDefault()
      asideNavLinks[asideNavLinks.length - 1].focus()
    }
  })

  if (asideNavLinks.length > 0) {
    asideNavLinks[asideNavLinks.length - 1].addEventListener('keydown', e => {
      if (!e.shiftKey && e.keyCode == 9) {
        e.preventDefault()
        closeNavButton.focus()
      }
    })
  }
  asideNav.hidden = false
  asideNav.setAttribute('aria-hidden', 'false')
}

function onNavClose () {
  html.classList.remove('noscroll')
  body.classList.remove('noscroll')
  asideNav.classList.remove('active')
  bodyOverlay.classList.remove('active')
  asideNav.hidden = true
  asideNav.setAttribute('aria-hidden', 'true')
  closeNavButton.tabIndex = -1
  for (let link of asideNavLinks) link.tabIndex = 1

  openNavButton.focus()
}

openNavButton.addEventListener('click', onNavOpen)
bodyOverlay.addEventListener('click', onNavClose)
closeNavButton.addEventListener('click', onNavClose)
