SELECT
    p.p_promo_id,
    p.p_purpose,
    COUNT(DISTINCT ws.ws_order_number) AS orders_cnt,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    SUM(ws.ws_net_profit) AS total_profit,
    MIN(ws.ws_sold_date_sk) AS first_sale_date_sk,
    MAX(ws.ws_sold_date_sk) AS last_sale_date_sk,
    RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
FROM
    web_sales ws
JOIN
    promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
WHERE
    p.p_channel_tv = 'Y'
    AND p.p_channel_demo = 'Y'
    AND p.p_promo_id IN ('AAAAAAAABAAAAAAA', 'AAAAAAAACAAAAAAA', 'AAAAAAAADAAAAAAA')
    AND ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
GROUP BY
    p.p_promo_id,
    p.p_purpose
HAVING
    SUM(ws.ws_net_profit) > 10000
ORDER BY
    profit_rank
LIMIT 100
