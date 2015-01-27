# Ducke

A nodejs API and command line tool for docker.

Ducke supports:
- Listing, building, inspecting and deleting images
- Listing, creating, inspecting, running, logging, attaching and deleting containers

Ducke does not yet support:
- Searching, pushing, pulling, tagging and history of images
- System events, docker versioning, creating images from containers and authentication
- Exporting, resizing TTY, pausing, unpausing, inspecting changes for a container
- Interacting with the docker registry and hub

[![NPM version](https://badge.fury.io/js/ducke.svg)](http://badge.fury.io/js/ducke)

Inspired by [dockerode](https://github.com/apocas/dockerode/).

## Install

To use on the command line

```sh
npm install -g ducke
```

To use as an API

```sh
npm install ducke
```

## Usage

```
Usage: ducke command [parameters]

Common:

    ps        List all running containers
    logs      Attach to container logs
    run       Start a new container interactively
    up        Start a new container
    exec      Run a command inside an existing container

Containers:

    inspect   Show details about containers
    kill      Send SIGTERM to running containers
    stop      Stop containers
    purge     Remove week old stopped containers
    rm        Delete containers

Images:

    ls        List available images
    orphans   List all orphaned images
    rmi       Delete images
    inspecti  Show details about images

Building:

    build     Build an image from a Dockerfile
    rebuild   Build an image from a Dockerfile from scratch
```

## Examples

Command

```sh
$  ~  ducke ls

  04c5d3b7b065 ubuntu:latest
  cf39b476aeec phusion/baseimage:0.9.15
    ...
  0e819813bc00 tutum/apache-php:latest
    ...
  5327fda0d529 phusion/passenger-full:0.9.11
  
```

```sh
$ ~  ducke ps

  stopped          happy_goldstine (234bce554bdcec9d4ad47a452bd37a95d291d825138421730aa06017da9c8412)
  stopped          loadbalancer-osx_daemon_1 (metocean/doppelganger:1.0.3)
  stopped          sleepy_turing (cf39b476aeec4d2bd097945a14a147dc52e16bd88511ed931357a5cd6f6590de)
  
```

```sh
$ ~  ducke run ubuntu

  running cranky_kowalevski (ubuntu)

root@09d3215f6677:/# ls
bin   dev  home  lib64  mnt  proc  run   srv  tmp  var
boot  etc  lib   media  opt  root  sbin  sys  usr
root@09d3215f6677:/#

///

$  ~  ducke exec cranky_kowalevski

  exec cranky_kowalevski (ubuntu)

root@10a2833bdafa:/# ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.4  0.3  18168  3164 ?        Ss+  04:19   0:00 bash
root        16  1.0  0.3  18172  3168 ?        S    04:19   0:00 bash
root        31  0.0  0.2  15572  2100 ?        R+   04:19   0:00 ps aux
root@10a2833bdafa:/#

```

```sh
$ ~  ducke cull happy_goldstine sleepy_turing

  deleted happy_goldstine
  deleted sleepy_turing

$  ~
```

API

```js
var Ducke = require('ducke');
var ducke = new Ducke.API(Ducke.Parameters());

// List all containers
ducke.ps(function(err, containers) {
    console.log(containers);
});

// Start a container
ducke
    .container('my_container')
    .start(function(err, result) {
        console.log(result);
    });

// Create a container
ducke
    .image('ubuntu:latest')
    .up('my_container', ['/bin/bash'], function(err, id) {
        console.log('Container id: ' + id);
    });
```

## API Reference

```js
ducke.ping(function(err, isup) {});
ducke.ps(function(err, containers) {
    // https://docs.docker.com/reference/api/docker_remote_api_v1.15/#list-containers
    containers[0].container
    // https://docs.docker.com/reference/api/docker_remote_api_v1.15/#inspect-a-container
    containers[0].inspect
});
ducke.ls(function(err, images) {
    // https://docs.docker.com/reference/api/docker_remote_api_v1.15/#list-images
    images.images[0].image
    images.graph = [
        {
            image: ...
            children: [
                {
                    image: ...
                    children: [...]
                }
            ]
        }
    ]
    images.tags = {
        'ubuntu:latest': {...}
        'my_image:0.0.1': {...}
    }
    images.ids = {
        '62b9c90893b4...': {...}
        'cd80a4b0ed6b...': {...}
    }
    ducke.lls(images, function(err, details) {
        // https://docs.docker.com/reference/api/docker_remote_api_v1.15/#inspect-an-image
        details = {
            '62b9c90893b4...': {...}
        }
    });
});
ducke
    .container('my_container')
    .inspect(function(err, inspect) {})
    .logs(function(err, stream) {})
    .resize(function(err, didresize) {})
    .start(function(err, result) {})
    .stop(function(err, result) {})
    .wait(function(err, result) {})
    .rm(function(err, result) {})
    .attach(function(err, stream) {})
    .kill(function(err, result) {})
    .exec(['/bin/bash'], process.stdin, process.stdout, process.stderr, function(err, code) {});

ducke
    .image('my_image')
    .build('/path/to/folder', console.log, function(err) {})
    .rebuild('/path/to/folder', console.log, function(err) {})
    .up('my_container', ['/bin/bash'], function(err, id) {})
    .inspect(function(err, results) {})
    .rm(function(err, results) {})
    .run(['/bin/bash'], process.stdin, process.stdout, process.stderr, function(err, code) {})
```

## Todo

- More of the docker API
- Tests
