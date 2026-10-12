WITH sales_agg AS (
    SELECT s.s_store_name AS store_name,
           d.d_year AS year,
           i.i_category AS category,
           SUM(ss.ss_net_paid) AS total_sales,
           SUM(ss.ss_net_profit) AS total_profit,
           COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
           AVG(ss.ss_ext_discount_amt) AS avg_discount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
    GROUP BY s.s_store_name, d.d_year, i.i_category
),
returns_agg AS (
    SELECT s.s_store_name AS store_name,
           d.d_year AS year,
           i.i_category AS category,
           SUM(sr.sr_return_amt) AS total_returns,
           SUM(sr.sr_net_loss) AS total_return_loss,
           COUNT(*) AS return_count
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
    GROUP BY s.s_store_name, d.d_year, i.i_category
)
SELECT sa.store_name,
       sa.year,
       sa.category,
       sa.total_sales,
       COALESCE(ra.total_returns, 0) AS total_returns,
       sa.total_sales - COALESCE(ra.total_returns, 0) AS net_revenue,
       sa.total_profit,
       sa.distinct_customers,
       sa.avg_discount,
       COALESCE(ra.return_count, 0) AS return_count,
       RANK() OVER (PARTITION BY sa.year ORDER BY (sa.total_sales - COALESCE(ra.total_returns, 0)) DESC) AS revenue_rank
FROM sales_agg sa
LEFT JOIN returns_agg ra ON sa.store_name = ra.store_name AND sa.year = ra.year AND sa.category = ra.category
ORDER BY net_revenue DESC
LIMIT 100
