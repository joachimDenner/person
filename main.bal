import ballerina/http;
import ballerinax/postgresql;
//import ballerina/sql;


configurable string USER = ?;
configurable string PASSWORD = ?;
configurable string HOST = ?;
configurable int PORT = ?;
configurable string DATABASE = ?;

final postgresql:Client dbClient = check new postgresql:Client(
    host = HOST,
    username = USER,
    password = PASSWORD,
    port = PORT,
    database = DATABASE,
    options = {
        ssl: {
            mode: postgresql:REQUIRE
        }
    }
);

type anstalld record {|
    int id;
    string firstNamn;
    string lastName;
    string workTitle;
    string created;
    string updated;
    string comment;
|};

service /anstalld on new http:Listener(9090) {

    // GET: Hämta alla anställda
    resource function get .() returns string {
        string result = "Hämtar alla anställda";
        return result;
    }

    // GET: Hämta en anställd via id
    resource function get [int id]() returns string {
        string result = "Hämtar EN anställda" + id.toString();
        return result;
    }
}
