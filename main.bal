import ballerina/http;
import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;
import ballerina/sql;
import ballerina/log;
import ballerina/os;

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
    string? lastevent;
|};

// Databaskoppling
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


// SKV-koppling - används i hämtning av token
string SKV_TOKEN_URL = "https://sysorgoauth2.test.skatteverket.se/oauth2/v1/sysorg/token";
string SKV_TOKEN_CONTENT_TYPE = "application/x-www-form-urlencoded;charset=UTF-8";
string SKV_TOKEN_GRANT_TYPE = "client_credentials";
string SKV_TOKEN_SCOPE = "fbfuppgoffakt";
string SKV_TOKEN_CLIENT_ID = "a00b962dfdc8e743eebcf407c38ecead83bd69f7202e2f68";
string SKV_TOKEN_CLIENT_SECRET = "da21079d64e9740442deb79c08f0041692fc6edac949cead83bd69f7202e2f68";
# SKV_TOKEN_CLIENT_CERT_PATH = "/c/projcerts/orebrokommun/client-cert.pem"
string SKV_TOKEN_CLIENT_CERT_PATH = "c:/projcerts/orebrokommun/client-cert.pem";
#SKV_TOKEN_CLIENT_KEY_PATH = "/c/projcerts/orebrokommun/client_key.pem"
string SKV_TOKEN_CLIENT_KEY_PATH = "c:/projcerts/orebrokommun/client_key.pem";
string SKV_TOKEN_CLIENT_KEY_PASSWORD = "your_key_password";

// Skatteverket API - används i hämtning av persondata
//string SKV_API_URL = "https://api.test.skatteverket.se/folkbokforing/folkbokforingsuppgifter-for-offentliga-aktorer/v3/hamta";
//string SKV_API_CONTENT_TYPE = "application/json";
//string SKV_API_AUTHORIZATION = "Bearer <access_token>";
//string SKV_API_CLIENT_CORRELATION_ID = "78b82991-6122-4933-bf18-ccfc75b3e199";
//string SKV_API_CLIENT_ID = "c7b3346b-06fe-4e48-8a9e-bb8bed786c8a";
//string SKV_API_CLIENT_SECRET = "a0562b37-8514-47b4-952e-d53f0499c054";


// HTTP-klienter
//http:Client skvTokenClient = check new (SKV_TOKEN_URL);
//http:Client skvApiClient = check new (SKV_API_URL);


service /person on new http:Listener(8080) {

    resource function get checkEnv() returns json {
        string? choreoVar = os:getEnv("CHOREO_API_URL");
        string? k8sVar = os:getEnv("KUBERNETES_SERVICE_HOST");

        if choreoVar is string && choreoVar.trim() != "" {
            return {
                "environment": "Choreo",
                "variable": "CHOREO_API_URL",
                "value": choreoVar
            };
        } else if k8sVar is string && k8sVar.trim() != "" {
            return {
                "environment": "Kubernetes",
                "variable": "KUBERNETES_SERVICE_HOST",
                "value": k8sVar
            };
        } else {
            return {
                "environment": "Local",
                "variable": "N/A",
                "value": "N/A"
            };
        }
    }

    // Hämta token från Skatteverket
    resource function get skvToken() returns json|error {
        http:Client skvClient = check new(SKV_TOKEN_URL, {
            secureSocket: {
                key: {
                    certFile: "c:/projcerts/orebrokommun/client-cert.crt",
                    keyFile: "c:/projcerts/orebrokommun/client-key.key"
                },
                cert: "c:/projcerts/orebrokommun/client-cert.crt",
                protocol: {
                    name: http:TLS,
                    versions: ["TLSv1.2", "TLSv1.1"]
                },

                ciphers: ["TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA"]
            }
        });

        map<string> formData = {
            grant_type: "client_credentials",
            scope: "fbfuppgoffakt",
            client_id: SKV_TOKEN_CLIENT_ID,
            client_secret: SKV_TOKEN_CLIENT_SECRET
        };

        http:Request req = new;
        req.setHeader("Accept", "application/json");
        req.setPayload(formData, contentType = "application/x-www-form-urlencoded");
        
        http:Response tokenResp = check skvClient->post("", req);

        if tokenResp.statusCode == 200 {
            json|error tokenJson = tokenResp.getJsonPayload();
            if tokenJson is json {
                log:printInfo("Token hämtad");
                return tokenJson;
            } else {
                log:printError("Kunde inte tolka JSON: " + tokenJson.toString());
                return error("Kunde inte tolka JSON från Skatteverket");
            }
        } else {
            log:printError("Skatteverket svarade med status: " + tokenResp.statusCode.toString());
            return error("Token-anrop misslyckades med status " + tokenResp.statusCode.toString());
        }
    }

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
                uppdateraddatum,
                lastevent
            ) VALUES (
                /*
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
                */
                ${pers.folkBokforingsDatum},
                ${pers.folkBokforingsTyp},
                ${pers.typAvIdBet},
                ${pers.idBet},
                ${pers.hanvisningsNummer},
                ${pers.sekretessMark},
                ${pers.skyddadFolkBokforing},
                ${pers.skapadDatum},
                ${pers.uppdateradDatum},
                ${pers.lastevent}
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
        uppdateraddatum = ${pers.uppdateradDatum},
        lastevent = ${pers.lastevent}
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

    //   Hämta (GET) en person mha idbet (personnummer)
    resource function get hamtaPersonByPersonnummer(string idBet) returns json {
        sql:ParameterizedQuery query = `SELECT * FROM person WHERE idbet = ${idBet}`;
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
}   