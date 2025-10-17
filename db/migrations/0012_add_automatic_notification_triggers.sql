-- =======================================
-- Migration: Add Automatic Notification Triggers for All System Events
-- Date: 2025-10-17
-- Description: Creates database triggers to automatically send notifications for:
--              - Order status changes
--              - Wallet/Balance updates
--              - Allowance distribution
--              - User approval/acceptance
-- =======================================

-- =======================================
-- 1. TRIGGER FOR ORDER STATUS CHANGES
-- =======================================

CREATE OR REPLACE FUNCTION notify_order_status_change()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id uuid;
    v_order_number text;
    v_status_name text;
    v_notification_title text;
    v_notification_body text;
    v_kennis_tipe_id uuid;
BEGIN
    -- Get user ID and order number from the order item
    SELECT bki.best_id, bki.best_nommer, b.gebr_id
    INTO v_order_number, v_user_id
    FROM bestelling_kos_item bki
    JOIN bestelling b ON bki.best_id = b.best_id
    WHERE bki.best_kos_id = NEW.best_kos_id;
    
    -- Get status name
    SELECT kos_stat_naam INTO v_status_name
    FROM kos_item_statusse
    WHERE kos_stat_id = NEW.kos_stat_id;
    
    -- Get or create 'order' notification type
    INSERT INTO kennisgewing_tipes (kennis_tipe_naam)
    VALUES ('order')
    ON CONFLICT DO NOTHING;
    
    SELECT kennis_tipe_id INTO v_kennis_tipe_id
    FROM kennisgewing_tipes
    WHERE kennis_tipe_naam = 'order';
    
    -- Build notification message based on status
    CASE v_status_name
        WHEN 'In voorbereiding' THEN
            v_notification_title := 'Bestelling Word Voorberei';
            v_notification_body := format('Jou bestelling #%s word nou voorberei! 👨‍🍳', v_order_number);
        WHEN 'Wag vir afhaal' THEN
            v_notification_title := 'Bestelling Gereed!';
            v_notification_body := format('Jou bestelling #%s is gereed vir afhaal! 🎉', v_order_number);
        WHEN 'Ontvang' THEN
            v_notification_title := 'Bestelling Ontvang';
            v_notification_body := format('Jou bestelling #%s is suksesvol afgehaal. Geniet! 😊', v_order_number);
        WHEN 'Afgehandel' THEN
            v_notification_title := 'Bestelling Voltooi';
            v_notification_body := format('Jou bestelling #%s is voltooi. Dankie! ✅', v_order_number);
        WHEN 'Gekanselleer' THEN
            v_notification_title := 'Bestelling Gekanselleer';
            v_notification_body := format('Jou bestelling #%s is gekanselleer. 😔', v_order_number);
        ELSE
            v_notification_title := 'Bestelling Status Opdatering';
            v_notification_body := format('Jou bestelling #%s status is opgedateer na: %s', v_order_number, v_status_name);
    END CASE;
    
    -- Create notification (will trigger push notification via existing trigger)
    INSERT INTO kennisgewings (
        gebr_id,
        kennis_titel,
        kennis_beskrywing,
        kennis_tipe_id,
        kennis_gelees
    )
    VALUES (
        v_user_id,
        v_notification_title,
        v_notification_body,
        v_kennis_tipe_id,
        false
    );
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error but don't fail the status update
        RAISE WARNING 'Error sending order status notification: %', SQLERRM;
        RETURN NEW;
END;
$$;

-- Create trigger for order status changes
DROP TRIGGER IF EXISTS on_order_status_change_notify ON best_kos_item_statusse;

CREATE TRIGGER on_order_status_change_notify
    AFTER INSERT ON best_kos_item_statusse
    FOR EACH ROW
    EXECUTE FUNCTION notify_order_status_change();

COMMENT ON FUNCTION notify_order_status_change() IS 
'Automatically sends notifications to users when their order status changes';

-- =======================================
-- 2. TRIGGER FOR WALLET/BALANCE UPDATES
-- =======================================

CREATE OR REPLACE FUNCTION notify_wallet_update()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
    v_transaction_type text;
    v_notification_title text;
    v_notification_body text;
    v_kennis_tipe_id uuid;
    v_is_allowance boolean := false;
BEGIN
    -- Get transaction type name
    SELECT tt.trans_tipe_naam INTO v_transaction_type
    FROM transaksie_tipe tt
    WHERE tt.trans_tipe_id = NEW.trans_tipe_id;
    
    -- Check if this is an allowance transaction
    v_is_allowance := (v_transaction_type IN ('toelae_inbetaling', 'toelae_uitbetaling'));
    
    -- Get or create appropriate notification type
    IF v_is_allowance THEN
        INSERT INTO kennisgewing_tipes (kennis_tipe_naam)
        VALUES ('allowance')
        ON CONFLICT DO NOTHING;
        
        SELECT kennis_tipe_id INTO v_kennis_tipe_id
        FROM kennisgewing_tipes
        WHERE kennis_tipe_naam = 'allowance';
    ELSE
        INSERT INTO kennisgewing_tipes (kennis_tipe_naam)
        VALUES ('wallet')
        ON CONFLICT DO NOTHING;
        
        SELECT kennis_tipe_id INTO v_kennis_tipe_id
        FROM kennisgewing_tipes
        WHERE kennis_tipe_naam = 'wallet';
    END IF;
    
    -- Build notification message based on transaction type and amount
    IF NEW.trans_bedrag > 0 THEN
        IF v_is_allowance THEN
            v_notification_title := 'Toelae Ontvang!';
            v_notification_body := format('Jy het R%.2f toelae ontvang! 💰', NEW.trans_bedrag);
        ELSE
            v_notification_title := 'Beursie Opglaai';
            v_notification_body := format('Jou beursie is opggelaai met R%.2f! 💳', NEW.trans_bedrag);
        END IF;
    ELSE
        v_notification_title := 'Beursie Transaksie';
        v_notification_body := format('R%.2f is van jou beursie afgetrek. 💸', ABS(NEW.trans_bedrag));
    END IF;
    
    -- Add description if provided
    IF NEW.trans_beskrywing IS NOT NULL AND NEW.trans_beskrywing != '' THEN
        v_notification_body := v_notification_body || ' ' || NEW.trans_beskrywing;
    END IF;
    
    -- Create notification (will trigger push notification via existing trigger)
    INSERT INTO kennisgewings (
        gebr_id,
        kennis_titel,
        kennis_beskrywing,
        kennis_tipe_id,
        kennis_gelees
    )
    VALUES (
        NEW.gebr_id,
        v_notification_title,
        v_notification_body,
        v_kennis_tipe_id,
        false
    );
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error but don't fail the transaction
        RAISE WARNING 'Error sending wallet update notification: %', SQLERRM;
        RETURN NEW;
END;
$$;

-- Create trigger for wallet transactions
DROP TRIGGER IF EXISTS on_wallet_transaction_notify ON beursie_transaksie;

CREATE TRIGGER on_wallet_transaction_notify
    AFTER INSERT ON beursie_transaksie
    FOR EACH ROW
    EXECUTE FUNCTION notify_wallet_update();

COMMENT ON FUNCTION notify_wallet_update() IS 
'Automatically sends notifications to users when their wallet balance changes';

-- =======================================
-- 3. TRIGGER FOR USER APPROVAL/ACTIVATION
-- =======================================

CREATE OR REPLACE FUNCTION notify_user_approval()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
    v_notification_title text;
    v_notification_body text;
    v_kennis_tipe_id uuid;
BEGIN
    -- Only notify if user was just activated (changed from inactive to active)
    IF OLD.is_aktief = false AND NEW.is_aktief = true THEN
        -- Get or create 'approval' notification type
        INSERT INTO kennisgewing_tipes (kennis_tipe_naam)
        VALUES ('approval')
        ON CONFLICT DO NOTHING;
        
        SELECT kennis_tipe_id INTO v_kennis_tipe_id
        FROM kennisgewing_tipes
        WHERE kennis_tipe_naam = 'approval';
        
        -- Build notification message
        v_notification_title := 'Rekening Geaktiveer! 🎉';
        v_notification_body := format('Welkom %s! Jou rekening is goedgekeur en geaktiveer. Jy kan nou begin bestel! 🍽️', 
                                     COALESCE(NEW.gebr_naam, 'gebruiker'));
        
        -- Create notification (will trigger push notification via existing trigger)
        INSERT INTO kennisgewings (
            gebr_id,
            kennis_titel,
            kennis_beskrywing,
            kennis_tipe_id,
            kennis_gelees
        )
        VALUES (
            NEW.gebr_id,
            v_notification_title,
            v_notification_body,
            v_kennis_tipe_id,
            false
        );
    END IF;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error but don't fail the user update
        RAISE WARNING 'Error sending user approval notification: %', SQLERRM;
        RETURN NEW;
END;
$$;

-- Create trigger for user approval
DROP TRIGGER IF EXISTS on_user_approval_notify ON gebruikers;

CREATE TRIGGER on_user_approval_notify
    AFTER UPDATE ON gebruikers
    FOR EACH ROW
    WHEN (OLD.is_aktief IS DISTINCT FROM NEW.is_aktief)
    EXECUTE FUNCTION notify_user_approval();

COMMENT ON FUNCTION notify_user_approval() IS 
'Automatically sends notifications to users when their account is approved/activated';

-- =======================================
-- 4. ADDITIONAL HELPER FUNCTION: SEND CUSTOM NOTIFICATION
-- =======================================

CREATE OR REPLACE FUNCTION send_custom_notification(
    p_user_id uuid,
    p_title text,
    p_body text,
    p_type text DEFAULT 'info'
)
RETURNS json
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
    v_kennis_tipe_id uuid;
    v_kennis_id uuid;
BEGIN
    -- Get or create notification type
    INSERT INTO kennisgewing_tipes (kennis_tipe_naam)
    VALUES (p_type)
    ON CONFLICT DO NOTHING;
    
    SELECT kennis_tipe_id INTO v_kennis_tipe_id
    FROM kennisgewing_tipes
    WHERE kennis_tipe_naam = p_type;
    
    -- Create notification
    INSERT INTO kennisgewings (
        gebr_id,
        kennis_titel,
        kennis_beskrywing,
        kennis_tipe_id,
        kennis_gelees
    )
    VALUES (
        p_user_id,
        p_title,
        p_body,
        v_kennis_tipe_id,
        false
    )
    RETURNING kennis_id INTO v_kennis_id;
    
    RETURN json_build_object(
        'success', true,
        'notification_id', v_kennis_id,
        'message', 'Notification created and push notification triggered automatically'
    );
END;
$$;

COMMENT ON FUNCTION send_custom_notification IS 
'Helper function to send custom notifications to users. Push notifications are sent automatically via trigger.';

GRANT EXECUTE ON FUNCTION send_custom_notification TO authenticated;
GRANT EXECUTE ON FUNCTION send_custom_notification TO service_role;

-- =======================================
-- 5. GRANT PERMISSIONS
-- =======================================

GRANT EXECUTE ON FUNCTION notify_order_status_change TO postgres;
GRANT EXECUTE ON FUNCTION notify_order_status_change TO service_role;

GRANT EXECUTE ON FUNCTION notify_wallet_update TO postgres;
GRANT EXECUTE ON FUNCTION notify_wallet_update TO service_role;

GRANT EXECUTE ON FUNCTION notify_user_approval TO postgres;
GRANT EXECUTE ON FUNCTION notify_user_approval TO service_role;

-- =======================================
-- VERIFICATION
-- =======================================

-- List all notification triggers
SELECT 
    trigger_name,
    event_object_table as table_name,
    action_timing,
    event_manipulation as event
FROM information_schema.triggers
WHERE trigger_name LIKE '%notify%'
ORDER BY trigger_name;

RAISE NOTICE '✅ Automatic notification triggers created successfully!';
RAISE NOTICE 'ℹ️  Triggers created for:';
RAISE NOTICE '   - Order status changes (best_kos_item_statusse)';
RAISE NOTICE '   - Wallet updates (beursie_transaksie)';
RAISE NOTICE '   - User approval (gebruikers.is_aktief)';
RAISE NOTICE '';
RAISE NOTICE '🎉 All system events will now automatically send push notifications!';

