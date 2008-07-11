= poolparty

  http://poolpartyrb.com
  Ari Lerner
  CitrusByte
  http://blog.citrusbyte.com

== DESCRIPTION:
  
poolparty (http://poolpartyrb.com), Ari Lerner (http://blog.xnot.org, http://blog.citrusbyte.com) - poolparty is a framework for maintaining and running auto-scalable applications on Amazon's EC2 cloud. Run entire applications using the EC2 cluster and the unlimited S3 disk. More details to be listed at http://poolpartyrb.com.

== Basics

poolparty is written with the intention of being as application-agnostic as possible. It installs only the basic required software to glue the cloud together on the instances as listed below.

poolparty is easily configuration. In fact, it makes little assumptions about your development environment and allows several options on how to begin configuring the cloud. 

= Development setup

=== IN THE ENVIRONMENT

There are 5 values that poolparty reads from the environment, you can set these basic environment variables and leave the rest to the poolparty defaults. Those values are:

  ENV["ACCESS_KEY"] => AWS access key
  ENV["SECRET_ACCESS_KEY"] => AWS secret access key
  ENV["CONFIG_FILE"] => Location of your config yaml file (optional)
  ENV["EC2_HOME"] => EC2 home directory (defaults to ~/.ec2)
  ENV["KEYPAIR_NAME"] => The keypair used to launch instances

The structure assumed for the keypair is EC2_HOME/id_rsa-<keypairname>

=== IN A CONFIG FILE

poolparty assumes your config directory is set in config/config.yml. However, you can set this in your environment variables and it will read the config file from the environment variable

=== WITH A RAKE TASK

poolparty comes with a rake task that can setup your environment for you. Set the environment variables above and run
  
  rake dev:setup

This will write a .<KEYPAIR_NAME>_pool_keys into your home directory. Then you can just run
  
  source ~/.<KEYPAIR_NAME>_pool_keys

and your environment will be all setup for you everytime you want to work on the cloud

= Basics

poolparty can work in two ways to load balance it's traffic. It can either do server-side or client-side load-balancing. Since every instance load balances itself, you can either set the client to grab an instance and send it to that using client-side load balancing (with a js library). Alternatively, you can set the master in dns and reference it when referring to the application.

Since poolparty makes no assumptions as to what you will be hosting on the application, the world is your oyster when running a cloud. You can set each instance to register with a dynDNS service so that your application has multiple points of entry and can run load-balanced on the fly.

Every instance will auto-mount the s3 bucket set in the config file (if it is set up) into the /data folder of the instance. This gives each instance access to the same data regardless of the instance. It uses s3fuse and caching through s3fuse in the /tmp directory to work as fast as possible on the local instances.

The instances all are loaded with the following software:
  
* Haproxy - The basic load balancing software
* Heartbeat - The failover software
* S3Fuse - The mounting software for the s3 bucket
* Monit - The maintainer of the services to maintain services

When an instance is started or brought down, the master is responsible for reloading every instance with the new data on each instance. If the master goes down, the next in succession will take over as the master (using heartbeat) and it will reconfigure the cloud, setting itself as the master and take over the maintenance of the cloud.

Your cloud is never guaranteed to be maintained, but with more than 1 instance unless you have more than 1 instance up 

Each instance has a /etc/hosts file that has each node listed as the node name listed in the cloud:list (rake task).

= CloudSpeak - Communicating to your cloud(s)
Binaries!
Included in poolparty are two binaries to communicate back with your clouds. Those are:
  
* pool - operate on your pool. This includes list, start, stop maintain, restart. Check the help with pool -h
* instance - operate on a specific instance. This allos you to ssh, scp, reload, install as well. Check the help with: instance -h

The cloud can be maintained entirely through rake tasks, although there are a few front-ends being developed (one in cocoa). 

It is simple to include these tasks in your Rakefile. Just add the following lines:
  
  require "poolparty"
  PoolParty.include_cloud_tasks # or PoolParty.tasks or PoolParty.include_tasks
  
All the cloud rake tasks are in the cloud namespace and can be viewed with:

  rake -T cloud

The instance rake tasks are in the instance namespace and can be listed with:

  rake -T instance

For more help, check http://poolpartyrb.com 

== REQUIREMENTS:

* aws/s3
* aska
* EC2

== INSTALL:

  gem install auser-poolparty

== ROADMAP

v0.1.5 - Add AMI bundling tasks

== THANKS

Ron Evans, http://deadprogrammersociety.blogspot.com/ for his enthusiasm
Tim Goh, http://citrusbyte.com for sanity checks and thoughts
PJ Cabrera, http://pjtrix.com for excitement, thoughts and contribution
Blake Mizerany, http://sinatrarb.com/, for his support and ideas
Nicolás 'Foca' Sanguinetti, http://nicolassanguinetti.info/

== LICENSE:

(The MIT License)

Copyright (c) 2008 Ari Lerner. CitrusByte

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
