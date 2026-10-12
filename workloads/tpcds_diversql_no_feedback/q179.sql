WITH sales_data AS (
    SELECT
        s.s_state AS state,
        cd.cd_gender AS gender,
        substr(p.p_channel_details, 1, 10) AS channel_snippet,
        ss.ss_sales_price AS sales_price,
        ss.ss_quantity AS quantity,
        ss.ss_net_profit AS net_profit
    FROM store_sales ss
    FULL OUTER JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE
        regexp_like(p.p_channel_details, '(High|Old)')
        AND s.s_state LIKE 'A%'
)
SELECT
    state,
    gender,
    channel_snippet,
    SUM(sales_price) AS total_sales,
    SUM(quantity) AS total_quantity,
    AVG(net_profit) AS avg_profit
FROM sales_data
GROUP BY CUBE(state, gender, channel_snippet)
ORDER BY total_sales DESC
LIMIT 100
