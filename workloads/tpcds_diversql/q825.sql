WITH sales_returns AS (
    SELECT
        s.s_store_name,
        i.i_category,
        d.d_month_seq,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(cr.cr_return_amount) AS total_returns
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN web_site w ON d.d_date_sk = w.web_open_date_sk
    JOIN call_center cc ON d.d_date_sk = cc.cc_closed_date_sk
    JOIN catalog_page cp ON d.d_date_sk = cp.cp_start_date_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_item_sk = i.i_item_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
        AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        AND cr.cr_call_center_sk = cc.cc_call_center_sk
        AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND i.i_brand_id = 3002001
      AND s.s_gmt_offset BETWEEN -5.00 AND 5.00
      AND cc.cc_market_manager = 'James Smith'
      AND sm.sm_type = 'AIR'
      AND r.r_reason_desc LIKE '%damaged%'
    GROUP BY GROUPING SETS
        ((s.s_store_name, i.i_category, d.d_month_seq),
         (s.s_store_name, i.i_category),
         (s.s_store_name),
         ())
),
qualified_stores AS (
    SELECT s_store_name FROM sales_returns WHERE total_sales > 100000
    INTERSECT
    SELECT s_store_name FROM sales_returns WHERE total_returns < 5000
),
final_agg AS (
    SELECT
        sr.s_store_name,
        SUM(sr.total_sales) AS sum_sales,
        SUM(sr.total_returns) AS sum_returns,
        SUM(sr.total_sales - COALESCE(sr.total_returns, 0)) AS net_sales
    FROM sales_returns sr
    WHERE sr.s_store_name IN (SELECT s_store_name FROM qualified_stores)
    GROUP BY sr.s_store_name
    HAVING SUM(sr.total_sales) > (SELECT AVG(total_sales) FROM sales_returns)
)
SELECT
    f.s_store_name,
    f.sum_sales,
    f.sum_returns,
    f.net_sales,
    f.net_sales / NULLIF(f.sum_sales, 0) AS net_margin
FROM final_agg f
ORDER BY f.net_sales DESC, f.s_store_name
LIMIT 100
