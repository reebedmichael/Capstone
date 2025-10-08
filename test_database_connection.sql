-- Test database connection and wallet functionality
-- Check if transaction types exist
SELECT * FROM transaksie_tipe;

-- Check current user's wallet balance
SELECT gebr_id, beursie_balans FROM gebruikers WHERE gebr_id = 'fe08a973-bdd4-4618-b4ca-6754d510c9a5';

-- Check existing transactions
SELECT * FROM beursie_transaksie WHERE gebr_id = 'fe08a973-bdd4-4618-b4ca-6754d510c9a5' ORDER BY trans_geskep_datum DESC LIMIT 5;
