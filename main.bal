import ballerina/time;
import ballerinax/postgresql;
import ballerina/sql;

isolated function sayHelloEasy() returns string {
        result = "Hello, World!";
        return result;
    }

isolated function sayHelloWithName(string name) returns string {
        result = "Hello, " + name + "!";
        return result;
    }

isolated function sayHelloWithNameAndAge(string name, int age) returns string {
        result = "Hello, " + name + "! You are " + age.toString() + " years old.";
        return result;
    }