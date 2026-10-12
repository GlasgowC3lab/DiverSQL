WITH filtered_returns AS (
    SELECT
        p.p_promo_name,
        r.r_reason_desc,
        wr.wr_net_loss,
        wr.wr_return_amt
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE p.p_promo_name LIKE 'Holiday%'
      AND regexp_like(r.r_reason_desc, '(?i)defect')
)
SELECT
    p.p_promo_name,
    r.r_reason_desc,
    p.p_promo_name || ' - ' || r.r_reason_desc AS promo_reason,
    SUM(wr.wr_net_loss)          AS total_net_loss,
    SUM(wr.wr_return_amt)        AS total_return_amt,
    COUNT(*)                     AS return_count
FROM web_returns wr
JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
WHERE p.p_promo_name LIKE 'Holiday%'
  AND regexp_like(r.r_reason_desc, '(?i)defect')
GROUP BY ROLLUP (p.p_promo_name, r.r_reason_desc)
ORDER BY total_net_loss DESC
LIMIT 100
