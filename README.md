# Cursa iOS — prototip experimental

Calculează prețul afișat de Bolt / (distanța până la client + distanța cursei).
Exemplul de referință: 12,60 / (0,4 + 3,4) = 3,32 lei/km.
Nu deduce comisioane și nu evaluează profitul. Nu este afiliat Bolt.

## Stare reală

Codul a fost pregătit pe Windows. NU este încă compilat cu Xcode și NU a fost testat pe iPhone. Nu există încă un IPA verificat.
Nu este confirmat că iOS va permite actualizarea continuă a PiP și captura ReplayKit simultan în fundal.
API-urile ReplayKit sunt folosite pentru compatibilitatea țintită cu iOS 26; documentația SDK-urilor Apple mai noi poate marca aceste API-uri deprecated. Prima compilare în cloud va arăta eventualele incompatibilități.

## Blocaj posibil la instalarea gratuită

Aplicația și extensia folosesc același App Group pentru a schimba rezultatul OCR. Un cont Personal Team / o metodă de sideload poate să nu permită sau să elimine acest entitlement. O simplă resemnare nu garantează această funcționalitate. În acest caz testul PiP poate funcționa, dar capturarea live nu poate furniza rezultatul aplicației. Nu cumpăra servicii înainte de verificare.

Nu șterge extensia Broadcast la instalare dacă vrei testul live. Dacă semnarea remapează identificatorii, trebuie să păstreze concordanța dintre bundle ID, preferredExtension, CURSA_GROUP și App Groups în ambele targeturi.

## Compilare prin GitHub Actions (alternativa pregătită)

1. Încarcă fișierele proiectului în rădăcina repository-ului tău, inclusiv folderul `.github/workflows/` și corecțiile din `Shared/Offer.swift` și `Tests/main.swift`.
2. Fișierul `.github/workflows/ios.yml` trebuie să existe pe branch-ul implicit. Dacă încărcarea prin browser omite folderul `.github`, folosește Add file → Create new file, introdu numele complet `.github/workflows/ios.yml` și copiază conținutul din arhivă.
3. Deschide Actions → Cursa iOS → Run workflow. Pornirea este manuală, pentru a evita consumul la fiecare editare.
4. După succes descarcă `Cursa-unsigned` din Artifacts. Arhiva descărcată conține IPA-ul nesemnat; nu este instalabil direct.
5. Dacă build-ul eșuează, deschide pasul roșu și păstrează logul. Nu este necesar un cont Codemagic pentru această rută.

Runnerul standard macOS este gratuit pentru repository-uri publice; cele private folosesc cota inclusă în cont. Păstrează repository-ul privat dacă nu dorești publicarea codului. Nu activa cheltuieli suplimentare pentru acest test. Workflow-ul nu publică aplicația și nu conține certificate sau parole.
GitHub Actions nu rezolvă limitările App Groups sau semnarea iOS. Aceleași teste pe telefon rămân necesare.

## Compilare gratuită de încercat în Codemagic

1. În GitHub creează un repository privat, de exemplu `cursa-ios`. Încarcă întreg conținutul acestui folder în rădăcina repository-ului. `codemagic.yaml` și `project.yml` trebuie să fie la rădăcină. Nu încărca fotografia cu numele și adresele clientului.
2. Deschide https://codemagic.io și creează un cont individual. Conectează GitHub, acordând acces doar repository-ului ales. Aceste operații sunt făcute de titularul contului.
3. Adaugă proiectul folosind configurația `codemagic.yaml`. Alege workflow-ul `ios-prototype` pe Mac mini M2. Nu activa billing suplimentar sau integrarea Apple Developer.
4. Pornește build-ul. Se compilează și execută întâi opt teste ale parserului Swift, se generează proiectul Xcode, apoi se compilează aplicația și extensia fără semnare.
5. Dacă build-ul reușește, descarcă artifactul `Cursa-unsigned.ipa`. Dacă eșuează, păstrează logul erorii pentru corectare; un build eșuat nu produce o aplicație validată.

Planul individual Codemagic afișa 500 minute macOS M2 gratuite/lună la verificarea din 29 octombrie 2026. Verifică oferta afișată în cont înainte de pornire. Configurația limitează fiecare build la 30 minute.

## Instalare și testare pe iPhone

Un IPA nesemnat NU se instalează direct cu iTunes. Este necesară semnarea pentru dispozitiv. AltStore Classic pe Windows este o posibilă rută de test cu cont gratuit, dar suportul pentru extensie și App Groups nu este confirmat pentru acest proiect.
Ghid oficial: https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows
Nu trimite parola Apple în chat. Nu este necesar jailbreak pentru a încerca această rută.

Testează staționat:

1. Deschide Cursa și apasă `Test PiP`. Rezultatul demo trebuie să fie marcat DEMO și să afișeze 3,32 lei/km.
2. Treci într-o altă aplicație și verifică dacă fereastra rămâne vizibilă. Acest pas nu testează captura Bolt.
3. Revino, activează citirea reală și pornește explicit difuzarea `Cursa Capture` din butonul sistemului. Microfonul nu este folosit.
4. Dacă apare `App Group indisponibil`, notează acest blocaj. Nu interpreta testul demo ca funcționalitate live.
5. Deschide PiP, apoi Bolt Driver. Mută fereastra în partea de sus; oferta trebuie să rămână vizibilă.
6. Verifică o ofertă reală: cele două distanțe se însumează. Sunt necesare două citiri OCR consecutive identice. Când oferta dispare, rezultatul trebuie să dispară, iar datele mai vechi de trei secunde nu se afișează ca actuale.
7. Testează separat schimbarea ofertei, textul cu virgulă, oferta acoperită, captura oprită și aplicația în fundal cel puțin un minut. Dacă PiP îngheață în fundal, prototipul nu îndeplinește cerința.
8. Oprește PiP din aplicație și captura separat din indicatorul sistemului iOS.

## Confidențialitate și limitări

OCR rulează local prin Vision; cadrele nu sunt salvate, încărcate sau logate. Se păstrează numai ultimul preț, cele două distanțe, ora și mesajul de stare într-un fișier local partajat. Nu există backend sau analytics.
Parserul este intenționat strict: o sumă cu lei/RON, exact două valori km și text de confirmare/acceptare, în partea inferioară a ecranului. Alte formate Bolt pot necesita ajustări. Nu calculează oferte cu distanțe exprimate în metri.
PiP utilizează cadre generate local pentru a afișa rezultatul. Aceasta este o utilizare experimentală, nu o confirmare de eligibilitate App Store. Verificarea pe dispozitiv este obligatorie.

## Fișiere

- `App/`: interfață SwiftUI și generator de cadre PiP.
- `Broadcast/`: extensie ReplayKit cu Vision OCR.
- `Shared/`: parser și schimb local de rezultate.
- `Tests/`: opt verificări rulate de workflow în macOS.
- `project.yml`: proiect XcodeGen, aplicație + extensie.
- `codemagic.yaml`: build fără semnare și împachetare IPA.

Pentru build manual pe un Mac: `brew install xcodegen`, apoi `xcodegen generate`. Semnarea reală se configurează ulterior; nu există certificate sau chei incluse în proiect.
