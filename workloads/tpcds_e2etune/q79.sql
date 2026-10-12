WITH promo_sales AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        p.p_channel_tv,
        p.p_channel_email,
        p.p_channel_radio,
        p.p_discount_active,
        p.p_start_date_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity
    FROM promotion p
    JOIN web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_start_date_sk BETWEEN 2450118 AND 2450675
      AND p.p_discount_active = 'Y'
      AND p.p_channel_tv = 'N'
    GROUP BY
        p.p_promo_id,
        p.p_promo_name,
        p.p_channel_tv,
        p.p_channel_email,
        p.p_channel_radio,
        p.p_discount_active,
        p.p_start_date_sk
)
SELECT
    ps.p_promo_id,
    ps.p_promo_name,
    ps.p_channel_tv,
    ps.p_channel_email,
    ps.p_channel_radio,
    ps.p_discount_active,
    ps.total_sales,
    ps.total_profit,
    ps.total_quantity,
    RANK() OVER (ORDER BY ps.total_profit DESC) AS profit_rank,
    ROUND(ps.total_profit / SUM(ps.total_profit) OVER () * 100, 2) AS profit_pct
FROM promo_sales ps
ORDER BY profit_rank
LIMIT 10
