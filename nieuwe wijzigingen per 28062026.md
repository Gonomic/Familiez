# Nieuwe wijzigingen per 28062026

Dit document is de bron voor advies en opvolging van geplande wijzigingsgroepen.

## Werkwijze
- Per wijzigingsgroep: doel, betrokken repo(s), risico, acceptatiecriteria.
- Eerst advies, daarna pas uitvoering (nog niet uitvoeren in deze fase).
- Wijzigingsgroepen worden hieronder oplopend toegevoegd.

## Wijzigingsgroepen

### WG-01 Verbinden van familieleden in stamboom (lijnstructuur)
- Doel:
	Kinderen niet meer via directe diagonale lijnen koppelen, maar via een horizontale kinderlijn met verticale koppelingen van ouders en kinderen naar die lijn.
- Betrokken repo(s):
	FE (canvas rendering en positionering).
- Advies:
	Werk dit gefaseerd uit:
	1. Eerst alleen renderlogica voor lijnen wijzigen.
	2. Daarna edge-cases: meerdere partners, halfbroers/-zussen, ontbrekende ouder.
	3. Pas daarna finetuning van spacing en overlap.
- Risico:
	Hoog visueel regressierisico bij complexe families.
- Acceptatiecriteria:
	- Geen diagonale ouder-kind lijnen meer.
	- Elk sibling-cluster heeft een horizontale lijn.
	- Ouders en kinderen zijn via verticale lijnen gekoppeld aan die horizontale lijn.
	- Layout blijft leesbaar op desktop en mobiel.
- Status:
	Deels uitgevoerd op 10-07-2026 (eerste FE-rendering geïmplementeerd, nog niet afgerond).
- Huidige testuitkomst:
	Lijnweergave op scherm is nog niet overal correct; visuele issues zijn nog open.
- Vervolg:
	- Later verder testen met praktijkcases.
	- Daarna finetuning van lijnpositionering/overlap en edge-cases afronden.
	- Pas na die testronde WG-01 definitief als afgerond markeren.

### WG-02 Contextmenu persoon aanpassen
- Doel:
	In contextmenu op canvas:
	- Verwijderen: Kind toevoegen.
	- Toevoegen: Broer toevoegen, Zus toevoegen, Dochter toevoegen, Zoon toevoegen.
- Betrokken repo(s):
	FE (contextmenu en acties), MW/BE mogelijk voor nieuwe relatiescenario's.
- Advies:
	Eerst FE-menu en action-routing aanpassen, daarna backend-validatie per relationeel scenario controleren.
- Risico:
	Middel. UI lijkt snel klaar, maar dataconsistentie is kritisch.
- Acceptatiecriteria:
	- Menu-optie Kind toevoegen is weg.
	- Vier nieuwe menu-opties zijn aanwezig en werken.
	- Nieuwe personen worden met correcte relatie opgeslagen.
- Status:
	FE afgerond en backend gevalideerd op 10-07-2026.
- Uitgevoerd in FE:
	- Contextmenu aangepast: Broer/Zus/Dochter/Zoon toegevoegd, Kind toevoegen verwijderd.
	- Action-routing uitgebreid met relationAction van contextmenu naar add-form.
	- Add-form uitgebreid met:
		- Dochter/Zoon: geslacht vooraf ingevuld.
		- Broer/Zus: ouders overnemen van geselecteerde persoon (indien beschikbaar).
	- Gerichte tests toegevoegd voor menu-acties en routing.
- Backend-validatie (MW/BE):
	- MW geeft FatherId/MotherId/PartnerId ongewijzigd door naar AddPerson_v2.
	- BE AddPerson_v2 ondersteunt moeder/vader/partner-relaties en schrijft deze weg in relations.
	- Conclusie: voor WG-02 geen extra MW/BE codewijziging nodig.
- Let op / vervolgadvies:
	- Nuance: als geselecteerde persoon geen ouders heeft, kan Broer/Zus zonder ouderkoppeling worden toegevoegd.
	- Aanbevolen vervolgstap: FE-warning of blokkade tonen bij Broer/Zus als beide ouders onbekend zijn.
	- Uitgevoerd op 10-07-2026: hard blokkade + zichtbare schermmelding bij Broer/Zus zonder bekende ouders.
	- FE commit: c022a52 (WG-02: block sibling add when parents are unknown).

### WG-03 Leeftijd niet tonen bij overleden zonder overlijdensdatum
- Doel:
	Indien persoon overleden is maar overlijdensdatum onbekend, geen leeftijd tonen.
- Betrokken repo(s):
	FE (weergavelogica), eventueel MW als leeftijd server-side berekend wordt.
- Advies:
	Maak de regel expliciet en centraal: overleden + geen overlijdensdatum = leeftijd leeg.
- Risico:
	Laag.
- Acceptatiecriteria:
	- Overleden + onbekende overlijdensdatum toont geen leeftijd.
	- Overige gevallen blijven ongewijzigd.
- Status:
	Uitgevoerd op 10-07-2026 in FE.
- Implementatie:
	- Centrale regel toegevoegd in FE voor leeftijdsweergave: overleden zonder overlijdensdatum => geen leeftijd.
	- UI-rendering op PersonTriangle gebruikt nu de centrale regel.
	- Unit- en componenttests toegevoegd en groen.
- Git:
	- Repo: Gonomic/Familiez-FE
	- Branch: feature/nieuwe-wijzigingen-2026-06-28
	- Commit: e299b45
	- Commit message: WG-03: hide age when deceased has no death date
	- Push: uitgevoerd

### WG-04 Partners bewerken in contextmenu
- Doel:
	Menu-optie Partners bewerken toevoegen en daarmee partners koppelen aan de geselecteerde persoon voor actueel huwelijk/relatie.
- Betrokken repo(s):
	FE (menu + dialoog), MW (API), BE (sproc voor partnerrelaties).
- Advies:
	Eerst functionele regels vastleggen:
	- Wat is actueel huwelijk als er meerdere partnerrelaties zijn?
	- Maximaal 1 actieve partner tegelijk of meerdere toegestaan?
	- Hoe omgaan met bestaande partnerkoppelingen?
	Daarna pas UI/API/DB implementeren.
- Risico:
	Hoog vanwege relationele integriteit.
- Acceptatiecriteria:
	- Contextmenu bevat Partners bewerken.
	- Partner toevoegen/verwijderen werkt zonder dubbele of conflicterende relaties.
	- Boomweergave volgt de nieuwe partnerkoppeling correct.

### WG-05 Overzicht laatst toegevoegde personen
- Doel:
	Linkermenu-optie om recent toegevoegde personen te tonen.
- Betrokken repo(s):
	FE (menu + lijstweergave), MW/BE (query op aanmaakmoment of transactienummer).
- Advies:
	Eerst datadefinitie kiezen:
	- Wat is laatst toegevoegd: op datum/tijd, transactie of persoon-id?
	- Hoeveel records tonen (bijvoorbeeld top 25)?
	- Filter op familie/context ja of nee?
- Risico:
	Middel.
- Acceptatiecriteria:
	- Nieuwe menu-optie aanwezig.
	- Lijst toont juiste sortering van nieuw naar oud.
	- Performance acceptabel bij grotere datasets.

### WG-06 Systeeminstelling partners tonen of verbergen
- Doel:
	Instelling toevoegen waarmee partners in stamboom wel of niet getoond worden.
- Betrokken repo(s):
	FE (setting + rendering), mogelijk MW indien instelling persistent per gebruiker moet zijn.
- Advies:
	Begin met FE-only toggle als snelle MVP. Breid daarna uit naar persistente gebruikersinstelling indien gewenst.
- Risico:
	Middel. Verbergen mag geen relaties breken in layout.
- Acceptatiecriteria:
	- Toggle aanwezig in systeeminstellingen.
	- Uitgeschakeld: partners niet zichtbaar in canvas.
	- Ingeschakeld: partners weer zichtbaar zonder herlaadproblemen.

### WG-07 Geboorteplaats en overlijdensplaats onbekend toestaan
- Doel:
	Waarde Onbekend toestaan wanneer geboorteplaats of overlijdensplaats niet bekend is.
- Betrokken repo(s):
	FE (formuliervalidatie), MW/BE (validatie en opslag).
- Advies:
	Kies een eenduidige aanpak:
	- Ofwel letterlijke waarde Onbekend.
	- Ofwel NULL in database en Onbekend alleen als weergavetekst.
	Tweede optie is technisch meestal schoner.
- Risico:
	Middel door mogelijke rapportage-impact.
- Acceptatiecriteria:
	- Invoer zonder bekende plaats is toegestaan.
	- Weergave toont Onbekend waar nodig.
	- Bestaande records blijven compatibel.

## Aanbevolen uitvoervolgorde
1. WG-03 (klein, lage impact).
2. WG-02 (menu-aanpassingen basis).
3. WG-07 (dataconsistentie rondom onbekend).
4. WG-06 (togglegedrag in rendering).
5. WG-01 (grote visualisatie-aanpassing).
6. WG-04 (partnerbeheer, hoogste integriteitsrisico).
7. WG-05 (rapportage/overzicht als afronding).

## Algemene notities
- Uitvoering staat nog uit: alleen advies en vastlegging in dit document.
- Voor WG-01 en WG-04 vooraf expliciete beslisregels vastleggen om herwerk te vermijden.

## Implementatievoorstel WG-01 (niet uitvoeren)

### Scope en uitgangspunt
- Alleen FE aanpassen voor deze wijziging.
- Doelbeeld:
	- Ouders blijven verbonden met elkaar zoals nu.
	- Kinderen in dezelfde sibling-groep krijgen 1 horizontale buslijn.
	- Verticale lijnen:
		- van ouder-anker naar horizontale buslijn
		- van elk kind naar horizontale buslijn
	- Geen diagonale ouder-kind lijnen meer.

### Relevante codehotspots
- render ouder-kind lijnen in FamilyTreeCanvas.
- layout/positionering van parent-child groepen en partner-ankers.
- huidige fallback met diagonale lijnen volledig uitfaseren na stabiele bus-implementatie.

### Voorgestelde techniek
1. Voeg een afgeleide datastructuur toe in renderfase: childBusGroups.
2. Bouw groepen op basis van zichtbare ouders van elk kind:
	 - Twee ouders zichtbaar en partnerkoppel zichtbaar: groepeer op pair-key.
	 - Slechts 1 zichtbare ouder: groepeer op single-parent-key.
	 - Geen zichtbare ouder in canvas: geen bus tekenen.
3. Per groep berekenen:
	 - minChildX, maxChildX
	 - busY op vaste offset boven kind-top
	 - parentAnchorX
4. Tekenvolgorde:
	 - partnerlijnen
	 - horizontale buslijnen
	 - verticale parent-naar-bus lijnen
	 - verticale kind-naar-bus lijnen
	 - huwelijklabels en partnerdots

### Geometrievoorstel
- busY = min(childTopY) - 24
- busStartX = min(childX) - 14
- busEndX = max(childX) + 14
- parentVertical:
	- x = partnerCenter.x bij ouderpaar
	- x = ouderBottomX bij single parent
	- y1 = parentBottomY
	- y2 = busY
- childVertical:
	- x = childTopMiddleX
	- y1 = busY
	- y2 = childTopY

### Fasering
1. Fase A: interne group-builder toevoegen met logging voor debugging.
2. Fase B: bus-rendering toevoegen naast bestaande lijnen via feature-flag.
3. Fase C: vergelijken op 6 testsituaties en diagonal fallback uitzetten.
4. Fase D: visuele tuning van offsets en stroke-stijl.

### Testsituaties (handmatig)
1. Klassiek gezin met 2 ouders en 3 kinderen.
2. Single parent met 2 kinderen.
3. Halfbroers/-zussen met gedeeltelijk gedeelde ouder.
4. Root met partner en meerdere kinderen over 2 generaties.
5. Situatie met ontbrekende partnerrelatie maar wel beide ouders bekend.
6. Grote boom met veel nodes en zoom/pan.

### Acceptatiecheck WG-01
1. Geen diagonale ouder-kind lijnen zichtbaar.
2. Elke sibling-groep heeft precies 1 horizontale lijn.
3. Verticale koppelingen raken buslijn exact.
4. Geen overlap met naamlabels die leesbaarheid schaadt.
5. Renderperformance blijft vloeiend bij grotere bomen.

### Risicobeheersing
- Risico op visuele regressie beperken via tijdelijke feature-flag op FE-niveau.
- Eerst alleen onderliggende generatiepaden activeren, daarna ook siblings van root.
- Bij regressie snel terug via bestaande fallback branch/tag (al aangemaakt).
