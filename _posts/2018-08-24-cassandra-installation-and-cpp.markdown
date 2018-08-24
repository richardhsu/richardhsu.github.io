---
layout: post
comments: true

title: "Cassandra Installation and C++ with Auth"
date: 2018-08-24 3:53:00 PM
tags: [Tutorial, Cassandra, C++]
---

I had the opportunity to experiment with Cassandra at one point and figured it was worth sharing my experience with
getting started on it. There's a good amount of documentation on it, but figured my distilled learnings here could be
helpful for others. At the very basic, I think Cassandra is great, it's a key value store has some origins from the
[Dynamo][dynamo] paper. I've also worked a lot with DynamoDB so it's interesting to compare, though they aren't
completely the same.

<!--more-->

## Introduction

From [Apache Cassandra website][cassandra]:

> The Apache Cassandra database is the right choice when you need scalability and high availability without
compromising performance. Linear scalability and proven fault-tolerance on commodity hardware or cloud infrastructure
make it the perfect platform for mission-critical data. Cassandra's support for replicating across multiple datacenters
is best-in-class, providing lower latency for your users and the peace of mind of knowing that you can survive
regional outages.

I was surprised to learn it was based on the Dynamo paper although has different design decisions as it's grown. But
at the very basic it reminded me a lot about DynamoDB in the beginning before I knew of this. But what was also
interesting about my experimenting with Cassandra was also playing around with the performance with a traditionally
relational design.

Overall it's scalable and fault-tolerant and very performant. I was able to play around with it in AWS and set up a
cluster spanning California to Virginia and seeing latencies around 300ms for client requests was great! There's a lot
of material on Cassandra so I won't go into those details as other sites can do a much better job as well as discussing
trade-offs with other competitors etc.

## Installation on Ubuntu

This isn't as interesting because like all great software, Cassandra actually gives clear cut installation instructions!
Honestly, I don't know why not all sites have easy to follow guides like this, so you can see it at
[Cassandra's Getting Started Guide][cassandra-install].

At the basic level, I first tested around on a single machine. I generally use [Vagrant][vagrant] for my development
needs and [SaltStack][salt] for provisioning which also I am familiar with in production environment.

### Salt Configuration

For those curious, since this may be more interesting is trying to convert this into a salt state. This was the salt
configuration I used for my vagrant machine (YAML file, see configuration for details):

```yaml
cassandra-pkg:
  pkgrepo.managed:
    - humanname: Cassandra PPA
    - name: deb http://www.apache.org/dist/cassandra/debian 311x main
    - dist: 311x
    - file: /etc/apt/sources.list.d/cassandra.sources.list
    - key_url: https://www.apache.org/dist/cassandra/KEYS
  pkg.installed:
    - name: cassandra

/etc/cassandra/cassandra.yaml:
  file.managed:
    - source: salt://cassandra/cassandra.yaml

cassandra:
  service.running:
    - enable: True
    - init_delay: 5
    - watch:
      - file: /etc/cassandra/cassandra.yaml

# Install CPP Drivers (DataStax)
cassandra-cpp-pkgs:
  pkg.latest:
    - pkgs:
      - cmake
      - build-essential
      - libssl-dev
      - libuv1-dev

/opt/install/cassandra-cpp:
  git.latest:
    - name: https://github.com/datastax/cpp-driver.git
    - rev: 2.9.0
    - target: /opt/install/cassandra-cpp
    - force_checkout: True
    - force_reset: True

cassandra-cpp.install:
  cmd.wait:
    - name: "ldconfig && cd /opt/install/cassandra-cpp && mkdir build && cd build && cmake .. && make && make install && ldconfig"
    - watch:
      - git: /opt/install/cassandra-cpp
```

## Configuration

Below are the various settings I changed for my experiment. In most part I had the following configuration:

* For vagrant, it was just a single machine so nothing too special
* For experiment, I had 3 regions (California, Oregon, Virginia) and in each region there were 3 nodes which were
distributed amongst the various availability zones.

The following were updated in the `cassandra.yaml` configuration file:

### Step 1: Change the Cluster Name

```yaml
cluster_name: 'CassandraExperimentCluster'
```

I ended up giving the cluster a different name since the default is `Test Cluster`. Oh how a headache this gave.
Apparently once Cassandra service starts up it fixes this cluster name in the system configuration! So in order to
properly start up the new cluster, you'll likely need to do the following **after** you've finished modifying the YAML
configuration file:

```bash
sudo service cassandra stop
sudo rm -rf /var/lib/cassandra/data/system/*
```

This allows Cassandra to pick up the new configuration and changes the cluster name rather than using the old one.
**Warning:** This will delete all the data, so do this as soon as possible once you've configured the YAML file.

> For vagrant, I used the value `Test Cluster` still since that's just easiest otherwise have to deal with the system
data purge for Cassandra

### Step 2: Change the Snitch Endpoint

```yaml
endpoint_snitch: GossipingPropertyFileSnitch
```

This Snitch allows the nodes to "gossip" and have protocol for determining datacenter and rack information for the
cluster. This is described more in detail in the YAML file so you can choose a different one, such as
`Ec2MultiRegionSnitch` if you're on AWS. I didn't use this since I used all internal IPs and wasn't sure if the
`Ec2MultiRegionSnitch` would work without the public IPs.

> For vagrant, I used the value `SimpleSnitch` as default since there's only one node.

### Step 3: Change Seed Providers

The seed providers only need to be a few of the nodes, not all of them. I elected a single node in each region to be
the seeds, ended up just being first machines I brought up in each region. Then I grabbed their internal IPs:

```yaml
seed_provider:
    # Addresses of hosts that are deemed contact points.
    # Cassandra nodes use this list of hosts to find each other and learn
    # the topology of the ring.  You must change this if you are running
    # multiple nodes!
    - class_name: org.apache.cassandra.locator.SimpleSeedProvider
      parameters:
          # seeds is actually a comma-delimited list of addresses.
          # Ex: "<ip1>,<ip2>,<ip3>"
          - seeds: "10.0.0.1,10.0.1.2,10.0.2.3"
```

The IPs above are just examples but since they were in 3 different regions, I had 3 different subnets which is why
the internal IPs aren't all on same subnet.

> For vagrant, the default of `127.0.0.1` was still maintained since there weren't any real nodes talking to other
nodes and it'd be the only seed anyways.

### Step 4: Change the Listening and RPC addresses

This was an interesting point, I didn't change all the IPs correctly to the corresponding machines so when I first
connected to the cluster, it'd throw error trying to "connect" to `127.0.0.1` in the production environment which
didn't make sense since the client wasn't running a Cassandra node. But it was because one of my nodes didn't have
all the addresses set in the configuration so when it connected to the cluster, it was told to connect to that node
and that node said to use `127.0.0.1`.

For each node, I configured the addresses to be based on its internal IP address, so in this snippet it's for node
with the IP of `10.0.0.3`:

```yaml
listen_address: 10.0.0.3
rpc_address: 0.0.0.0
broadcast_rpc_address: 10.0.0.3
```

Note, the documentation states that you don't want to expose to the internet, so I actually have Firewall as well as
the fact that the machines are on an internal network. (I use a bastion machine to connect to the nodes)

> For vagrant, this is just the defaults of `localhost` and the `broadcast_rpc_address` is commented out still.

This allows it to communicate across machines and with client; however, make sure you have the right ports open, in
general I ended up opening the following ports:

* 7000 - For inter-node cluster gossip communication
* 7001 - For SSL inter-node cluster communication (Although I didn't set up SSL yet)
* 7199 - For JMX monitoring
* 9042 - For CQL client communications (clients and `cqlsh`)

### Step 5: Change the DC and Rack Properties

The above was for the `cassandra.yaml` file, this next bit is just for the `cassandra-rackdc.properties` file:

```yaml
dc=us-west-1
rack=us-west-1b
```

This was interesting, but I ended up assigning the `dc` or `datacenter` to be the region name from AWS and the `rack`
to be the availability zone since that's best guarantee can get similar to a rack setup.

----------

At this point, we've configured what we can, and can now start up the nodes again.

* First start up each seed node one by one with `sudo service cassandra start`
* Then start up the remaining nodes once all seeds are up and running. You can use `nodetool status` to see the nodes
and how they are doing.

## Testing with CQLSH

Cassandra comes with an interactive shell that you can use called `cqlsh`. It's nice and handy and it comes with the
installation of Cassandra through the package. If you want it on a separate machine you can install it through `pip`:

```bash
sudo apt-get install python-pip
pip install cassandra-driver
pip install cqlsh
```

From there I used `CQLSH_NO_BUNDLED=true cqlsh -u cassandra -p cassandra` in order to connect and you'll see the
console:

```
cassandra@cqlsh>
```

### Setting Up User and Keyspace

At this point Cassandra is running and things are looking good. Now let's first set up a separate user from the default:

#### Step 1: Modify System Data to Replicate

First modify the `system_auth` to replicate, this is important, otherwise you'll get authorization issues or even
update issues when trying to modify or add a role:

```sql
ALTER KEYSPACE system_auth WITH REPLICATION = { 'class': 'NetworkTopologyStrategy', 'us-west-1': 2, 'us-west-2': 2, 'us-east-1': 2 }
```

I ended up using a replication factor of 2 since there are 3 nodes in each region. The formatting is generally the
datacenter name and then replication factor. The higher the replication factor, the more gossip will occur so just
think about that tradeoff. For authentication, you could put it at highest if wanted since that's fairly important,
but for your other keyspaces, changing it to your desired effect may be best.

#### Step 2: Add New User

Next you can now add your new user with the password:

```sql
CREATE ROLE IF NOT EXISTS experiment WITH SUPERUSER = true AND LOGIN = true AND PASSWORD = '<PASSWORD_HERE>';
```

#### Step 3: Change Cassandra's Default Password

Finally you can change `cassandra` default password:

```sql
ALTER USER cassandra WITH PASSWORD '<RANDOM_PASSWORD>';
```

#### Step 4: Set up Keyspace

Finally set up your new keyspace:

```sql
CREATE KEYSPACE experimentapp WITH REPLICATION = { 'class': 'NetworkTopologyStrategy', 'us-west-1': 2, 'us-west-2': 2, 'us-east-1': 2 }
```

I ended up using same replication set up as the system auth, but you can vary it depending on how you feel. At this
point you can start creating your tables as you normally would in the console. Here's quick example for users:

```sql
CREATE TABLE experimentapp.users (
  id bigint,
  name text,
  email text,
  PRIMARY KEY (id)
);

CREATE INDEX users_email ON experimentapp.users (email);
```

This creates my table with primary key of `id` that we'd look up users but also an index on `email` for easy lookups
by `email`!

## C++ Connection

So we've set up our keyspace and nodes, now we want to connect. There are various clients and drivers that you can use,
but since I like C++ and there's usually less documentation C++ figured I'd write out my examples of connecting in C++
as some added benefit to the community (*hopefully*).

On bright side DataStax has some great drivers so I ended up using their [C++ Driver][datastax-driver] which you can
reference their examples for some more details. But the following I felt were some stuff I had to dig through the
documentation more than just using a simple drop in code snippet:

I ended up creating a singleton client class: `CassandraSingleton` which basically looks like this for
`cassandra_singleton.h`:

```cpp
#pragma once

#include <cassandra.h>
#include <string>

using namespace std;

class CassandraException : public exception {
public:
  virtual ~CassandraException() throw() {}
  virtual const char* what() const noexcept override { return "CassandraException"; }
  string error_msg_;
};


// Credentials data object
struct CassandraCredentials {
  const string username;
  const string password;
};

// Interface to Cassandra keyspaces. Allows reading and writing of objects.
class CassandraSingleton {
public:
  CassandraSingleton();
  virtual ~CassandraSingleton();

  static void configure(const string &hosts, const string &user, const string &password);
  static void teardown();

  // Basic Operations
  // Writes returns status of write if succeeds otherwise errors with error message
  static bool cassandra_write(CassStatement *statement, string *error);
  // Reads will return a future to get results and throws exception on error.
  // Fails as likely SELECT was written incorrectly and you should know ASAP
  static CassFuture *cassandra_select(CassStatement *statement);

private:
  // Initialize the session to be used
  static void initialize_connection();

  static string hosts_;
  static string user_;
  static string password_;
  static bool initialized_;
  static CassCluster *cluster_;
  static CassSession *session_;
};
```

And finally the definition `cassandra_singleton.cc`:

```cpp
#include "cassandra_singleton.h"

#include <glog/logging.h>

string CassandraSingleton::hosts_;
string CassandraSingleton::user_;
string CassandraSingleton::password_;
bool CassandraSingleton::initialized_ = false;
CassCluster *CassandraSingleton::cluster_ = NULL;  // Note: This can be shared across threads
CassSession *CassandraSingleton::session_ = NULL;  // Note: This can be shared across threads

CassandraSingleton::CassandraSingleton() {}

CassandraSingleton::~CassandraSingleton() {}

void CassandraSingleton::configure(const string &hosts, const string &user,
                                   const string &password) {
  hosts_ = hosts;
  user_ = user;
  password_ = password;
  if (!initialized_) { initialize_connection(); }
}

void CassandraSingleton::teardown() {
  // Close the session
  CassFuture *close_future = cass_session_close(session_);
  cass_future_wait(close_future);
  cass_future_free(close_future);

  // Free cluster and session
  cass_cluster_free(cluster_);
  cass_session_free(session_);
}

namespace {
  // Callback for Cassandra authentication to initiate authentication exchange
  // See initialize_connection for callbacks
  void on_auth_initial(CassAuthenticator *auth, void *data) {
    const CassandraCredentials* credentials = (const CassandraCredentials *) data;

    size_t username_size = credentials->username.size();
    size_t password_size = credentials->password.size();
    size_t size = username_size + password_size + 2;

    char *response = cass_authenticator_response(auth, size);

    // Credentials are prefixed with '\0'
    response[0] = '\0';
    memcpy(response + 1, credentials->username.c_str(), username_size);

    response[username_size + 1] = '\0';
    memcpy(response + username_size + 2, credentials->password.c_str(), password_size);
  }
};

void CassandraSingleton::initialize_connection() {
  cluster_ = cass_cluster_new();
  session_ = cass_session_new();
  cass_cluster_set_contact_points(cluster_, hosts_.c_str());

  // Callbacks initial, challenge, success, cleanup
  // Only initial needed for simple auth as other fields are used for
  // other systems like Kerberos etc
  CassAuthenticatorCallbacks auth_cbs = { on_auth_initial, NULL, NULL, NULL };
  CassandraCredentials credentials = { user_, password_ };

  cass_cluster_set_authenticator_callbacks(cluster_, &auth_cbs, NULL, &credentials);
  CassFuture *connect_future = cass_session_connect(session_, cluster_);
  if (cass_future_error_code(connect_future) == CASS_OK) {
    initialized_ = true;
    LOG(INFO) << "Connected to Cassandra for hosts " << hosts_;
    cass_future_free(connect_future);
    return;
  }
  // Errored so grab message and throw exception
  const char *message;
  size_t message_length;
  cass_future_error_message(connect_future, &message, &message_length);
  CassandraException exception;
  exception.error_msg_ = "Could not connect to Cassandra database: " + string(message);
  LOG(ERROR) << exception.error_msg_;
  cass_future_free(connect_future);
  throw exception;
}

bool CassandraSingleton::cassandra_write(CassStatement *statement, string *error) {
  CassFuture* future = cass_session_execute(session_, statement);
  cass_future_wait(future);
  if (cass_future_error_code(future) == CASS_OK) {
    cass_future_free(future);
    return true;
  }
  // Errored so grab message and return up
  const char* message;
  size_t message_length;
  cass_future_error_message(future, &message, &message_length);
  error->assign(message);
  cass_future_free(future);
  return false;
}

CassFuture *CassandraSingleton::cassandra_select(CassStatement *statement) {
  CassFuture *future = cass_session_execute(session_, statement);
  cass_future_wait(future);
  if (cass_future_error_code(future) == CASS_OK) {
    return future;
  }
  // Errored so grab message and throw exception
  const char* message;
  size_t message_length;
  cass_future_error_message(future, &message, &message_length);
  CassandraException exception;
  exception.error_msg_ = "SELECT failed for Cassandra query: " + string(message);
  LOG(ERROR) << exception.error_msg_;
  cass_future_free(future);
  throw exception;
}
```

I've extracted the "write" and "select" pretty much since overall constructing the statement and then passing it to
something to handle the future and message seemed modular enough.

### Writing

An example call for `INSERT` might look like:

```cpp
const string query = "INSERT INTO experimentapp.users (id, name, email) VALUES (?, ?, ?)";
CassStatement *statement = cass_statement_new(query.c_str(), 3);
cass_statement_bind_int64(statement, 0, id);  // Note: id, name, email initialized elsewhere
cass_statement_bind_string(statement, 1, name);
cass_statement_bind_string(statement, 2, email);
string error;
const bool result = CassandraSingleton::cassandra_write(statement, &error);
cass_statement_free(statement);
```

### Reading

An example call for `SELECT` might look like:

```cpp
const string query = "SELECT * FROM experimentapp.users WHERE id = ?";
CassStatement *statement = cass_statement_new(query.c_str(), 1);
cass_statement_bind_int64(statement, 0, id);
CassFuture *future = cassandra_select(statement);
const CassResult *result = cass_future_get_result(future);
CassIterator *iterator = cass_iterator_from_result(result);
while (cass_iterator_next(iterator)) {
  const CassRow *row = cass_iterator_get_row(iterator);
  // .. Get your data from the row ..
}
cass_future_free(future);
cass_result_free(result);
cass_iterator_free(iterator);
```

You can even go as far as refactoring this so that you have a method that either takes in a lambda or you can store
the data in some structure and return that instead. Unfortunately though, since there's more objects needed for
retrieval of results and clean up it isn't as easy to pull it out and remove the "behind the scene" objects like the
future and such.

## Conclusion

Well, I hope this helps someone! Let me know if it does as I always like being able to talk about these things but
sometimes it's hard to find time to write these things up or it doesn't feel as worthwhile but since I spent some
time digging around, figured this could help others learn a bit about setting up Cassandra!

All this was compiled from various documents on [DataStax][datastax], [DataStax driver repository][datastax-driver],
and [Cassandra's documentation][cassandra-doc].

[dynamo]: https://www.allthingsdistributed.com/files/amazon-dynamo-sosp2007.pdf
[cassandra]: http://cassandra.apache.org/
[vagrant]: https://www.vagrantup.com/
[salt]: https://saltstack.com/
[cassandra-install]: http://cassandra.apache.org/doc/latest/getting_started/installing.html
[datastax-driver]: https://github.com/datastax/cpp-driver
[datastax]: https://www.datastax.com/dev/blog/getting-started-with-the-datastax-c-driver
[cassandra-doc]: http://cassandra.apache.org/doc/latest/
