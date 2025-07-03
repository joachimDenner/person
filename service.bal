import ballerina/http;
import ballerina/openapi;

@openapi:ServiceInfo {
    title: "Anstalld API",
    version: "1.0.0",
    description: "API för att hantera anställda"
}

service /anstalld on new http:Listener(9090) {
  isolated resource function post .(@http:Payload anstalld anst) returns int|error? {
        return addAnstalld(anst);
    }  

    isolated resource function get [int id]() returns anstalld?|error? {
        return getAnstalld(id);
    }

    isolated resource function get .() returns (anstalld[]|error)? {
        return getAllAnstalld();
    }

    isolated resource function put .(@http:Payload anstalld anst) returns int|error? {
        return updateAnstalld(anst);
    }

    isolated resource function delete [int id]() returns int|error? {
        return removeAnstalld(id);
    }
}