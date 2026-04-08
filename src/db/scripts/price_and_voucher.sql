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
       P.PRICE_TYPE "PRICE_TYPE_ID",
       DOMAIN_DISPLAY(P.PRICE_TYPE) "PRICE_TYPE_NAME",
       P.DESCRIPTION,
       CASE WHEN CURRENT_TIMESTAMP < P.FROM_DATE THEN 'Not active'
            WHEN CURRENT_TIMESTAMP > P.THRU_DATE THEN 'Expired'
            ELSE CAST(P.THRU_DATE - CURRENT_TIMESTAMP AS INTERVAL DAY(2) TO SECOND(3)) || ' days left'
       END "STATUS",
       TRIM(LEADING ',' FROM DECODE(P.PRODUCT_ID, NULL, '', ', Product: ' || P.PRODUCT_ID)
           || DECODE(P.PRODUCT_FEATURE_ID, NULL, '', ', Product Feature: ' || P.PRODUCT_FEATURE_ID)
           || DECODE(P.QUANTITY_BREAK_ID, NULL, '', ', Quantity: More than ' || QB.FROM_QUANTITY || DECODE(QB.THRU_QUANTITY, NULL, '', ' to ' || QB.THRU_QUANTITY))
           || DECODE(P.ORDER_VALUE_ID, NULL, '', ', Order Value: More than ' || OV.FROM_AMOUNT || DECODE(OV.THRU_AMOUNT, NULL, '', ' to ' || OV.THRU_AMOUNT))
           || DECODE(P.RESTAURANT_ID, NULL, '', ', Restaurant: ' || P.RESTAURANT_ID)
           || DECODE(P.MEMBERSHIP_ID, NULL, '', ', Membership: ' || P.MEMBERSHIP_ID)
           || DECODE(P.VOUCHER_ID, NULL, '', ', Voucher: ' || P.VOUCHER_ID)
           || DECODE(P.VENDOR_ID, NULL, '', ', Vendor: ' || P.VENDOR_ID)) "SCOPE",
       TRIM(LEADING ' ' FROM DECODE(P.PERCENTAGE, NULL, TO_CHAR(P.AMOUNT, '$999,999.99'), TO_CHAR(P.PERCENTAGE * 100, '99.99') || '%')) "AMOUNT",
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
        name voucher.name%type,
        description  restaurant.description%type,
        usage_limit  voucher.usage_limit%type
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
            v_order_value_id order_value.id%type;
        begin
            for i in 1 .. p_pricing.count
            loop
                v_quantity_break_id := null;
                v_order_value_id := null;
                if p_pricing(i).quantity_break is not null
                then
                    select id, from_quantity, thru_quantity
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
                end if;

                if p_pricing(i).order_value is not null
                then
                    select id, from_amount, thru_amount
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
                end if;

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
                values (1,
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
                        v_voucher_id
                        );
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
            new voucher_utils.basic_voucher_def_t(name => '4/4 Celebration', description => 'Celebrate 4/4 with 10% off for members or above RM 100'),
            new voucher_utils.voucher_price_condition_t(
                voucher_utils.voucher_price_condition_t(membership_id => 1),
                voucher_utils.voucher_price_condition_t(membership_id => 2),
                voucher_utils.voucher_price_condition_t(order_value => voucher_utils.order_value_def_t(from_amount => 100))
           )
    );
end;
/


create procedure proc_2() as

begin

end;
/


create procedure report_() as

begin

end;
/


create procedure report_check_voucher_performance() as

begin

end;
/


