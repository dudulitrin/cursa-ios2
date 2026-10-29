# Panou PiP cu patru valori

Înlocuiește în repository:
- `App/PiPModel.swift`
- `Shared/Offer.swift`
- `Tests/main.swift`
- `Broadcast/SampleHandler.swift` (include optimizarea OCR anterioară)

Pornește o rulare NOUĂ: Actions → Cursa iOS → Run workflow → main.
Instalează IPA-ul acelei rulări prin aceeași metodă AltServer.

Panoul afișează RON/km, RON/oră, distanța totală și durata totală. Fundal albastru închis, tarif/km galben, două casete pentru totaluri. Nu conține profit, cost sau verdict.

Distanță = până la client + cursă. Durată = minute până la client + minute cursă. RON/oră = preț × 60 / durata totală în minute. Este un tarif calculat pentru oferta afișată, nu venitul garantat într-o oră de lucru.
Minutele trebuie recunoscute în exact două valori. Duratele exprimate în ore sau citirile incomplete/ambigue afișează „—” pentru durată și RON/oră; calculul pe kilometru rămâne disponibil.

Exemplu: 11,46 lei, 1 + 3,7 km, 2 + 9 min → 2,44 RON/km, 62,51 RON/oră, 4,7 km, 11 min.

Validare locală: 9 verificări ale expresiilor de durată și calculelor rulate în JavaScript. Cele 23 de verificări Swift se execută în GitHub Actions. UIKit/PiP nu pot fi compilate sau inspectate pe acest PC Windows; aspectul și OCR-ul trebuie verificate pe iPhone. Datele demo și stările fără ofertă rămân explicit marcate.
