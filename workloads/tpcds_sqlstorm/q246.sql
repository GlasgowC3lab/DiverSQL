SELECT
    d_year,
    s_store_id,
    i_category,
    orders,
    total_quantity,
    total_sales,
    total_profit,
    avg_discount,
    RANK() OVER (PARTITION BY d_year, s_store_id ORDER BY total_sales DESC) AS sales_rank
FROM (
    SELECT
        d.d_year,
        s.s_store_id,
        i.i_category,
        COUNT(*) AS orders,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND s.s_country = 'United States'
    GROUP BY d.d_year, s.s_store_id, i.i_category
    HAVING SUM(ss.ss_ext_sales_price) > 100000
) t
ORDER BY d_year, total_sales DESC
