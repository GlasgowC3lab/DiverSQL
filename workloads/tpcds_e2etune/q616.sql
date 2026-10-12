WITH catalog_agg AS (
    SELECT
        cs.cs_call_center_sk AS cs_call_center_sk,
        cs.cs_warehouse_sk AS cs_warehouse_sk,
        td.t_hour,
        SUM(cs.cs_net_paid_inc_tax) AS net_paid,
        SUM(cs.cs_net_profit) AS net_profit
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND cc.cc_market_manager IN ('Julius Tran', 'Gary Colburn')
      AND cc.cc_country = 'United States'
      AND cc.cc_rec_start_date >= DATE '2000-01-01'
    GROUP BY cs.cs_call_center_sk, cs.cs_warehouse_sk, td.t_hour
),
web_agg AS (
    SELECT
        NULL AS cs_call_center_sk,
        ws.ws_warehouse_sk AS cs_warehouse_sk,
        td.t_hour,
        SUM(ws.ws_net_paid_inc_tax) AS net_paid,
        SUM(ws.ws_net_profit) AS net_profit
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
    GROUP BY ws.ws_warehouse_sk, td.t_hour
),
sales_combined AS (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM web_agg
),
returns_agg AS (
    SELECT
        td.t_hour,
        SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc IN ('Customer Not Satisfied', 'Damaged Item')
    GROUP BY td.t_hour
)
SELECT
    COALESCE(cc.cc_market_manager, 'Web Sales') AS market_manager,
    w.w_city,
    sc.t_hour,
    SUM(sc.net_paid) AS total_net_paid,
    SUM(sc.net_profit) AS total_net_profit,
    COALESCE(MAX(r.total_return_loss), 0) AS total_return_loss,
    (SUM(sc.net_profit) - COALESCE(MAX(r.total_return_loss), 0)) AS net_profit_after_returns
FROM sales_combined sc
LEFT JOIN call_center cc ON sc.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w ON sc.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN returns_agg r ON sc.t_hour = r.t_hour
GROUP BY COALESCE(cc.cc_market_manager, 'Web Sales'), w.w_city, sc.t_hour
ORDER BY net_profit_after_returns DESC
LIMIT 20
