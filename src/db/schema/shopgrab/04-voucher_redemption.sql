CREATE TABLE voucher_redemption
(
    voucher_distribution_id INT REFERENCES voucher_distribution (id) UNIQUE,
    invoice_id              INT REFERENCES invoice (id),
    PRIMARY KEY (voucher_distribution_id, invoice_id)
);

create trigger t_check_voucher_is_available_to_redeem
    before
        insert
    on voucher_redemption
declare
    redeemed_voucher_id int;
    used                int;
    available           int;
    voucher_fully_redeemed exception;
    pragma exception_init ( voucher_fully_redeemed, -4096 );
begin
    begin
        select v.id, v.usage_limit
        into redeemed_voucher_id, available
        from voucher_distribution vd
                 join voucher v on v.id = vd.voucher_id
        where vd.id = new.voucher_distribution_id;
    exception
        when no_data_found then
            raise_application_error(-20322, 'Voucher cannot be found');
    end;

    if available is null then
        return;
    end if;

    select count(*)
    into used
    from voucher_redemption vr
             join voucher_distribution vd on vr.voucher_distribution_id = vd.id
    where vd.voucher_id = redeemed_voucher_id;

    if (used >= available) then
        raise voucher_fully_redeemed;
    end if;
exception
    when voucher_fully_redeemed then
        raise_application_error(-20300, 'Voucher could not be redeemed');
end;


create trigger t_check_voucher_can_change_usage_limit
    before
        update of usage_limit
    on voucher
declare
    used int;
    voucher_insufficient exception;
    pragma exception_init ( voucher_insufficient, -4096 );
begin
    select count(*)
    into used
    from voucher_redemption vr
             join voucher_distribution vd on vr.voucher_distribution_id = vd.id
    where vd.voucher_id = new.id;

    if (used >= new.usage_limit) then
        raise voucher_insufficient;
    end if;
exception
    when voucher_insufficient then
        raise_application_error(
                -20300,
                'Cannot set limit from ' || old.usage_limit || ' to ' || new.usage_limit || ' ' ||
                'when ' || used || ' is in use.'
        );
end;