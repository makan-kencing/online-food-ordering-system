CREATE TABLE voucher_redemption
(
    voucher_distribution_id INT REFERENCES voucher_distribution (id) UNIQUE,
    invoice_id              INT REFERENCES invoice (id),
    PRIMARY KEY (voucher_distribution_id, invoice_id)
);

create trigger t_check_voucher_is_available_to_redeem
    for insert
    on voucher_redemption
    compound trigger
    type voucher_ids_t is table of voucher.id%type;
    voucher_ids voucher_ids_t;
    type usages_t is table of int;
    usages usages_t;

    type voucher_usages_t is table of int index by varchar2(80);
    v_voucher_usages voucher_usages_t;

    v_voucher_id voucher.id%type;
    v_usage_limit voucher.usage_limit%type;
    v_within_redeem_time boolean;
    voucher_fully_redeemed exception;
    voucher_redeem_out_of_time exception;
    pragma exception_init ( voucher_fully_redeemed, -4096 );
before statement is
begin
    select v.id, count(vvr.voucher_distribution_id)
        bulk collect
    into voucher_ids, usages
    from voucher v
             left join voucher_distribution vvd on vvd.voucher_id = v.id
             left join voucher_redemption vvr on vvr.voucher_distribution_id = vvd.id
    group by v.id;
    for j in 1..voucher_ids.count()
        loop
            v_voucher_usages(voucher_ids(j)) := usages(j);
        end loop;
end before statement;
    after each row is
    begin
        select v.id, v.usage_limit, i.invoiced_at between v.from_date and coalesce(v.thru_date, current_timestamp)
        into v_voucher_id, v_usage_limit, v_within_redeem_time
        from voucher_distribution vd
                 join invoice i on i.id = :new.invoice_id
                 join voucher v on vd.voucher_id = v.id
        where vd.id = :new.voucher_distribution_id
        group by v.id, v.usage_limit, v.from_date, v.thru_date, i.invoiced_at;

        if (v_usage_limit is not null) and (v_usage_limit <= v_voucher_usages(v_voucher_id)) then
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
    end after each row;
end;
/

create trigger t_check_voucher_can_change_usage_limit
    before
        update of usage_limit
    on voucher
    for each row
declare
    v_number_of_redeems int;
    voucher_insufficient exception;
    pragma exception_init ( voucher_insufficient, -4096 );
begin
    select count(*)
    into v_number_of_redeems
    from voucher_redemption vr
             join voucher_distribution vd on vd.id = vr.voucher_distribution_id
    where vd.voucher_id = :new.id;

    if (v_number_of_redeems >= :new.usage_limit) then
        raise voucher_insufficient;
    end if;
exception
    when voucher_insufficient then
        raise_application_error(
                -20300,
                'Cannot set limit from ' || :old.usage_limit || ' to ' || :new.usage_limit || ' ' ||
                'when ' || v_number_of_redeems || ' is in use.'
        );
end;
/
