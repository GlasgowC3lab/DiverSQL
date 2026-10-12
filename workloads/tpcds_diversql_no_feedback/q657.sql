WITH sales_union AS (
    SELECT
        cs.cs_order_number AS order_number,
        c.c_customer_id AS customer_id,
        cs.cs_ext_sales_price AS sales_amount,
        t.t_hour AS hour,
        'Catalog' AS sales_channel,
        c.c_customer_sk AS customer_sk
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE cp.cp_department = 'Electronics'
      AND t.t_hour BETWEEN 8 AND 12
      AND cs.cs_quantity > 5

    UNION ALL

    SELECT
        ws.ws_order_number AS order_number,
        c.c_customer_id AS customer_id,
        ws.ws_ext_sales_price AS sales_amount,
        t.t_hour AS hour,
        'Web' AS sales_channel,
        c.c_customer_sk AS customer_sk
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE ws.ws_quantity > 5
      AND t.t_hour BETWEEN 8 AND 12
      AND ws.ws_sales_price > 100
)
SELECT
    order_number,
    customer_id,
    sales_amount,
    hour,
    sales_channel
FROM sales_union su
WHERE EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_customer_sk = su.customer_sk
          AND sr.sr_return_quantity > 0
    )
   OR EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_refunded_customer_sk = su.customer_sk
          AND wr.wr_return_quantity > 0
    )
ORDER BY sales_amount DESC
LIMIT 100
