import ballerina/http;
import ballerinax/postgresql;
import ballerina/sql;

type anstalld record {|
    int id;
    string firstNamn;
    string lastName;
    string workTitle;
    string created;
    string updated;
    string comment;
|};


service /anstalld on new http:Listener(8080) {
    resource function get getAnstalld(string name) returns string {
        return "Get anstalld, " + name + "!";
    }

    resource function get createAnstalld(string name) returns string {
        return "Create anstalld, " + name;
    }

    resource function get readAnstalld() returns string {
        return "Read anstallda";
    }
    resource function get updateAnstalld(string name) returns string {
        return "Update anstalld, " + name;
    }

    resource function get deleteAnstalld(string name) returns string {
        return "Delete anstalld, " + name;
    }
}
