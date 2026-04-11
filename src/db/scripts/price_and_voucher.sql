CREATE VIEW V_VOUCHER_STATISTICS AS
SELECT V.ID,
       V.NAME,
       V.DESCRIPTION,
       V.FROM_DATE,
       V.THRU_DATE,
       V.USAGE_LIMIT,
       COUNT(VD.ID)                                                            "DISTRIBUTED",
       COUNT(VR.INVOICE_ID)                                                    "REDEEMED",
       DECODE(V.USAGE_LIMIT, NULL, NULL, V.USAGE_LIMIT - COUNT(VR.INVOICE_ID)) "REMAINING"
FROM VOUCHER V
         LEFT JOIN VOUCHER_DISTRIBUTION VD ON V.ID = VD.VOUCHER_ID
         LEFT JOIN VOUCHER_REDEMPTION VR ON VD.ID = VR.VOUCHER_DISTRIBUTION_ID
GROUP BY V.ID, V.NAME, V.DESCRIPTION, V.FROM_DATE, V.THRU_DATE, V.USAGE_LIMIT;

SELECT *
FROM V_VOUCHER_STATISTICS
WHERE TIMESTAMP '2026-03-01 0:0:0' BETWEEN FROM_DATE AND THRU_DATE;


CREATE OR REPLACE VIEW V_PRICE_PREVIEW AS
SELECT P.ID,
       P.CODE,
       P.FROM_DATE,
       P.THRU_DATE,
       P.PRICE_TYPE                                                               "PRICE_TYPE_ID",
       DOMAIN_DISPLAY(P.PRICE_TYPE)                                               "PRICE_TYPE_NAME",
       P.DESCRIPTION,
       CASE
           WHEN CURRENT_TIMESTAMP < P.FROM_DATE THEN 'Not active'
           WHEN CURRENT_TIMESTAMP > P.THRU_DATE THEN 'Expired'
           ELSE CAST(P.THRU_DATE - CURRENT_TIMESTAMP AS INTERVAL DAY(2) TO SECOND(3)) || ' days left'
           END                                                                    "STATUS",
       TRIM(LEADING ',' FROM DECODE(P.PRODUCT_ID, NULL, '', ', Product: ' || P.PRODUCT_ID)
           || DECODE(P.PRODUCT_FEATURE_ID, NULL, '', ', Product Feature: ' || P.PRODUCT_FEATURE_ID)
           || DECODE(P.QUANTITY_BREAK_ID, NULL, '', ', Quantity: More than ' || QB.FROM_QUANTITY ||
                                                    DECODE(QB.THRU_QUANTITY, NULL, '', ' to ' || QB.THRU_QUANTITY))
           || DECODE(P.ORDER_VALUE_ID, NULL, '', ', Order Value: More than ' || OV.FROM_AMOUNT ||
                                                 DECODE(OV.THRU_AMOUNT, NULL, '', ' to ' || OV.THRU_AMOUNT))
           || DECODE(P.RESTAURANT_ID, NULL, '', ', Restaurant: ' || P.RESTAURANT_ID)
           || DECODE(P.MEMBERSHIP_ID, NULL, '', ', Membership: ' || P.MEMBERSHIP_ID)
           || DECODE(P.VOUCHER_ID, NULL, '', ', Voucher: ' || P.VOUCHER_ID)
           || DECODE(P.VENDOR_ID, NULL, '', ', Vendor: ' || P.VENDOR_ID))         "SCOPE",
       TRIM(LEADING ' ' FROM DECODE(P.PERCENTAGE, NULL, TO_CHAR(P.AMOUNT, '$999,999.99'),
                                    TO_CHAR(P.PERCENTAGE * 100, '99.99') || '%')) "AMOUNT",
       P.CREATED_BY_ID
FROM PRICE_COMPONENT P
         LEFT JOIN QUANTITY_BREAK QB ON P.QUANTITY_BREAK_ID = QB.ID
         LEFT JOIN ORDER_VALUE OV ON P.ORDER_VALUE_ID = OV.ID;

SELECT *
FROM V_PRICE_PREVIEW
WHERE PRICE_TYPE_ID = PRICE_TYPE.DISCOUNT;


create package voucher_utils as
    type quantity_break_def_t is record
                                 (
                                     from_quantity quantity_break.from_quantity%type,
                                     thru_quantity quantity_break.thru_quantity%type
                                 );
    type order_value_def_t is record
                              (
                                  from_amount order_value.from_amount%type,
                                  thru_amount order_value.thru_amount%type
                              );
    type basic_voucher_def_t is record
                                (
                                    name        voucher.name%type,
                                    description restaurant.description%type,
                                    usage_limit voucher.usage_limit%type
                                );
    type voucher_price_condition_t is record
                                      (
                                          product_id          price_component.id%type null,
                                          product_feature_id  price_component.id%type null,
                                          product_category_id price_component.id%type null,
                                          restaurant_id       price_component.restaurant_id%type null,
                                          quantity_break      quantity_break_def_t null,
                                          order_value         order_value_def_t null,
                                          membership_id       price_component.membership_id%type null,
                                          vendor_id           price_component.vendor_id%type null
                                      );
    type price_conditions_t is table of voucher_price_condition_t;

    procedure create_basic_voucher(
        p_discount decimal,
        p_from_date in price_component.from_date%type,
        p_thru_date in price_component.thru_date%type,
        p_created_by_id in price_component.created_by_id%type,
        p_voucher in basic_voucher_def_t,
        p_pricing in price_conditions_t
    );
end voucher_utils;
/

create package body voucher_utils as
    procedure create_basic_voucher(
        p_discount decimal,
        p_from_date in price_component.from_date%type,
        p_thru_date in price_component.thru_date%type,
        p_created_by_id in price_component.created_by_id%type,
        p_voucher in basic_voucher_def_t,
        p_pricing in price_conditions_t
    ) as
        v_voucher_id voucher.id%type;
    begin
        insert into voucher (name, description, usage_limit, from_date, thru_date, created_by_id)
        values (p_voucher.name,
                p_voucher.description,
                p_voucher.usage_limit,
                p_from_date,
                p_thru_date,
                p_created_by_id)
        returning id into v_voucher_id;

        declare
            v_quantity_break_id quantity_break.id%type;
            v_order_value_id    order_value.id%type;
        begin
            for i in 1 .. p_pricing.count
                loop
                    v_quantity_break_id := null;
                    v_order_value_id := null;
                    begin
                        select id
                        into v_quantity_break_id
                        from quantity_break
                        where from_quantity = p_pricing(i).quantity_break.from_quantity
                          and thru_quantity = p_pricing(i).quantity_break.thru_quantity;

                        if v_quantity_break_id is null
                        then
                            insert into quantity_break (from_quantity, thru_quantity)
                            values (p_pricing(i).quantity_break.from_quantity,
                                    p_pricing(i).quantity_break.thru_quantity)
                            returning id into v_quantity_break_id;
                        end if;
                    exception
                        when NO_DATA_FOUND then null;
                    end;

                    begin
                        select id
                        into v_order_value_id
                        from order_value
                        where from_amount = p_pricing(i).order_value.from_amount
                          and thru_amount = p_pricing(i).order_value.thru_amount;

                        if v_quantity_break_id is null
                        then
                            insert into order_value (from_amount, thru_amount)
                            values (p_pricing(i).order_value.from_amount,
                                    p_pricing(i).order_value.thru_amount)
                            returning id into v_order_value_id;
                        end if;
                    exception
                        when NO_DATA_FOUND then null;
                    end;

                    insert into price_component (price_type, from_date, thru_date, description, created_by_id,
                                                 amount, percentage,
                                                 product_id,
                                                 product_feature_id,
                                                 product_category_id,
                                                 quantity_break_id,
                                                 order_value_id,
                                                 restaurant_id,
                                                 membership_id,
                                                 vendor_id,
                                                 voucher_id)
                    values (2,
                            p_from_date,
                            p_thru_date,
                            p_voucher.description,
                            p_created_by_id,
                            case when p_discount >= 1 then p_discount end,
                            case when p_discount < 1 then p_discount end,
                            p_pricing(i).product_id,
                            p_pricing(i).product_feature_id,
                            p_pricing(i).product_category_id,
                            v_quantity_break_id,
                            v_order_value_id,
                            p_pricing(i).restaurant_id,
                            p_pricing(i).membership_id,
                            p_pricing(i).vendor_id,
                            v_voucher_id);
                end loop;
        end;
    end;
end voucher_utils;
/

begin
    voucher_utils.create_basic_voucher(
            0.10,
            TIMESTAMP '2026-04-04 0:0:0',
            TIMESTAMP '2026-04-10 0:0:0',
            1,
            new voucher_utils.basic_voucher_def_t(name => '4/4 Celebration',
            description => 'Celebrate 4/4 with 10% off for members or above RM 100'),
            new voucher_utils.price_conditions_t(
            voucher_utils.voucher_price_condition_t(membership_id => 1),
            voucher_utils.voucher_price_condition_t(membership_id => 2),
            voucher_utils.voucher_price_condition_t(order_value => voucher_utils.order_value_def_t(from_amount => 100))
                                                )
    );
end;
/


create package price_utils as
    procedure proc_deduplicate_quantity_breaks_and_order_values;
end price_utils;
/

create package body price_utils as
    procedure proc_deduplicate_quantity_breaks_and_order_values as
        cursor duplicate_quantity_break_cur is
            select qb.id as id, keep.id as keep_id
            from quantity_break qb
                     join (select min(id) as id, from_quantity, thru_quantity
                           from quantity_break
                           group by from_quantity, thru_quantity) keep
                          on keep.id != qb.id and
                             keep.from_quantity = qb.from_quantity
                              and decode(keep.thru_quantity, qb.thru_quantity, 1, 0);
        cursor duplicate_order_value_cur is
            select qb.id as id, keep.id as keep_id
            from order_value qb
                     join (select min(id) as id, from_amount, thru_amount
                           from order_value
                           group by from_amount, thru_amount) keep
                          on keep.id != qb.id and keep.from_amount = qb.from_amount
                              and decode(keep.thru_amount, qb.thru_amount, 1, 0);
        type duplicate_row_t is record (id int, keep_id int);
        duplicate_row duplicate_row_t;
    begin
        open duplicate_quantity_break_cur;

        loop
            fetch duplicate_quantity_break_cur into duplicate_row;
            exit when duplicate_quantity_break_cur%notfound;

            update price_component
            set quantity_break_id = duplicate_row.keep_id
            where quantity_break_id = duplicate_row.id;

            delete quantity_break
            where id = duplicate_row.id;
        end loop;

        close duplicate_quantity_break_cur;

        open duplicate_order_value_cur;

        loop
            fetch duplicate_order_value_cur into duplicate_row;
            exit when duplicate_order_value_cur%notfound;

            update price_component
            set order_value_id = duplicate_row.keep_id
            where order_value_id = duplicate_row.id;

            delete order_value
            where id = duplicate_row.id;
        end loop;

        close duplicate_order_value_cur;
    end;
end price_utils;
/

begin
    price_utils.proc_deduplicate_quantity_breaks_and_order_values();
end;
/

create or replace procedure report_product_and_features_price_changes(p_product_id in product.id%type) as
    cursor product_price_cur is
        SELECT *
        FROM PRICE_COMPONENT PC
        WHERE PC.PRICE_TYPE = 1
          AND PC.PRODUCT_ID = p_product_id
        ORDER BY PC.FROM_DATE;
    product_price_row         product_price_cur%rowtype;
    cursor product_attributes_cur is
        SELECT PFG.ID, PFG.NAME, PFG.MIN, PFG.MAX
        FROM PRODUCT_ATTRIBUTE PA
                 JOIN PRODUCT_FEATURE_GROUP PFG ON PA.PRODUCT_FEATURE_GROUP_ID = PFG.ID
        WHERE PA.PRODUCT_ID = p_product_id;
    product_attributes_row    product_attributes_cur%rowtype;
    cursor product_features_cur(p_product_feature_group_id PRODUCT_FEATURE_GROUP.ID%type) is
        SELECT PFGF.PRODUCT_FEATURE_ID
        FROM PRODUCT_FEATURE_GROUP PFG
                 JOIN PRODUCT_FEATURE_GROUP_FIELD PFGF ON PFG.ID = PFGF.PRODUCT_FEATURE_GROUP_ID
        WHERE PFG.ID = p_product_feature_group_id;
    product_features_row      product_features_cur%rowtype;
    cursor product_feature_price_cur(p_product_feature_id price_component.PRODUCT_FEATURE_ID%type) is
        SELECT *
        FROM PRICE_COMPONENT PC
        WHERE PC.PRICE_TYPE = 1
          AND PC.PRODUCT_FEATURE_ID = p_product_feature_id
          AND (PC.PRODUCT_ID IS NULL OR PC.PRODUCT_ID = 1)
        ORDER BY PC.FROM_DATE;
    product_feature_price_row product_feature_price_cur%rowtype;
    v_name                    VARCHAR(100);
    v_last_amount             price_component.AMOUNT%type;
    product_not_found exception;
begin
    begin
        select name into v_name from product where id = p_product_id;
    exception
        when NO_DATA_FOUND then raise product_not_found;
    end;

    DBMS_OUTPUT.PUT_LINE(REPEAT('=', 100));
    DBMS_OUTPUT.PUT_LINE(CPAD(v_name || ' Price History', 100, ' '));
    DBMS_OUTPUT.PUT_LINE(REPEAT('=', 100));

    open product_price_cur;
    v_last_amount := 0;
    loop
        fetch product_price_cur into product_price_row;
        exit when product_price_cur%notfound;

        DBMS_OUTPUT.PUT_LINE(
                '  ' || TO_CHAR(product_price_row.FROM_DATE, 'DD-Mon-YYYY') || ' - '
                    || CASE
                           WHEN product_price_row.THRU_DATE IS NULL
                               THEN RPAD('Now', 11, ' ')
                           ELSE TO_CHAR(product_price_row.THRU_DATE, 'DD-Mon-YYYY') END
                    || '  : RM ' || TRIM(LEADING ' ' FROM TO_CHAR(product_price_row.AMOUNT, '9,999.99'))
                    || '( ' || case SIGN(product_price_row.AMOUNT - v_last_amount) when 1 then '+' end
                    || TRIM(LEADING ' ' FROM TO_CHAR(product_price_row.AMOUNT - v_last_amount, '9,999.99')) || ' )');
        v_last_amount := product_price_row.AMOUNT;
    end loop;
    close product_price_cur;

    open product_attributes_cur;
    loop
        fetch product_attributes_cur into product_attributes_row;
        exit when product_attributes_cur%notfound;

        select name into v_name from PRODUCT_FEATURE_GROUP where id = product_attributes_row.ID;

        DBMS_OUTPUT.PUT_LINE(CHR(10));
        DBMS_OUTPUT.PUT_LINE('  - ' || v_name);

        open product_features_cur(product_attributes_row.ID);
        loop
            fetch product_features_cur into product_features_row;
            exit when product_features_cur%notfound;

            select name into v_name from product_feature where id = product_features_row.PRODUCT_FEATURE_ID;

            DBMS_OUTPUT.PUT_LINE('    - ' || v_name);

            open product_feature_price_cur(product_features_row.PRODUCT_FEATURE_ID);
            v_last_amount := 0;
            loop
                fetch product_feature_price_cur into product_feature_price_row;
                exit when product_feature_price_cur%notfound;


                DBMS_OUTPUT.PUT_LINE(
                        '       ' || TO_CHAR(product_feature_price_row.FROM_DATE, 'DD-Mon-YYYY') || ' - '
                            || CASE
                                   WHEN product_feature_price_row.THRU_DATE IS NULL
                                       THEN RPAD('Now', 11, ' ')
                                   ELSE TO_CHAR(product_feature_price_row.THRU_DATE, 'DD-Mon-YYYY') END
                            || ' : RM ' || TRIM(LEADING ' ' FROM TO_CHAR(product_feature_price_row.AMOUNT, '9,999.99'))
                            || '( ' || case SIGN(product_feature_price_row.AMOUNT - v_last_amount) when 1 then '+' end
                            ||
                        TRIM(LEADING ' ' FROM TO_CHAR(product_feature_price_row.AMOUNT - v_last_amount, '9,999.99')) ||
                        ' )');
                v_last_amount := product_feature_price_row.AMOUNT;
            end loop;
            close product_feature_price_cur;
        end loop;
        close product_features_cur;
    end loop;
    close product_attributes_cur;

    DBMS_OUTPUT.PUT_LINE(CHR(10));
    DBMS_OUTPUT.PUT_LINE(REPEAT('=', 100));
    DBMS_OUTPUT.PUT_LINE(CPAD('-- End of Price History --', 100, ' '));
    DBMS_OUTPUT.PUT_LINE(REPEAT('=', 100));
exception
    when product_not_found then raise_application_error(-20300, 'Product ' || p_product_id || ' is not found');
end;
/

begin
    report_product_and_features_price_changes(1);
end;
/

create procedure report_top_performing_voucher(p_year in int) as
    cursor yearly_voucher_cur(year int) is
        SELECT EXTRACT(MONTH FROM I.INVOICED_AT) AS MONTH, VS.DISTRIBUTED, COUNT(I.ID) AS REDEEMED
        FROM VOUCHER V
                 LEFT JOIN VOUCHER_DISTRIBUTION VD ON V.ID = VD.VOUCHER_ID
                 LEFT JOIN VOUCHER_REDEMPTION VR ON VD.ID = VR.VOUCHER_DISTRIBUTION_ID
                 LEFT JOIN INVOICE I ON VR.INVOICE_ID = I.ID
                 JOIN (SELECT EXTRACT(MONTH FROM FROM_DATE) AS MONTH, SUM(DISTRIBUTED) AS DISTRIBUTED
                       FROM V_VOUCHER_STATISTICS
                       GROUP BY EXTRACT(MONTH FROM FROM_DATE)) VS ON EXTRACT(MONTH FROM I.INVOICED_AT) = VS.MONTH
        WHERE EXTRACT(YEAR FROM I.INVOICED_AT) = year
        GROUP BY EXTRACT(MONTH FROM I.INVOICED_AT), VS.DISTRIBUTED
        ORDER BY MONTH;
    yearly_voucher_row  yearly_voucher_cur%rowtype;
    cursor monthly_voucher_cur(year int, month int) is
        SELECT V.ID,
               V.DESCRIPTION,
               V.FROM_DATE,
               V.THRU_DATE,
               VS.DISTRIBUTED,
               COUNT(I.ID)                                                        AS REDEEMED,
               DECODE(VS.DISTRIBUTED, 0, 100, COUNT(I.ID) / VS.DISTRIBUTED * 100) AS USAGE_RATE
        from VOUCHER V
                 LEFT JOIN VOUCHER_DISTRIBUTION VD ON V.ID = VD.VOUCHER_ID
                 LEFT JOIN VOUCHER_REDEMPTION VR ON VD.ID = VR.VOUCHER_DISTRIBUTION_ID
                 LEFT JOIN INVOICE I ON VR.INVOICE_ID = I.ID
            AND EXTRACT(MONTH FROM I.INVOICED_AT) = month
            AND EXTRACT(YEAR FROM I.INVOICED_AT) = year
                 JOIN (SELECT ID, SUM(DISTRIBUTED) AS DISTRIBUTED
                       FROM V_VOUCHER_STATISTICS
                       GROUP BY ID) VS ON V.ID = VS.ID
        GROUP BY V.ID, V.DESCRIPTION, V.FROM_DATE, V.THRU_DATE, VS.DISTRIBUTED
        ORDER BY REDEEMED IS NOT NULL DESC, REDEEMED DESC;
    monthly_voucher_row monthly_voucher_cur%rowtype;
    type summary_t is record (total int, distributed int, redeemed int);
    v_summary           summary_t;
begin
    DBMS_OUTPUT.PUT_LINE(REPEAT('=', 100));
    DBMS_OUTPUT.PUT_LINE(CPAD(p_year || ' Year Top Voucher Performance', 100, ' '));
    DBMS_OUTPUT.PUT_LINE(REPEAT('=', 100));

    open yearly_voucher_cur(p_year);

    loop
        -- noinspection SqlIllegalCursorState
        fetch yearly_voucher_cur into yearly_voucher_row;
        exit when yearly_voucher_cur%notfound;

        DBMS_OUTPUT.PUT_LINE(CHR(10) || '[ Month: ' || TO_CHAR(TO_DATE(yearly_voucher_row.MONTH, 'MM'), 'MONTH') ||
                             ' ]');
        DBMS_OUTPUT.PUT_LINE(REPEAT('-', 91));
        DBMS_OUTPUT.PUT_LINE(
                ' ' || RPAD('ID', 5, ' ') || '  '
                    || RPAD('Description', 40, ' ') || '  '
                    || CPAD('Distributed', 12, ' ') || '  '
                    || CPAD('Redeemed', 12, ' ') || '  '
                    || CPAD('Usage rate %', 12, ' ')
        );
        DBMS_OUTPUT.PUT_LINE(REPEAT('-', 91));

        open monthly_voucher_cur(p_year, yearly_voucher_row.MONTH);

        for i in 1..6
            loop
                fetch monthly_voucher_cur into monthly_voucher_row;
                exit when monthly_voucher_cur%notfound;

                if i = 6
                then
                    DBMS_OUTPUT.PUT_LINE(' ...');
                    continue;
                end if;

                DBMS_OUTPUT.PUT_LINE(
                        ' ' || RPAD(monthly_voucher_row.ID, 5, ' ') || '  '
                            || RPAD(monthly_voucher_row.DESCRIPTION, 40, ' ') || '  '
                            || CPAD(monthly_voucher_row.DISTRIBUTED, 12, ' ') || '  '
                            || CPAD(monthly_voucher_row.REDEEMED, 12, ' ') || '  '
                            || CPAD(TO_CHAR(monthly_voucher_row.USAGE_RATE, '999.99') || '%', 12, ' ')
                );
            end loop;
        close monthly_voucher_cur;

        DBMS_OUTPUT.PUT_LINE(
                RPAD(' This month', 50, ' ')
                    || CPAD(yearly_voucher_row.DISTRIBUTED, 12, ' ') || '  '
                    || CPAD(yearly_voucher_row.REDEEMED, 12, ' ') || '  '
                    ||
                CPAD(TO_CHAR(yearly_voucher_row.REDEEMED / yearly_voucher_row.DISTRIBUTED * 100, '999.99') || '%', 12,
                     ' ')
        );
    end loop;

    SELECT VS.TOTAL, VS.DISTRIBUTED, COUNT(I.ID) "REDEMPTION"
    INTO v_summary
    FROM VOUCHER V
             LEFT JOIN VOUCHER_DISTRIBUTION VD ON V.ID = VD.VOUCHER_ID
             LEFT JOIN VOUCHER_REDEMPTION VR ON VD.ID = VR.VOUCHER_DISTRIBUTION_ID
             LEFT JOIN INVOICE I ON VR.INVOICE_ID = I.ID AND EXTRACT(YEAR FROM I.INVOICED_AT) = p_year
             CROSS JOIN (SELECT COUNT(*) AS TOTAL, SUM(DISTRIBUTED) AS "DISTRIBUTED"
                         FROM V_VOUCHER_STATISTICS
                         WHERE EXTRACT(YEAR FROM FROM_DATE) = p_year) VS
    GROUP BY VS.TOTAL, VS.DISTRIBUTED;

    DBMS_OUTPUT.PUT_LINE(CHR(10));

    DBMS_OUTPUT.PUT_LINE(CPAD('Summary', 40, ' '));
    DBMS_OUTPUT.PUT_LINE(REPEAT('-', 40));
    DBMS_OUTPUT.PUT_LINE(RPAD('New Vouchers', 20, ' ') || ': ' || v_summary.total);
    DBMS_OUTPUT.PUT_LINE(RPAD('Total Distributed', 20, ' ') || ': ' || v_summary.distributed);
    DBMS_OUTPUT.PUT_LINE(RPAD('Total Redeemed', 20, ' ') || ': ' || v_summary.redeemed);

    DBMS_OUTPUT.PUT_LINE(CHR(10));

    DBMS_OUTPUT.PUT_LINE(REPEAT('=', 100));
    DBMS_OUTPUT.PUT_LINE(CPAD(' -- END OF TOP VOUCHER REPORT --', 100, ' '));
    DBMS_OUTPUT.PUT_LINE(REPEAT('=', 100));

    close yearly_voucher_cur;
end;
/

begin
    report_top_performing_voucher(2025);
end;
/
