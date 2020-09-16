# djrpc

This a implementation of the [JSON-RPC](https://www.jsonrpc.org/) spec, written in D.
It is transport agnostic, there are alternative libraries but those assume TCP transport.

# Goals
- no dependencies
- support for 1.0 and 2.0
- tests
- not handling transport
