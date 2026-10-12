SELECT
    d_year,
    d_month_seq,
    i_category,
    total_sales,
    total_profit,
    total_promo_cost,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS category_rank
FROM (
    SELECT
        d.d_year AS d_year,
        d.d_month_seq AS d_month_seq,
        i.i_category AS i_category,
        SUM(s.net_paid) AS total_sales,
        SUM(s.net_profit) AS total_profit,
        SUM(p.p_cost) AS total_promo_cost
    FROM (
        SELECT ss_sold_date_sk AS sold_date_sk,
               ss_item_sk AS item_sk,
               ss_net_paid AS net_paid,
               ss_net_profit AS net_profit,
               ss_promo_sk AS promo_sk,
               ss_store_sk AS store_sk
        FROM store_sales
        UNION ALL
        SELECT cs_sold_date_sk,
               cs_item_sk,
               cs_net_paid,
               cs_net_profit,
               cs_promo_sk,
               NULL
        FROM catalog_sales
        UNION ALL
        SELECT ws_sold_date_sk,
               ws_item_sk,
               ws_net_paid,
               ws_net_profit,
               ws_promo_sk,
               NULL
        FROM web_sales
    ) s
    JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    LEFT JOIN promotion p ON s.promo_sk = p.p_promo_sk
    LEFT JOIN store st ON s.store_sk = st.s_store_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_month_seq, i.i_category
) agg
ORDER BY d_year, total_sales DESC
LIMIT 200
