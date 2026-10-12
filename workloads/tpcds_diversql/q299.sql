WITH a AS (
    SELECT cc.cc_call_center_id
    FROM call_center cc
    JOIN catalog_sales cs ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE regexp_like(cc.cc_name, 'Center')
      AND sm.sm_carrier LIKE 'DI%'
      AND d.d_year = 2001
    GROUP BY cc.cc_call_center_id
    HAVING sum(cs.cs_net_paid) > 10000
),
 b AS (
    SELECT cc.cc_call_center_id
    FROM call_center cc
    JOIN catalog_sales cs ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE regexp_like(sm.sm_contract, '^.{5}a')
      AND regexp_like(cc.cc_name, '^North.*')
      AND d.d_month_seq BETWEEN 1200 AND 1212
    GROUP BY cc.cc_call_center_id
    HAVING sum(cs.cs_net_paid) > 8000
),
 c AS (
    SELECT cc.cc_call_center_id
    FROM call_center cc
    JOIN catalog_sales cs ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE regexp_like(cust.c_email_address, 'gmail\\.com$')
      AND d.d_year = 2001
    GROUP BY cc.cc_call_center_id
    HAVING count(DISTINCT cs.cs_order_number) >= 5
),
 d AS (
    SELECT cc.cc_call_center_id
    FROM call_center cc
    JOIN catalog_returns cr ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY cc.cc_call_center_id
    HAVING sum(cr.cr_net_loss) > 5000
)
SELECT cc_id
FROM (
    SELECT cc_call_center_id AS cc_id FROM a
    UNION
    SELECT cc_call_center_id AS cc_id FROM b
) AS union_ab
INTERSECT
SELECT cc_call_center_id AS cc_id FROM c
EXCEPT
SELECT cc_call_center_id AS cc_id FROM d
ORDER BY cc_id
LIMIT 100
