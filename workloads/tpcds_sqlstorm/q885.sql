SELECT
    t2.s_store_name,
    t2.i_category,
    t2.d_year,
    t2.d_month_seq,
    t2.total_profit,
    t2.total_sales,
    t2.sales_count
FROM (
    SELECT
        t1.*,
        ROW_NUMBER() OVER (PARTITION BY t1.s_store_name ORDER BY t1.total_profit DESC) AS rn
    FROM (
        SELECT
            s.s_store_name,
            i.i_category,
            d.d_year,
            d.d_month_seq,
            SUM(ss.ss_net_profit) AS total_profit,
            SUM(ss.ss_ext_sales_price) AS total_sales,
            COUNT(*) AS sales_count
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        WHERE d.d_year = 2000
          AND c.c_preferred_cust_flag = 'Y'
        GROUP BY s.s_store_name, i.i_category, d.d_year, d.d_month_seq
    ) t1
) t2
WHERE t2.rn <= 5
ORDER BY t2.s_store_name, t2.total_profit DESC
