import 'kositem.dart';

class WeekSpyskaart {
	final DateTime weekBegin;
	final Map<int, List<Kositem>> itemsPerDag; // 1=Ma, 7=So
	final DateTime? sperdatum;
	const WeekSpyskaart({required this.weekBegin, required this.itemsPerDag, this.sperdatum});
} 