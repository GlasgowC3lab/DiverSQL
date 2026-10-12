WITH cs_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_call_center_sk,
        cs.cs_warehouse_sk,
        cs.cs_bill_hdemo_sk,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2450500
      AND cs.cs_quantity > 0
      AND cs.cs_net_paid > 0
    GROUP BY cs.cs_item_sk, cs.cs_promo_sk, cs.cs_call_center_sk, cs.cs_warehouse_sk, cs.cs_bill_hdemo_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    p.p_promo_name,
    cc.cc_name,
    w.w_warehouse_name,
    s.s_store_name,
    hd.hd_buy_potential,
    cs_agg.total_sales,
    cs_agg.total_quantity,
    CASE WHEN cs_agg.total_sales > 5000 THEN 'High' ELSE 'Low' END AS sales_category,
    LAG(cs_agg.total_sales) OVER (PARTITION BY p.p_promo_sk ORDER BY cs_agg.total_sales) AS prev_sales,
    SUM(cs_agg.total_sales) OVER (PARTITION BY p.p_promo_sk ORDER BY cs_agg.total_sales ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_sales,
    ROW_NUMBER() OVER (PARTITION BY p.p_promo_sk ORDER BY cs_agg.total_sales DESC) AS sales_rank
FROM cs_agg
JOIN item i ON cs_agg.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs_agg.cs_promo_sk = p.p_promo_sk
JOIN call_center cc ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w ON cs_agg.cs_warehouse_sk = w.w_warehouse_sk
JOIN household_demographics hd ON cs_agg.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = i.i_item_sk
LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
WHERE
    s.s_state = 'CA'
    AND s.s_hours LIKE '%8AM-4PM%'
    AND p.p_discount_active = 'Y'
    AND i.i_units = 'Ounce'
    AND w.w_state = 'CA'
    AND i.i_item_sk NOT IN (SELECT i2.i_item_sk FROM item i2 WHERE i2.i_units = 'Tbl')
LIMIT 100
