WITH catalog_part AS (
    SELECT
        i.i_item_id AS item_id,
        d.d_year AS year,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_other_amount,
        CASE WHEN SUM(cs.cs_net_profit) > 1000 THEN 'High' ELSE 'Low' END AS category
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE cs.cs_item_sk IN (SELECT i2.i_item_sk FROM item i2 WHERE i2.i_color = 'Red')
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY i.i_item_id, d.d_year
),
store_part AS (
    SELECT
        i.i_item_id AS item_id,
        COALESCE(d_s.d_year, d_r.d_year) AS year,
        SUM(COALESCE(ss.ss_ext_sales_price, 0)) AS total_sales,
        SUM(COALESCE(sr.sr_return_amt_inc_tax, 0)) AS total_other_amount,
        CASE 
            WHEN SUM(COALESCE(ss.ss_net_paid, 0) - COALESCE(sr.sr_refunded_cash, 0)) > 500 THEN 'Profitable'
            ELSE 'Not Profitable'
        END AS category
    FROM store_sales ss
    FULL OUTER JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
    LEFT JOIN (SELECT * FROM item TABLESAMPLE BERNOULLI (10)) i
        ON i.i_item_sk = COALESCE(ss.ss_item_sk, sr.sr_item_sk)
    LEFT JOIN date_dim d_s
        ON ss.ss_sold_date_sk = d_s.d_date_sk
    LEFT JOIN date_dim d_r
        ON sr.sr_returned_date_sk = d_r.d_date_sk
    WHERE i.i_brand = 'Brand#12'
      AND COALESCE(d_s.d_year, d_r.d_year) BETWEEN 2000 AND 2002
    GROUP BY i.i_item_id, COALESCE(d_s.d_year, d_r.d_year)
)
SELECT *
FROM (
    SELECT item_id, year, total_sales, total_other_amount, category FROM catalog_part
    UNION
    SELECT item_id, year, total_sales, total_other_amount, category FROM store_part
) t
ORDER BY item_id, year DESC
LIMIT 100
