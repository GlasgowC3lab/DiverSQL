WITH site_quarter_profit AS (
    SELECT
        ws.ws_web_site_sk,
        w.web_name,
        w.web_state,
        d.d_current_year,
        d.d_quarter_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS orders_cnt,
        AVG(ws.ws_ext_sales_price) AS avg_sales_price
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2020 AND 2022
    GROUP BY ws.ws_web_site_sk, w.web_name, w.web_state, d.d_current_year, d.d_quarter_name
)
SELECT
    sqp.ws_web_site_sk,
    sqp.web_name,
    sqp.web_state,
    sqp.d_current_year,
    sqp.d_quarter_name,
    sqp.total_profit,
    sqp.orders_cnt,
    sqp.avg_sales_price,
    CASE
        WHEN sqp.total_profit >= 200000 THEN 'Platinum'
        WHEN sqp.total_profit >= 100000 THEN 'Gold'
        WHEN sqp.total_profit >= 50000 THEN 'Silver'
        ELSE 'Bronze'
    END AS profit_tier,
    RANK() OVER (PARTITION BY sqp.d_current_year, sqp.d_quarter_name ORDER BY sqp.total_profit DESC) AS profit_rank
FROM site_quarter_profit sqp
ORDER BY sqp.d_current_year, sqp.d_quarter_name, profit_rank
