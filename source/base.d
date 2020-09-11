module djrpc.base;

import std.json;
import std.typecons : Nullable;

enum JsonRpcVersion : string {
    V1_0 = "1.0",
    V2_0 = "2.0"
}

interface JsonRpcMessage {
    JsonRpcVersion getVersion();
    static JsonRpcMessage parse(string msg);
    string encode();
}

interface JsonRpcRequest: JsonRpcMessage {
    JSONValue getID();
    string getMethod();
    JSONValue getParams();
}

interface JsonRpcResponse: JsonRpcMessage {
    JSONValue getID();
    bool success();
    Nullable!JSONValue getResult();
    Nullable!JSONValue getError();
}

interface JsonRpcNotification: JsonRpcMessage {

}
