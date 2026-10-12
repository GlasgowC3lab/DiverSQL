WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        d.d_moy AS month,
        cp.cp_department,
        sm.sm_type AS ship_type,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales_price,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_cnt,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, d.d_moy, cp.cp_department, sm.sm_type
),
store_returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        d.d_moy AS month,
        cp.cp_department,
        SUM(sr.sr_net_loss) AS total_store_return_loss,
        SUM(sr.sr_return_quantity) AS total_store_return_qty,
        COUNT(*) AS store_return_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, d.d_moy, cp.cp_department
),
web_returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        d.d_moy AS month,
        cp.cp_department,
        SUM(wr.wr_net_loss) AS total_web_return_loss,
        SUM(wr.wr_return_quantity) AS total_web_return_qty,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, d.d_moy, cp.cp_department
)
SELECT
    s.d_year,
    s.month,
    s.cp_department,
    s.ship_type,
    s.total_net_profit,
    s.total_sales_price,
    s.sales_cnt,
    ROUND(s.avg_discount, 2) AS avg_discount,
    COALESCE(sr.total_store_return_loss, 0) AS total_store_return_loss,
    COALESCE(wr.total_web_return_loss, 0) AS total_web_return_loss,
    (COALESCE(sr.total_store_return_loss, 0) + COALESCE(wr.total_web_return_loss, 0)) AS total_return_loss,
    (s.total_net_profit - COALESCE(sr.total_store_return_loss, 0) - COALESCE(wr.total_web_return_loss, 0)) AS net_profit_after_returns,
    ROUND((COALESCE(sr.total_store_return_loss, 0) + COALESCE(wr.total_web_return_loss, 0)) / NULLIF(s.total_net_profit, 0) * 100, 2) AS return_loss_pct,
    SUM(s.total_net_profit) OVER (PARTITION BY s.cp_department ORDER BY s.d_year, s.month) AS cumulative_net_profit
FROM sales_agg s
LEFT JOIN store_returns_agg sr
    ON s.d_year = sr.d_year
    AND s.month = sr.month
    AND s.cp_department = sr.cp_department
LEFT JOIN web_returns_agg wr
    ON s.d_year = wr.d_year
    AND s.month = wr.month
    AND s.cp_department = wr.cp_department
ORDER BY s.d_year, s.month, s.cp_department, s.ship_type
