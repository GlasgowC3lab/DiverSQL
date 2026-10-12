WITH filtered_item AS (
    SELECT i_item_sk
    FROM item
    WHERE i_brand = 'Brand#12'
)
SELECT
    d.d_year,
    s.s_state,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(ws.ws_net_profit) AS web_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_ticket_cnt,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
    AVG(p.p_cost) AS avg_promo_cost,
    MIN(sr.sr_return_amt) AS min_store_return,
    MAX(wr.wr_return_amt) AS max_web_return
FROM date_dim d
LEFT JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d.d_date_sk
LEFT JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN item i
    ON i.i_item_sk = cs.cs_item_sk
JOIN household_demographics hd
    ON hd.hd_demo_sk = cs.cs_bill_hdemo_sk
JOIN income_band ib
    ON ib.ib_income_band_sk = hd.hd_income_band_sk
JOIN store s
    ON s.s_store_sk = ss.ss_store_sk
JOIN promotion p
    ON p.p_promo_sk = cs.cs_promo_sk
JOIN ship_mode sm
    ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
JOIN warehouse w
    ON w.w_warehouse_sk = cs.cs_warehouse_sk
JOIN reason r
    ON r.r_reason_sk = sr.sr_reason_sk
JOIN web_page wp
    ON wp.wp_web_page_sk = ws.ws_web_page_sk
WHERE d.d_year = 2001
  AND s.s_state IN ('CA', 'TX', 'NY')
  AND w.w_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND cs.cs_item_sk IN (SELECT i_item_sk FROM filtered_item)
  AND ib.ib_upper_bound > 50000
GROUP BY d.d_year, s.s_state
ORDER BY catalog_net_profit DESC
LIMIT 100
