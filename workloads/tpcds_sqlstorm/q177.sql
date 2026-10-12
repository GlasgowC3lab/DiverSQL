WITH
date_range AS (
    SELECT d_date_sk,
           d_date,
           d_year,
           d_month_seq
    FROM date_dim
    WHERE d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
),
item_filtered AS (
    SELECT i_item_sk,
           i_product_name,
           i_brand,
           i_category,
           i_current_price
    FROM item
    WHERE i_brand = 'Brand#12' OR i_category = 'Sports'
),
sales_per_channel AS (
    SELECT
        dr.d_year,
        dr.d_month_seq,
        i.i_item_sk,
        'CAT' AS channel,
        SUM(cs.cs_ext_sales_price) AS sales_amount,
        SUM(cs.cs_net_profit) AS profit_amount,
        SUM(cs.cs_quantity) AS qty,
        MAX(cs.cs_call_center_sk) AS call_center_sk
    FROM catalog_sales cs
    JOIN date_range dr ON cs.cs_sold_date_sk = dr.d_date_sk
    JOIN item_filtered i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY GROUPING SETS ((dr.d_year, dr.d_month_seq, i.i_item_sk), (dr.d_year))

    UNION ALL

    SELECT
        dr.d_year,
        dr.d_month_seq,
        i.i_item_sk,
        'STORE' AS channel,
        SUM(ss.ss_ext_sales_price) AS sales_amount,
        SUM(ss.ss_net_profit) AS profit_amount,
        SUM(ss.ss_quantity) AS qty,
        NULL AS call_center_sk
    FROM store_sales ss
    JOIN date_range dr ON ss.ss_sold_date_sk = dr.d_date_sk
    JOIN item_filtered i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY GROUPING SETS ((dr.d_year, dr.d_month_seq, i.i_item_sk), (dr.d_year))

    UNION ALL

    SELECT
        dr.d_year,
        dr.d_month_seq,
        i.i_item_sk,
        'WEB' AS channel,
        SUM(ws.ws_ext_sales_price) AS sales_amount,
        SUM(ws.ws_net_profit) AS profit_amount,
        SUM(ws.ws_quantity) AS qty,
        NULL AS call_center_sk
    FROM web_sales ws
    JOIN date_range dr ON ws.ws_sold_date_sk = dr.d_date_sk
    JOIN item_filtered i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY GROUPING SETS ((dr.d_year, dr.d_month_seq, i.i_item_sk), (dr.d_year))
),
returns_per_channel AS (
    SELECT
        dr.d_year,
        dr.d_month_seq,
        i.i_item_sk,
        'CAT' AS channel,
        COALESCE(SUM(cr.cr_return_quantity),0) AS ret_qty,
        COALESCE(SUM(cr.cr_net_loss),0) AS ret_loss
    FROM catalog_returns cr
    JOIN date_range dr ON cr.cr_returned_date_sk = dr.d_date_sk
    JOIN item_filtered i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY GROUPING SETS ((dr.d_year, dr.d_month_seq, i.i_item_sk), (dr.d_year))

    UNION ALL

    SELECT
        dr.d_year,
        dr.d_month_seq,
        i.i_item_sk,
        'STORE' AS channel,
        COALESCE(SUM(sr.sr_return_quantity),0) AS ret_qty,
        COALESCE(SUM(sr.sr_net_loss),0) AS ret_loss
    FROM store_returns sr
    JOIN date_range dr ON sr.sr_returned_date_sk = dr.d_date_sk
    JOIN item_filtered i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY GROUPING SETS ((dr.d_year, dr.d_month_seq, i.i_item_sk), (dr.d_year))

    UNION ALL

    SELECT
        dr.d_year,
        dr.d_month_seq,
        i.i_item_sk,
        'WEB' AS channel,
        COALESCE(SUM(wr.wr_return_quantity),0) AS ret_qty,
        COALESCE(SUM(wr.wr_net_loss),0) AS ret_loss
    FROM web_returns wr
    JOIN date_range dr ON wr.wr_returned_date_sk = dr.d_date_sk
    JOIN item_filtered i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY GROUPING SETS ((dr.d_year, dr.d_month_seq, i.i_item_sk), (dr.d_year))
),
promo_latest AS (
    SELECT
        i.i_item_sk,
        MAX(p.p_start_date_sk) AS latest_promo_start_sk,
        MAX(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) AS promo_active_flag
    FROM item_filtered i
    LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk
),
call_center_filtered AS (
    SELECT cc_call_center_sk,
           cc_name
    FROM call_center
    WHERE cc_name LIKE '%Center%' ESCAPE '\'
),
combined AS (
    SELECT
        sp.d_year,
        sp.d_month_seq,
        sp.i_item_sk,
        sp.channel,
        sp.sales_amount,
        sp.profit_amount,
        sp.qty,
        COALESCE(rp.ret_qty,0) AS ret_qty,
        COALESCE(rp.ret_loss,0) AS ret_loss,
        CASE
            WHEN sp.sales_amount = 0 THEN NULL
            ELSE (sp.profit_amount - COALESCE(rp.ret_loss,0)) / NULLIF(sp.sales_amount,0)
        END AS profit_margin,
        pl.promo_active_flag,
        cc.cc_name AS call_center_name
    FROM sales_per_channel sp
    LEFT JOIN returns_per_channel rp
        ON rp.d_year = sp.d_year
        AND rp.d_month_seq IS NOT DISTINCT FROM sp.d_month_seq
        AND rp.i_item_sk IS NOT DISTINCT FROM sp.i_item_sk
        AND rp.channel = sp.channel
    LEFT JOIN promo_latest pl
        ON pl.i_item_sk = sp.i_item_sk
    LEFT JOIN call_center_filtered cc
        ON cc.cc_call_center_sk = sp.call_center_sk
    WHERE (sp.sales_amount IS NOT NULL AND sp.sales_amount > 0)
          OR sp.channel = 'CAT'
),
ranked AS (
    SELECT
        c.*,
        ROW_NUMBER() OVER (PARTITION BY c.d_year ORDER BY c.profit_amount DESC) AS profit_rank_year,
        NTILE(4) OVER (PARTITION BY c.d_year ORDER BY c.profit_margin NULLS LAST) AS profit_quartile,
        CONCAT('Item-', LPAD(CAST(c.i_item_sk AS VARCHAR), 10, '0')) AS item_key,
        CASE 
            WHEN c.promo_active_flag = 1 THEN 'PROMO' 
            ELSE 'NONE' 
        END AS promo_status,
        CASE 
            WHEN c.profit_margin IS NULL THEN 'No Sales'
            WHEN c.profit_margin < 0 THEN 'Loss'
            WHEN c.profit_margin < 0.05 THEN 'Low'
            WHEN c.profit_margin < 0.15 THEN 'Medium'
            ELSE 'High'
        END AS profit_category,
        LAG(c.profit_margin) OVER (PARTITION BY c.i_item_sk ORDER BY c.d_year, c.d_month_seq) AS prev_month_profit_margin,
        ROW_NUMBER() OVER (ORDER BY c.profit_amount DESC) AS global_profit_rank,
        TRY_CAST(SUBSTRING(CONCAT('X', CONCAT('Item-', LPAD(CAST(c.i_item_sk AS VARCHAR), 10, '0'))) FROM 2) AS BIGINT) AS item_key_numeric,
        CASE 
            WHEN c.call_center_name IS NOT NULL THEN UPPER(c.call_center_name)
            ELSE NULL
        END AS call_center_name_upper
    FROM combined c
    WHERE EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_item_sk = c.i_item_sk
          AND p.p_cost > 0
    )
)
SELECT
    r.d_year,
    r.d_month_seq,
    r.i_item_sk,
    r.item_key,
    r.channel,
    r.sales_amount,
    r.profit_amount,
    r.qty,
    r.ret_qty,
    r.ret_loss,
    r.profit_margin,
    r.prev_month_profit_margin,
    r.profit_rank_year,
    r.profit_quartile,
    r.promo_status,
    r.profit_category,
    r.call_center_name_upper,
    r.item_key_numeric
FROM ranked r
WHERE r.global_profit_rank <= 100
ORDER BY r.global_profit_rank
