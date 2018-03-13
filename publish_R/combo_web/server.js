console.log("Server starting...");
var fs = require("fs");
var d3 = require("d3");
var logger = require("morgan"); // for the logger


// Read the content of the file
console.log("Loading file...");
var a = fs.readFileSync('./combo_all_combos2.csv' ,'utf8'); //
console.log("File loaded. Length in characters: "+a.length);
console.log("Parsing file (d3.csv.parse)...");

// Parse the CSV
b = d3.csv.parse(a);
console.log("File parsed. Number of rows: "+b.length);
 
var indar = {};
//console.log('async if "Number of rows" appears before "File parsed"');
for (k=0; k<b.length; k++) { 
	if (indar[b[k].Drug1+"_"+b[k].Drug2] !== undefined)
		indar[b[k].Drug1+"_"+b[k].Drug2].push(b[k]);
	else indar[b[k].Drug1+"_"+b[k].Drug2] = [b[k]];
 }



var express = require('express');
var app = express();

// Keep connections log, don't log all the mouseovers though
var logFile = fs.createWriteStream('./myLogFile.log', {flags: 'a'});
app.use(logger('combined', {stream: logFile, skip: function(req, res) {return req._parsedUrl.pathname == "/q"} })); // 

// setup static server
app.use(express.static(__dirname + '/.'));


// query example: http://localhost:3000/q?Drug1=Wnti&Drug2=lenalidomide
app.get('/q', function(req, res){
	console.log(req.query);
    console.time('one');
    indari = indar[req.query.Drug1+'_'+req.query.Drug2];
    //console.log(indari)
    if (indari === undefined) {
    	indari = indar[req.query.Drug2+'_'+req.query.Drug1];
    }
    if (indari === undefined) {
    	res.send('Error: drug combination not found');
    } else {
    res.send(d3.csv.format(indari));
	}
    console.timeEnd('one');
  //connect.logger();
});

// just another link to see the csv nicely formated in the browser
// query example: http://localhost:3000/seecsv?Drug1=Wnti&Drug2=lenalidomide
app.get('/seecsv', function(req, res){
	console.log(req.query)
    console.time('one');
    indari = indar[req.query.Drug1+'_'+req.query.Drug2];
    //console.log(indari)
    if (indari == undefined) {
    	indari = indar[req.query.Drug2+'_'+req.query.Drug1];
    }
    if (indari == undefined) {
    	res.send('Error: drug combination not found');
    } else {
    res.send('<pre>'+d3.csv.format(indari)+'</pre>');
	}
    console.timeEnd('one');
});



app.listen(3000);
console.log('listening at http://localhost:3000/')

