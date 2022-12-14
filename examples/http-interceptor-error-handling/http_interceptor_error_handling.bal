import ballerina/http;

type Album readonly & record {|
    string title;
    string artist;
|};

table<Album> key(title) albums = table [
    {title: "Blue Train", artist: "John Coltrane"},
    {title: "Sarah Vaughan and Clifford Brown", artist: "Sarah Vaughan"}
];

service class RequestInterceptor {
    *http:RequestInterceptor;

    resource function 'default [string... path](@http:Header string x\-api\-version, 
            http:RequestContext ctx) returns http:NotImplemented|http:NextService|error? {
        if x\-api\-version != "v1" {
            return http:NOT_IMPLEMENTED;
        }
        return ctx.next();
    }
}

RequestInterceptor requestInterceptor = new;

// A `RequestErrorInterceptor` service class implementation. It allows you to 
// intercept the error that occurred in the request path and handle it accordingly.
// A `RequestErrorInterceptor` service class can have only one resource function.
service class RequestErrorInterceptor {
    *http:RequestErrorInterceptor;

    // The resource function inside a `RequestErrorInterceptor` is only allowed 
    // to have the default method and path. The error occurred in the interceptor
    // execution can be accessed by the mandatory argument: `error`.
    resource function 'default [string... path](error err) returns http:BadRequest {
        // In this case, all of the errors are sent as `400 BadRequest` responses with a customized
        // media type and body. You can also send different status code responses according to
        // the error type. Furthermore, you can also call `ctx.next()` if you want to continue the 
        // request flow after fixing the error.
        return {
            mediaType: "application/org+json",
            body: {message: err.message()}
        };
    }
}

// Creates a new `RequestErrorInterceptor`.
RequestErrorInterceptor requestErrorInterceptor = new;

listener http:Listener interceptorListener = new http:Listener(9090, config = {
    // To handle all of the errors in the request path, the `RequestErrorInterceptor`
    // is added as the last interceptor as it has to be executed last. 
    interceptors: [requestInterceptor, requestErrorInterceptor] 
});

service / on interceptorListener {

    resource function get albums() returns Album[] {
        return albums.toArray();
    }
}
