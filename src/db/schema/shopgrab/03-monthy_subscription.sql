CREATE TABLE monthly_subscription
(
    id            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    membership_id INT REFERENCES membership (id)      NOT NULL,
    member_id     INT REFERENCES member (id)          NOT NULL,
    from_date     TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    thru_date     TIMESTAMP                           NOT NULL,
    payment_id    INT REFERENCES payment (id)         NOT NULL,
    CHECK ( thru_date > from_date )
);

-- TODO: trigger to check dont have overlapping membership duration

CREATE SEQUENCE seq_daily_ref_no
    start with 1
    increment by 1
    nomaxvalue
    order;

create trigger trg_autogenerate_ref_no
    before insert
    on payment
    for each row
    begin
        :new.ref_no :='REF' || to_char(current_date, 'yyyymmdd') || lpad(seq_daily_ref_no.nextval, 4, '0');
    end;
/
CREATE OR REPLACE PROCEDURE reset_daily_payment_ref AS
BEGIN

    EXECUTE IMMEDIATE 'ALTER SEQUENCE seq_daily_payment_ref RESTART START WITH 1';
END;
/

BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
        job_name        => 'job_reset_payment_ref_daily',
        job_type        => 'STORED_PROCEDURE',
        job_action      => 'RESET_DAILY_PAYMENT_REF',
        repeat_interval => 'FREQ=DAILY;INTERVAL=1;BYHOUR=0',
        job_style => 'LIGHTWEIGHT',
        comments        => 'Job that reset the payment ref_no sequence every day at midnight'
    );
END;
/