// Copyright Epic Games, Inc. All Rights Reserved.

var httpPort = 90;
var matchmakerPort = 9999;

const argv = require('yargs').argv;

const express = require('express');
const app = express();
const http = require('http').Server(app);

const msRestAzure = require('ms-rest-azure');
const msRest = require('ms-rest');

// A list of all the Cirrus server which are connected to the Matchmaker.
var cirrusServers = new Map();

//
// Parse command line.
//

if (typeof argv.httpPort != 'undefined') {
	httpPort = argv.httpPort;
}
if (typeof argv.matchmakerPort != 'undefined') {
	matchmakerPort = argv.matchmakerPort;
}

//
// Connect to browser.
//

http.listen(httpPort, () => {
    console.log('HTTP listening on *:' + httpPort);
});

// Get a Cirrus server if there is one available which has no clients connected.
function getAvailableCirrusServer() {
	for (cirrusServer of cirrusServers.values()) {
		if (cirrusServer.numConnectedClients === 0) {
			return cirrusServer;
		}
	}
	
	console.log('WARNING: No empty Cirrus servers are available');
	return undefined;
}

// No servers are available so send some simple JavaScript to the client to make
// it retry after a short period of time.
function sendRetryResponse(res) {
	res.send(`All ${cirrusServers.size} Cirrus servers are in use. Retrying in <span id="countdown">10</span> seconds.
	<script>
		var countdown = document.getElementById("countdown").textContent;
		setInterval(function() {
			countdown--;
			if (countdown == 0) {
				window.location.reload(1);
			} else {
				document.getElementById("countdown").textContent = countdown;
			}
		}, 1000);
	</script>`);
}

// Handle standard URL.
app.get('/', (req, res) => {
	cirrusServer = getAvailableCirrusServer();
	if (cirrusServer != undefined) {
		res.redirect(`http://${cirrusServer.address}:${cirrusServer.port}/`);
		console.log(`Redirect to ${cirrusServer.address}:${cirrusServer.port}`);
	} else {
		sendRetryResponse(res);
	}
});

// Handle URL with custom HTML.
app.get('/custom_html/:htmlFilename', (req, res) => {
	cirrusServer = getAvailableCirrusServer();
	if (cirrusServer != undefined) {
		res.redirect(`http://${cirrusServer.address}:${cirrusServer.port}/custom_html/${req.params.htmlFilename}`);
		console.log(`Redirect to ${cirrusServer.address}:${cirrusServer.port}`);
	} else {
		sendRetryResponse(res);
	}
});

//
// Connection to Cirrus.
//

const net = require('net');

function disconnect(connection) {
	console.log(`Ending connection to remote address ${connection.remoteAddress}`);
	connection.end();
}

const matchmaker = net.createServer((connection) => {
	connection.on('data', (data) => {
		try {
			message = JSON.parse(data);
		} catch(e) {
			console.log(`ERROR (${e.toString()}): Failed to parse Cirrus information from data: ${data.toString()}`);
			disconnect(connection);
			return;
		}
		if (message.type === 'connect') {
			// A Cirrus server connects to this Matchmaker server.
			cirrusServer = {
				address: message.address,
				port: message.port,
				numConnectedClients: 0
			};
			cirrusServers.set(connection, cirrusServer);
			console.log(`Cirrus server ${cirrusServer.address}:${cirrusServer.port} connected to Matchmaker`);
		} else if (message.type === 'clientConnected') {
			// A client connects to a Cirrus server.
			cirrusServer = cirrusServers.get(connection);
			cirrusServer.numConnectedClients++;
			console.log(`Client connected to Cirrus server ${cirrusServer.address}:${cirrusServer.port}`);
		} else if (message.type === 'clientDisconnected') {
			// A client disconnects from a Cirrus server.
			cirrusServer = cirrusServers.get(connection);
			cirrusServer.numConnectedClients--;
			console.log(`Client disconnected from Cirrus server ${cirrusServer.address}:${cirrusServer.port}`);
		} else {
			console.log('ERROR: Unknown data: ' + JSON.stringify(message));
			disconnect(connection);
		}
	});

	// A Cirrus server disconnects from this Matchmaker server.
	connection.on('error', () => {
		cirrusServers.delete(connection);
		console.log(`Cirrus server ${cirrusServer.address}:${cirrusServer.port} disconnected from Matchmaker`);
	});
});

matchmaker.listen(matchmakerPort, () => {
	console.log('Matchmaker listening on *:' + matchmakerPort);
});
