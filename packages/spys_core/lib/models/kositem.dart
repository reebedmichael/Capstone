class Kositem {
	final String id;
	final String naam;
	final String beskrywing;
	final String kategorie;
	final double prys;
	final bool beskikbaar;
	final String? prentUrl;

	const Kositem({
		required this.id,
		required this.naam,
		required this.beskrywing,
		required this.kategorie,
		required this.prys,
		required this.beskikbaar,
		this.prentUrl,
	});
} 