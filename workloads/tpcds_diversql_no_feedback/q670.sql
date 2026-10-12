WITH cat_ret_agg AS (
    SELECT
        cr_item_sk,
        cr_reason_sk,
        SUM(cr_return_amount)      AS total_return_amount,
        SUM(cr_return_quantity)    AS total_return_qty
    FROM catalog_returns
    GROUP BY cr_item_sk, cr_reason_sk
)
,
union_data AS (
    SELECT
        d.d_year,
        i.i_category,
        cc.cc_state,
        sm.sm_type,
        r.r_reason_desc,
        SUM(cs.cs_ext_sales_price)      AS total_sales,
        SUM(cat_ret_agg.total_return_amount) AS total_returns,
        COUNT(DISTINCT cs.cs_order_number)    AS order_cnt
    FROM date_dim d
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN cat_ret_agg
        ON cat_ret_agg.cr_item_sk = cs.cs_item_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN reason r
        ON cat_ret_agg.cr_reason_sk = r.r_reason_sk
    LEFT JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
       AND ss.ss_quantity > 5
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
       AND wr.wr_return_quantity > 1
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND cc.cc_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND r.r_reason_desc = 'Customer Not Available'
      AND cs.cs_ext_sales_price > (
          SELECT AVG(cr_return_amount) FROM catalog_returns
      )
    GROUP BY d.d_year, i.i_category, cc.cc_state, sm.sm_type, r.r_reason_desc

    UNION DISTINCT

    SELECT
        d.d_year,
        i.i_category,
        cc.cc_state,
        sm.sm_type,
        r.r_reason_desc,
        SUM(cs.cs_ext_sales_price)      AS total_sales,
        SUM(cat_ret_agg.total_return_amount) AS total_returns,
        COUNT(DISTINCT cs.cs_order_number)    AS order_cnt
    FROM date_dim d
    JOIN catalog_sales cs
        ON cs.cs_ship_date_sk = d.d_date_sk
    JOIN cat_ret_agg
        ON cat_ret_agg.cr_item_sk = cs.cs_item_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN reason r
        ON cat_ret_agg.cr_reason_sk = r.r_reason_sk
    LEFT JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
       AND ss.ss_quantity > 5
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
       AND wr.wr_return_quantity > 1
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND cc.cc_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND r.r_reason_desc = 'Customer Not Available'
      AND cs.cs_ext_sales_price > (
          SELECT AVG(cr_return_amount) FROM catalog_returns
      )
    GROUP BY d.d_year, i.i_category, cc.cc_state, sm.sm_type, r.r_reason_desc
)
SELECT
    u.d_year,
    u.i_category,
    u.cc_state,
    u.sm_type,
    u.r_reason_desc,
    SUM(u.total_sales)   AS sum_sales,
    SUM(u.total_returns) AS sum_returns,
    COUNT(*)             AS union_rows,
    AVG(u.total_sales)   AS avg_sales_per_row
FROM union_data u
GROUP BY u.d_year, u.i_category, u.cc_state, u.sm_type, u.r_reason_desc
ORDER BY sum_sales DESC
LIMIT 100
