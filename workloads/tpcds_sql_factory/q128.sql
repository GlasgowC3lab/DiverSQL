SELECT
    cs.cs_order_number,
    cs.cs_net_profit,
    cs.cs_net_paid,
    bill_c.c_customer_id AS bill_customer_id,
    ship_c.c_customer_id AS ship_customer_id,
    bill_cd.cd_gender AS bill_gender,
    ship_cd.cd_gender AS ship_gender,
    bill_cd.cd_credit_rating AS bill_credit_rating,
    ship_cd.cd_credit_rating AS ship_credit_rating,
    CASE
        WHEN bill_cd.cd_gender <> ship_cd.cd_gender THEN 1 ELSE 0
    END AS gender_mismatch,
    CASE
        WHEN bill_cd.cd_credit_rating <> ship_cd.cd_credit_rating THEN 1 ELSE 0
    END AS credit_rating_mismatch,
    CASE
        WHEN bill_c.c_current_addr_sk <> ship_c.c_current_addr_sk THEN 1 ELSE 0
    END AS address_mismatch,
    ROW_NUMBER() OVER (ORDER BY cs.cs_net_profit DESC) AS profit_rank
FROM catalog_sales cs
JOIN customer bill_c ON cs.cs_bill_customer_sk = bill_c.c_customer_sk
JOIN customer ship_c ON cs.cs_ship_customer_sk = ship_c.c_customer_sk
JOIN customer_demographics bill_cd ON cs.cs_bill_cdemo_sk = bill_cd.cd_demo_sk
JOIN customer_demographics ship_cd ON cs.cs_ship_cdemo_sk = ship_cd.cd_demo_sk
WHERE
    (bill_cd.cd_gender <> ship_cd.cd_gender
     OR bill_cd.cd_credit_rating <> ship_cd.cd_credit_rating
     OR bill_c.c_current_addr_sk <> ship_c.c_current_addr_sk)
    AND cs.cs_net_profit > 500
ORDER BY cs.cs_net_profit DESC
LIMIT 20
