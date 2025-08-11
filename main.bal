import ballerina/http;
import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;
import ballerina/sql;

type anstalld record {|
    int id?;
    string firstNamn;
    string lastName;
    string workTitle;
    string created;
    string updated;
    string comment;
|};

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

service /anstalld on new http:Listener(8080) {
    //   Hämta (GET) en anställd
    resource function get hamtaAnstalldX(int id) returns json {
        sql:ParameterizedQuery query = `SELECT * FROM anstalld WHERE id = ${id}`;
        stream<anstalld, error?> resultStream = dbClient->query(query);

        anstalld[] resultList = [];
        error? e = resultStream.forEach(function(anstalld row) {
            resultList.push(row);
        });

        if e is error {
            return {
                "message": "Kunde inte hämta anställda: " + e.message()
            };
        }
        return <json>resultList;
    }

   // Skapa (POST) en ny anställd
    resource function post skapaAnstalld(anstalld anst) returns json|error {
        sql:ParameterizedQuery query = `INSERT INTO anstalld (
                "firstNamn", 
                "lastName", 
                "workTitle",
                "created",
                "updated",
                "comment"
            ) VALUES (
                ${anst.firstNamn}, 
                ${anst.lastName},
                ${anst.workTitle}, 
                ${anst.created}, 
                ${anst.updated},
                ${anst.comment}
            ) RETURNING id`;

        int insertedId = check dbClient->queryRow(query, int);
        if insertedId > 0 {
            return {
                message: "Anställd skapades!",
                id: insertedId
            };
        } else {
            return {
                message: "Kunde inte skapa ny anställd!"
            };
        }
    }


    //   Hämta (GET) alla anställda
    resource function get hamtaAllaAnstallda() returns json {
        sql:ParameterizedQuery query = `SELECT * FROM anstalld`;
        stream<anstalld, error?> resultStream = dbClient->query(query);

        anstalld[] resultList = [];
        error? e = resultStream.forEach(function(anstalld row) {
            resultList.push(row);
        });

        if e is error {
            return {
                "message": "Kunde inte hämta anställda: " + e.message()
            };
        }
        return <json>resultList;
    }

    // Uppdatera (PUT) en anställd
    resource function put uppdateraAnstalld(int id, anstalld anst) returns json|error {
        sql:ParameterizedQuery query = `UPDATE anstalld SET
                "firstNamn" = ${anst.firstNamn},
                "lastName" = ${anst.lastName},
                "workTitle" = ${anst.workTitle},
                "created" = ${anst.created},
                "updated" = ${anst.updated},
                "comment" = ${anst.comment}
            WHERE id = ${id}`;

        sql:ExecutionResult result = check dbClient->execute(query);
        int? affectedRowCount = result.affectedRowCount;

        if affectedRowCount is int && affectedRowCount > 0 {
            return {
                message: "Anställd uppdaterades!",
                id: id
            };
        } else {
            return {
                message: "Kunde inte uppdatera anställd!"
            };
        }
    }

    //  Ta bort (DELETE) en anställd
    resource function delete tabortAnstalld(int id) returns json {
        sql:ExecutionResult|error execResult = dbClient->execute(`
        DELETE FROM anstalld WHERE id = ${id}
        `);

        if execResult is sql:ExecutionResult {
            int? affectedRowCount = execResult.affectedRowCount;
            if affectedRowCount is int && affectedRowCount == 0 {
                return { "message": "Anställd med id: " + id.toString() + " saknas!" };
            }
                        
            if affectedRowCount is int && affectedRowCount > 0 {
                return { "message": "Anställd med id: " + id.toString() + " borttagen!" };
            }
            
        } else {
            return { "message": "Fel inträffade vid borttagning: " + execResult.message() };
        }
    }
}   