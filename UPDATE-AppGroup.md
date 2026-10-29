# Actualizare pentru instalarea AltServer

Înlocuiește în GitHub aceste trei fișiere din arhivă:

- `.github/workflows/ios.yml`
- `Shared/Offer.swift`
- `App/CursaApp.swift`

Pornește Actions → Cursa iOS → Run workflow. Descarcă artifactul nou, nu rularea anterioară.
IPA-ul poartă încă numele Cursa-unsigned.ipa pentru compatibilitate, însă conține acum o semnătură ad-hoc locală care păstrează entitlements pentru resemnarea AltServer. Aceasta NU este o semnătură Apple pentru instalare și nu acordă singură App Groups.

Instalează noul IPA folosind AltServer pe Windows: Shift + clic pe pictograma de lângă ceas → Sideload .ipa. Folosește același cont și păstrează extensia. Nu este necesară ștergerea prealabilă a aplicației.

Deschide Cursa → Diagnostic instalare. Dacă grupul este în continuare indisponibil, trimite captura acelui panou: numai atunci știm ce grupuri au fost păstrate în profil. Nu trimite profilul complet, certificate sau parole.

Schimbările detectează numele grupului după resemnare și identificatorul real al extensiei incluse. Nu confirmă că semnarea gratuită acordă permisiunea necesară; aceasta rămâne de verificat pe telefon. Compilarea acestei actualizări nu a fost executată pe Windows.
