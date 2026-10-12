WITH order_reasons AS (
    SELECT
        cr.cr_order_number,
        array_agg(r.r_reason_desc) AS reason_array
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    GROUP BY cr.cr_order_number
)
SELECT
    d.d_year,
    sm.sm_ship_mode_id,
    wsit.web_company_id,
    unnest_reason AS reason_desc,
    SUM(cs.cs_net_paid) AS total_catalog_sales,
    SUM(ws.ws_net_paid) AS total_web_sales,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    AVG(cr.cr_net_loss) AS avg_return_loss
FROM date_dim d
JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    AND ws.ws_bill_customer_sk = c.c_customer_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_customer_sk = c.c_customer_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN order_reasons orr ON orr.cr_order_number = cs.cs_order_number
CROSS JOIN UNNEST(orr.reason_array) AS t (unnest_reason)
WHERE d.d_year = 2001
  AND d.d_quarter_seq = 14
  AND wsit.web_company_id = 2
  AND c.c_birth_country = 'United States'
  AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = c.c_customer_sk
          AND sr2.sr_returned_date_sk = d.d_date_sk
  )
GROUP BY d.d_year, sm.sm_ship_mode_id, wsit.web_company_id, unnest_reason
ORDER BY total_catalog_sales DESC
LIMIT 100
