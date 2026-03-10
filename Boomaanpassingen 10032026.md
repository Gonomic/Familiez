# Compacte Run Prompt

Gebruik het context bestand `/home/frans/Documenten/Dev/Familiez/Boomaanpassingen 10032026.md` als volledige context en voer de daarin beschreven wijzigingsset uit voor de Familiez app.

Werk in grote lijnen als volgt:
- start vanaf de actuele hoofdbranch en maak een aparte feature branch;
- voer stap 1 eerst uit: grotere persoon-driehoeken, kleinere generatieafstand, fotozone met lazy/progressieve fotolading en aangepaste tijdelijke introhulpteksten met pijlen;
- voer stap 2 daarna apart uit: pan/zoom zonder regressie op bestaande interacties;
- maak aparte commit(s) voor stap 1 en aparte commit(s) voor stap 2;
- werk primair in FE en pas MW/BE alleen aan als dat functioneel nodig is voor foto-ophaal of metadata;
- test de aangepaste functionaliteit en rapporteer aan het einde welke bestanden en repo's zijn gewijzigd, plus eventuele restrisico's.
- Kijk voor details en detailaanwijzingen nu eerst- én wanneer het nodig is (bijvoorbeeld na compacting) in het voornoemde context bestand

# Toekomstige Prompt - Boomaanpassingen (10-03-2026)

Gebruik deze prompt in een nieuwe sessie om de wijzigingen direct uit te voeren.

## Prompt voor Copilot

Voer de onderstaande wijzigingen uit voor de Familiez app. Werk zorgvuldig, zonder regressies.

### 1. Context en architectuur
- Dit is een 3-tier app:
- FE = React frontend in `FE/`
- MW = Python middleware in `MW/`
- BE = MariaDB backend in `BE/`
- Boven de repo-mappen staat een map `Familiez/` met aanvullende documentatie en context.
- In `BE/init/` staat SQL voor database-initialisatie en voor het vullen van releasegegevens in de Familiez database.

### 2. Scope en branchstrategie
- Start vanaf de actuele hoofdbranch per repo (`main` voor FE/MW, `master` voor BE).
- Maak een aparte feature branch voor deze wijzigingsset (niet direct op de actuele branch werken).
- Werk primair in FE.
- Pas MW en/of BE alleen aan als dat functioneel nodig is voor foto-ophaal of fotometadata.

### 3. Stap 1 - Canvas layout, foto in driehoek, introteksten
Pas de stamboomweergave aan met behoud van bestaande inhoud en logica.

#### 3.1 Driehoek en generatieafstand
- Vergroot de persoon-driehoek:
- Breedte: +30%
- Hoogte: +40%
- Verklein de verticale afstand tussen generaties met 50%.
- Houd de bestaande indeling en inhoud van de driehoek in principe gelijk.

#### 3.2 Tekst- en fotoregels in driehoek
- Zorg dat naamtekst beter in het bovenste deel past.
- Voeg in het onderste deel van de driehoek een fotozone toe.
- Toon foto alleen als die in opslag beschikbaar is.
- Als geen foto beschikbaar is: leeg laten.
- Foto-vorm: cirkel.
- Als tekst te lang is: afkappen met `...`.

#### 3.3 Lazy/progressieve foto-opbouw (niet blokkeren)
- Teken personen/verbindingen zo snel mogelijk eerst zonder foto.
- Voeg foto's daarna asynchroon en progressief toe.
- Laat het programma niet blokkeren door trage foto-ophaal.
- Gebruik een beperkte concurrency voor foto-ophaal (bijv. 4-6 tegelijk).
- Prioriteer zichtbare personen in viewport.
- Gebruik caching op `personId` om onnodige herhaalde fetches te beperken.
- Zorg dat fouten/timeouts bij foto-ophaal de rest van de weergave niet verstoren.

#### 3.4 Introhulptekst op hoofdscherm (zonder boom)
Vervang de huidige verwijstekst en toon exact deze 2 regels in deze volgorde:

1. `Klik rechtsboven op de drie streepjes om een persoon, familie of stamboom te kiezen.`
2. `Gebruik het menu links voor technische informatie, releasegegevens en het testen van de verbinding met de centrale omgeving.`

Extra eisen voor deze introhulp:
- Achter regel 1: een gebogen pijl die naar het rechtersymbool wijst.
- Voor regel 2: een pijl die naar het linkermenu wijst.
- Er mag extra verticale ruimte gebruikt worden voor leesbaarheid.
- Deze hulptekst en pijlen zijn tijdelijk: alleen tonen als er nog geen stamboom op het canvas staat.
- Zodra de boom zichtbaar is, moeten hulptekst en pijlen verdwijnen (niet overlappen met boominhoud).

### 4. Stap 2 - Pan/zoom als aparte wijzigingsstap
Voeg pan/zoom toe als aparte vervolgstap, zonder verlies van bestaande functionaliteit.

- Implementeer zoom in/uit op het canvas (muiswiel).
- Implementeer pan op de canvas-achtergrond.
- Gebruik een centrale viewport-transform (scale + translate) voor SVG-inhoud.
- Pas drag-coordinate omzetting aan zodat persoon-drag correct blijft onder zoom/pan.
- Behoud bestaande functionaliteit:
- Personen verslepen (inclusief partnergedrag)
- Contextmenu en bestaande acties
- Selectie/markering
- Lijnen tussen personen
- Loading overlay/boomopbouw
- Voeg een `reset view` actie toe.
- Gebruik veilige zoomlimieten (bijv. min 0.4, max 2.5).

### 5. Commitstrategie
- Maak aparte commit(s) voor stap 1.
- Maak aparte commit(s) voor stap 2 (pan/zoom), gescheiden van stap 1.
- Houd commitberichten functioneel en duidelijk.

### 6. Acceptatiecriteria
- Driehoekgrootte en generatieafstand exact volgens afspraken.
- Foto onderin driehoek werkt volgens beschikbaarheid, vorm en fallback.
- Snelle eerste render van boom zonder blokkade door foto's.
- Introhulptekst exact volgens afgesproken inhoud en volgorde, met pijlen en tijdelijke zichtbaarheid.
- Pan/zoom werkt en veroorzaakt geen regressie in bestaande interacties.
- Geen build/lint errors in aangepaste onderdelen.

### 7. Testen en oplevering
- Test minimaal:
- Boom zonder foto's
- Boom met deels wel/deels geen foto's
- Grote boom (prestatie-indruk)
- Introhulp zichtbaar zonder boom en verborgen met boom
- Drag/contextmenu voor en na pan/zoom
- Lever op met:
- Korte samenvatting van wijzigingen per repo (FE, evt MW, evt BE)
- Lijst van aangepaste bestanden
- Bekende restrisico's of open punten
