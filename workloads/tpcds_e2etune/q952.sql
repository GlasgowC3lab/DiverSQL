WITH sales_agg AS (
    SELECT
        cp.cp_department AS department,
        d.d_quarter_name AS quarter,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE sm.sm_type = 'AIR'
      AND cp.cp_start_date_sk > 2450800
      AND d.d_year = 2001
    GROUP BY cp.cp_department, d.d_quarter_name
),
returns_agg AS (
    SELECT
        d.d_quarter_name AS quarter,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_quarter_name
)
SELECT
    s.department,
    s.quarter,
    s.total_net_profit,
    s.total_quantity,
    s.avg_discount,
    s.sales_cnt,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    COALESCE(r.return_cnt, 0) AS return_cnt,
    RANK() OVER (PARTITION BY s.quarter ORDER BY s.total_net_profit DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r ON s.quarter = r.quarter
ORDER BY s.quarter, profit_rank
LIMIT 100
