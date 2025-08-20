# Person REST API – Ballerina + PostgreSQL

Ett REST API för att hantera personer med CRUD-funktionalitet.  
Byggt med [Ballerina](https://ballerina.io/) och PostgreSQL.  

## 📦 Förutsättningar

- [Ballerina](https://ballerina.io/downloads/) installerat (≥ v2201.9.0)
- [PostgreSQL](https://www.postgresql.org/download/) installerat och en databas skapad
- En tabell `person` i databasen:

```sql
CREATE TABLE person (
    id SERIAL PRIMARY KEY,
    careOf VARCHAR(255),
    utdelningsadress1 VARCHAR(255),
    utdelningsadress2 VARCHAR(255),
    postNr VARCHAR(20),
    postOrt VARCHAR(255),
    forNamn VARCHAR(100),
    mellanNamn VARCHAR(100),
    efterNamn VARCHAR(100),
    aviseringsNamn VARCHAR(255)
);
