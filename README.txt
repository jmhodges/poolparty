= PoolParty
  Ari Lerner
  Nicolás Sanguinetti
  CitrusByte
  http://blog.citrusbyte.com

== DESCRIPTION:

Run your entire application off Amazon's EC2 cloud, dynamically sized based on server-load and backup to the S3 database. The gem is packed full of power and is intended on being both highly configurable while providing an easily understandable interface to the functionality.

You can either run the entire application off the EC2 cloud or run the small monitor on an offsite, stable server and let your application be run entirely on the cloud. Due to the volatility of the cloud, we recommend that you use a server off-site to ensure maximum stability. (I use slicehost)

== Basics

The gem requires you to have a config.yml file that all the instances and the monitor have access. Again, I suggest that this is hosted on the S3 system as it is universally accessible. Alternatively, if it rarely changes, you can place this in the application directory, in an svn repository, etc. Either way, the gem needs access to the <tt>config.yml</tt> file.

To get started, you'll need a <tt>config.yml</tt>. A basic one is in the <tt>test_app/config</tt> directory is as follows:

== config.yml attributes

  defaults: &defaults
    app_name: "test_app"
    user_id: "XXXX-XXXX-XXXX"
    access_key_id: "XXXXXXXXXXXXXXX"
    secret_access_key: "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    server_pool_bucket: "pool_party_test-bucket"
    cookie_bucket: "pool_party-cookies"
    ami: "ami-9cXXXXXXX"
    heavy_load: 0.75 
    light_load: 0.25 
    polling_time: "30.seconds"
    interval_wait_time: "5.minutes"
    minimum_instances: 1
    maximum_instances: 2
  development:
    <<: *defaults
  production:
    <<: *defaults
    
Most of these should be self explanatory. For more information, check out <a href="http://poolpartyrb.com">http://www.poolpartyrb.com/</a>

== Client
In your application, add the following line:

  PoolParty.client("config/config.yml", :env => "production")
  
With just that one line, if your application is started on an ec2 instance, it will register itself in the bucket and expand its cloud appropriately, using the bucket as a registration. However, you need an end-point to point the browser. This is where the monitor comes in.

== Monitor

The monitor is the server that you point your browser to. This is the stable server, or the application with on an ec2 instance (the master instance). 

Edit 
  
  ruby start_pool_party -e production -p 7788
  
Now, your monitor will load the registered instances from the s3 bucket and proxy any requests directed to it to the instances. It attempts to soft load balance the requests based on the number of hits directed at each one sorted against their load averages.

There is an example in the <tt>test/test_app</tt> directory. 

== REQUIREMENTS:
  * yaml
  * aws/s3
  * sqs
  * EC2
  * rack
  * fastthread

== INSTALL:

  gem install pool_party

== ROADMAP
* v0.1.0 - Add SQS task support
* v0.2.0 - Callback support

== LICENSE:

(The MIT License)

Copyright (c) 2008 FIX

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
