WITH
date_feb1998 AS (
    SELECT d_date_sk,
           d_date,
           d_year,
           d_month_seq,
           d_week_seq,
           d_day_name,
           d_holiday,
           CASE WHEN d_dow = 6 THEN true ELSE false END AS is_saturday_feb
    FROM date_dim
    WHERE d_year = 1998
      AND d_moy = 2
),
call_center_ex AS (
    SELECT cc_call_center_sk,
           concat(cc_name, ' ', COALESCE(cc_manager, ''), ' ', cc_state) AS cc_full_desc,
           CASE WHEN cc_gmt_offset < -5 THEN 'WEST' ELSE 'EAST' END AS region,
           nullif(cc_tax_percentage, 0) AS tax_pct_nonzero
    FROM call_center
    WHERE cc_closed_date_sk IS NULL OR cc_closed_date_sk > (SELECT MAX(d_date_sk) FROM date_feb1998)
),
store_sales_agg AS (
    SELECT
        ss.ss_item_sk AS item_sk,
        dd.d_year,
        SUM(ss.ss_quantity) AS total_qty,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        COUNT(*) AS txn_cnt,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_item_sk ORDER BY SUM(ss.ss_net_paid) DESC) AS rn_item
    FROM store_sales ss
    JOIN date_feb1998 dd ON ss.ss_sold_date_sk = dd.d_date_sk
    GROUP BY ss.ss_item_sk, dd.d_year
),
catalog_sales_agg AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        dd.d_year,
        SUM(cs.cs_quantity) AS total_qty,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        COUNT(*) AS txn_cnt,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_net_paid) DESC) AS rn_item
    FROM catalog_sales cs
    JOIN date_feb1998 dd ON cs.cs_sold_date_sk = dd.d_date_sk
    LEFT JOIN call_center_ex cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    GROUP BY cs.cs_item_sk, dd.d_year
),
combined_sales AS (
    SELECT item_sk, d_year, total_qty, total_net_paid, total_discount, txn_cnt, 'store' AS src
    FROM store_sales_agg
    UNION ALL
    SELECT item_sk, d_year, total_qty, total_net_paid, total_discount, txn_cnt, 'catalog' AS src
    FROM catalog_sales_agg
),
sales_rank AS (
    SELECT *,
           RANK() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS year_rank,
           SUM(total_net_paid) OVER (PARTITION BY src) AS src_total_net_paid
    FROM combined_sales
),
common_items AS (
    SELECT item_sk FROM store_sales_agg
    INTERSECT
    SELECT item_sk FROM catalog_sales_agg
),
item_detail AS (
    SELECT i.i_item_sk,
           i.i_product_name,
           i.i_brand,
           i.i_category,
           i.i_color,
           i.i_current_price,
           i.i_units,
           CASE WHEN i.i_units IS NULL THEN 'UNKNOWN' ELSE i.i_units END AS unit_desc,
           concat(i.i_brand, '_', i.i_category, '_', coalesce(i.i_color, 'NO_COLOR')) AS brand_category_key
    FROM item i
    WHERE i.i_item_sk IN (SELECT item_sk FROM common_items)
),
returns_flag AS (
    SELECT
        sr.sr_item_sk AS item_sk,
        MAX(d.d_year) AS last_return_year,
        MAX(CASE WHEN sr.sr_return_quantity IS NOT NULL THEN 1 ELSE 0 END) AS has_return
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY sr.sr_item_sk
),
promo_info AS (
    SELECT p.p_item_sk AS item_sk,
           MIN(p.p_start_date_sk) AS promo_start_sk,
           MAX(p.p_end_date_sk) AS promo_end_sk,
           COUNT(*) AS promo_count,
           array_join(array_agg(p.p_promo_name ORDER BY p.p_start_date_sk), ',') AS promo_names
    FROM promotion p
    GROUP BY p.p_item_sk
),
final_report AS (
    SELECT
        dr.d_year,
        id.i_product_name,
        id.i_brand,
        id.i_category,
        id.i_color,
        id.i_current_price,
        sr.total_qty,
        sr.total_net_paid,
        sr.total_discount,
        sr.txn_cnt,
        sr.src,
        sr.year_rank,
        sr.src_total_net_paid,
        rf.last_return_year,
        rf.has_return,
        pi.promo_start_sk,
        pi.promo_end_sk,
        pi.promo_count,
        pi.promo_names
    FROM sales_rank sr
    JOIN date_feb1998 dr ON sr.d_year = dr.d_year
    JOIN item_detail id ON sr.item_sk = id.i_item_sk
    LEFT JOIN returns_flag rf ON sr.item_sk = rf.item_sk
    LEFT JOIN promo_info pi ON sr.item_sk = pi.item_sk
    WHERE sr.year_rank <= 10
)
SELECT *
FROM final_report
ORDER BY d_year, year_rank
