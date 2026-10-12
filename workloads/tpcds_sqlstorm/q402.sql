WITH sales AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           i.i_category AS category,
           cs.cs_quantity AS quantity,
           cs.cs_net_paid AS revenue,
           cs.cs_net_profit AS profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           i.i_category,
           ss.ss_quantity,
           ss.ss_net_paid,
           ss.ss_net_profit
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           i.i_category,
           ws.ws_quantity,
           ws.ws_net_paid,
           ws.ws_net_profit
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
),
filtered_sales AS (
    SELECT s.*, d.d_year, d.d_quarter_seq
    FROM sales s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
agg AS (
    SELECT
        d_year,
        d_quarter_seq,
        category,
        SUM(quantity) AS total_quantity,
        SUM(revenue) AS total_revenue,
        SUM(profit) AS total_profit
    FROM filtered_sales
    GROUP BY d_year, d_quarter_seq, category
)
SELECT
    d_year,
    d_quarter_seq,
    category,
    total_quantity,
    total_revenue,
    total_profit,
    RANK() OVER (PARTITION BY d_year, d_quarter_seq ORDER BY total_revenue DESC) AS revenue_rank
FROM agg
ORDER BY d_year, d_quarter_seq, revenue_rank
LIMIT 100
