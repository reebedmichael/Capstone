enum BestellingStatus { geplaas, in_voorbereiding, reg_vir_afhaal, afgehandel, gekanselleer }

enum BetalingStatus { onbetaal, betaal }

class Bestelling {
	final String id;
	final DateTime datum;
	final BestellingStatus status;
	final BetalingStatus betalingStatus;
	final double totaal;

	const Bestelling({
		required this.id,
		required this.datum,
		required this.status,
		required this.betalingStatus,
		required this.totaal,
	});
} 