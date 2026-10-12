WITH ss_sample AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
    WHERE ss_ext_tax > 50
)
SELECT
    p.p_promo_id,
    p.p_channel_tv,
    ss.ss_store_sk,
    ws.ws_ship_mode_sk,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_transactions,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    SUM(ws.ws_net_paid) AS total_web_net_paid,
    SUM(wr.wr_net_loss) AS total_return_net_loss,
    AVG(wr.wr_return_ship_cost) AS avg_return_ship_cost,
    MIN(ss.ss_ext_tax) AS min_store_tax,
    MAX(ws.ws_ext_tax) AS max_web_tax
FROM ss_sample ss
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN web_sales ws
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_returns wr
    ON wr.wr_item_sk = ws.ws_item_sk
   AND wr.wr_order_number = ws.ws_order_number
WHERE p.p_channel_tv = 'N'
  AND wr.wr_return_ship_cost < 100
  AND p.p_end_date_sk > 2450000
GROUP BY
    p.p_promo_id,
    p.p_channel_tv,
    ss.ss_store_sk,
    ws.ws_ship_mode_sk
ORDER BY total_store_net_paid DESC
LIMIT 100
