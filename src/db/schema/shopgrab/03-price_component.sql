CREATE DOMAIN price_type AS ENUM
(
    BASE,
    DISCOUNT,
    SURCHARGE
);

CREATE TABLE price_component
(
    id                  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code                CHAR(14)                            NOT NULL,
    price_type          price_type                          NOT NULL,
    from_date           TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    thru_date           TIMESTAMP,
    description         VARCHAR(200)                        NOT NULL,
    amount              DECIMAL CHECK ( amount > 0 ),
    percentage          DECIMAL(5, 4) CHECK ( percentage > 0 AND percentage < 1 ),
    product_id          INT REFERENCES product (id),
    product_feature_id  INT REFERENCES product_feature (id),
    product_category_id INT REFERENCES product_category (id),
    quantity_break_id   INT REFERENCES quantity_break (id),
    order_value_id      INT REFERENCES order_value (id),
    restaurant_id       INT REFERENCES restaurant (id),
    membership_id       INT REFERENCES membership (id),
    voucher_id          INT REFERENCES voucher (id),
    vendor_id           INT REFERENCES delivery_vendor (id),
    CHECK ( amount IS NULL != percentage IS NULL ),                       -- mutual exclusion
    CHECK ( thru_date is null or thru_date > from_date ),
    CHECK ( coalesce(product_id, product_feature_id, product_category_id, -- at least one condition
                     quantity_break_id, order_value_id, restaurant_id,
                     membership_id, voucher_id, vendor_id) IS NOT NULL )
);

create sequence seq_daily_price_index
    start with 1
    increment by 1
    nomaxvalue
    order;

create trigger trg_autogenerate_price_code
    before insert
    on price_component
    for each row
begin
    :new.code := 'PR' || to_char(current_date, 'yyyymmdd') || lpad(seq_price_daily_index.nextval, 4, '0');
end;
/

create procedure reset_daily_price_index as
begin
    execute immediate 'alter sequence seq_daily_price_index restart start with 1;';
end;
/

begin
    DBMS_SCHEDULER.CREATE_JOB(
            job_name => 'periodic_reset_daily_price_index',
            job_type => 'STORED_PROCEDURE',
            job_action => 'SHOPGRAB.RESET_DAILY_PRICE_INDEX',
            repeat_interval => 'FREQ=DAILY;INTERVAL=1;BYHOUR=0',
            job_style => 'LIGHTWEIGHT',
            comments => 'Job that reset the price_component code sequence every day at midnight'
    );
end;
/