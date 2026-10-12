WITH sales_agg AS (
    SELECT
        d.d_date_sk,
        hd.hd_demo_sk,
        cc.cc_state,
        cc.cc_mkt_class,
        COUNT(DISTINCT cs.cs_order_number) AS num_orders,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit
    FROM
        catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE
        d.d_year = 2022
        AND cc.cc_state IN ('TN','GA','MI')
        AND hd.hd_vehicle_count >= 2
    GROUP BY
        d.d_date_sk,
        hd.hd_demo_sk,
        cc.cc_state,
        cc.cc_mkt_class
),
returns_agg AS (
    SELECT
        d.d_date_sk,
        hd.hd_demo_sk,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(*) AS num_returns
    FROM
        store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE
        d.d_year = 2022
        AND hd.hd_vehicle_count >= 2
    GROUP BY
        d.d_date_sk,
        hd.hd_demo_sk
)
SELECT
    s.cc_state,
    s.cc_mkt_class,
    d.d_date AS sales_date,
    s.num_orders,
    s.total_sales,
    s.total_profit,
    COALESCE(r.num_returns, 0) AS num_returns,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    (s.total_profit - COALESCE(r.total_return_loss, 0)) AS net_margin,
    ROUND((COALESCE(r.total_return_loss, 0) / NULLIF(s.total_profit, 0)) * 100, 2) AS loss_to_profit_pct
FROM
    sales_agg s
    LEFT JOIN returns_agg r
        ON s.d_date_sk = r.d_date_sk
        AND s.hd_demo_sk = r.hd_demo_sk
    JOIN date_dim d ON s.d_date_sk = d.d_date_sk
WHERE
    s.total_profit > 5000
ORDER BY
    net_margin DESC
LIMIT 100
