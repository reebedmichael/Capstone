// Shared constants for order management
class OrderConstants {
  // Days of the week in Afrikaans
  static const List<String> weekDays = [
    'Maandag',
    'Dinsdag',
    'Woensdag',
    'Donderdag',
    'Vrydag',
    'Saterdag',
    'Sondag',
  ];

  // Special filter options
  static const List<String> specialFilters = ['Geskiedenis'];

  // Status display mappings
  static const Map<String, String> statusLabels = {
    'pending': 'Bestelling Ontvang',
    'preparing': 'Besig met Voorbereiding',
    'readyDelivery': 'Gereed vir aflewering',
    'readyFetch': 'Reg vir afhaal',
    'outForDelivery': 'Uit vir aflewering',
    'delivered': 'By afleweringspunt',
    'done': 'Afgehandel',
    'cancelled': 'Gekanselleer',
  };

  // Common UI strings
  static const Map<String, String> uiStrings = {
    'searchPlaceholder': 'Soek vir kliënt e-pos of bestelling ID...',
    'noOrdersFound': 'Geen bestellings',
    'ordersForDay': 'Bestellings vir',
    'orderHistory': 'Bestelling Geskiedenis',
    'viewDetails': 'Besigtig',
    'updateStatus': 'Opdateer',
    'cancelOrder': 'Kanseleer',
    'bulkUpdate': 'Bevorder bestellings na:',
    'selectAction': 'Kies aksie',
    'updateCount': 'Opdateer',
    'noEligibleOrders': 'Geen kwalifiserende bestellings nie',
    'noActionsAvailable': 'Geen aksies beskikbaar nie',
    'confirmCancellation': 'Bevestig Kanselasie',
    'irreversibleAction': 'Hierdie aksie kan nie ongedaan gemaak word nie.',
    'orderDetails': 'Bestelling besonderhede',
    'orderId': 'Bestelling ID:',
    'client': 'Kliënt:',
    'day': 'Dag:',
    'itemsToCancel': 'Items om te kanseleer:',
    'total': 'Totaal:',
    'close': 'Maak toe',
    'keepOrder': 'Hou bestelling',
    'cancelItems': 'Kanseleer',
    'thisWeek': 'Hierdie week',
    'items': 'Items om aan kliënte af te lewer',
    'totalItems': 'totaal',
    'filtered': 'Gefiltreer',
    'clearFilter': 'Vee filter uit om alle items te wys',
  };

  // Helper methods
  static String getCurrentDayInAfrikaans() {
    const dayNames = {
      1: "Maandag",
      2: "Dinsdag",
      3: "Woensdag",
      4: "Donderdag",
      5: "Vrydag",
      6: "Saterdag",
      7: "Sondag",
    };
    return dayNames[DateTime.now().weekday] ?? "Onbekend";
  }

  static String getStatusLabel(String status) {
    return statusLabels[status] ?? status;
  }

  static String getUiString(String key) {
    return uiStrings[key] ?? key;
  }
}
