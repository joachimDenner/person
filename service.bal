import ballerina/http;
import ballerina/openapi;

@openapi:ServiceInfo {
    title: "REST API Mot Neon Db",
    version: "1.0.0",
    description: "API för att hantera anställda"
}

service /rest_api_mot_neon_db on new http:Listener(8080) {
    isolated resource function get sayHelloEasy() returns string {
        return sayHelloEasy();
    }

    isolated resource function get sayHelloWithName(string name) returns string {
        return sayHelloWithName(name);
    }

    isolated resource function get sayHelloWithNameAndAge(string name, int age) returns string {
        return sayHelloWithNameAndAge(name, age);
    }
}