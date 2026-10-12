WITH cs_agg AS (
    SELECT
        cs.cs_order_number AS order_number,
        SUM(cs.cs_net_paid) AS cs_net_paid
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_category = 'Electronics'
      AND p.p_discount_active = 'Y'
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY cs.cs_order_number
),
ws_agg AS (
    SELECT
        ws.ws_order_number AS order_number,
        SUM(ws.ws_net_paid) AS ws_net_paid
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
    JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
    JOIN time_dim t2 ON ws.ws_sold_time_sk = t2.t_time_sk
    JOIN customer_demographics cd2 ON ws.ws_bill_cdemo_sk = cd2.cd_demo_sk
    JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE i2.i_class = 'accessories'
      AND r.r_reason_desc LIKE '%color%'
      AND t2.t_hour BETWEEN 12 AND 20
    GROUP BY ws.ws_order_number
),
common_orders AS (
    SELECT order_number FROM cs_agg
    INTERSECT
    SELECT order_number FROM ws_agg
)
SELECT
    co.order_number,
    cs.cs_net_paid,
    ws.ws_net_paid,
    (cs.cs_net_paid + ws.ws_net_paid) / 2.0 AS avg_net_paid
FROM common_orders co
JOIN cs_agg cs ON co.order_number = cs.order_number
JOIN ws_agg ws ON co.order_number = ws.order_number
ORDER BY avg_net_paid DESC
LIMIT 100
