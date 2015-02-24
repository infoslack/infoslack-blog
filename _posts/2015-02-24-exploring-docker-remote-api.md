---
layout: post
title: "[EN] - Exploring Docker Remote API"
description: "Execute the docker commands via REST API"
category: devops
keywords: linux, devops, docker, ruby, gem, api, rest, docker-api, postgres
---

> In all the posts about Docker, I used the shell to execute the commands, 
today we will see how to perform the same Docker commands remotely via 
`REST API` and the power that it can provide.

### First steps

The first thing to do is to configure the Docker to make use of the API, 
you just change the setting in `/etc/default/docker` and restart the 
service:

{% highlight bash %}
$ echo "DOCKER_OPTS='-H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock'" \
> /etc/default/docker
$ service docker restart
{% endhighlight %}

As a result of setting the Docker continue working via unix socket and 
now also answer on port `TCP/IP 2375`.

For the first test, we can list all the images using the `curl`:

{% highlight bash %}
$ curl -X GET http://127.0.0.1:2375/images/json

[
	{
		"Created":1420935607,
		"Id":"4106803b0e8f",
		"ParentId":"1870b4c5265a",
		"RepoTags":[
			"railsdockerdemo_app:latest"
		],
		"Size":2064519,
		"VirtualSize":838022842
	},

	{
		"Created":1420685151,
		"Id":"facc3d0d228ec",
		"ParentId":"9a9e0eaaf857",
		"RepoTags":[
			"inkscape:latest"
		],
		"Size":0,
		"VirtualSize":672397560
	},

	{
		"Created":1420102338,
		"Id":"b36113199f789",
		"ParentId":"258a0a9eb8af",
		"RepoTags":[
			"postgres:9.3"
		],
		"Size":0,
		"VirtualSize":213151121
	}
]
{% endhighlight %}

Or simply checking the version:

{% highlight bash %}
$ curl -X GET http://127.0.0.1:2375/version

	{
		"ApiVersion":"1.17",
		"Arch":"amd64",
		"GitCommit":"5bc2ff8",
		"GoVersion":"go1.4",
		"KernelVersion":"3.14.33",
		"Os":"linux",
		"Version":"1.5.0"
	}
{% endhighlight %}

### Control containers

To create a container, the API supports all the options we use the 
command terminal. We can create this:

{% highlight bash %}
$ curl -X POST -H "Content-Type: application/json" \
> http://127.0.0.1:2375/containers/create -d '{
	"Hostname":"",
	"User":"",
	"Memory":0,
	"MemorySwap":0,
	"AttachStdin":false,
	"AttachStdout":true,
	"AttachStderr":true,
	"PortSpecs":null,
	"Privileged":false,
	"Tty":false,
	"OpenStdin":false,
	"StdinOnce":false,
	"Env":null,
	"Dns":null,
	"Image":"postgres:9.3",
	"Volumes":{},
	"VolumesFrom":{},
	"WorkingDir":""
}'
{"Id":"3e9879113012"}
{% endhighlight %}

When creating a container API returns its `ID`, you can now initialize 
the container:

{% highlight bash %}
$ curl -X POST http://127.0.0.1:2375/containers/3e9879113012/start
{% endhighlight %}


We can check listing the containers that are running:

{% highlight bash %}
$ curl -X GET http://127.0.0.1:2375/containers/json

[
	{
		"Command":"/docker-entrypoint.sh postgres",
		"Created":1424801791,"Id":"3e9879113012",
		"Image":"postgres:9.3",
		"Names":["/sleepy_galileo"],
		"Ports":[{"PrivatePort":5432,"Type":"tcp"}],
		"Status":"Up 8 seconds"
	}
]
{% endhighlight %}

Pause and remove a container is also relatively simple:

{% highlight bash %}
$ curl -X POST http://127.0.0.1:2375/containers/3e9879113012/stop
$ curl -X DELETE http://127.0.0.1:2375/containers/3e9879113012
{% endhighlight %}

### Using the API with your favorite programming language

Well, my favorite language is Ruby ;)

Using the [docker-api](https://github.com/swipely/docker-api) gem we have a friendly interface manipulation API, 
to install and begin testing is very simple:

{% highlight bash %}
$ gem install docker-api
$ irb
2.2.0 (main)> require 'docker'
=> true
2.2.0 (main)> Docker.version
=> {
	"ApiVersion" => "1.17",
	"Arch" => "amd64",
	"GitCommit" => "5bc2ff8",
	"GoVersion" => "go1.4",
	"KernelVersion" => "3.14.33",
	"Os" => "linux",
	"Version" => "1.5.0"
}
2.2.0 (main)>
{% endhighlight %}

Everything we do using the curl can be done more friendly way, we can 
create a container like this:

{% highlight bash %}
2.2.0 (main)> container = Docker::Container.create('Image' => 'postgres:9.3')
2.2.0 (main)>
{% endhighlight %}
					
We can run the container with the `start` method:

{% highlight bash %}
2.2.0 (main)> container.start

=> #<Docker::Container:0x007fdc21d87ca0 
		@id="ce22467a9c23", 
		@info={"Warnings"=>nil, "id"=>"ce22467a9c23"}, 
		@connection=#<Docker::Connection:0x007fdc223de4f0 @url="unix:///", 
		@options={:socket=>"/var/run/docker.sock"}>>
{% endhighlight %}

And list the running processes in the container with top:

{% highlight bash %}
2.2.0 (main)> container.top
=> [
	[0] {
		"UID" => "999",
			"PID" => "1455",
			"PPID" => "30814",
			"C" => "0",
			"STIME" => "15:56",
			"TTY" => "?",
			"TIME" => "00:00:00",
			"CMD" => "postgres"
	},
	[1] {
		"UID" => "999",
		"PID" => "1517",
		"PPID" => "1455",
		"C" => "0",
		"STIME" => "15:56",
		"TTY" => "?",
		"TIME" => "00:00:00",
		"CMD" => "postgres: checkpointer process"
	},
	[2] {
		"UID" => "999",
		"PID" => "1518",
		"PPID" => "1455",
		"C" => "0",
		"STIME" => "15:56",
		"TTY" => "?",
		"TIME" => "00:00:00",
		"CMD" => "postgres: writer process"
	}
]
{% endhighlight %}

### Conclusion

It's amazing the possibilities of what we can build with Docker API, 
will continue exploring more about this in other posts.

If you are interested in playing with the API on other platforms, 
there are many libraries:

- Python: [https://github.com/docker/docker-py](https://github.com/docker/docker-py)
- Java: [https://github.com/kpelykh/docker-java](https://github.com/kpelykh/docker-java)
- PHP: [https://github.com/mikemilano/docker-php](https://github.com/mikemilano/docker-php)
- Go: [https://github.com/fsouza/go-dockerclient](https://github.com/fsouza/go-dockerclient)

Happy Hacking ;)

### References

- [https://docs.docker.com/reference/api/docker_remote_api/](https://docs.docker.com/reference/api/docker_remote_api/)

- [https://docs.docker.com/reference/api/docker_remote_api_v1.17/](https://docs.docker.com/reference/api/docker_remote_api_v1.17/)

- [https://github.com/swipely/docker-api](https://github.com/swipely/docker-api)
