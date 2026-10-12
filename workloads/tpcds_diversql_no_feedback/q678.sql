WITH intersect_orders AS (
        SELECT cs.cs_order_number AS order_number
        FROM catalog_sales cs
        WHERE cs.cs_quantity > 5
          AND cs.cs_ext_sales_price > 200
        INTERSECT
        SELECT ws.ws_order_number
        FROM web_sales ws
        WHERE ws.ws_quantity > 5
          AND ws.ws_ext_sales_price > 200
    ),
    base AS (
        SELECT
            cs.cs_order_number,
            cs.cs_quantity,
            cs.cs_ext_sales_price,
            cs.cs_ext_discount_amt,
            cs.cs_net_profit,
            cs.cs_promo_sk,
            cs.cs_call_center_sk,
            cs.cs_catalog_page_sk,
            cs.cs_sold_time_sk,
            ws.ws_quantity        AS ws_quantity,
            ws.ws_ext_sales_price AS ws_ext_sales_price,
            ws.ws_net_profit      AS ws_net_profit,
            ws.ws_promo_sk,
            ws.ws_web_page_sk,
            ws.ws_web_site_sk,
            ss.ss_ext_sales_price AS ss_ext_sales_price,
            ss.ss_net_profit      AS ss_net_profit,
            wr.wr_return_amt,
            wr.wr_net_loss,
            p.p_channel_catalog,
            p.p_discount_active,
            cc.cc_name,
            cp.cp_department,
            t.t_hour,
            c.c_first_name,
            c.c_last_name,
            ca.ca_city,
            cd.cd_gender,
            hd.hd_income_band_sk
        FROM catalog_sales cs
        JOIN promotion p               ON cs.cs_promo_sk      = p.p_promo_sk
        JOIN call_center cc            ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp           ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN time_dim t                ON cs.cs_sold_time_sk   = t.t_time_sk
        JOIN customer c                ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_address ca       ON cs.cs_bill_addr_sk   = ca.ca_address_sk
        JOIN customer_demographics cd  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN web_sales ws              ON cs.cs_order_number   = ws.ws_order_number
        JOIN web_page wp               ON ws.ws_web_page_sk    = wp.wp_web_page_sk
        JOIN web_site we               ON ws.ws_web_site_sk    = we.web_site_sk
        JOIN store_sales ss            ON ss.ss_sold_time_sk   = t.t_time_sk
                                      AND ss.ss_customer_sk   = c.c_customer_sk
        JOIN web_returns wr           ON wr.wr_order_number   = ws.ws_order_number
                                      AND wr.wr_returned_time_sk = t.t_time_sk
        WHERE cs.cs_ext_sales_price > 200
          AND p.p_channel_catalog = 'N'
          AND t.t_hour BETWEEN 9 AND 17
    )
SELECT
    b.cs_order_number,
    b.cc_name,
    b.cp_department,
    b.p_channel_catalog,
    SUM(b.cs_ext_sales_price)   AS total_catalog_sales,
    AVG(b.ws_ext_sales_price)   AS avg_web_sales,
    SUM(b.ss_ext_sales_price)   AS total_store_sales,
    COUNT(DISTINCT b.c_first_name) AS distinct_customers,
    MIN(b.cs_ext_discount_amt)  AS min_discount,
    MAX(b.cs_net_profit)        AS max_catalog_net_profit,
    MAX(b.ws_net_profit)        AS max_web_net_profit,
    MAX(b.ss_net_profit)        AS max_store_net_profit,
    SUM(b.wr_return_amt)        AS total_return_amount,
    SUM(b.wr_net_loss)          AS total_return_loss,
    metric
FROM base b
JOIN intersect_orders i ON b.cs_order_number = i.order_number
CROSS JOIN LATERAL (
        SELECT ARRAY[CAST(b.cs_quantity AS double), CAST(b.ws_quantity AS double)] AS qty_arr
) q
CROSS JOIN UNNEST(q.qty_arr) AS u(metric)
GROUP BY
    b.cs_order_number,
    b.cc_name,
    b.cp_department,
    b.p_channel_catalog,
    metric
ORDER BY total_catalog_sales DESC
LIMIT 100
