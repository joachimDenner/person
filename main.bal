import ballerina/http;
import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;
import ballerina/sql;

type person record {|
    int id?;
    string? careOf;
    string? utdelningsadress1;
    string? utdelningsadress2;
    string? postNr;
    string? postOrt;
    string? forNamn;
    string? mellanNamn;
    string? efterNamn;
    string? aviseringsNamn;
    string? code;
    string? kodTilltalsNamn;
    string? lan;
    string? kommun;
    string? forsamling;
    string? folkBokforingsDatum;
    string? folkBokforingsTyp;
    string? typAvIdBet;
    string? idBet;
    string? hanvisningsNummer;
    string? sekretessMark;
    string? skyddadFolkBokforing;
    string? skapadDatum;
    string? uppdateradDatum;
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

service /person on new http:Listener(8080) {
    //   Hämta (GET) en person
    resource function get hamtaPerson(int id) returns json {
        sql:ParameterizedQuery query = `SELECT * FROM person WHERE id = ${id}`;
        stream<person, error?> resultStream = dbClient->query(query);

        person[] resultList = [];
        error? e = resultStream.forEach(function(person row) {
            resultList.push(row);
        });

        if e is error {
            return {
                "message": "Kunde inte hämta person: " + e.message()
            };
        }
        return <json>resultList;
    }

   // Skapa (POST) en ny person
    resource function post skapaPerson(person pers) returns json|error {
        sql:ParameterizedQuery query = `INSERT INTO person (
                careof,
                utdelningsadress1,
                utdelningsadress2,
                postnr,
                postort,
                fornamn,
                mellannamn,
                efternamn,
                aviseringsnamn,
                code,
                kodtilltalsnamn,
                lan,
                kommun,
                forsamling,
                folkbokforingsdatum,
                folkbokforingstyp,
                typavidbet,
                idbet,
                hanvisningsnummer,
                sekretessmark,
                skyddadfolkbokforing,
                skapaddatum,
                uppdateraddatum
            ) VALUES (
                ${pers.careOf},
                ${pers.utdelningsadress1},
                ${pers.utdelningsadress2},
                ${pers.postNr},
                ${pers.postOrt},
                ${pers.forNamn},
                ${pers.mellanNamn},
                ${pers.efterNamn},
                ${pers.aviseringsNamn},
                ${pers.code},
                ${pers.kodTilltalsNamn},
                ${pers.lan},
                ${pers.kommun},
                ${pers.forsamling},
                ${pers.folkBokforingsDatum},
                ${pers.folkBokforingsTyp},
                ${pers.typAvIdBet},
                ${pers.idBet},
                ${pers.hanvisningsNummer},
                ${pers.sekretessMark},
                ${pers.skyddadFolkBokforing},
                ${pers.skapadDatum},
                ${pers.uppdateradDatum}
            ) RETURNING id`;

        int insertedId = check dbClient->queryRow(query, int);
        if insertedId > 0 {
            return {
                message: "Person skapades!",
                id: insertedId
            };
        } else {
            return {
                message: "Kunde inte skapa ny person!"
            };
        }
    }


    //   Hämta (GET) alla personer by id
    resource function get hamtaAllaPersonerSortByIdAsc() returns json {
        sql:ParameterizedQuery query = `SELECT * FROM person order by id asc`;
        stream<person, error?> resultStream = dbClient->query(query);

        person[] resultList = [];
        error? e = resultStream.forEach(function(person row) {
            resultList.push(row);
        });

        if e is error {
            return {
                "message": "Kunde inte hämta personer: " + e.message()
            };
        }
        return <json>resultList;
    }

    //   Hämta (GET) alla personer by efterNamn
    resource function get hamtaAllaPersonerSortByEfternamnAsc() returns json {
        sql:ParameterizedQuery query = `SELECT * FROM person ORDER BY efterNamn asc`;
        stream<person, error?> resultStream = dbClient->query(query);

        person[] resultList = [];
        error? e = resultStream.forEach(function(person row) {
            resultList.push(row);
        });

        if e is error {
            return {
                "message": "Kunde inte hämta personer: " + e.message()
            };
        }
        return <json>resultList;
    }

    // Uppdatera (PUT) en person
    resource function put uppdateraPerson(int id, person pers) returns json|error {
    sql:ParameterizedQuery query = `UPDATE person SET
        careof = ${pers.careOf},
        utdelningsadress1 = ${pers.utdelningsadress1},
        utdelningsadress2 = ${pers.utdelningsadress2},
        postnr = ${pers.postNr},
        postort = ${pers.postOrt},
        fornamn = ${pers.forNamn},
        mellannamn = ${pers.mellanNamn},
        efternamn = ${pers.efterNamn},
        aviseringsnamn = ${pers.aviseringsNamn},
        code = ${pers.code},
        kodtilltalsnamn = ${pers.kodTilltalsNamn},
        lan = ${pers.lan},
        kommun = ${pers.kommun},
        forsamling = ${pers.forsamling},
        folkbokforingsdatum = ${pers.folkBokforingsDatum},
        folkbokforingstyp = ${pers.folkBokforingsTyp},
        typavidbet = ${pers.typAvIdBet},
        idbet = ${pers.idBet},
        hanvisningsnummer = ${pers.hanvisningsNummer},
        sekretessmark = ${pers.sekretessMark},
        skyddadfolkbokforing = ${pers.skyddadFolkBokforing},
        uppdateraddatum = ${pers.uppdateradDatum}
        WHERE id = ${id}`;

        sql:ExecutionResult result = check dbClient->execute(query);
        int? affectedRowCount = result.affectedRowCount;

        if affectedRowCount is int && affectedRowCount > 0 {
            return {
                message: "Person uppdaterades!",
                id: id
            };
        } else {
            return {
                message: "Kunde inte uppdatera person!"
            };
        }
    }

    //  Ta bort (DELETE) en person
    resource function delete tabortPerson(int id) returns json {
        sql:ExecutionResult|error execResult = dbClient->execute(`
        DELETE FROM person WHERE id = ${id}
        `);

        if execResult is sql:ExecutionResult {
            int? affectedRowCount = execResult.affectedRowCount;
            if affectedRowCount is int && affectedRowCount == 0 {
                return { "message": "Person med id: " + id.toString() + " saknas!" };
            }
                        
            if affectedRowCount is int && affectedRowCount > 0 {
                return { "message": "Person med id: " + id.toString() + " borttagen!" };
            }
            
        } else {
            return { "message": "Fel inträffade vid borttagning: " + execResult.message() };
        }
    }
}   