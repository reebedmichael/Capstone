enum GebruikersRol { admin, gebruiker }

enum GoedkeuringsStatus { wagtend, goedgekeur, geweier }

class Gebruiker {
	final String id;
	final String naam;
	final String van;
	final String epos;
	final String selfoon;
	final List<GebruikersRol> rolle;
	final bool aktief;
	final GoedkeuringsStatus goedkeuringsStatus;
	const Gebruiker({
		required this.id,
		required this.naam,
		required this.van,
		required this.epos,
		required this.selfoon,
		required this.rolle,
		required this.aktief,
		required this.goedkeuringsStatus,
	});
} 