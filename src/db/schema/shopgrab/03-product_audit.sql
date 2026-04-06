CREATE TABLE product_audit (
    audit_id         VARCHAR2(20) PRIMARY KEY, -- eg: PA2603290001
    product_id       INT,
    column_name      VARCHAR2(50),
    old_value        VARCHAR2(500),
    new_value        VARCHAR2(500),
    changed_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by       VARCHAR2(50)
);

-- Sequence 1 (ID)
CREATE SEQUENCE prod_audit_id_daily START WITH 1 INCREMENT BY 1 MAXVALUE 9999 CYCLE;

-- Trigger
CREATE OR REPLACE TRIGGER trg_product_audit
    AFTER UPDATE ON product
    FOR EACH ROW
DECLARE
    v_audit_prefix VARCHAR2(10);
    v_base_seq     VARCHAR2(4);
    v_counter      NUMBER := 1;
    v_change_count NUMBER := 0;
BEGIN
    v_audit_prefix := 'PA' || TO_CHAR(SYSDATE, 'YYMMDD');

    IF :OLD.name <> :NEW.name THEN
        v_change_count := v_change_count + 1;
    END IF;
    IF :OLD.description <> :NEW.description THEN
        v_change_count := v_change_count + 1;
    END IF;

    BEGIN
        SELECT LPAD(prod_audit_id_daily.NEXTVAL, 4, '0') INTO v_base_seq FROM DUAL;
    EXCEPTION
        WHEN OTHERS THEN
            v_base_seq := '0001';
    END;

    IF :OLD.name <> :NEW.name THEN
        IF v_change_count > 1 THEN
            INSERT INTO product_audit (audit_id, product_id, column_name, old_value, new_value, changed_by)
            VALUES (v_audit_prefix || v_base_seq || LPAD(v_counter, 2, '0'),
                    :OLD.id, 'NAME', :OLD.name, :NEW.name, USER);
        ELSE
            INSERT INTO product_audit (audit_id, product_id, column_name, old_value, new_value, changed_by)
            VALUES (v_audit_prefix || v_base_seq,
                    :OLD.id, 'NAME', :OLD.name, :NEW.name, USER);
        END IF;
        v_counter := v_counter + 1;
    END IF;

    IF :OLD.description <> :NEW.description THEN
        IF v_change_count > 1 THEN
            INSERT INTO product_audit (audit_id, product_id, column_name, old_value, new_value, changed_by)
            VALUES (v_audit_prefix || v_base_seq || LPAD(v_counter, 2, '0'),
                    :OLD.id, 'DESCRIPTION', :OLD.description, :NEW.description, USER);
        ELSE
            INSERT INTO product_audit (audit_id, product_id, column_name, old_value, new_value, changed_by)
            VALUES (v_audit_prefix || v_base_seq,
                    :OLD.id, 'DESCRIPTION', :OLD.description, :NEW.description, USER);
        END IF;
        v_counter := v_counter + 1;
    END IF;
END;
/

CREATE OR REPLACE PROCEDURE reset_daily_product_audit_seq AS
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE prod_audit_id_daily';
    EXECUTE IMMEDIATE 'CREATE SEQUENCE prod_audit_id_daily START WITH 1 INCREMENT BY 1 MAXVALUE 9999 CYCLE';
END;
/

BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
            job_name        => 'JOB_RESET_AUDIT_SEQ_DAILY',
            job_type        => 'STORED_PROCEDURE',
            job_action      => 'RESET_DAILY_PRODUCT_AUDIT_SEQ',
            start_date      => SYSTIMESTAMP,
            repeat_interval => 'FREQ=DAILY;INTERVAL=1;BYHOUR=0',
            enabled         => TRUE,
            comments        => 'Job that resets product audit sequence every day at midnight'
    );
END;
/