WITH ranked_brands AS (
    SELECT
        t.t_hour,
        i.i_brand,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) / NULLIF(SUM(ss.ss_ext_sales_price), 0) AS profit_margin,
        ROW_NUMBER() OVER (PARTITION BY t.t_hour ORDER BY SUM(ss.ss_net_profit) DESC) AS brand_rank
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE i.i_color = 'red'
      AND i.i_brand_id IN (5003002, 1001001)
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY t.t_hour, i.i_brand
    HAVING SUM(ss.ss_net_profit) > 10000
)
SELECT
    t_hour,
    i_brand,
    total_profit,
    avg_discount,
    total_sales,
    profit_margin,
    brand_rank
FROM ranked_brands
WHERE brand_rank <= 5
ORDER BY t_hour, brand_rank
