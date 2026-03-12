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
    for each row
declare
    v_voucher_id int;
    v_within_usage_limit boolean;
    v_within_redeem_time boolean;
    voucher_fully_redeemed exception;
    voucher_redeem_out_of_time exception;
    pragma exception_init ( voucher_fully_redeemed, -4096 );
begin
    begin
        select v.id, count(vvr.voucher_distribution_id) < v.usage_limit, i.invoiced_at between v.from_date and coalesce(v.thru_date, current_timestamp)
        into v_voucher_id, v_within_usage_limit, v_within_redeem_time
            from voucher_distribution vd
            join invoice i on i.id = new.invoice_id
            join voucher v  on vd.voucher_id = v.id
            left join voucher_distribution vvd on vvd.voucher_id = v.id
            left join voucher_redemption vvr on vvr.voucher_distribution_id = vvd.id
        where vd.id = new.voucher_distribution_id
        group by v.id, v.usage_limit, v.from_date, v.thru_date, i.invoiced_at;
    exception
        when no_data_found then
            raise_application_error(-20322, 'Voucher cannot be found');
    end;

    if (v_within_usage_limit = true) then
        raise voucher_fully_redeemed;
    end if;

    if (v_within_redeem_time = false) then
        raise voucher_redeem_out_of_time;
    end if;
exception
    when voucher_fully_redeemed then
        raise_application_error(-20300, 'Voucher fully redeemed');
    when voucher_redeem_out_of_time then
        raise_application_error(-20300, 'Voucher cannot be redeemed out of the available time range');
end;


create trigger t_check_voucher_can_change_usage_limit
    before
        update of usage_limit
    on voucher
    for each row
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