WITH date_filtered AS (
    SELECT d_date_sk,
           d_date,
           d_year,
           d_day_name
    FROM date_dim
    WHERE d_year IN (1998, 1999, 2000)
),
promo_sales AS (
    SELECT cs.cs_sold_date_sk,
           cs.cs_item_sk,
           cs.cs_quantity,
           cs.cs_net_paid,
           cs.cs_net_profit,
           cs.cs_promo_sk,
           p.p_promo_name,
           p.p_discount_active,
           p.p_start_date_sk,
           p.p_end_date_sk
    FROM catalog_sales cs
    LEFT JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_filtered df
        ON cs.cs_sold_date_sk = df.d_date_sk
    WHERE cs.cs_sold_date_sk IS NOT NULL
),
top_items AS (
    SELECT i.i_item_sk,
           i.i_category,
           i.i_class,
           i.i_item_desc,
           SUM(ps.cs_net_paid) AS total_sales,
           SUM(ps.cs_net_profit) AS total_profit,
           SUM(ps.cs_quantity) AS total_qty
    FROM promo_sales ps
    JOIN item i
        ON ps.cs_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, i.i_category, i.i_class, i.i_item_desc
    HAVING SUM(ps.cs_quantity) > 100
),
store_performance AS (
    SELECT s.s_store_sk,
           s.s_store_name,
           d.d_year,
           SUM(ss.ss_net_paid) AS store_sales,
           SUM(ss.ss_net_profit) AS store_profit,
           AVG(ss.ss_quantity) AS avg_quantity,
           RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(ss.ss_net_paid) DESC) AS sales_rank
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year
),
return_analysis AS (
    SELECT cr.cr_item_sk,
           i.i_item_id,
           COALESCE(SUM(cr.cr_return_quantity), 0) AS return_qty,
           COALESCE(SUM(cr.cr_return_amt_inc_tax), 0) AS return_amount,
           COUNT(DISTINCT cr.cr_returned_date_sk) AS distinct_return_days
    FROM catalog_returns cr
    LEFT JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_returned_date_sk IS NOT NULL
    GROUP BY cr.cr_item_sk, i.i_item_id
),
combined AS (
    SELECT ti.i_item_sk,
           ti.i_category,
           ti.i_class,
           ti.i_item_desc,
           ti.total_sales,
           ti.total_profit,
           COALESCE(ra.return_qty, 0) AS return_qty,
           COALESCE(ra.return_amount, 0) AS return_amount,
           CASE WHEN ti.total_sales > 0 THEN COALESCE(ra.return_qty, 0) * 100.0 / ti.total_sales ELSE NULL END AS return_rate_percent,
           CONCAT(ti.i_item_desc, ' - ', ti.i_category) AS item_full_desc
    FROM top_items ti
    LEFT JOIN return_analysis ra
        ON ti.i_item_sk = ra.cr_item_sk
    WHERE ti.total_sales > 10000 OR ti.total_profit > 5000
),
ranked_combined AS (
    SELECT c.*,
           ROW_NUMBER() OVER (ORDER BY c.total_sales DESC) AS rn
    FROM combined c
    WHERE c.return_rate_percent IS NOT NULL
),
top_combined AS (
    SELECT *
    FROM ranked_combined
    WHERE rn <= 100
),
sp AS (
    SELECT sp.s_store_sk,
           sp.s_store_name,
           sp.d_year,
           sp.store_sales,
           sp.store_profit,
           sp.sales_rank
    FROM store_performance sp
    WHERE sp.sales_rank <= 10
)
SELECT tc.item_full_desc,
       tc.total_sales,
       tc.total_profit,
       tc.return_qty,
       tc.return_amount,
       ROUND(tc.return_rate_percent, 2) AS return_rate_pct,
       (SELECT AVG(c2.total_profit) FROM combined c2 WHERE c2.i_category = tc.i_category) AS avg_category_profit,
       sp.s_store_name,
       sp.store_sales,
       sp.store_profit,
       sp.sales_rank,
       CASE WHEN sp.sales_rank <= 5 THEN 'Top5' ELSE 'Other' END AS store_category
FROM top_combined tc
LEFT JOIN sp
    ON tc.i_item_sk = sp.s_store_sk
UNION ALL
SELECT 'Aggregated Totals' AS item_full_desc,
       SUM(tc.total_sales) AS total_sales,
       SUM(tc.total_profit) AS total_profit,
       SUM(tc.return_qty) AS return_qty,
       SUM(tc.return_amount) AS return_amount,
       ROUND(SUM(tc.return_qty) * 100.0 / NULLIF(SUM(tc.total_sales), 0), 2) AS return_rate_pct,
       ROUND(AVG(tc.total_profit), 2) AS avg_category_profit,
       NULL AS s_store_name,
       NULL AS store_sales,
       NULL AS store_profit,
       NULL AS sales_rank,
       NULL AS store_category
FROM combined tc
WHERE tc.total_sales > 0
