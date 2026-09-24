// Einheitliche Formatierung. Kurse mit einer Nachkommastelle wie beim Broker,
// Zeiten ohne Tilde, R mit Vorzeichen.
import "dart:ui" show FontFeature;

String px(num v) => v.toStringAsFixed(1);
String rr(num v) => "${v >= 0 ? "+" : ""}${v.toStringAsFixed(1)} R";
String usd(num v) => "${v.round()} \$";

String ago(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return "gerade eben";
  if (d.inMinutes < 60) return "vor ${d.inMinutes} min";
  if (d.inHours < 24) return "vor ${d.inHours} Std";
  if (d.inDays == 1) return "gestern";
  return "vor ${d.inDays} Tagen";
}

String hhmm(DateTime t) {
  final l = t.toLocal();
  return "${l.hour.toString().padLeft(2, "0")}:${l.minute.toString().padLeft(2, "0")}";
}

String ddmm(DateTime t) {
  final l = t.toLocal();
  return "${l.day.toString().padLeft(2, "0")}.${l.month.toString().padLeft(2, "0")}.";
}

const tabular = [FontFeature.tabularFigures()];
