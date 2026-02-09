CREATE TABLE voucher_distribution
(
    id                  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    voucher_id          INT REFERENCES voucher (id) NOT NULL,
    member_id           INT REFERENCES member (id)  NOT NULL,
    redeemed_invoice_id INT REFERENCES invoice (id),
    UNIQUE (voucher_id, member_id)
);

-- TODO: check voucher is still usable based on the usage_limit