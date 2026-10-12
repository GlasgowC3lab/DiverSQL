WITH sales_agg AS (
    SELECT 
        ca.ca_state AS state,
        d.d_year,
        d.d_month_seq AS month,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(ss.ss_quantity) AS quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2002
    GROUP BY ca.ca_state, d.d_year, d.d_month_seq

    UNION ALL

    SELECT 
        ca.ca_state AS state,
        d.d_year,
        d.d_month_seq AS month,
        SUM(cs.cs_net_profit) AS net_profit,
        SUM(cs.cs_quantity) AS quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2002
    GROUP BY ca.ca_state, d.d_year, d.d_month_seq

    UNION ALL

    SELECT 
        ca.ca_state AS state,
        d.d_year,
        d.d_month_seq AS month,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(ws.ws_quantity) AS quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2002
    GROUP BY ca.ca_state, d.d_year, d.d_month_seq
),
returns_agg AS (
    SELECT 
        ca.ca_state AS state,
        d.d_year,
        d.d_month_seq AS month,
        SUM(sr.sr_net_loss) AS net_loss,
        SUM(sr.sr_return_quantity) AS return_qty
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2002
    GROUP BY ca.ca_state, d.d_year, d.d_month_seq

    UNION ALL

    SELECT 
        ca.ca_state AS state,
        d.d_year,
        d.d_month_seq AS month,
        SUM(cr.cr_net_loss) AS net_loss,
        SUM(cr.cr_return_quantity) AS return_qty
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON cr.cr_returning_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2002
    GROUP BY ca.ca_state, d.d_year, d.d_month_seq

    UNION ALL

    SELECT 
        ca.ca_state AS state,
        d.d_year,
        d.d_month_seq AS month,
        SUM(wr.wr_net_loss) AS net_loss,
        SUM(wr.wr_return_quantity) AS return_qty
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON wr.wr_returning_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2002
    GROUP BY ca.ca_state, d.d_year, d.d_month_seq
),
combined AS (
    SELECT 
        s.state,
        s.d_year,
        s.month,
        SUM(s.net_profit) AS total_net_profit,
        SUM(s.quantity) AS total_quantity,
        SUM(COALESCE(r.net_loss, 0)) AS total_net_loss,
        SUM(COALESCE(r.return_qty, 0)) AS total_return_qty
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.state = r.state
        AND s.d_year = r.d_year
        AND s.month = r.month
    GROUP BY s.state, s.d_year, s.month
)
SELECT 
    state,
    d_year,
    month,
    total_net_profit - total_net_loss AS net_profit_after_returns,
    total_quantity - total_return_qty AS net_quantity,
    ROW_NUMBER() OVER (PARTITION BY d_year, month ORDER BY (total_net_profit - total_net_loss) DESC) AS rank_by_profit
FROM combined
ORDER BY d_year, month, rank_by_profit
LIMIT 100
