# Crowdsec

[Crowdsec](https://docs.crowdsec.net/docs/intro) is an open-source, lightweight agent to detect and respond to bad behaviors. It also automatically benefits from our global community-wide IP reputation database

Crowdsec is composed of an `agent` that parses logs and creates alerts, and a `local API (LAPI)`
that transforms these alerts into decisions.
The agent and the LAPI can run on the same node/container or separately (the `agent` must be present to take action).
In complex configurations, it makes sense to have `agents` on each machine that runs the protected applications,
and a single LAPI that gathers all signals from agents and communicates with the central API.

## `cscli`: crowdsec terminal interface

[installation instructions](https://docs.crowdsec.net/docs/user_guides/cscli_macos/)

- compile and install natively
- run in container

## OPNsense

Crowdsec offers an OPNsense plugin [ref](https://docs.crowdsec.net/docs/getting_started/install_crowdsec_opnsense/).

By installing the CrowdSec plugin, available through the OPNsense repositories, you can:

- use the OPNsense server as LAPI for other agents and bouncers
- deploy an agent on OPNsense and scan its logs for attacks
- block attackers from your whole network with a single firewall bouncer
- list the hub plugins (parsers, scenarios..) and decisions on the OPNsense admin interface

### OPNsense config

In general, the default installation configuration is just fine on OPNsense.

- if using OPNsense deployment as central LAPI, set LAPI listen address in `Services > CrowdSec > Settings`
- it may make sense to whitelist internal IP addresses:

  ```txt
  # /path/to/crowdsec/parsers/s02-enrich/whitelist.yaml
  name: admin-whitelist
  description: "Whitelist events from private/admin ipv4 addresses"
  whitelist:
    reason: "private ipv4/ipv6 ip/ranges"
    ip:
      - "127.0.0.1"
      -  "::1"
      - "<opnsense ips>"
      - "<network infra IP>"
      - "<admin static IP>"
  ```

## [Multi-server](https://docs.crowdsec.net/docs/user_guides/multiserver_setup)

- The agent is in charge of processing the logs, matching them against scenarios,
  and sending the resulting alerts to the local API
- The local API (LAPI from now on) receives the alerts and converts them into decisions based on your profile
- The bouncer(s) query the LAPI to receive the decisions to be applied
