WITH date_range AS (
    SELECT d.d_date_sk, d.d_year
    FROM date_dim d
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '2000-12-31'
),
store_sales_agg AS (
    SELECT ss.ss_store_sk AS store_sk,
           SUM(ss.ss_net_paid) AS total_net_paid,
           SUM(ss.ss_ext_sales_price) AS total_ext_sales,
           SUM(ss.ss_quantity) AS total_quantity,
           COUNT(*) AS sales_txns,
           COUNT(DISTINCT ss.ss_item_sk) AS distinct_items_sold
    FROM store_sales ss
    JOIN date_range dr ON ss.ss_sold_date_sk = dr.d_date_sk
    GROUP BY ss.ss_store_sk
),
store_returns_agg AS (
    SELECT sr.sr_store_sk AS store_sk,
           SUM(sr.sr_return_amt_inc_tax) AS total_return_amt,
           SUM(sr.sr_return_quantity) AS total_return_qty,
           COUNT(*) AS return_txns
    FROM store_returns sr
    JOIN date_range dr ON sr.sr_returned_date_sk = dr.d_date_sk
    GROUP BY sr.sr_store_sk
),
store_item_sales AS (
    SELECT ss2.ss_store_sk AS store_sk,
           ss2.ss_item_sk AS item_sk,
           SUM(ss2.ss_quantity) AS total_qty
    FROM store_sales ss2
    JOIN date_range dr2 ON ss2.ss_sold_date_sk = dr2.d_date_sk
    GROUP BY ss2.ss_store_sk, ss2.ss_item_sk
),
store_item_top AS (
    SELECT store_sk, item_sk, total_qty,
           ROW_NUMBER() OVER (PARTITION BY store_sk ORDER BY total_qty DESC) AS rn
    FROM store_item_sales
),
catalog_sales_agg AS (
    SELECT cs.cs_item_sk AS item_sk,
           SUM(cs.cs_net_paid) AS cat_net_paid,
           SUM(cs.cs_ext_sales_price) AS cat_ext_sales,
           COUNT(*) AS cat_txns,
           AVG(cs.cs_sales_price) AS avg_cat_price
    FROM catalog_sales cs
    JOIN date_range dr ON cs.cs_sold_date_sk = dr.d_date_sk
    GROUP BY cs.cs_item_sk
),
web_sales_agg AS (
    SELECT ws.ws_item_sk AS item_sk,
           SUM(ws.ws_net_paid) AS web_net_paid,
           SUM(ws.ws_ext_sales_price) AS web_ext_sales,
           COUNT(*) AS web_txns,
           AVG(ws.ws_sales_price) AS avg_web_price
    FROM web_sales ws
    JOIN date_range dr ON ws.ws_sold_date_sk = dr.d_date_sk
    GROUP BY ws.ws_item_sk
),
cat_web_sales AS (
    SELECT COALESCE(ca.item_sk, wa.item_sk) AS item_sk,
           COALESCE(ca.cat_net_paid, 0) AS cat_net_paid,
           COALESCE(wa.web_net_paid, 0) AS web_net_paid,
           COALESCE(ca.cat_txns, 0) + COALESCE(wa.web_txns, 0) AS total_txns,
           COALESCE(ca.avg_cat_price, 0) AS avg_cat_price,
           COALESCE(wa.avg_web_price, 0) AS avg_web_price
    FROM catalog_sales_agg ca
    FULL OUTER JOIN web_sales_agg wa ON ca.item_sk = wa.item_sk
),
item_price_stats AS (
    SELECT i.i_item_sk,
           i.i_product_name,
           COALESCE(ca.avg_cat_price, 0) AS avg_catalog_price,
           COALESCE(wa.avg_web_price, 0) AS avg_web_price,
           COALESCE(ca.cat_txns, 0) AS cat_txns,
           COALESCE(wa.web_txns, 0) AS web_txns
    FROM item i
    LEFT JOIN catalog_sales_agg ca ON i.i_item_sk = ca.item_sk
    LEFT JOIN web_sales_agg wa ON i.i_item_sk = wa.item_sk
)
SELECT
    'Store' AS record_type,
    CONCAT(s.s_store_name, ' (', s.s_city, ')') AS description,
    s.s_store_sk AS store_sk,
    CONCAT(s.s_store_name, ' (', s.s_city, ')') AS store_full_name,
    COALESCE(ssa.total_net_paid, 0) AS sales_net_paid,
    COALESCE(sra.total_return_amt, 0) AS returns_total,
    (COALESCE(ssa.total_net_paid, 0) - COALESCE(sra.total_return_amt, 0)) AS net_sales_after_returns,
    RANK() OVER (ORDER BY COALESCE(ssa.total_net_paid, 0) DESC) AS sales_rank,
    CASE 
        WHEN COALESCE(ssa.total_net_paid, 0) = 0 THEN 'No Sales'
        WHEN COALESCE(sra.total_return_amt, 0) / NULLIF(COALESCE(ssa.total_net_paid, 0), 0) > 0.2 THEN 'High Returns'
        ELSE 'Normal'
    END AS return_category,
    date_diff('year', s.s_rec_start_date, DATE '2024-10-01') AS store_age_years,
    (SELECT AVG(ss2.ss_net_paid) FROM store_sales ss2 WHERE ss2.ss_store_sk = s.s_store_sk) AS overall_avg_net_paid,
    SUM(COALESCE(ssa.total_net_paid, 0)) OVER () AS total_all_store_sales,
    COALESCE(ssa.total_net_paid, 0) / NULLIF(SUM(COALESCE(ssa.total_net_paid, 0)) OVER (), 0) AS pct_of_total_sales,
    LAG(COALESCE(ssa.total_net_paid, 0)) OVER (ORDER BY COALESCE(ssa.total_net_paid, 0) DESC) AS previous_store_sales,
    COALESCE(ssa.distinct_items_sold, 0) AS distinct_items_sold,
    itop.i_product_name AS top_item_product_name,
    sit.total_qty AS top_item_quantity,
    NULL AS item_sk,
    NULL AS item_product_name,
    NULL AS cat_net_paid,
    NULL AS web_net_paid,
    NULL AS total_txns,
    NULL AS avg_cat_price,
    NULL AS avg_web_price,
    NULL AS price_availability
FROM store s
LEFT JOIN store_sales_agg ssa ON s.s_store_sk = ssa.store_sk
LEFT JOIN store_returns_agg sra ON s.s_store_sk = sra.store_sk
LEFT JOIN (
    SELECT store_sk, item_sk, total_qty
    FROM store_item_top
    WHERE rn = 1
) sit ON s.s_store_sk = sit.store_sk
LEFT JOIN item itop ON sit.item_sk = itop.i_item_sk
WHERE s.s_closed_date_sk IS NULL

UNION ALL

SELECT
    'Item' AS record_type,
    ip.i_product_name AS description,
    NULL AS store_sk,
    NULL AS store_full_name,
    NULL AS sales_net_paid,
    NULL AS returns_total,
    NULL AS net_sales_after_returns,
    NULL AS sales_rank,
    NULL AS return_category,
    NULL AS store_age_years,
    NULL AS overall_avg_net_paid,
    NULL AS total_all_store_sales,
    NULL AS pct_of_total_sales,
    NULL AS previous_store_sales,
    NULL AS distinct_items_sold,
    NULL AS top_item_product_name,
    NULL AS top_item_quantity,
    csws.item_sk,
    ip.i_product_name AS item_product_name,
    csws.cat_net_paid,
    csws.web_net_paid,
    csws.total_txns,
    csws.avg_cat_price,
    csws.avg_web_price,
    CASE 
        WHEN csws.avg_cat_price > 0 AND csws.avg_web_price > 0 THEN 'Both Prices'
        WHEN csws.avg_cat_price > 0 THEN 'Catalog Only'
        WHEN csws.avg_web_price > 0 THEN 'Web Only'
        ELSE 'No Price'
    END AS price_availability
FROM cat_web_sales csws
JOIN item_price_stats ip ON csws.item_sk = ip.i_item_sk
WHERE csws.item_sk IS NOT NULL
ORDER BY record_type, description, store_sk, item_sk
