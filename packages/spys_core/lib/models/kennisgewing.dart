enum KennisgewingTipe { info, waarskuwing, krities }

class Kennisgewing {
	final String id;
	final String titel;
	final String kortBoodskap;
	final String inhoud;
	final KennisgewingTipe tipe;
	final int prioriteit; // 1-5
	const Kennisgewing({
		required this.id,
		required this.titel,
		required this.kortBoodskap,
		required this.inhoud,
		required this.tipe,
		required this.prioriteit,
	});
} 