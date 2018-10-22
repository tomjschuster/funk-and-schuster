exports.config = {
  files: {
    stylesheets: {
      joinTo: 'css/app.css',
      order: {
        after: ['priv/static/css/app.scss'] // concat app.css last
      }
    }
  },

  conventions: {
    assets: /^(static)/
  },

  paths: {
    watched: ['static', 'css', 'js', 'fonts', 'vendor'],
    public: '../priv/static'
  },

  npm: {
    enabled: true
  }
}
