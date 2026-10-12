WITH inv_agg AS (
    SELECT
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk
)
SELECT
    i.i_category,
    i.i_class,
    cc.cc_name,
    t.t_hour,
    COUNT(DISTINCT c.c_customer_sk) AS num_customers,
    SUM(COALESCE(ss.ss_net_paid, 0)) AS store_sales_net,
    SUM(COALESCE(ws.ws_net_paid, 0)) AS web_sales_net,
    SUM(COALESCE(cs.cs_net_paid, 0)) AS catalog_sales_net,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS store_returns_loss,
    SUM(COALESCE(cr.cr_net_loss, 0)) AS catalog_returns_loss,
    SUM(COALESCE(inv_agg.total_on_hand, 0)) AS total_inventory_on_hand
FROM call_center cc
JOIN catalog_sales cs
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
JOIN time_dim t
    ON t.t_time_sk = cs.cs_sold_time_sk
JOIN item i
    ON i.i_item_sk = cs.cs_item_sk
JOIN promotion p
    ON p.p_promo_sk = cs.cs_promo_sk
JOIN ship_mode sm
    ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
JOIN customer c
    ON c.c_customer_sk = cs.cs_bill_customer_sk
JOIN household_demographics hd
    ON hd.hd_demo_sk = cs.cs_bill_hdemo_sk
JOIN income_band ib
    ON ib.ib_income_band_sk = hd.hd_income_band_sk
JOIN inv_agg
    ON inv_agg.inv_item_sk = i.i_item_sk
FULL OUTER JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
FULL OUTER JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
LEFT JOIN reason r
    ON r.r_reason_sk = sr.sr_reason_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
WHERE cc.cc_state = 'CA'
  AND i.i_category = 'furniture'
  AND t.t_hour >= 9
  AND t.t_hour <= 17
  AND ib.ib_upper_bound > 50000
GROUP BY i.i_category, i.i_class, cc.cc_name, t.t_hour
ORDER BY store_sales_net DESC
LIMIT 100
