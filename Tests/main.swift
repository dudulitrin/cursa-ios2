import Foundation

func check(_ condition: Bool, _ message: String) {
    guard condition else { fatalError(message) }
}
let valid = OfferParser.parse("lei 12.60 (NET, tax included)\n1 min • 0.4 km\n8 min • 3.4 km\nConfirm")
check(valid != nil, "Screenshot format")
check(abs(valid!.perKM - 3.3157894736842106) < 0.000001, "Total distance includes pickup")
let comma = OfferParser.parse("12,60 lei\n0,4 km\n3,4 km\nConfirmă")
check(comma == valid, "Romanian comma and suffix currency")
check(OfferParser.parse("lei 12.60\n0.4 km\nConfirm") == nil, "Missing distance")
check(OfferParser.parse("lei 12.60\n0 km\n0 km\nConfirm") == nil, "Zero distance")
check(OfferParser.parse("lei 12.60\n0.4 km\n3.4 km") == nil, "Not an offer")
check(OfferParser.parse("lei 12.60\nlei 20\n0.4 km\n3.4 km\nConfirm") == nil, "Ambiguous price")
check(OfferParser.parse("lei 12.60\n0.4 km\n3.4 km\n5 km\nConfirm") == nil, "Ambiguous distances")
check(OfferParser.parse("12.60 lei\n1 min • 0.4 km\n8 min • 3.4 km\nConfirm") == valid, "Suffix currency followed by pickup minutes")
check(OfferParser.parse("RON 12,60\n0,4 km\n3,4 km\nConfirm") == valid, "RON prefix")
check(OfferParser.parse("12,60\u{00A0}lei\r\n0,4 km\r\n3,4 km\r\nConfirm") == valid, "Nonbreaking space and CRLF")
print("11 parser checks passed")
