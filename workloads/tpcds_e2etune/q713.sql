SELECT
    p.p_promo_name AS promo_name,
    d_sales.d_year,
    d_sales.d_moy AS month,
    SUM(COALESCE(ss.ss_net_profit, 0)) AS store_net_profit,
    SUM(COALESCE(ws.ws_net_profit, 0)) AS web_net_profit,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS web_return_net_loss,
    (SUM(COALESCE(ss.ss_net_profit, 0)) + SUM(COALESCE(ws.ws_net_profit, 0)) - SUM(COALESCE(wr.wr_net_loss, 0))) AS net_contribution,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_cnt,
    COUNT(DISTINCT ws.ws_order_number) AS web_sales_cnt,
    AVG(COALESCE(ss.ss_ext_discount_amt, 0)) AS avg_store_discount,
    AVG(COALESCE(ws.ws_ext_discount_amt, 0)) AS avg_web_discount
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
LEFT JOIN web_sales ws
    ON ws.ws_promo_sk = p.p_promo_sk
   AND ws.ws_sold_date_sk = d_sales.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
LEFT JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
WHERE d_sales.d_year = 2001
  AND d_sales.d_holiday = 'N'
  AND d_sales.d_weekend = 'N'
  AND p.p_discount_active = 'Y'
  AND d_start.d_date_sk <= d_sales.d_date_sk
  AND d_end.d_date_sk >= d_sales.d_date_sk
GROUP BY p.p_promo_name, d_sales.d_year, d_sales.d_moy
HAVING (SUM(COALESCE(ss.ss_net_profit, 0)) + SUM(COALESCE(ws.ws_net_profit, 0)) - SUM(COALESCE(wr.wr_net_loss, 0))) > 0
ORDER BY net_contribution DESC
LIMIT 50
