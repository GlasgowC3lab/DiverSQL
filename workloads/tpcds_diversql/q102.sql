SELECT
    d.d_year,
    w.w_state,
    cp.cp_department,
    SUM(cs.cs_net_paid_inc_ship) AS total_sales,
    SUM(COALESCE(cr.cr_return_amount, 0)) AS total_returns,
    AVG(cs.cs_coupon_amt) AS avg_coupon_amount,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    MIN(cs.cs_net_profit) AS min_net_profit,
    MAX(cs.cs_net_profit) AS max_net_profit,
    SUM(
        CASE
            WHEN cs.cs_net_profit > 1000 THEN cs.cs_net_paid_inc_ship
            ELSE 0
        END
    ) AS high_profit_sales
FROM catalog_sales cs
JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
   AND ws.ws_sold_time_sk = t.t_time_sk
   AND ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_site we
    ON ws.ws_web_site_sk = we.web_site_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
   AND sr.sr_return_time_sk = t.t_time_sk
FULL OUTER JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
WHERE d.d_year = 2001
  AND w.w_state = 'TN'
  AND t.t_shift = 'first'
  AND p.p_discount_active = 'Y'
  AND cp.cp_department = 'Electronics'
GROUP BY d.d_year, w.w_state, cp.cp_department
ORDER BY total_sales DESC
LIMIT 100
