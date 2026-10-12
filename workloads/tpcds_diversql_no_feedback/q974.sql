WITH joined_all AS (
    SELECT
        cs.cs_order_number AS order_key,
        cs.cs_net_paid,
        ws.ws_net_paid,
        cs.cs_quantity,
        ws.ws_net_profit
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN inventory i
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
        AND ws.ws_promo_sk = p.p_promo_sk
        AND ws.ws_sold_time_sk = td.t_time_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE cc.cc_state = 'CA'
      AND p.p_channel_demo = 'N'
      AND w.w_zip = '38048'
      AND td.t_hour = 4
      AND cp.cp_type = 'A'
),
order_intersect AS (
    SELECT cs.cs_order_number AS order_key
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 5
    INTERSECT
    SELECT ws.ws_order_number AS order_key
    FROM web_sales ws
    WHERE ws.ws_quantity > 3
)
SELECT
    ja.order_key,
    SUM(ja.cs_net_paid) AS sum_cs_net_paid,
    SUM(ja.ws_net_paid) AS sum_ws_net_paid,
    COUNT(*) AS txn_count,
    AVG(ja.cs_quantity) AS avg_cs_quantity,
    MAX(ja.ws_net_profit) AS max_ws_net_profit
FROM joined_all ja
WHERE ja.order_key IN (SELECT order_key FROM order_intersect)
GROUP BY ja.order_key
LIMIT 100
