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

var url         = require('url');
var http        = require('http');
var when        = require('when');
var request     = require('request');
var crypto      = require('crypto-js')

var app = express();

// get the app environment from Cloud Foundry
var appEnv = cfenv.getAppEnv();

var serviceURLs = {
    TextToSpeech: "https://stream.watsonplatform.net/text-to-speech/api",
    SpeechToText: "https://stream.watsonplatform.net/speech-to-text/api",
    LanguageTranslation: "https://gateway.watsonplatform.net/language-translation/api"
};

var tokenURLs = {
    Gateway: "https://gateway.watsonplatform.net/authorization/api/v1/token",
    Stream: "https://stream.watsonplatform.net/authorization/api/v1/token"
};


function getAppProof( access_token, app_secret) {
  var hash = crypto.HmacSHA256(access_token, app_secret);
  return hash.toString(CryptoJS.enc.Base64);
}

// This function takes an OAuth token for Facebook and validates it using their web service.
function validateFBToken(args) {

    // requires a fbToken
    var fbToken = args.fbtoken

    var deferred = when.defer();

    if (fbToken == "") {
	deferred.reject("Need to provide a Facebook profile.");
    }

    var proof = getAppProof(fbToken, APP_SECRET);

    console.log("Proof is " + proof);

    var url = "https://graph.facebook.com/me?fields=email,first_name,last_name?access_token="
        + fbToken + "&appsecret_proof=" + proof;

    console.log("Validating token at " + url);

    request.get(url, function (error, response, body) {

	if (error) { deferred.reject(error); }

	console.log(body);

	var response = JSON.parse(body);

	if (response.id) {

	    args.email = response.email;
	    args.first_name = response.first_name;
	    args.last_name = response.last_name;

	    deferred.resolve(args);

	} else {

	    var err = {error: {
		message: "Facebook OAuth token could not be verified.",
		type: "OAuthException"}}

	    deferred.reject(err);

	}



    });

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

    var deferred = when.defer();

    var tokenURL = args.tokenURL;
    var serviceURL = args.serviceURL;
    var username = args.username;
    var password = args.password;

    var url = tokenURL + "?url=" + serviceURL;

    request.get(url, function (error, response, body) {

	if (error) {

	    err = {error: {
		message: "Watson rejected the token request.",
		type: "OAuth Exception"}}

	    deferred.reject(err);

	}

	args.watsonToken = body;

	console.log("Received Watson token: " + body);

	deferred.resolve(args);

    }).auth(username, password, false);

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

    if (!serviceName) {
	res.send("ERROR: need to specify a url to the service you are using.");
    }

    console.log("Fetching key for " + serviceName);
    // console.log(keys);

    if (!appEnv.getServices()[serviceName]) {
	     var err = {error: {
	        message: "Could not find service " + serviceName,
	        type: "Service exception",
	        code: 403}};
	res.send(err);
	return;
    }

    var username = appEnv.getServices()[serviceName].credentials.username;
    var password = appEnv.getServices()[serviceName].credentials.password;
    var serviceURL = appEnv.getServices()[serviceName].credentials.url;

    console.log("Credentials " + username + " " + password + " " + serviceURL);

    if (!username || !password || !serviceURL) {
	var err = {error: {
	    message: "Credentials not found for " + serviceName,
	    type: "Service exception",
	    code: 403}};

	res.send(err);
	return;
    }

    if (serviceName == "text-to-speech-service" || serviceName == "speech-to-text-service") {
	var tokenURL = tokenURLs.Stream;
    } else {
	var tokenURL = tokenURLs.Gateway;
    }

    var args = {
	username: username,
	password: password,
	serviceURL: serviceURL,
	fbtoken: fbtoken,
	tokenURL: tokenURL
    }

    validateFBToken(args)
	.then(writeToDB)
	.then(getWatsonToken)
	.then( function (args) {

	    var resp = {token: args.watsonToken,
			first_name: args.first_name,
			last_name: args.last_name,
			email: args.email};
	    res.send(resp);
	})
	.otherwise(function (err) {
	    res.send(err);
	});

});


var server = app.listen(appEnv.port, '0.0.0.0', function () {

    var host = server.address().address;
    var port = server.address().port;

    console.log('Example app listening at http://%s:%s', host, port);
});
