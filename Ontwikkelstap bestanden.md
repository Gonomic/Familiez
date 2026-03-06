
Ik wil in de Familiez app (React frontend, FastAPI middleware, MariaDB backend) volledige ondersteuning voor uploaden, opslaan, koppelen, tonen en downloaden van afbeeldingen en documenten. Afbeeldingen en documenten worden tijdens ontwikkeling en test fysiek opgeslagen op deze ontwikkel machine en tijdens productie op de NAS (Docker volume), metadata in MariaDB, geen blobs.

Vanaf "Specificaties:" in onderstaande tekst beginnen de specificaties voor het voorgaande. Ik wil dat je de volgende dingen doet:

    Weten dat in de root folder van de Familiez 3 tier app, te weten "Familiez", dit en andere bestanden staan. Daar zul je af en toe moeten lezen.

    We alles onder Specificaties in drie aparte stappen ontwikkelen (één stap voor Opslagstructuur op schijf, een stap voor Database en één stap voor Frontend).

    Per stap de volgende acties nemen:
        
        Zeggen wat je gaat doen en daarvoor mijn goedkeuring vragen.

        Nieuwe Git branche maken.

        Jouw bij de stap behorende acties uitvoeren.

        Samenvatting geven van wat is gedaan en deze opslaan in de Familiez root folder, zodat je deze als context en start kunt gebruiken voor de vlogende stap en daarna ook jouw geschiedenis kunt vergeten van de voorgaande stappen. Dit  ivm memory gebruik en om context rot te vookomen. 

        Versie informatie opslaan in de BE folder en in de Familiez database in de structuur die hiervoor al in de database bestaat.

        Alle wijzigingen met de centrale Github repo synchroniseren.

        De repo branch weer samenvoegen met de hoofdbranche

Specificaties:

Opslagstructuur op schijf:

    Voor ontwikkel en test: op deze machine, Persoon: frans/Documenten/Dev/Familiez/BESTANDEN/<persoon_id>/<slugified_naam>/ 
    Voor ontwikkel en test; op deze machine, Familie (ouderpaar): media/<vader_id>_<moeder_id>/<slugified_vadernaam>_<slugified_moedernaam>/

    Voor productie: op de Synology NAS, Persoon: docker/familiez/media/<persoon_id>/<slugified_naam>/
    Voor productie: op de Synology NAS, Familie (ouderpaar): docker/familiez/media/<vader_id>_<moeder_id>/<slugified_vadernaam>_<slugified_moedernaam>/


    Slugify: lowercase, accenten weg, alleen [a-z0-9_], spaties/koppelteken → _, dubbele _ reduceren.

    Bestandsnaam: <persoon_of_family_id>_<documenttype>_<jaar>_<uuid>.<ext>

    Nooit dupliceren: één fysiek bestand, meerdere koppelingen.

Database (BE folder):

    In the bestaande Familiez database

    files(id, path, filename, document_type, year, created_at, uploaded_by)

    person_files(person_id, file_id)

    family_files(father_id, mother_id, file_id)

    Let op: gebruik reeds bestaande veldnamen zo veel als mogelijk, verzin niet onnodig nieuwe veldnamen!

Frontend (React in FE folder):

    Menu optie "Bestanden" toevoegen in het menu dat verschijnt als je op het SVG canvas op de driehoek van een persoon klikt. 

    Na het klikken op de menu optie "Bestanden" een nieuw formulier in de rightdrawer met daarin het onderstaande:
   
        Upload UI moet expliciet kiezen:

            scope: "person" of "family"

            documenttype: portret, familiefoto, trouwakte, geboorteakte, overlijdensakte, opleidingsdocument, werkdocument, overig

            optioneel: jaar

        Groepeer in UI / in het nieuwe formulier in de rightdrawer: persoonlijke documenten en familiedocumenten.

        Toon thumbnails via /api/files/{id}/thumbnail.

        Klik op thumbnail opent popup window (geen nieuwe tab):
        window.open("/api/files/"+fileId, "familiezPreview", "width=900,height=700,menubar=no,toolbar=no,location=no,status=no,resizable=yes,scrollbars=yes");

Middleware (FastAPI in MW folder):

    Upload‑endpoint: ontvangt file + metadata, bepaalt map op basis van scope, genereert bestandsnaam, slaat op, schrijft metadata, maakt koppelingen.

    Download‑endpoint: /api/files/{file_id} streamt bestand.

    Thumbnail‑endpoint: /api/files/{file_id}/thumbnail.

    Query‑endpoints:
    /api/person/{id}/files en /api/family/{fatherId}/{motherId}/files.

Genereer per stap alle benodigde code (React‑componenten, FastAPI‑endpoints, database‑migraties, slugify‑functie, bestandsopslag, thumbnail‑generatie, UI‑flow) volgens bovenstaande specificaties.
