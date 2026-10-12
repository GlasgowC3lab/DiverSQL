WITH sampled_wp AS (
    SELECT *
    FROM web_page TABLESAMPLE BERNOULLI (10)
)
SELECT
    d_sold.d_year,
    i_sales.i_brand,
    sm.sm_type,
    wsite.web_name,
    r.r_reason_desc,
    SUM(ws.ws_net_paid) AS total_web_sales,
    SUM(ss.ss_net_paid) AS total_store_sales,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN item i_sales
    ON ws.ws_item_sk = i_sales.i_item_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN sampled_wp wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
   AND ws.ws_item_sk = wr.wr_item_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
   AND ss.ss_item_sk = i_sales.i_item_sk
WHERE EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_customer_sk = ws.ws_bill_customer_sk
          AND ss2.ss_sold_date_sk = d_sold.d_date_sk
    )
  AND ws.ws_item_sk IN (
        SELECT ws_item_sk FROM web_sales
        INTERSECT
        SELECT i_item_sk FROM item
    )
  AND ws.ws_coupon_amt > (
        SELECT MAX(sm_ship_mode_sk) FROM ship_mode WHERE sm_type = 'REGULAR'
    )
  AND d_sold.d_year = (SELECT MAX(d_year) FROM date_dim WHERE d_year = 1999)
GROUP BY
    d_sold.d_year,
    i_sales.i_brand,
    sm.sm_type,
    wsite.web_name,
    r.r_reason_desc
ORDER BY total_web_sales DESC
LIMIT 100
