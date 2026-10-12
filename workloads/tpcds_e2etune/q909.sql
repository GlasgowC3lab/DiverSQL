SELECT
    p.p_promo_name,
    src.channel AS sales_channel,
    cd.cd_gender,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(src.net_profit) AS total_net_profit,
    AVG(src.discount_amount) AS avg_discount_amount,
    SUM(src.sales_price) AS total_sales_price
FROM (
    SELECT
        ss.ss_promo_sk AS promo_sk,
        ss.ss_net_profit AS net_profit,
        ss.ss_ext_discount_amt AS discount_amount,
        ss.ss_sales_price AS sales_price,
        'store' AS channel,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_cdemo_sk AS cdemo_sk
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_promo_sk AS promo_sk,
        ws.ws_net_profit AS net_profit,
        ws.ws_ext_discount_amt AS discount_amount,
        ws.ws_sales_price AS sales_price,
        'web' AS channel,
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_bill_cdemo_sk AS cdemo_sk
    FROM web_sales ws
) src
JOIN promotion p ON src.promo_sk = p.p_promo_sk
JOIN customer c ON src.customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON src.cdemo_sk = cd.cd_demo_sk
WHERE
    p.p_cost > 1000
    AND c.c_birth_year >= 1950
    AND cd.cd_gender IS NOT NULL
GROUP BY
    p.p_promo_name,
    src.channel,
    cd.cd_gender
ORDER BY total_net_profit DESC
LIMIT 50
