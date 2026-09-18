# Prompt: Koppel gebruiker aan persoon in stamboom

## Doel
Maak het mogelijk dat elke ingelogde gebruiker zichzelf koppelt aan een persoon in de stamboom. Na inloggen wordt de eigen stamboom automatisch getoond als de gebruiker dat heeft ingesteld.

---

## Laag 1 – Database (BE)

Voeg een nieuwe tabel `familiez_user_preferences` toe met de volgende kolommen:

| Kolom              | Type          | Standaard | Opmerking                        |
|--------------------|---------------|-----------|----------------------------------|
| `username`         | VARCHAR(100)  | –         | PRIMARY KEY                      |
| `linked_person_id` | INT           | NULL      | Nullable FK naar persons-tabel   |
| `generations_up`   | INT           | 3         |                                  |
| `generations_down` | INT           | 3         |                                  |
| `auto_show_tree`   | TINYINT(1)    | 0         |                                  |

Maak twee stored procedures:
- `GetUserPreferences(usernameIn)` – geeft de rij terug voor de opgegeven gebruiker (of lege set als nog niet ingesteld)
- `SetUserPreferences(usernameIn, personIdIn, genUpIn, genDownIn, autoShowIn)` – INSERT ON DUPLICATE KEY UPDATE

---

## Laag 2 – Middleware (MW)

Voeg twee nieuwe endpoints toe in `main.py`. Beide zijn toegankelijk voor alle ingelogde gebruikers (geen admin-vereiste). De `username` wordt altijd afgeleid uit de JWT/sessie, nooit uit de request-body, zodat een gebruiker alleen zijn eigen instellingen kan lezen en schrijven.

- `GET /user/my-preferences` – haalt de eigen instellingen op
- `PUT /user/my-preferences` – slaat de eigen instellingen op; de MW valideert dat `linked_person_id` bestaat in de persons-tabel voordat het wordt opgeslagen

---

## Laag 3 – Frontend (FE)

### `familyDataService.js`
Voeg twee nieuwe functies toe:
- `getMyPreferences()` → roept `GET /user/my-preferences` aan
- `saveMyPreferences(payload)` → roept `PUT /user/my-preferences` aan met `{ linked_person_id, generations_up, generations_down, auto_show_tree }`

### `FamiliezSysteem.jsx`
Voeg een nieuw `<Paper>` panel toe met de titel **"Mijn stamboom instellingen"**. Het panel is zichtbaar voor alle ingelogde gebruikers. Inhoud van het panel:
- Een persoonszoekveldje op basis van de bestaande `getPersonsLike`-logica (autocomplete), met label "Zoek en selecteer uw persoon in de stamboom"
- Een `<TextField type="number">` voor generaties omhoog (label: "Generaties omhoog tonen", minimum 0, maximum 10)
- Een `<TextField type="number">` voor generaties omlaag (label: "Generaties omlaag tonen", minimum 0, maximum 10)
- Een `<Checkbox>` met label "Stamboom automatisch tonen na inloggen"
- Een opslaan-knop die `saveMyPreferences()` aanroept en een succesmelding toont

Bij het openen van het scherm: `getMyPreferences()` aanroepen en alle velden voorinvullen met de opgeslagen waarden. Als er nog geen koppeling is opgeslagen, staan de velden leeg respectievelijk op de standaardwaarden (3/3/uitgevinkt).

### `app.jsx`
Voeg logica toe die direct na een geslaagde login `getMyPreferences()` aanroept. Als `auto_show_tree` true is én `linked_person_id` is ingesteld:
- Navigeer automatisch naar de stamboomweergave
- Geef `linked_person_id`, `generations_up` en `generations_down` als startparameters door aan `FamilyTreeCanvas`

---

## Beveiliging
- De MW-endpoints lezen de `username` uitsluitend uit de JWT/sessie. Een gebruiker kan daardoor nooit de instellingen van een ander lezen of overschrijven.
- De MW valideert dat `linked_person_id` (indien opgegeven) bestaat in de persons-tabel. Geef een duidelijke foutmelding terug als het ID niet bestaat.
