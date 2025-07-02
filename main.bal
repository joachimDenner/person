import ballerina/http;

service /hello on new http:Listener(8080) {
    resource function get sayHello() returns string {
        return "Hello, World!";
    }
}
