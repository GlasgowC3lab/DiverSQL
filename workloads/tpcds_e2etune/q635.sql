WITH sales_agg AS (
    SELECT
        cp.cp_department,
        td.t_hour,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cp.cp_type = 'quarterly'
      AND cp.cp_start_date_sk >= 2450800
      AND cp.cp_end_date_sk <= 2451100
    GROUP BY cp.cp_department, td.t_hour
),
returns_agg AS (
    SELECT
        cp.cp_department,
        td.t_hour,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(*) AS returns_cnt
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE cp.cp_type = 'quarterly'
      AND cp.cp_start_date_sk >= 2450800
      AND cp.cp_end_date_sk <= 2451100
    GROUP BY cp.cp_department, td.t_hour
)
SELECT
    s.cp_department,
    s.t_hour,
    s.total_sales_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_sales_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns,
    s.sales_cnt,
    COALESCE(r.returns_cnt, 0) AS returns_cnt,
    RANK() OVER (ORDER BY (s.total_sales_profit - COALESCE(r.total_return_loss, 0)) DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.cp_department = r.cp_department
   AND s.t_hour = r.t_hour
ORDER BY net_profit_after_returns DESC
LIMIT 100
