WITH returns_agg AS (
    SELECT
        cc.cc_name AS call_center_name,
        d.d_year,
        'return_loss' AS metric,
        SUM(cr.cr_net_loss) AS amount,
        (SELECT COUNT(DISTINCT cc2.cc_call_center_sk) FROM call_center cc2) AS total_call_centers
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE NOT EXISTS (
        SELECT 1 FROM catalog_returns cr2
        WHERE cr2.cr_call_center_sk = cc.cc_call_center_sk
    )
    GROUP BY CUBE (cc.cc_name, d.d_year)
),
sales_agg AS (
    SELECT
        cc.cc_name AS call_center_name,
        d.d_year,
        'sales_profit' AS metric,
        SUM(ss.ss_net_profit) AS amount,
        (SELECT COUNT(DISTINCT cc2.cc_call_center_sk) FROM call_center cc2) AS total_call_centers
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    WHERE NOT EXISTS (
        SELECT 1 FROM catalog_returns cr3
        WHERE cr3.cr_call_center_sk = cc.cc_call_center_sk
    )
      AND ss.ss_net_profit > 0
    GROUP BY CUBE (cc.cc_name, d.d_year)
)
SELECT * FROM returns_agg
UNION ALL
SELECT * FROM sales_agg
LIMIT 100
