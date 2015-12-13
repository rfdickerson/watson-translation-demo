# Watson iOS SDK Authentication Example


Example demonstrating how to do authentication using Facebook OAuth on
iOS and with a NodeJS Backend.

Run the server locally:

```shell
$ cd server
$ npm install
$ node app.js
```

Load your browser to http://localhost:6001/LanguageTranslation/api/v1/token?fbtoken=XXX where XXX is your Facebook token.

Server deployment:

First, you must use the Cloud Foundary tool to create the services on your Bluemix account:

```
$ cf login
$ cf create-service speech_to_text standard speech-to-text-service
$ cf create-service text_to_speech standard text-to-speech-service
$ cf create-service language_translation standard language-translation-service
$ cf env
```

```
$ cd server
$ cf push
```
