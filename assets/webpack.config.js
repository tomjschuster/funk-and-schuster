const webpack = require('webpack')
const path = require('path')
const MiniCssExtractPlugin = require('mini-css-extract-plugin')
const UglifyJsPlugin = require('uglifyjs-webpack-plugin')
const OptimizeCSSAssetsPlugin = require('optimize-css-assets-webpack-plugin')
const CopyWebpackPlugin = require('copy-webpack-plugin')
const elmMinify = require('elm-minify')

const common = {
  entry: {
    style: './css/app.scss',
    app: './js/app.js'
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: [/elm-stuff/, /node_modules/],
        use: 'babel-loader'
      },
      {
        test: /\.(png)$/,
        loader: 'file-loader?name=images/[name].[ext]'
      },
      {
        test: /\.(eot|svg|ttf|woff|woff2)$/,
        loader: 'file-loader?name=fonts/[name].[ext]'
      },
      {
        test: /\.woff(2)?(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        loader: 'url-loader?limit=10000&mimetype=application/font-woff'
      },
      {
        test: /\.(svg)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        loader: 'file-loader?name=images/[name].[ext]'
      }
    ]
  }
}

module.exports = (env, options) =>
  options.mode === 'production'
    ? // Production Config
    {
      ...common,
      output: {
        filename: '[name].js',
        path: path.resolve(__dirname, '../priv/static/js'),
        publicPath: '/'
      },
      optimization: {
        minimizer: [
          new UglifyJsPlugin({
            cache: true,
            parallel: true,
            sourceMap: false
          }),
          new OptimizeCSSAssetsPlugin({})
        ]
      },
      module: {
        rules: [
          ...common.module.rules,
          {
            test: /\.elm$/,
            exclude: [/elm-stuff/, /node_modules/],
            use: { loader: 'elm-webpack-loader', options: { optimize: true } }
          },
          {
            test: /\.css$/,
            exclude: [/elm-stuff/, /node_modules/],
            use: [MiniCssExtractPlugin.loader, 'css-loader']
          },
          {
            test: /\.scss$/,
            exclude: [/elm-stuff/, /node_modules/],
            use: [
              MiniCssExtractPlugin.loader,
              'css-loader',
              'resolve-url-loader',
              'sass-loader'
            ]
          }
        ]
      },
      plugins: [
        new elmMinify.WebpackPlugin(),
        new MiniCssExtractPlugin({ filename: '../css/[name].css' }),
        new CopyWebpackPlugin([{ from: 'static/', to: '../' }])
      ]
    }
    : // Dev Config
    {
      ...common,
      output: {
        filename: 'js/[name].js',
        path: path.resolve(__dirname, './js'),
        publicPath: 'http://localhost:8080/'
      },
      module: {
        rules: [
          ...common.module.rules,
          {
            test: /\.elm$/,
            exclude: [/elm-stuff/, /node_modules/],
            use: [
              { loader: 'elm-hot-webpack-loader' },
              {
                loader: 'elm-webpack-loader',
                options: { debug: true, forceWatch: true }
              }
            ]
          },
          {
            test: /\.css$/,
            exclude: [/elm-stuff/, /node_modules/],
            use: ['style-loader', 'css-loader']
          },
          {
            test: /\.scss$/,
            exclude: [/elm-stuff/, /node_modules/],
            use: [
              'style-loader',
              'css-loader',
              'resolve-url-loader',
              'sass-loader'
            ]
          }
        ]
      },
      devServer: {
        headers: {
          'Access-Control-Allow-Origin': '*'
        },
        publicPath: 'http://localhost:8080/',
        contentBase: path.join(__dirname, 'static'),
        disableHostCheck: true
      },
      plugins: [
        new webpack.NamedModulesPlugin(),
        new webpack.NoEmitOnErrorsPlugin()
      ]
    }
