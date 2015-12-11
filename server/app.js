/**
 * Copyright IBM Corporation 2015
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

'use strict';

var express     = require('express');

// cfenv provides access to your Cloud Foundry environment
// for more info, see: https://www.npmjs.com/package/cfenv
var cfenv = require('cfenv');


var fs          = require('fs');
var plist       = require('plist');
var url         = require('url');
var http        = require('http');
var when        = require('when');
var request     = require('request');
var passport    = require('passport');

var app = express();

// get the app environment from Cloud Foundry
var appEnv = cfenv.getAppEnv();

var serviceURLs = {
        TextToSpeech: "https://stream.watsonplatform.net/text-to-speech/api",
        SpeechToText: "https://stream.watsonplatform.net/speech-to-text/api"
    };


function readConfigFile() {

    var obj = plist.parse(fs.readFileSync('Credentials.plist', 'utf8'));

    return obj;
}

function validateFBToken(args) {

  // requires a fbToken
  var fbToken = args.fbtoken

  var deferred = when.defer();

  if (fbToken == "") {
    deferred.reject("Need to provide a Facebook profile.");
  }

  var url = "https://graph.facebook.com/me?access_token=" + fbToken

  request.get(url, function (error, response, body) {

    if (error) { deferred.reject(error); }

    console.log(body);

    var response = JSON.parse(body);

    if (response.verified == true) {

      args.email = response.email;

      deferred.resolve(args);

    } else {
      deferred.reject("Facebook rejected the token");
    }

    

  })

  return deferred.promise;

}

function writeToDB(args) {

  var deferred = when.defer();

  console.log("Writing to the database");
  deferred.resolve(args);

  return deferred.promise;
}


function getWatsonToken(args) {

  // require tokenURL, serviceURL, username, password
  // var required = ["token", ..]
  var deferred = when.defer();

  // check(args,required, deferred)

  var tokenURL = args.tokenURL;
  var serviceURL = args.serviceURL;
  var username = args.username;
  var password = args.password;

  var url = tokenURL + "?url=" + serviceURL;

  request.get(url, function (error, response, body) {

    if (error) { deferred.reject(error); }

    args.watsonToken = body;

    console.log("Received Watson token: " + body);

    deferred.resolve(args);

  }).auth(username, password, false);


  // callback = function(response)
  return deferred.promise;
}

function handleError(e) {
  return "No token"
}

app.get('/', function (req, res) {

  res.send('Watson Token Gateway');

});

app.get('/:service_name/api/v1/token', function (req, res) {

  var url_parts = url.parse(req.url, true);
  var query = url_parts.query;

  var serviceName = req.params.service_name;
  var fbtoken = query["fbtoken"];

  var keys = readConfigFile();

  // var serviceName = keys["URLs"][serviceURL];

  if (!serviceName) {
    res.send("ERROR: need to specify a url to the service you are using.");
  }

  console.log("Fetching key for " + serviceName);
  // console.log(keys);

  var username = keys[serviceName + "Username"];
  var password = keys[serviceName + "Password"];

  var serviceURL = serviceURLs[serviceName];

  if (!username || !password) {
    res.send("ERROR: could not find stored authentication in Credentials.plist");
  }

  var args = {
    username: username,
    password: password,
    serviceURL: serviceURL,
    fbtoken: fbtoken,
    tokenURL: "https://stream.watsonplatform.net/authorization/api/v1/token"
  }

  validateFBToken(args)
  .then(writeToDB)
  .then(getWatsonToken)
  .then( function (args) {
    res.send(args.watsonToken);
  })  
  .otherwise(function (err) {
    res.send(err);
  });

  //var watsonToken = args.token;

  // res.send(watsonToken);

});


var server = app.listen(appEnv.port, '0.0.0.0', function () {
  var host = server.address().address;
  var port = server.address().port;

  console.log('Example app listening at http://%s:%s', host, port);
});
