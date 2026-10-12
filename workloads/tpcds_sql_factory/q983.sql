WITH cc_sales AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_state,
        cc.cc_employees,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        AVG(ws.ws_net_profit) AS avg_profit_per_order,
        MAX(d.d_year) AS latest_year
    FROM call_center cc
    JOIN web_sales ws
        ON ws.ws_sold_date_sk BETWEEN cc.cc_open_date_sk AND cc.cc_closed_date_sk
    JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
        AND cc.cc_country = ws_site.web_country
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY cc.cc_call_center_id, cc.cc_name, cc.cc_state, cc.cc_employees
)
SELECT
    cc_call_center_id,
    cc_name,
    cc_state,
    latest_year,
    total_profit,
    order_cnt,
    avg_profit_per_order,
    CASE
        WHEN total_profit >= 1000000 THEN 'Platinum'
        WHEN total_profit >= 500000 THEN 'Gold'
        WHEN total_profit >= 100000 THEN 'Silver'
        ELSE 'Bronze'
    END AS profit_tier,
    DENSE_RANK() OVER (ORDER BY total_profit DESC) AS profit_rank,
    ROUND(total_profit / NULLIF(cc_employees, 0), 2) AS profit_per_employee,
    ROUND(total_profit * 100.0 / SUM(total_profit) OVER (), 2) AS profit_pct_of_total
FROM cc_sales
WHERE total_profit > 0
ORDER BY profit_rank
