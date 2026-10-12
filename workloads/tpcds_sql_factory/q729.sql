WITH combined_sales AS (
    SELECT
        cs.cs_warehouse_sk AS warehouse_sk,
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_ext_ship_cost AS ext_ship_cost,
        cs.cs_net_paid_inc_ship_tax AS net_paid_inc_ship_tax
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ws.ws_warehouse_sk AS warehouse_sk,
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_ext_ship_cost AS ext_ship_cost,
        ws.ws_net_paid_inc_ship_tax AS net_paid_inc_ship_tax
    FROM web_sales ws
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
),
 daily_agg AS (
    SELECT
        warehouse_sk,
        sold_date_sk,
        SUM(ext_ship_cost) AS total_ext_ship_cost,
        AVG(ext_ship_cost) AS avg_ext_ship_cost,
        SUM(net_paid_inc_ship_tax) AS total_net_paid_inc_ship_tax
    FROM combined_sales
    GROUP BY warehouse_sk, sold_date_sk
)
SELECT
    w.w_warehouse_sk,
    w.w_warehouse_name,
    d.sold_date_sk,
    d.total_ext_ship_cost,
    CASE
        WHEN d.avg_ext_ship_cost >= 1000 THEN 'High'
        WHEN d.avg_ext_ship_cost >= 500 THEN 'Medium'
        ELSE 'Low'
    END AS ship_cost_category,
    d.total_net_paid_inc_ship_tax,
    LAG(d.total_net_paid_inc_ship_tax) OVER (PARTITION BY w.w_warehouse_sk ORDER BY d.sold_date_sk) AS lag_total_net_paid,
    LEAD(d.total_net_paid_inc_ship_tax) OVER (PARTITION BY w.w_warehouse_sk ORDER BY d.sold_date_sk) AS lead_total_net_paid,
    AVG(d.total_net_paid_inc_ship_tax) OVER (
        PARTITION BY w.w_warehouse_sk
        ORDER BY d.sold_date_sk
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg_3_days
FROM daily_agg d
JOIN warehouse w ON d.warehouse_sk = w.w_warehouse_sk
ORDER BY w.w_warehouse_sk, d.sold_date_sk
LIMIT 200
