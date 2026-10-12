WITH filtered_customers AS (
    SELECT c.*
    FROM customer c
    WHERE c.c_first_shipto_date_sk BETWEEN 2450000 AND 2453000                -- predicate 1
      AND c.c_birth_year BETWEEN 1960 AND 1990                                 -- predicate 2
      AND c.c_preferred_cust_flag = 'Y'                                         -- predicate 3
      AND c.c_last_review_date IN (SELECT MAX(c2.c_last_review_date) FROM customer c2)   -- predicate 4
      AND c.c_customer_sk IN (
          SELECT cs.cs_bill_customer_sk
          FROM catalog_sales cs
          WHERE cs.cs_ext_sales_price > 5000
      )                                                                        -- predicate 5 (IN subquery)
),
sales_with_item AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_mode_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        i.i_category,
        i.i_brand,
        i.i_brand_id
    FROM catalog_sales cs
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_ext_sales_price BETWEEN 1000 AND 10000                     -- predicate 6
      AND cs.cs_quantity > 1                                                  -- predicate 7
      AND cs.cs_wholesale_cost > 20                                           -- predicate 8
      AND cs.cs_ship_mode_sk IN (
          SELECT sm.sm_ship_mode_sk
          FROM ship_mode sm
          WHERE sm.sm_type = 'AIR'
      )                                                                      -- predicate 9 (IN subquery)
      AND cs.cs_sold_date_sk IN (
          SELECT sr.sr_returned_date_sk
          FROM store_returns sr
          WHERE sr.sr_return_amt > 100
      )                                                                      -- predicate 10 (IN subquery)
),
joined_all AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_bill_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        i.i_category,
        i.i_brand,
        sm.sm_type,
        sr.sr_return_amt,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        ARRAY[cs.cs_quantity, CAST(cs.cs_net_profit AS double)] AS qty_profit_arr
    FROM filtered_customers c
    JOIN sales_with_item cs      ON c.c_customer_sk = cs.cs_bill_customer_sk
    JOIN ship_mode sm            ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store_returns sr        ON sr.sr_item_sk = cs.cs_item_sk
                                 AND sr.sr_customer_sk = c.c_customer_sk
    JOIN item i                  ON cs.cs_item_sk = i.i_item_sk
    WHERE sr.sr_return_quantity > 0                                           -- predicate 11
      AND sr.sr_fee > 5                                                       -- predicate 12
      AND sm.sm_carrier = 'UPS'                                               -- predicate 13
      AND i.i_brand_id IN (
          SELECT DISTINCT i2.i_brand_id
          FROM item i2
          WHERE i2.i_color = 'Red'
      )                                                                      -- predicate 14 (IN subquery)
      AND EXISTS (
          SELECT 1
          FROM store_returns sr2
          WHERE sr2.sr_return_amt > 200
            AND sr2.sr_customer_sk = c.c_customer_sk
      )                                                                      -- predicate 15 (EXISTS)
)
SELECT
    ja.cs_sold_date_sk,
    ja.c_first_name,
    ja.c_last_name,
    ja.i_category,
    ja.i_brand,
    ja.sm_type,
    ja.sr_return_amt,
    ja.cs_ext_sales_price,
    CASE
        WHEN ja.cs_net_profit > 0 THEN 'PROFIT'
        ELSE 'LOSS'
    END AS profit_flag,
    (
        SELECT SUM(sr3.sr_return_amt)
        FROM store_returns sr3
        WHERE sr3.sr_customer_sk = ja.cs_bill_customer_sk
    ) AS total_return_amount_by_customer,                     -- correlated scalar subquery
    ROW_NUMBER() OVER (PARTITION BY ja.i_category ORDER BY ja.cs_ext_sales_price DESC) AS rn_category,
    RANK() OVER (ORDER BY ja.cs_net_profit DESC) AS global_profit_rank,
    CASE WHEN u.idx = 1 THEN u.val END AS quantity,
    CASE WHEN u.idx = 2 THEN u.val END AS profit_amount
FROM joined_all ja
CROSS JOIN UNNEST(ja.qty_profit_arr) WITH ORDINALITY AS u(val, idx)   -- expand array column
WHERE ja.cs_ext_sales_price IS NOT NULL
ORDER BY ja.cs_sold_date_sk DESC,
         rn_category ASC
LIMIT 100
