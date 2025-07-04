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
    //   Hämta (GET) en anställd
    resource function get hamtaAnstalld(int id) returns json {
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
    resource function get allaAnstallda() returns json {
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

    resource function get updateAnstalld(string name) returns string {
        return "Update anstalld, " + name;
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