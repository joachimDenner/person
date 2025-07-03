//import ballerina/http;
//import ballerinax/postgresql;
//import ballerina/sql;


// configurable string USER = ?;
// configurable string PASSWORD = ?;
// configurable string HOST = ?;
// configurable int PORT = ?;
// configurable string DATABASE = ?;

// final postgresql:Client dbClient = check new postgresql:Client(
//     host = HOST,
//     username = USER,
//     password = PASSWORD,
//     port = PORT,
//     database = DATABASE,
//     options = {
//         ssl: {
//             mode: postgresql:REQUIRE
//         }
//     }
// );

// type anstalld record {|
//     int id;
//     string firstNamn;
//     string lastName;
//     string workTitle;
//     string created;
//     string updated;
//     string comment;
// |};


import ballerina/http;

service /hello on new http:Listener(8080) {
    resource function get sayHelloEasy() returns string {
        return "Hello, World!";
    }
    resource function get sayHelloWithName(string name) returns string {
        return "Hello, " + name + "!";
    }
    resource function get sayHelloWithNameAndAge(string name, int age) returns string {
        return "Hello, " + name + "! You are " + age.toString() + " years old.";
    }
}
