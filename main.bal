import ballerina/time;
import ballerinax/postgresql;
import ballerina/sql;

public type anstalld record {
    int id?;
    string firstNamn;
    string lastName;
    string workTitle;
    time:Civil created;
    time:Civil updated;
    string comment;
    };

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

isolated function addAnstalld(anstalld anst) returns int|error {
    sql:ExecutionResult result = check dbClient->execute(`
        INSERT INTO anstalld (
            id, 
            firstNamn, 
            lastName, 
            workTitle,
            created,
            updated,
            comment)
        VALUES (
            ${anst.id}, 
            ${anst.firstNamn}, 
            ${anst.lastName},
            ${anst.workTitle}, 
            ${anst.created}, 
            ${anst.updated}, 
            ${anst.comment}
    `);

    int|string? lastInsertId = result.lastInsertId;
    if lastInsertId is int {
        return lastInsertId;
    } else {
        return error("Unable to obtain last insert ID");
    }
}

isolated function getAnstalld(int id) returns anstalld|error {
    anstalld anst = check dbClient->queryRow(
        `SELECT * FROM anstalld WHERE id = ${id}`
    );
    return anst;
}

isolated function getAllAnstalld() returns anstalld[]|error {
    anstalld[] anstalldList = [];
    stream<anstalld, error?> resultStream = dbClient->query(
        `SELECT * FROM anstalld`
    );
    check from anstalld anst in resultStream
    do {
        anstalldList.push(anst);
    };
    check resultStream.close();
    return anstalldList;
}

isolated function updateAnstalld(anstalld anst) returns int|error {
    sql:ExecutionResult result = check dbClient->execute(`
        UPDATE anstalld SET
            firstNamn = ${anst.firstNamn},
            lastName = ${anst.lastName},
            workTitle = ${anst.workTitle},
            created = ${anst.created},
            updated = ${anst.updated},
            comment = ${anst.comment}
            WHERE id = ${anst.id}
    `);

    int? affectedRowCount = result.affectedRowCount;
    if affectedRowCount is int {
        return affectedRowCount;
    } else {
        return error("Unable to obtain the affected row count");
    }
}

isolated function removeAnstalld(int id) returns int|error {
    sql:ExecutionResult result = check dbClient->execute(`
        DELETE FROM anstalld WHERE id = ${id}
    `);
    
    int? affectedRowCount = result.affectedRowCount;
    if affectedRowCount is int {
        return affectedRowCount;
    } else {
    return error("Unable to obtain the affected row count");
    }
}