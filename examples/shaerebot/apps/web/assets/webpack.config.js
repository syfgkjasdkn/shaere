const path = require("path");
const glob = require("glob");
const webpack = require("webpack");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const UglifyJsPlugin = require("uglifyjs-webpack-plugin");
const OptimizeCSSAssetsPlugin = require("optimize-css-assets-webpack-plugin");
const CopyWebpackPlugin = require("copy-webpack-plugin");

const prod = process.env.NODE_ENV === "prod";

module.exports = (env, options) => ({
  entry: {
    bundle: ["./css/app.css", "./js/app.js"],
    tachyons: "tachyons/css/tachyons.css"
  },

  output: {
    path: __dirname + "/../priv/static/",
    filename: "js/[name].js"
  },

  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: "babel-loader"
        }
      },
      {
        test: /\.css$/,
        use: [
          {
            loader: MiniCssExtractPlugin.loader,
            options: {
              sourceMap: !prod
            }
          },
          "css-loader"
        ]
      }
    ]
  },

  optimization: {
    minimizer: [
      new UglifyJsPlugin({ cache: true, parallel: true, sourceMap: false }),
      new OptimizeCSSAssetsPlugin({})
    ]
  },
  
  plugins: [
    new MiniCssExtractPlugin({
      filename: "css/[name].css",
      chunkFilename: "[id].css"
    }),
    new CopyWebpackPlugin([{ from: "static/", to: "../" }]),
    prod && new webpack.optimize.ModuleConcatenationPlugin()
  ].filter(Boolean),

  devtool: prod ? false : "inline-source-map"
});
