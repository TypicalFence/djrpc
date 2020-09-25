module djrpc.v2;

import std.exception;
import std.json;
import std.typecons : Nullable;
import djrpc.base;
import djrpc.exception;

class JsonRpc2Request : JsonRpcRequest {
    private JSONValue id;
    private string method;
    private JSONValue params;
    
    this(JSONValue id, string method, JSONValue params) {
        this.id = id;
        this.method = method;
        this.params = params;
    }

    JsonRpcVersion getVersion() {
        return JsonRpcVersion.V2_0;
    }
    
    static JsonRpcMessage parse(string msg) {
        JSONValue data = parseJSON(msg);
        
        string rpc_version = data["jsonrpc"].str;

        if (rpc_version != "2.0") {
            throw new MalformedRpcMessageException("not a jsonrpc 2.0 request");
        }

        JSONValue id = data["id"];
        string method = data["method"].str;
        JSONValue params;

        if (("params" in data) != null) {
            params = data["params"];
        } else {
            params = JSONValue(null);
        }

        return new JsonRpc2Request(id, method, params);
    }

    string encode() {
        JSONValue request = [ "id": this.id ];
        request["jsonrpc"] = JsonRpcVersion.V2_0;
        request["method"] = this.method;
        request["params"] = this.params;
        return toJSON(request);
    }

    JSONValue getID() {
        return this.id;
    }
    
    string getMethod() {
        return this.method;
    }

    JSONValue getParams() {
        return this.params;
    }
}

@("request valid jsonrpc")
unittest {
    string json = "{\"jsonrpc\": \"2.0\", \"method\": \"subtract\", \"params\": [42, 23], \"id\": 1}";
    JsonRpc2Request req = cast(JsonRpc2Request) JsonRpc2Request.parse(json);

    assert(req.getVersion() == JsonRpcVersion.V2_0);
    assert(req.getID().integer == 1);
    assert(req.getMethod() == "subtract");
}

@("request omit params")
@("valid jsonrpc 2.0 request")
unittest {
    string json = "{\"jsonrpc\": \"2.0\", \"method\": \"subtract\", \"id\": 1}";
    assertNotThrown!MalformedRpcMessageException(JsonRpc2Request.parse(json));
}

@("request wrong version number")
unittest {
    string json = "{\"jsonrpc\": \"1.0\", \"method\": \"subtract\", \"params\": [], \"id\": 1}";
    assertThrown!MalformedRpcMessageException(JsonRpc2Request.parse(json));
}

class JsonRpc2Response : JsonRpcResponse {
    private JSONValue id;
    private Nullable!JsonRpc2Error error;
    private Nullable!JSONValue result;
    
    this(JSONValue id, Nullable!JsonRpc2Error err, Nullable!JSONValue result) {
        this.id = id;
        this.error = err;
        this.result = result;
    }

    JsonRpcVersion getVersion() {
        return JsonRpcVersion.V2_0;
    }
    
    static JsonRpcMessage parse(string msg) {
        JSONValue data = parseJSON(msg);
        
        string rpc_version = data["jsonrpc"].str;

        if (rpc_version != "2.0") {
            throw new MalformedRpcMessageException("not a jsonrpc 2.0 response");
        }

        JSONValue id = data["id"];
        Nullable!JsonRpc2Error error = Nullable!JsonRpc2Error.init;
        Nullable!JSONValue result = Nullable!JSONValue.init;

        if ("error" in data) {
            error = Nullable!JsonRpc2Error(JsonRpc2Error.fromJSON(data["error"]));
        }

        if ("result" in data) {
            result = Nullable!JSONValue(data["result"]);
        }

        return new JsonRpc2Response(id, error, result);
    }

    string encode() {
        JSONValue request = [ "id": this.id ];
        request["jsonrpc"] = JsonRpcVersion.V2_0;
        
        if(this.error.isNull) {
            request["result"] = this.result.get;
        } else {
            request["error"] = this.error.get.toJSON;
        }

        return toJSON(request);
    }


    JSONValue getID() {
        return this.id;        
    }

    bool success() {
        return error.isNull;
    }

    Nullable!JSONValue getResult() {
        return this.result;
    }

    Nullable!JSONValue getError() {
        if (!this.error.isNull) {
            JsonRpc2Error err = this.error.get;
            return Nullable!JSONValue(err.toJSON());
        }

        return Nullable!JSONValue.init;
    }

    Nullable!JsonRpc2Error getErrorObject() {
        return this.error;
    }
}

@("response valid jsonrpc 2.0")
unittest {
    string json = "{\"jsonrpc\": \"2.0\", \"result\": 19, \"id\": 1}";
    JsonRpc2Response res = cast(JsonRpc2Response) JsonRpc2Response.parse(json);

    assert(res.getVersion() == JsonRpcVersion.V2_0);
    assert(res.getID().integer == 1);
    assert(!res.getResult.isNull());
    assert(res.getError.isNull());
    assert(res.getResult.get().integer() == 19);
}

@("response valid with error")
unittest {
    string json = "{\"jsonrpc\": \"2.0\", \"error\": {\"code\": -32601, \"message\": \"Method not found\"}, \"id\": \"1\"}";
    JsonRpc2Response res = cast(JsonRpc2Response) JsonRpc2Response.parse(json);

    assert(res.getVersion() == JsonRpcVersion.V2_0);
    assert(res.getID().str() == "1");
    assert(res.getResult.isNull());
    assert(!res.getError().isNull());
    assert(res.getErrorObject().getCode() == -32601);
}

class JsonRpc2Error {
    private long code;
    private string message;
    private Nullable!JSONValue data;

    this(long code, string msg, Nullable!JSONValue data) {
        this.code = code;
        this.message = msg;
        this.data = data;
    }

    static JsonRpc2Error fromJSON(JSONValue json) {
        long code = json["code"].integer;
        string msg = json["message"].str;
        Nullable!JSONValue data = Nullable!JSONValue.init;

        if ("data" in json) {
            data = Nullable!JSONValue(json["data"]);
        }

        return new JsonRpc2Error(code, msg, data);
    }

    JSONValue toJSON() {
        JSONValue json = JSONValue();
        json["code"] = this.code;
        json["message"] = this.message;
        
        if (!this.data.isNull()) {
            json["data"] = this.data.get();
        }

        return json;
    }

    long getCode() {
        return this.code;
    }

    string getMessage() {
        return this.message;
    }

    Nullable!JSONValue getData() {
        return this.data;
    }
}
