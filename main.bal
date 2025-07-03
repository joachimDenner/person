import ballerina/http;
import ballerinax/postgresql;
//import ballerina/sql;

type anstalld record {|
    int id;
    string firstNamn;
    string lastName;
    string workTitle;
    string created;
    string updated;
    string comment;
|};

final postgresql:Client dbClient = check new postgresql:Client(
    host = "ep-twilight-darkness-a93wnhjw-pooler.gwc.azure.neon.tech",
    username = "neondb_owner",
    password = "npg_hgGofDq81sXy",
    port = 5432,
    database = "my_test_db_in_neon",
    options = {
        ssl: {
            mode: postgresql:REQUIRE
        }
    }
);

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
