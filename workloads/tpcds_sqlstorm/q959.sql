WITH aggregated_sales AS (
    SELECT
        s.s_store_name,
        i.i_category,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_paid) AS total_net_paid,
        AVG(ss.ss_net_profit) AS avg_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(*) AS transaction_count
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND s.s_state = 'CA'
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY
        s.s_store_name,
        i.i_category,
        d.d_year,
        d.d_month_seq
    HAVING SUM(ss.ss_net_paid) > 10000
)
SELECT
    s_store_name,
    i_category,
    d_year,
    d_month_seq,
    total_net_paid,
    avg_net_profit,
    total_sales,
    transaction_count,
    PERCENT_RANK() OVER (PARTITION BY i_category ORDER BY total_net_paid DESC) AS category_store_sales_rank,
    SUM(total_net_paid) OVER (PARTITION BY s_store_name ORDER BY d_month_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_3_month_net_paid,
    total_net_paid / SUM(total_net_paid) OVER (PARTITION BY i_category) AS category_store_sales_pct
FROM aggregated_sales
ORDER BY total_net_paid DESC
LIMIT 100
