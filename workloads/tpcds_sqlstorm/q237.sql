WITH intersect_items AS (
    SELECT ss.ss_item_sk AS item_sk, ss.ss_sold_date_sk AS date_sk
    FROM store_sales ss
    INTERSECT
    SELECT ws.ws_item_sk, ws.ws_sold_date_sk
    FROM web_sales ws
),
unified_sales AS (
    SELECT 
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_quantity AS quantity,
        cs.cs_sales_price * cs.cs_quantity AS revenue,
        CASE WHEN cs.cs_quantity > 0 THEN cs.cs_ext_discount_amt / cs.cs_quantity ELSE NULL END AS avg_discount,
        cs.cs_promo_sk AS promo_sk,
        'Catalog' AS sales_channel,
        cs.cs_order_number AS order_num,
        cs.cs_call_center_sk AS call_center_sk
    FROM catalog_sales cs
    UNION ALL
    SELECT 
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_sales_price * ss.ss_quantity,
        CASE WHEN ss.ss_quantity > 0 THEN ss.ss_ext_discount_amt / ss.ss_quantity ELSE NULL END,
        ss.ss_promo_sk,
        'Store',
        ss.ss_ticket_number,
        NULL
    FROM store_sales ss
    UNION ALL
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price * ws.ws_quantity,
        CASE WHEN ws.ws_quantity > 0 THEN ws.ws_ext_discount_amt / ws.ws_quantity ELSE NULL END,
        ws.ws_promo_sk,
        'Web',
        ws.ws_order_number,
        NULL
    FROM web_sales ws
),
sales_with_flag AS (
    SELECT us.*, CASE WHEN ii.item_sk IS NOT NULL THEN 1 ELSE 0 END AS in_both_store_web_flag
    FROM unified_sales us
    LEFT JOIN intersect_items ii
      ON us.item_sk = ii.item_sk AND us.date_sk = ii.date_sk
),
date_enriched AS (
    SELECT swf.*,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq,
        d.d_holiday,
        d.d_weekend,
        CASE 
            WHEN d.d_holiday = 'Y' THEN 1 
            WHEN d.d_weekend = 'Y' THEN 0.5 
            ELSE 0 
        END AS holiday_weight
    FROM sales_with_flag swf
    LEFT JOIN date_dim d
      ON swf.date_sk = d.d_date_sk
),
promo_details AS (
    SELECT de.*,
        p.p_promo_name,
        p.p_discount_active,
        COALESCE(p.p_discount_active, 'N') AS discount_active_flag,
        CASE 
            WHEN p.p_promo_name IS NULL THEN 'No Promo' 
            ELSE p.p_promo_name 
        END AS promo_desc
    FROM date_enriched de
    LEFT JOIN promotion p 
      ON de.promo_sk = p.p_promo_sk
),
item_enriched AS (
    SELECT pd.*,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        i.i_color,
        i.i_size,
        concat('Item-', i.i_item_id, '-', COALESCE(i.i_color, 'UNC'), '-', substring(i.i_product_name, 1, 5)) AS fancy_item_code,
        COALESCE(i.i_size, 'UNKNOWN') AS size_clean,
        CASE 
            WHEN i.i_color IS NULL AND i.i_size IS NULL THEN 'MYSTERY'
            WHEN i.i_color = '' THEN 'NO-COLOR'
            ELSE i.i_color
        END AS color_flag,
        CASE 
            WHEN regexp_like(i.i_brand, '\\d') THEN 'BRAND_HAS_DIGIT'
            ELSE 'BRAND_NO_DIGIT'
        END AS brand_digit_flag
    FROM promo_details pd
    LEFT JOIN item i
      ON pd.item_sk = i.i_item_sk
),
call_center_info AS (
    SELECT ie.*,
        cc.cc_name,
        cc.cc_manager,
        cc.cc_gmt_offset,
        CASE 
            WHEN cc.cc_manager IS NULL THEN 'UNKNOWN'
            ELSE substring(cc.cc_manager, 1, 3)
        END AS manager_initials
    FROM item_enriched ie
    LEFT JOIN call_center cc
      ON ie.call_center_sk = cc.cc_call_center_sk
),
ranked_sales AS (
    SELECT cci.*,
        cci.revenue * (1 + cci.holiday_weight) AS weighted_revenue,
        SUM(cci.revenue) OVER (PARTITION BY cci.d_year, cci.d_month_seq) AS month_total_rev,
        ROW_NUMBER() OVER (PARTITION BY cci.d_year, cci.d_month_seq ORDER BY cci.revenue * (1 + cci.holiday_weight) DESC) AS revenue_rank,
        SUM(cci.quantity) OVER (PARTITION BY cci.sales_channel ORDER BY cci.d_date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_quantity_by_channel,
        CASE 
            WHEN cci.avg_discount IS NULL THEN 0 
            WHEN cci.avg_discount < 0 THEN -1 
            ELSE 1 
        END * (cci.quantity + COALESCE(cci.avg_discount, 0)) AS custom_metric
    FROM call_center_info cci
),
promo_joined AS (
    SELECT rs.*, p.p_promo_name AS promo_name_from_right
    FROM promotion p
    RIGHT JOIN ranked_sales rs
      ON p.p_promo_sk = rs.promo_sk
)
SELECT 
    pj.d_year,
    pj.d_month_seq,
    pj.sales_channel,
    pj.fancy_item_code,
    pj.brand_digit_flag,
    pj.color_flag,
    pj.manager_initials,
    pj.weighted_revenue,
    pj.month_total_rev,
    pj.revenue_rank,
    pj.cum_quantity_by_channel,
    pj.custom_metric,
    (SELECT MAX(r2.revenue_rank) FROM ranked_sales r2 WHERE r2.sales_channel = pj.sales_channel AND r2.d_year = pj.d_year AND r2.d_month_seq = pj.d_month_seq) AS max_rank_in_channel_month,
    CASE 
        WHEN pj.revenue_rank = (SELECT MAX(r2.revenue_rank) FROM ranked_sales r2 WHERE r2.sales_channel = pj.sales_channel AND r2.d_year = pj.d_year AND r2.d_month_seq = pj.d_month_seq) 
        THEN pj.weighted_revenue 
        ELSE nullif(pj.weighted_revenue, pj.weighted_revenue) 
    END AS top_revenue_or_null,
    pj.in_both_store_web_flag,
    CASE 
        WHEN pj.revenue = 0 OR pj.revenue IS NULL THEN NULL 
        ELSE (pj.quantity - COALESCE(pj.avg_discount,0)) / pj.revenue 
    END AS strange_ratio,
    pj.promo_name_from_right
FROM promo_joined pj
WHERE pj.revenue_rank <= 10
  AND (pj.d_holiday = 'Y' OR pj.d_weekend = 'Y' OR pj.sales_channel = 'Web')
UNION ALL
SELECT 
    CAST(NULL AS integer) AS d_year,
    CAST(NULL AS integer) AS d_month_seq,
    CAST(NULL AS varchar) AS sales_channel,
    CAST(NULL AS varchar) AS fancy_item_code,
    CAST(NULL AS varchar) AS brand_digit_flag,
    CAST(NULL AS varchar) AS color_flag,
    CAST(NULL AS varchar) AS manager_initials,
    CAST(NULL AS decimal(15,2)) AS weighted_revenue,
    CAST(NULL AS decimal(15,2)) AS month_total_rev,
    CAST(NULL AS integer) AS revenue_rank,
    CAST(NULL AS bigint) AS cum_quantity_by_channel,
    CAST(NULL AS decimal(15,2)) AS custom_metric,
    CAST(NULL AS integer) AS max_rank_in_channel_month,
    CAST(NULL AS decimal(15,2)) AS top_revenue_or_null,
    CAST(NULL AS integer) AS in_both_store_web_flag,
    CAST(NULL AS decimal(15,2)) AS strange_ratio,
    CAST(NULL AS varchar) AS promo_name_from_right
WHERE false
