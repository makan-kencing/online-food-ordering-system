CREATE TABLE menu_item_audit 
(
    audit_id      VARCHAR2(20) PRIMARY KEY,
    product_id    INT,
    restaurant_id INT,
    column_name   VARCHAR2(50),
    old_value     VARCHAR2(500),
    new_value     VARCHAR2(500),
    changed_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by    VARCHAR2(50)
);

-- Sequence - 1
CREATE SEQUENCE menu_item_audit_seq_daily
    START WITH 1
    INCREMENT BY 1
    MAXVALUE 9999
    CYCLE;

-- Trigger - 2
-- Record any changes made
CREATE OR REPLACE TRIGGER trg_menu_item_audit
    AFTER UPDATE ON menu_item
    FOR EACH ROW
DECLARE
    v_audit_prefix VARCHAR2(10);
    v_base_seq     VARCHAR2(4);
    v_counter      NUMBER := 1;
    v_change_count NUMBER := 0;
BEGIN
    v_audit_prefix := 'MA' || TO_CHAR(SYSDATE, 'YYMMDD');

    -- Count how many fields have been changed
    IF :OLD.is_unavailable <> :NEW.is_unavailable THEN
        v_change_count := v_change_count + 1;
    END IF;

    IF :OLD.from_date <> :NEW.from_date THEN
        v_change_count := v_change_count + 1;
    END IF;

    IF NVL(:OLD.thru_date, TO_TIMESTAMP('1900-01-01','YYYY-MM-DD')) <>
       NVL(:NEW.thru_date, TO_TIMESTAMP('1900-01-01','YYYY-MM-DD')) THEN
        v_change_count := v_change_count + 1;
    END IF;

    -- Get sequence
    BEGIN
        SELECT LPAD(menu_item_audit_seq_daily.NEXTVAL, 4, '0')
        INTO v_base_seq
        FROM DUAL;
    EXCEPTION
        WHEN OTHERS THEN
            v_base_seq := '0001';
    END;

    -- is_unavailable update
    IF :OLD.is_unavailable <> :NEW.is_unavailable THEN
        INSERT INTO menu_item_audit (
            audit_id, product_id, restaurant_id,
            column_name, old_value, new_value, changed_by
        )
        VALUES (
                   v_audit_prefix ||
                   CASE WHEN v_change_count > 1 THEN v_base_seq || LPAD(v_counter,2,'0') ELSE v_base_seq END,
                   :OLD.product_id,
                   :OLD.restaurant_id,
                   'IS_UNAVAILABLE',
                   TO_CHAR(:OLD.is_unavailable),
                   TO_CHAR(:NEW.is_unavailable),
                   USER
               );
        v_counter := v_counter + 1;
    END IF;

    -- from_date update
    IF :OLD.from_date <> :NEW.from_date THEN
        INSERT INTO menu_item_audit (
            audit_id, product_id, restaurant_id,
            column_name, old_value, new_value, changed_by
        )
        VALUES (
                   v_audit_prefix ||
                   CASE WHEN v_change_count > 1 THEN v_base_seq || LPAD(v_counter,2,'0') ELSE v_base_seq END,
                   :OLD.product_id,
                   :OLD.restaurant_id,
                   'FROM_DATE',
                   TO_CHAR(:OLD.from_date, 'YYYY-MM-DD HH24:MI:SS'),
                   TO_CHAR(:NEW.from_date, 'YYYY-MM-DD HH24:MI:SS'),
                   USER
               );
        v_counter := v_counter + 1;
    END IF;

    -- thru_date update
    IF NVL(:OLD.thru_date, TO_TIMESTAMP('1900-01-01','YYYY-MM-DD')) <>
       NVL(:NEW.thru_date, TO_TIMESTAMP('1900-01-01','YYYY-MM-DD')) THEN
        INSERT INTO menu_item_audit (
            audit_id, product_id, restaurant_id,
            column_name, old_value, new_value, changed_by
        )
        VALUES (
                   v_audit_prefix ||
                   CASE WHEN v_change_count > 1 THEN v_base_seq || LPAD(v_counter,2,'0') ELSE v_base_seq END,
                   :OLD.product_id,
                   :OLD.restaurant_id,
                   'THRU_DATE',
                   TO_CHAR(:OLD.thru_date, 'YYYY-MM-DD HH24:MI:SS'),
                   TO_CHAR(:NEW.thru_date, 'YYYY-MM-DD HH24:MI:SS'),
                   USER
               );
        v_counter := v_counter + 1;
    END IF;

END;
/

CREATE OR REPLACE PROCEDURE reset_daily_menu_item_audit_seq AS
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE menu_item_audit_seq_daily';
    EXECUTE IMMEDIATE 'CREATE SEQUENCE menu_item_audit_seq_daily START WITH 1 INCREMENT BY 1 MAXVALUE 9999 CYCLE';
END;

BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
            job_name        => 'JOB_RESET_MENU_ITEM_AUDIT_SEQ',
            job_type        => 'STORED_PROCEDURE',
            job_action      => 'RESET_DAILY_MENU_ITEM_AUDIT_SEQ',
            start_date      => SYSTIMESTAMP,
            repeat_interval => 'FREQ=DAILY;INTERVAL=1;BYHOUR=0',
            enabled         => TRUE,
            comments        => 'Reset menu item audit sequence daily at midnight'
    );
END;
/
