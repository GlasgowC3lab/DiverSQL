WITH per_warehouse AS (
    SELECT
        d.d_year,
        w.w_warehouse_name,
        SUM(cs.cs_net_profit) AS sales_profit,
        SUM(cr.cr_net_loss) AS return_loss,
        (SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss)) AS net_profit
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND w.w_state = 'CA'
      AND cs.cs_list_price > 100
      AND ws.ws_ship_date_sk > 2452000
    GROUP BY d.d_year, w.w_warehouse_name
),
per_year AS (
    SELECT
        d_year,
        AVG(net_profit) AS avg_net_profit,
        MAX(net_profit) AS max_net_profit
    FROM per_warehouse
    GROUP BY d_year
    HAVING AVG(net_profit) > 1000
)
SELECT
    d_year,
    avg_net_profit,
    max_net_profit,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY avg_net_profit DESC) AS rank_in_year,
    ROW_NUMBER() OVER (ORDER BY avg_net_profit DESC) AS overall_rank
FROM per_year
ORDER BY avg_net_profit DESC
LIMIT 100
