var express = require('express');
var Docker = require('dockerode');
var docker = new Docker({socketPath: '/var/run/docker.sock'});
var app = express();

app.get('/:id', function(req, res){
	let container = docker.getContainer(req.params.id);
	container.inspect(function (err, data) {
		if (err) {
			let statusCode = err.statusCode || 500;
			let message = err.json && err.json.message || "internal server error";
			res.status(statusCode).send(message);
		} else {
			let statusCode = 200;
			let state = data.State;
			if (state.ExitCode !== 0 || !state.Running) {
				statusCode = 500;
			}
			res.status(statusCode).send(state);
		}
	});
});

app.listen(3000);
