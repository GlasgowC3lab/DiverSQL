WITH combined_sales AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        'catalog' AS sales_channel,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
      AND p.p_response_target = 1
    GROUP BY i.i_item_sk, i.i_product_name

    UNION ALL

    SELECT
        i.i_item_sk,
        i.i_product_name,
        'store' AS sales_channel,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
      AND s.s_state = 'CA'
    GROUP BY i.i_item_sk, i.i_product_name
),
ranked_sales AS (
    SELECT
        i_item_sk,
        i_product_name,
        sales_channel,
        total_sales,
        total_profit,
        ROW_NUMBER() OVER (PARTITION BY sales_channel ORDER BY total_sales DESC) AS rn
    FROM combined_sales
)
SELECT
    i_item_sk,
    i_product_name,
    sales_channel,
    total_sales,
    total_profit
FROM ranked_sales
WHERE rn <= 5
ORDER BY sales_channel, total_sales DESC
LIMIT 100
