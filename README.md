# http-ext
[![NPM version][npm-image]][npm-url] [![Build Status][travis-image]][travis-url] [![Dependency Status][daviddm-image]][daviddm-url] [![Coverage Status][coveralls-image]][coveralls-url]

the http request client for nodejs module


## Install

You can install **http-ext** using the Node Package Manager (npm):

```bash
$ npm install --save http-ext
```

## Simple Usage

```javascript
var httpExt = require('http-ext');

httpExt.get('http://www.google.com', function (err, res){
  if (err) return console.log(err);
  console.log(res.body);
});
```

## How to use

* [httpExt.get(url, [options], callback)](#get)
* [httpExt.post(url, [options], callback)](#post)
* [httpExt.put(url, [options], callback)](#put)
* [httpExt.delete(url, [options], callback)](#delete)
* [Sending a custom body](#custombody)
* [Using a http(s) proxy](#proxy)

---------------------------------------
<a name="get" />
### httpExt.get(url, [options], callback)

__Arguments__
 - url: The url to connect to. Can be http or https.
 - options: (all are optional) The following options can be passed:
    - parameters: an object of query parameters
    - headers: an object of headers
    - cookies: an array of cookies
    - allowRedirects: (default: __true__ , only with httpExt.get() ), if true, redirects will be followed
    - maxRedirects: (default: __10__ ). For example 1 redirect will allow for one normal request and 1 extra redirected request.
    - timeout: (default: __none__ ). Adds a timeout to the http(s) request. Should be in milliseconds.
    - proxy, if you want to pass your request through a http(s) proxy server:
        - host: eg: "192.168.0.1"
        - port: eg: 8888
        - protocol: (default: __'http'__ ) can be 'http' or 'https'
     - rejectUnauthorized: validate certificate for request with HTTPS. [More here](http://nodejs.org/api/https.html#https_https_request_options_callback)
 - callback(err, res): A callback function which is called when the request is complete. __res__ contains and response ( __res__ ) the body ( __res.body__ )

__Example without options__

```js
var httpExt = require('http-ext');

httpExt.get('http://www.google.com', function (err, res){
	if (err) return console.log(err);
	console.log(res.body);
});
```

__Example with options__

```js
var httpExt = require('http-ext');

httpExt.get('http://posttestserver.com/post.php', {
	parameters: {
		name: 'John',
		lastname: 'Doe'
	},
	headers:{
		'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.7; rv:18.0) Gecko/20100101 Firefox/18.0'
	},
	cookies: [
		'token=DGcGUmplWQSjfqEvmu%2BZA%2Fc',
		'id=2'
	]
}, function (err, res){
	if (err){
		console.log(err);
	}else{
		console.log(res.body);
	}
});
```
---------------------------------------
<a name="post" />
### httpExt.post(url, [options], callback)

__Arguments__
 - url: The url to connect to. Can be http or https.
 - options: (all are optional) The following options can be passed:
    - parameters: an object of post parameters (content-type is set to *application/x-www-form-urlencoded; charset=UTF-8*)
    - json: if you want to send json directly (content-type is set to *application/json*)
    - body: custom body content you want to send. If used, previous options will be ignored and your custom body will be sent. (content-type will not be set)
    - headers: an object of headers
    - cookies: an array of cookies
    - allowRedirects: (default: __false__ ), if true, redirects will be followed
    - maxRedirects: (default: __10__ ). For example 1 redirect will allow for one normal request and 1 extra redirected request.
    - timeout: (default: none). Adds a timeout to the http(s) request. Should be in milliseconds.
    - proxy, if you want to pass your request through a http(s) proxy server:
        - host: eg: "192.168.0.1"
        - port: eg: 8888
        - protocol: (default: __'http'__ ) can be 'http' or 'https'
    - rejectUnauthorized: validate certificate for request with HTTPS. [More here](http://nodejs.org/api/https.html#https_https_request_options_callback)
 - callback(err, res): A callback function which is called when the request is complete. __res__ contains the response ( __res__ ) and the body ( __res.body__ )

__Example without extra options__

```js
var httpExt = require('httpExt');

httpExt.post('http://posttestserver.com/post.php', {
	parameters: {
		name: 'John',
		lastname: 'Doe'
	}
}, function (err, res){
	if (err){
		console.log(err);
	}else{
		console.log(res.body);
	}
});
```

__Example with options__

```js
var httpExt = require('http-ext');

httpExt.post('http://posttestserver.com/post.php', {
	parameters: {
		name: 'John',
		lastname: 'Doe'
	},
	headers:{
		'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.7; rv:18.0) Gecko/20100101 Firefox/18.0'
	},
	cookies: [
		'token=DGcGUmplWQSjfqEvmu%2BZA%2Fc',
		'id=2'
	]
}, function (err, res){
	if (err){
		console.log(err);
	}else{
		console.log(res.body);
	}
});
```

---------------------------------------
<a name="put" />
### httpExt.put(url, [options], callback)

Same options as [httpExt.post(url, [options], callback)](#post)

---------------------------------------
<a name="delete" />
### httpExt.delete(url, [options], callback)

Same options as [httpExt.post(url, [options], callback)](#post)

---------------------------------------
<a name="custombody" />
### Sending a custom body
Use the body option to send a custom body (eg. an xml post)

__Example__

```js
var httpExt = require('http-ext');

httpExt.post('http://posttestserver.com/post.php',{
  body: '<?xml version="1.0" encoding="UTF-8"?>',
  headers:{
    'Content-Type': 'text/xml',
  }},
  function (err, res) {
    if (err){
        console.log(err);
    }else{
        console.log(res.body);
    }
  }
);
```

---------------------------------------
<a name="proxy" />
### Using a http(s) proxy

__Example__

```js
var httpExt = require('http-ext');

httpExt.post('http://posttestserver.com/post.php', {
  proxy: {
    host: 'localhost',
    port: 8888
  }
}, function (err, res){
  if (err){
    console.log(err);
  }else{
    console.log(res.body);
  }
});
```

---------------------------------------

## API

_(Coming soon)_


## Contributing

In lieu of a formal styleguide, take care to maintain the existing coding style. Add unit tests for any new or changed functionality. Lint and test your code using [gulp](http://gulpjs.com/).


## License

Copyright (c) 2015 liuxiong. Licensed under the MIT license.



[npm-url]: https://npmjs.org/package/http-ext
[npm-image]: https://badge.fury.io/js/http-ext.svg
[travis-url]: https://travis-ci.org/liuxiong332/node-http-ext
[travis-image]: https://travis-ci.org/liuxiong332/node-http-ext.svg?branch=master
[daviddm-url]: https://david-dm.org/liuxiong332/node-http-ext
[daviddm-image]: https://david-dm.org/liuxiong332/node-http-ext.svg?theme=shields.io
[coveralls-url]: https://coveralls.io/r/liuxiong332/node-http-ext
[coveralls-image]: https://coveralls.io/repos/liuxiong332/node-http-ext/badge.png
