WITH sales_agg AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_hdemo_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        ARRAY[SUM(ss.ss_quantity), SUM(ss.ss_ext_sales_price)] AS metrics
    FROM store_sales ss
    GROUP BY ss.ss_sold_date_sk, ss.ss_store_sk, ss.ss_item_sk, ss.ss_hdemo_sk
),
returns_agg AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_call_center_sk,
        cr.cr_catalog_page_sk,
        cr.cr_item_sk,
        cr.cr_refunded_hdemo_sk,
        SUM(cr.cr_return_amount) AS total_returns,
        ARRAY[SUM(cr.cr_return_quantity), SUM(cr.cr_return_amount)] AS metrics
    FROM catalog_returns cr
    GROUP BY cr.cr_returned_date_sk, cr.cr_call_center_sk, cr.cr_catalog_page_sk, cr.cr_item_sk, cr.cr_refunded_hdemo_sk
),
union_all_data AS (
    -- Sales side
    SELECT
        d.d_year,
        s.s_store_name,
        i.i_item_id,
        i.i_brand,
        hd.hd_income_band_sk,
        cc.cc_name,
        cp.cp_catalog_number,
        ws.web_name,
        sales_agg.total_sales AS amount,
        metric_val,
        lt.line_total
    FROM sales_agg
    JOIN store s ON sales_agg.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON sales_agg.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON sales_agg.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON sales_agg.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN LATERAL (
        SELECT sales_agg.total_sales * 0.10 AS line_total
    ) lt ON TRUE
    CROSS JOIN UNNEST(sales_agg.metrics) AS t(metric_val)
    FULL OUTER JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    FULL OUTER JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    UNION DISTINCT
    -- Returns side
    SELECT
        d2.d_year,
        NULL AS s_store_name,
        i2.i_item_id,
        i2.i_brand,
        hd2.hd_income_band_sk,
        cc2.cc_name,
        cp2.cp_catalog_number,
        ws2.web_name,
        returns_agg.total_returns AS amount,
        metric_val2,
        lt2.line_total
    FROM returns_agg
    JOIN date_dim d2 ON returns_agg.cr_returned_date_sk = d2.d_date_sk
    JOIN item i2 ON returns_agg.cr_item_sk = i2.i_item_sk
    JOIN household_demographics hd2 ON returns_agg.cr_refunded_hdemo_sk = hd2.hd_demo_sk
    JOIN call_center cc2 ON returns_agg.cr_call_center_sk = cc2.cc_call_center_sk
    JOIN catalog_page cp2 ON returns_agg.cr_catalog_page_sk = cp2.cp_catalog_page_sk
    LEFT JOIN LATERAL (
        SELECT returns_agg.total_returns * 0.20 AS line_total
    ) lt2 ON TRUE
    CROSS JOIN UNNEST(returns_agg.metrics) AS t2(metric_val2)
    LEFT JOIN web_site ws2 ON ws2.web_open_date_sk = d2.d_date_sk
),
final_set AS (
    SELECT * FROM union_all_data
    INTERSECT
    SELECT * FROM union_all_data
)
SELECT *
FROM final_set
ORDER BY d_year DESC, amount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
