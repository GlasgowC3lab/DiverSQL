WITH avg_profit AS (
    SELECT avg(ws_net_profit) AS avg_profit
    FROM web_sales
)
SELECT
    s.s_store_id,
    s.s_store_name,
    d.d_year,
    c.c_customer_id,
    hd.hd_income_band_sk,
    cp.cp_department,
    cr.cr_return_quantity,
    ws.ws_net_profit,
    ws.ws_net_profit - avgp.avg_profit AS profit_vs_avg,
    RANK() OVER (PARTITION BY s.s_store_id ORDER BY ws.ws_net_profit DESC) AS profit_rank,
    SUM(ws.ws_net_profit) OVER (PARTITION BY s.s_store_id ORDER BY d.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_profit
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
RIGHT JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = ws.ws_item_sk
LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk AND cr.cr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
CROSS JOIN avg_profit avgp
WHERE d.d_year = 2001
  AND s.s_market_id IN (3, 7)
  AND c.c_preferred_cust_flag = 'Y'
  AND w.w_gmt_offset = -5.00
  AND cp.cp_department = 'Sports'
  AND cr.cr_return_quantity > 0
ORDER BY s.s_store_id, profit_rank
