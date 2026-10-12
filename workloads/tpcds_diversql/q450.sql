WITH sampled_inventory AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (10)
),

order_diff AS (
    SELECT cr_order_number AS order_number
    FROM catalog_returns
    EXCEPT
    SELECT ws_order_number AS order_number
    FROM web_sales
),

joined_data AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cc.cc_state,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        p.p_end_date_sk,
        sm.sm_type,
        w.w_warehouse_id,
        i.inv_quantity_on_hand,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        wr.wr_return_amt,
        ARRAY[cs.cs_quantity, cs.cs_ext_sales_price] AS cs_metrics
    FROM catalog_returns cr
    FULL OUTER JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN sampled_inventory i
        ON w.w_warehouse_sk = i.inv_warehouse_sk
    LEFT JOIN web_sales ws
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    WHERE
        hd.hd_income_band_sk IN (5, 10)
        AND cd.cd_purchase_estimate > 5000
        AND p.p_end_date_sk < 2450300
        AND cc.cc_state = 'TX'
        AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450500
),

metrics_agg AS (
    SELECT
        jd.cr_order_number AS order_number,
        AVG(metric) AS avg_metric_value
    FROM joined_data jd
    CROSS JOIN UNNEST(jd.cs_metrics) AS t(metric)
    GROUP BY jd.cr_order_number
),

aggregated AS (
    SELECT
        jd.cc_state,
        jd.sm_type,
        COUNT(DISTINCT jd.cd_purchase_estimate) AS distinct_purchase_estimates,
        COUNT(DISTINCT jd.p_end_date_sk) AS distinct_promo_end_dates,
        SUM(jd.cs_ext_sales_price) AS total_cs_sales,
        SUM(jd.ws_quantity) AS total_ws_quantity,
        AVG(jd.cr_return_amount) AS avg_return_amount,
        jd.cr_order_number AS order_number
    FROM joined_data jd
    GROUP BY jd.cc_state, jd.sm_type, jd.cr_order_number
),

final AS (
    SELECT
        a.cc_state,
        a.sm_type,
        a.distinct_purchase_estimates,
        a.distinct_promo_end_dates,
        a.total_cs_sales,
        a.total_ws_quantity,
        a.avg_return_amount,
        a.order_number,
        m.avg_metric_value
    FROM aggregated a
    INNER JOIN order_diff od
        ON a.order_number = od.order_number
    LEFT JOIN metrics_agg m
        ON a.order_number = m.order_number
    WHERE a.total_cs_sales > 1000
)
SELECT
    f.cc_state,
    f.sm_type,
    f.distinct_purchase_estimates,
    f.distinct_promo_end_dates,
    f.total_cs_sales,
    f.total_ws_quantity,
    f.avg_return_amount,
    f.order_number,
    f.avg_metric_value
FROM final f
ORDER BY f.total_cs_sales DESC
LIMIT 100
