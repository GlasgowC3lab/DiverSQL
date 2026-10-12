WITH brand_customer_sales AS (
    SELECT
        i.i_brand,
        c.c_customer_id,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS transaction_count,
        cd.cd_gender,
        cd.cd_marital_status
    FROM store_sales ss
    INNER JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    INNER JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    INNER JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    GROUP BY i.i_brand, c.c_customer_id, cd.cd_gender, cd.cd_marital_status
)
SELECT
    i_brand,
    c_customer_id,
    total_net_profit,
    transaction_count,
    cd_gender,
    cd_marital_status,
    RANK() OVER (PARTITION BY i_brand ORDER BY total_net_profit DESC) AS brand_customer_rank,
    CASE
        WHEN total_net_profit > 10000 THEN 'High'
        WHEN total_net_profit > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM brand_customer_sales
WHERE transaction_count >= 5
ORDER BY i_brand, brand_customer_rank
LIMIT 50
