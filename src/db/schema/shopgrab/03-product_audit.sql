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