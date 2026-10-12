WITH inv_agg AS (
    SELECT inv_item_sk AS i_item_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk
)
SELECT
    i.i_item_id,
    p.p_promo_name,
    SUM(cs.cs_net_paid)                AS total_catalog_sales,
    SUM(ws.ws_net_paid)                AS total_web_sales,
    SUM(sr.sr_return_amt)              AS total_return_amount,
    SUM(ia.total_on_hand)              AS total_on_hand,
    AVG(td_cs.t_hour)                  AS avg_sale_hour
FROM store_returns sr
JOIN time_dim td_sr
    ON sr.sr_return_time_sk = td_sr.t_time_sk
JOIN item i
    ON sr.sr_item_sk = i.i_item_sk
JOIN household_demographics hd_sr
    ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN inv_agg ia
    ON i.i_item_sk = ia.i_item_sk
JOIN catalog_sales cs
    ON cs.cs_item_sk = i.i_item_sk
JOIN time_dim td_cs
    ON cs.cs_sold_time_sk = td_cs.t_time_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
JOIN time_dim td_ws
    ON ws.ws_sold_time_sk = td_ws.t_time_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we
    ON ws.ws_web_site_sk = we.web_site_sk
JOIN household_demographics hd_ws
    ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
WHERE cc.cc_tax_percentage > 0.05
  AND cp.cp_catalog_number IN (2, 11, 16)
  AND i.i_current_price BETWEEN 10 AND 1000
  AND p.p_discount_active = 'Y'
  AND td_sr.t_hour BETWEEN 9 AND 17
  AND sr.sr_return_quantity > 1
  AND ws.ws_ext_ship_cost < 500
  AND ia.total_on_hand > 1000
GROUP BY GROUPING SETS (
    (i.i_item_id, p.p_promo_name),
    (i.i_item_id),
    (p.p_promo_name),
    ()
)
ORDER BY total_catalog_sales DESC
