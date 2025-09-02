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

// SKV token variabler
configurable string SKV_TOKEN_URL = ?;
configurable string SKV_TOKEN_CLIENT_ID = ?;
configurable string SKV_TOKEN_CLIENT_SECRET = ?;
configurable string SKV_TOKEN_CERTFILE = ?;
configurable string SKV_TOKEN_KEYFILE = ?;

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
    resource function get skvToken() returns json {
        // 1. Skapa request och sätt header
        // Motsvaras av -H "Content-Type: application/x-www-form-urlencoded" i cURL
        http:Request req = new;
        req.setHeader("Content-Type", "application/x-www-form-urlencoded");
        
        // 2. Förbered request-data NOT: Måste ligga på EN rad i denna kod även om den i cURL kan ligga på fler rader!!
        // Motsvaras av --data i cURL
        string formData = "grant_type=client_credentials"
            + "&client_id=" + SKV_TOKEN_CLIENT_ID
            + "&client_secret=" + SKV_TOKEN_CLIENT_SECRET;

        // 3. Lägg på formData på payload   
        req.setPayload(formData);

        // 4. Förbered debug-loggning om error
        // Hämta Content-Type-headern, eller fallback om den saknas
        string contentTypeHeader = "";
        string|http:HeaderNotFoundError h = req.getHeader("Content-Type");
        if h is string {
            contentTypeHeader = h;
        } else {
            contentTypeHeader = "Header saknas";
        }

        // 5. Bygg på debug-strängen
        string requestDebug = string `url=${SKV_TOKEN_URL}, headers=${contentTypeHeader}, payload=${formData}`;

        do {
            http:Client skvClient = check new(SKV_TOKEN_URL, {
                secureSocket: {
                    key: {
                        certFile: SKV_TOKEN_CERTFILE,
                        keyFile: SKV_TOKEN_KEYFILE
                    },
                    protocol: { name: http:TLS, versions: ["TLSv1.2"] },
                    ciphers: [
                        "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",
                        "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"
                    ]
                }
            });

            // 6. Skicka POST-anrop
            http:Response tokenResp = check skvClient->post("", req);

            if tokenResp.statusCode == 200 {
                json|error tokenJson = tokenResp.getJsonPayload();
                if tokenJson is json {
                    log:printInfo("Token hämtad");
                    return tokenJson;
                } else {
                    fail error("1) requestDebug: " + requestDebug);
                }
            } else {
                // Försök hämta respons som JSON
                json|error errorJson = tokenResp.getJsonPayload();
                if errorJson is json {
                    fail error("Skatteverket svarade med status: " + tokenResp.statusCode.toString() + ", 2) requestDebug: " + requestDebug);
                } else {
                    // Om inte JSON, hämta textpayload
                    string|error errorText = tokenResp.getTextPayload();
                    if errorText is string {
                        fail error("Skatteverket svarade med status: " + tokenResp.statusCode.toString()
                                + " och payload: " + errorText + ", 3) requestDebug: " + requestDebug);
                    } else {
                        fail error("Skatteverket svarade med status: " + tokenResp.statusCode.toString()
                                + " men kunde inte läsa payload" + ", 4) requestDebug: " + requestDebug);
                    }
                }
            }
        } on fail error e {
            return {
                "status": 500,
                "error": e.message(),
                "stackTrace": e.stackTrace().toString(),
                "request": requestDebug
            };
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