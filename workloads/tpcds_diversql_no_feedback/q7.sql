WITH joined AS (
    SELECT
        promotion.p_promo_name,
        promotion.p_channel_tv,
        promotion.p_channel_details,
        store_sales.ss_sold_date_sk,
        store_sales.ss_list_price,
        store_sales.ss_sales_price,
        store_sales.ss_net_paid,
        store_sales.ss_quantity
    FROM tpcds.promotion AS promotion
    JOIN tpcds.store_sales AS store_sales
        ON store_sales.ss_promo_sk = promotion.p_promo_sk
    WHERE store_sales.ss_list_price > 50
      AND store_sales.ss_sales_price BETWEEN 20 AND 150
      AND store_sales.ss_sold_date_sk BETWEEN 2451220 AND 2452596
      AND promotion.p_channel_tv = 'N'
      AND promotion.p_promo_name LIKE '%bar%'
)
SELECT
    p_promo_name,
    p_channel_tv,
    word,
    COUNT(*) AS sales_count,
    SUM(ss_net_paid) AS total_net_paid,
    AVG(ss_sales_price) AS avg_sales_price,
    MIN(ss_list_price) AS min_list_price,
    MAX(ss_list_price) AS max_list_price
FROM joined
CROSS JOIN UNNEST(split(p_channel_details, ' ')) AS t(word)
GROUP BY p_promo_name, p_channel_tv, word
ORDER BY total_net_paid DESC
LIMIT 100
