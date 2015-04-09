var httpExt = require('http-ext');

var options = {
  proxy: {
    host: 'localhost',
    port: 8888,
  }
};

//request the url by proxy server
httpExt.get('https://bjmail.kingsoft.com/EWS/exchange.asmx', options, function(err, res) {
  if(err) throw err;
  console.log(res);
});
