WITH
    bill_cust AS (
        SELECT c.c_customer_sk,
               c.c_customer_id,
               c.c_current_hdemo_sk
        FROM   customer c
    ),
    ship_cust AS (
        SELECT c.c_customer_sk,
               c.c_current_hdemo_sk
        FROM   customer c
    ),
    hd_bill AS (
        SELECT hd.hd_demo_sk,
               hd.hd_income_band_sk,
               hd.hd_buy_potential
        FROM   household_demographics hd
    ),
    hd_ship AS (
        SELECT hd.hd_demo_sk,
               hd.hd_income_band_sk
        FROM   household_demographics hd
    ),
    hd_cur AS (
        SELECT hd.hd_demo_sk,
               hd.hd_income_band_sk
        FROM   household_demographics hd
    ),
    ib AS (
        SELECT ib_income_band_sk,
               ib_lower_bound,
               ib_upper_bound
        FROM   income_band
    ),
    base_sales AS (
        SELECT cs.*, 
               bc.c_customer_id,
               bc.c_current_hdemo_sk AS bc_current_hdemo_sk,
               sc.c_current_hdemo_sk AS sc_current_hdemo_sk
        FROM   catalog_sales cs
        LEFT JOIN bill_cust bc ON cs.cs_bill_customer_sk = bc.c_customer_sk
        LEFT JOIN ship_cust sc ON cs.cs_ship_customer_sk = sc.c_customer_sk
    )
SELECT
    cc.cc_name,
    i.i_brand,
    ib.ib_lower_bound,
    COUNT(DISTINCT cs.cs_order_number)                AS orders,
    SUM(cs.cs_net_paid)                               AS total_net_paid,
    AVG(cs.cs_quantity)                               AS avg_quantity
FROM   base_sales cs
FULL   OUTER JOIN call_center cc               ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN   item i                                 ON cs.cs_item_sk = i.i_item_sk
JOIN   item i_extra                           ON cs.cs_item_sk = i_extra.i_item_sk   -- second alias of item
JOIN   hd_bill hb                             ON cs.cs_bill_hdemo_sk = hb.hd_demo_sk
JOIN   hd_ship hs                             ON cs.cs_ship_hdemo_sk = hs.hd_demo_sk
JOIN   hd_cur hc                              ON cs.bc_current_hdemo_sk = hc.hd_demo_sk
JOIN   ib                                     ON hb.hd_income_band_sk = ib.ib_income_band_sk
CROSS  JOIN (SELECT DATE '2023-01-01' AS ref_date) d
WHERE  NOT EXISTS (
           SELECT 1
           FROM   item i2
           WHERE  i2.i_item_sk = cs.cs_item_sk
           AND    i2.i_color = 'Red'
       )
GROUP  BY cc.cc_name, i.i_brand, ib.ib_lower_bound
ORDER  BY total_net_paid DESC, orders DESC
LIMIT  100
