/*
Goal: Identify high‑value web returns, joining returns with the related item, customer, and web page data. Apply multiple realistic filters, keep only returns that have no other return for the same order with a larger amount (anti‑join), restrict to items that satisfy two intersecting key‑set conditions, rank returns per customer, and return the top 100 rows.
*/
WITH intersect_keys AS (
    SELECT wr.wr_item_sk
    FROM web_returns wr
    WHERE wr.wr_return_amt > 100
    INTERSECT
    SELECT i.i_item_sk
    FROM item i
    WHERE i.i_current_price > 50
),
filtered_returns AS (
    SELECT
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wr.wr_return_ship_cost,
        wr.wr_order_number,
        wr.wr_item_sk,
        wr.wr_refunded_customer_sk,
        wr.wr_web_page_sk,
        i.i_product_name,
        i.i_brand_id,
        c.c_customer_id,
        c.c_birth_year,
        c.c_first_sales_date_sk,
        wp.wp_url
    FROM web_returns wr
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wr.wr_web_page_sk IN (1436, 2269)
      AND wr.wr_return_ship_cost > 20
      AND wr.wr_return_quantity BETWEEN 1 AND 5
      AND i.i_brand_id IN (5003002, 1004002)
      AND c.c_birth_year = 1975
      AND c.c_first_sales_date_sk BETWEEN 2450890 AND 2452167
      AND wr.wr_item_sk IN (SELECT wr_item_sk FROM intersect_keys)
      AND NOT EXISTS (
          SELECT 1
          FROM web_returns wr2
          WHERE wr2.wr_order_number = wr.wr_order_number
            AND wr2.wr_item_sk = wr.wr_item_sk
            AND wr2.wr_return_amt > wr.wr_return_amt
      )
)
SELECT
    fr.c_customer_id,
    fr.i_product_name,
    fr.wr_return_amt,
    fr.wr_return_quantity,
    fr.wp_url,
    ROW_NUMBER() OVER (PARTITION BY fr.c_customer_id ORDER BY fr.wr_return_amt DESC) AS rn
FROM filtered_returns fr
ORDER BY rn, fr.wr_return_amt DESC
LIMIT 100
