WITH purchase AS (
    SELECT
        c.c_customer_id,
        CASE
            WHEN SUM(cs.cs_ext_sales_price) > 1000 THEN 'High'
            ELSE 'Low'
        END AS spending_category
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE td.t_hour BETWEEN 8 AND 20
      AND i.i_brand_id = 1
    GROUP BY c.c_customer_id
),
returns AS (
    SELECT
        c.c_customer_id,
        CASE
            WHEN SUM(sr.sr_return_amt) > 500 THEN 'High'
            ELSE 'Low'
        END AS spending_category
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE td.t_hour BETWEEN 8 AND 20
      AND i.i_brand_id = 1
    GROUP BY c.c_customer_id
)
SELECT p.c_customer_id,
       p.spending_category
FROM purchase p
EXCEPT
SELECT r.c_customer_id,
       r.spending_category
FROM returns r
LIMIT 100
