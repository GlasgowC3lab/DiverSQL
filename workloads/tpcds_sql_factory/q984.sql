WITH cc_sales AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_state,
        cc.cc_country,
        cc.cc_employees,
        cc.cc_tax_percentage AS cc_tax_pct,
        ws_site.web_tax_percentage AS site_tax_pct,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        CASE WHEN cc.cc_employees = 0 THEN NULL ELSE ROUND(SUM(ws.ws_net_profit) / cc.cc_employees, 2) END AS profit_per_employee
    FROM call_center cc
    JOIN web_site ws_site
        ON cc.cc_country = ws_site.web_country
        AND cc.cc_state = ws_site.web_state
    JOIN web_sales ws
        ON ws.ws_web_site_sk = ws_site.web_site_sk
        AND ws.ws_sold_date_sk BETWEEN cc.cc_open_date_sk AND cc.cc_closed_date_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY cc.cc_call_center_id, cc.cc_name, cc.cc_state, cc.cc_country, cc.cc_employees, cc.cc_tax_percentage, ws_site.web_tax_percentage
)
SELECT
    cc_call_center_id,
    cc_name,
    cc_state,
    cc_country,
    total_profit,
    order_cnt,
    cc_employees,
    profit_per_employee,
    cc_tax_pct,
    site_tax_pct,
    ROUND(total_profit * (site_tax_pct - cc_tax_pct) / 100.0, 2) AS tax_impact_amount,
    CASE
        WHEN profit_per_employee IS NULL THEN 'Insufficient Data'
        WHEN profit_per_employee > 10000 THEN 'Excellent'
        WHEN profit_per_employee > 5000 THEN 'Good'
        WHEN profit_per_employee > 1000 THEN 'Average'
        ELSE 'Poor'
    END AS efficiency_category,
    DENSE_RANK() OVER (ORDER BY profit_per_employee DESC NULLS LAST) AS profit_per_employee_rank
FROM cc_sales
WHERE total_profit > 0
ORDER BY profit_per_employee_rank
