WITH sales_promo AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_sold_date_sk,
        p.p_channel_tv,
        p.p_channel_email,
        p.p_channel_radio,
        p.p_promo_id
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2458000 AND 2459000
)
SELECT
    wsite.web_site_sk,
    wsite.web_name,
    CASE 
        WHEN sp.p_channel_tv = 'Y' THEN 'TV'
        WHEN sp.p_channel_email = 'Y' THEN 'Email'
        WHEN sp.p_channel_radio = 'Y' THEN 'Radio'
        ELSE 'Other'
    END AS promo_channel,
    SUM(sp.ws_net_profit) AS total_net_profit,
    SUM(sp.ws_ext_sales_price) AS total_sales,
    AVG(sp.ws_ext_discount_amt) AS avg_discount_amt,
    COUNT(DISTINCT sp.p_promo_id) AS distinct_promos,
    RANK() OVER (ORDER BY SUM(sp.ws_net_profit) DESC) AS profit_rank
FROM sales_promo sp
JOIN web_site wsite ON sp.ws_web_site_sk = wsite.web_site_sk
WHERE wsite.web_state = 'CA'
  AND wsite.web_open_date_sk >= 2450000
GROUP BY
    wsite.web_site_sk,
    wsite.web_name,
    CASE 
        WHEN sp.p_channel_tv = 'Y' THEN 'TV'
        WHEN sp.p_channel_email = 'Y' THEN 'Email'
        WHEN sp.p_channel_radio = 'Y' THEN 'Radio'
        ELSE 'Other'
    END
ORDER BY total_net_profit DESC
LIMIT 100
