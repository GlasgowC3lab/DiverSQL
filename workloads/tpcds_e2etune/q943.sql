WITH sales_with_returns AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_sold_time_sk,
        ss.ss_promo_sk,
        ss.ss_ext_sales_price      AS ext_sales,
        ss.ss_ext_discount_amt    AS ext_discount,
        ss.ss_net_profit          AS net_profit,
        COALESCE(sr.sr_net_loss, 0) AS return_loss
    FROM store_sales ss
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
       AND ss.ss_item_sk = sr.sr_item_sk
)
SELECT
    p.p_promo_name,
    p.p_channel_email,
    p.p_channel_tv,
    t.t_hour,
    SUM(s.ext_sales)                                 AS total_sales,
    SUM(s.ext_discount)                              AS total_discount,
    SUM(s.net_profit) - SUM(s.return_loss)           AS net_profit_after_returns,
    CASE WHEN SUM(s.ext_sales) = 0 THEN 0
         ELSE ROUND(100.0 * SUM(s.ext_discount) / SUM(s.ext_sales), 2)
    END                                              AS discount_pct,
    RANK() OVER (ORDER BY SUM(s.net_profit) - SUM(s.return_loss) DESC) AS profit_rank
FROM sales_with_returns s
JOIN promotion p ON s.ss_promo_sk = p.p_promo_sk
JOIN time_dim t ON s.ss_sold_time_sk = t.t_time_sk
GROUP BY p.p_promo_name, p.p_channel_email, p.p_channel_tv, t.t_hour
HAVING SUM(s.ext_sales) > 1000
ORDER BY net_profit_after_returns DESC
LIMIT 100
