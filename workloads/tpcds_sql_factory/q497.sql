WITH sales_agg AS (
    SELECT
        d_open.d_year AS cc_open_year,
        cc.cc_division,
        cc.cc_division_name,
        AVG(cc.cc_employees) AS avg_employees,
        SUM(CASE WHEN ss.ss_net_profit > 0 THEN ss.ss_net_profit ELSE 0 END) AS total_positive_profit
    FROM store_sales ss
    JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN call_center cc ON d_sold.d_date_sk BETWEEN cc.cc_open_date_sk AND cc.cc_closed_date_sk
    JOIN date_dim d_open ON cc.cc_open_date_sk = d_open.d_date_sk
    JOIN catalog_page cp ON d_sold.d_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
    WHERE cp.cp_type = 'Promotion'
    GROUP BY d_open.d_year, cc.cc_division, cc.cc_division_name
    HAVING SUM(CASE WHEN ss.ss_net_profit > 0 THEN ss.ss_net_profit ELSE 0 END) > 0
)
SELECT
    cc_open_year,
    cc_division,
    cc_division_name,
    avg_employees,
    total_positive_profit,
    RANK() OVER (PARTITION BY cc_open_year ORDER BY total_positive_profit DESC) AS profit_rank_by_year,
    DENSE_RANK() OVER (ORDER BY avg_employees DESC) AS employee_density_rank
FROM sales_agg
ORDER BY cc_open_year, profit_rank_by_year
