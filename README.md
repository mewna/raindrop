# Raindrop

A distributed [snowflake](https://github.com/twitter/snowflake/tree/snowflake-2010)
generator. Please read the link for more info on snowflakes. The short version
is that snowflakes are unique 64-bit identifiers that encode some useful
information like timestamps. 

## WARNING

This is not production-ready. No attempt is made to protect against non-monotonic
clocks, or to prevent rollover within the same millisecond, or etc. Additionally,
worker id selection may take a *very* long time if you have many nodes - it just 
generates random numbers until it gets one that isn't used by another node. 

On top of this (as if there weren't enough issues amirite), Raindrop will wait
a maximum of 1000ms (to allow time to connect to nodes) before generating a 
worker id. Depending on your setup, this may not be enough time, and Raindrop
may end up connected to some or no nodes in the cluster when it starts finding
a worker id. 

## Usage

Raindrop is available as a Docker image: https://hub.docker.com/r/mewna/raindrop/

Raindrop uses Redis via [Lace](https://github.com/queer/lace) for building a cluster of generators. Use the following env. vars to run:

```Bash
# Port to run the generator on
PORT=1234
# IP of your redis host
REDIS_IP="localhost"
# Password of your redis host
REDIS_PASS="a"
# Name of the node. Used for clustering as well as Redis keys
NODE_NAME="raindrop"
# Name of the node group. Used for Redis keys
GROUP_NAME="raindrop"
# Erlang node cookie
# See http://erlang.org/doc/reference_manual/distributed.html §13.7 "Security"
COOKIE="586545388b1609f8098afa0ac941b8bda090a2753076a1611996291a35f5dd25"
# Epoch (in milliseconds) to create timestamps from. 
EPOCH="12345678901234567890"
```

Make sure that you have an `epmd` daemon running:

```
epmd -daemon
```

To generate snowflakes, simply send a `GET` request to `http://raindrop-location/`. 

## Picking apart ids

```Elixir
# << snowflake::integer-size(64) >>
# << 0::1, 11286889534::41, 123::10, 2047::12 >>
<< _sign::1, time::41, worker::10, seq::12 >> = Raindrop.Generator.gen_drop() 

# Sign bit doesn't matter to us, so it can be ignored or just set to zero
_sign::1,
# Timestamp of snowflake generation. Will be in millseconds from your configured epoch,
# ie. :os.system_time(:millisecond) - @epoch
time::41,
# Worker id. A random number
worker::10,
# Sequence number. Rolls over at 4096, ie. seqnums are on the range [0, 4096)
seq::12
>> = <<
# Sign bit, set to zero
0::1,
# Timestamp. Add your configured epoch to this to get the real time
11286889534::41,
# Random worker ID
123::10,
# Sequence number
2047::12 >>
```
