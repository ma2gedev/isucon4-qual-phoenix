# Isucon4

Phoenix implementation of isucon4 qual application

## debug mode

clone repository and run `mix deps.get`

`$ mix phoenix.server`

## production mode

`$ PORT=4000 MIX_ENV=prod mix phoenix.server`

## benchmark

results on my MacBook Air

```
# Phoenix
$ ./benchmarker bench --host=localhost:4000
23:19:39 type:info  message:!!! DEBUG MODE !!! DEBUGE MODE !!!
23:19:39 type:info  message:launch benchmarker
23:19:39 type:warning   message:Result not sent to server because API key is not set
23:19:39 type:info  message:init environment
23:19:44 type:info  message:run benchmark workload: 1
23:20:44 type:info  message:finish benchmark workload: 1
23:20:49 type:info  message:check banned ips and locked users report
23:21:28 type:report    count:banned ips    value:0
23:21:28 type:report    count:locked users  value:2543
23:21:28 type:info  message:Result not sent to server because API key is not set
23:21:28 type:score success:4720    fail:0  score:1020

# Ruby
$ ./benchmarker bench --host=localhost:8080
23:17:35 type:info  message:!!! DEBUG MODE !!! DEBUGE MODE !!!
23:17:35 type:info  message:launch benchmarker
23:17:35 type:warning   message:Result not sent to server because API key is not set
23:17:35 type:info  message:init environment
23:17:40 type:info  message:run benchmark workload: 1
23:18:40 type:info  message:finish benchmark workload: 1
23:18:45 type:info  message:check banned ips and locked users report
23:19:19 type:report    count:banned ips    value:0
23:19:19 type:report    count:locked users  value:2525
23:19:19 type:info  message:Result not sent to server because API key is not set
23:19:19 type:score success:3410    fail:0  score:737
```

## Requirements

- Erlang 17.4
- Elixir 1.0.4
