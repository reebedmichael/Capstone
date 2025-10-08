import 'package:supabase_flutter/supabase_flutter.dart';
import 'db.dart';

class EmailService {
  EmailService(this._db);
  final SupabaseDb _db;

  SupabaseClient get _sb => _db.raw;

  /// Stuur email notifikasie aan 'n spesifieke gebruiker
  Future<bool> stuurEmail({
    required String gebrId,
    required String onderwerp,
    required String inhoud,
    String? tipe,
  }) async {
    try {
      // Kry gebruiker inligting
      final gebruiker = await _sb.from('gebruikers')
          .select('gebr_email, gebr_naam')
          .eq('gebr_id', gebrId)
          .maybeSingle();

      if (gebruiker == null) {
        print('Gebruiker nie gevind nie: $gebrId');
        return false;
      }

      final email = gebruiker['gebr_email'] as String?;
      final naam = gebruiker['gebr_naam'] as String?;

      if (email == null || email.isEmpty) {
        print('Geen email adres vir gebruiker: $gebrId');
        return false;
      }

      // Stuur email via Supabase Edge Functions
      final response = await _sb.functions.invoke(
        'send-email',
        body: {
          'to': email,
          'subject': onderwerp,
          'html': _maakEmailHTML(naam ?? 'Gebruiker', inhoud, tipe),
          'text': inhoud,
        },
      );

      if (response.status == 200) {
        print('✅ Email gestuur aan $email');
        return true;
      } else {
        print('❌ Fout met stuur email: ${response.data}');
        return false;
      }
    } catch (e) {
      print('❌ Fout met stuur email: $e');
      return false;
    }
  }

  /// Stuur email aan alle gebruikers
  Future<bool> stuurEmailAanAlleGebruikers({
    required String onderwerp,
    required String inhoud,
    String? tipe,
  }) async {
    try {
      // Kry alle gebruikers met email adresse
      final gebruikers = await _sb.from('gebruikers')
          .select('gebr_email, gebr_naam')
          .not('gebr_email', 'is', null)
          .neq('gebr_email', '');

      if (gebruikers.isEmpty) {
        print('Geen gebruikers met email adresse gevind');
        return false;
      }

      // Stuur email aan elke gebruiker
      int suksesvol = 0;
      for (final gebruiker in gebruikers) {
        final email = gebruiker['gebr_email'] as String?;
        final naam = gebruiker['gebr_naam'] as String?;

        if (email != null && email.isNotEmpty) {
          try {
            final response = await _sb.functions.invoke(
              'send-email',
              body: {
                'to': email,
                'subject': onderwerp,
                'html': _maakEmailHTML(naam ?? 'Gebruiker', inhoud, tipe),
                'text': inhoud,
              },
            );

            if (response.status == 200) {
              suksesvol++;
            }
          } catch (e) {
            print('Fout met stuur email aan $email: $e');
          }
        }
      }

      print('✅ $suksesvol van ${gebruikers.length} emails gestuur');
      return suksesvol > 0;
    } catch (e) {
      print('❌ Fout met stuur email aan alle gebruikers: $e');
      return false;
    }
  }

  /// Stuur email aan spesifieke gebruikers
  Future<bool> stuurEmailAanSpesifiekeGebruikers({
    required List<String> gebrIds,
    required String onderwerp,
    required String inhoud,
    String? tipe,
  }) async {
    try {
      if (gebrIds.isEmpty) return false;

      // Kry gebruikers met email adresse
      final gebruikers = await _sb.from('gebruikers')
          .select('gebr_id, gebr_email, gebr_naam')
          .inFilter('gebr_id', gebrIds)
          .not('gebr_email', 'is', null)
          .neq('gebr_email', '');

      if (gebruikers.isEmpty) {
        print('Geen gebruikers met email adresse gevind');
        return false;
      }

      // Stuur email aan elke gebruiker
      int suksesvol = 0;
      for (final gebruiker in gebruikers) {
        final email = gebruiker['gebr_email'] as String?;
        final naam = gebruiker['gebr_naam'] as String?;

        if (email != null && email.isNotEmpty) {
          try {
            final response = await _sb.functions.invoke(
              'send-email',
              body: {
                'to': email,
                'subject': onderwerp,
                'html': _maakEmailHTML(naam ?? 'Gebruiker', inhoud, tipe),
                'text': inhoud,
              },
            );

            if (response.status == 200) {
              suksesvol++;
            }
          } catch (e) {
            print('Fout met stuur email aan $email: $e');
          }
        }
      }

      print('✅ $suksesvol van ${gebruikers.length} emails gestuur');
      return suksesvol > 0;
    } catch (e) {
      print('❌ Fout met stuur email aan spesifieke gebruikers: $e');
      return false;
    }
  }

  /// Maak HTML email template
  String _maakEmailHTML(String naam, String inhoud, String? tipe) {
    final tipeKleur = _kryTipeKleur(tipe);
    final tipeIkoon = _kryTipeIkoon(tipe);

    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Spys Kennisgewing</title>
        <style>
            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                line-height: 1.6;
                color: #333;
                max-width: 600px;
                margin: 0 auto;
                padding: 20px;
                background-color: #f5f5f5;
            }
            .container {
                background-color: white;
                border-radius: 10px;
                padding: 30px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            }
            .header {
                text-align: center;
                border-bottom: 2px solid #007bff;
                padding-bottom: 20px;
                margin-bottom: 30px;
            }
            .logo {
                font-size: 28px;
                font-weight: bold;
                color: #007bff;
                margin-bottom: 10px;
            }
            .notification {
                background-color: ${tipeKleur}15;
                border-left: 4px solid $tipeKleur;
                padding: 20px;
                border-radius: 5px;
                margin: 20px 0;
            }
            .notification-icon {
                font-size: 24px;
                margin-right: 10px;
                color: $tipeKleur;
            }
            .content {
                font-size: 16px;
                line-height: 1.8;
            }
            .footer {
                text-align: center;
                margin-top: 30px;
                padding-top: 20px;
                border-top: 1px solid #eee;
                color: #666;
                font-size: 14px;
            }
            .button {
                display: inline-block;
                background-color: #007bff;
                color: white;
                padding: 12px 24px;
                text-decoration: none;
                border-radius: 5px;
                margin: 20px 0;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <div class="logo">🍽️ Spys</div>
                <p>Jou kampus kos bestelling platform</p>
            </div>
            
            <h2>Hallo $naam!</h2>
            
            <div class="notification">
                <span class="notification-icon">$tipeIkoon</span>
                <div class="content">
                    $inhoud
                </div>
            </div>
            
            <p>Dankie dat jy Spys gebruik!</p>
            
            <div class="footer">
                <p>Hierdie email is gestuur vanaf die Spys platform.</p>
                <p>As jy nie hierdie email verwag het nie, kan jy dit ignoreer.</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  String _kryTipeKleur(String? tipe) {
    switch (tipe?.toLowerCase()) {
      case 'waarskuwing':
        return '#ff9800';
      case 'fout':
        return '#f44336';
      case 'sukses':
        return '#4caf50';
      case 'kritiek':
        return '#d32f2f';
      default:
        return '#2196f3';
    }
  }

  String _kryTipeIkoon(String? tipe) {
    switch (tipe?.toLowerCase()) {
      case 'waarskuwing':
        return '⚠️';
      case 'fout':
        return '❌';
      case 'sukses':
        return '✅';
      case 'kritiek':
        return '🚨';
      default:
        return 'ℹ️';
    }
  }
}
