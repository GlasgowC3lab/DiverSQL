WITH page_period AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_id,
        cp.cp_catalog_page_number,
        cp.cp_department,
        sd.d_date AS start_date,
        ed.d_date AS end_date,
        date_diff('day', sd.d_date, ed.d_date) + 1 AS active_days
    FROM catalog_page cp
    JOIN date_dim sd ON cp.cp_start_date_sk = sd.d_date_sk
    JOIN date_dim ed ON cp.cp_end_date_sk = ed.d_date_sk
    WHERE cp.cp_type = 'PROMO'                     -- filter to promo pages only
),
sales_daily AS (
    SELECT
        cs.cs_catalog_page_sk,
        d.d_date,
        SUM(cs.cs_net_paid_inc_tax) AS daily_net_paid_inc_tax,
        SUM(cs.cs_quantity) AS daily_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002                         -- restrict to year 2002
    GROUP BY cs.cs_catalog_page_sk, d.d_date
),
sales_agg AS (
    SELECT
        pp.cp_catalog_page_sk,
        pp.cp_catalog_page_id,
        pp.cp_catalog_page_number,
        pp.cp_department,
        pp.start_date,
        pp.end_date,
        pp.active_days,
        SUM(sd.daily_net_paid_inc_tax) AS total_net_paid_inc_tax,
        SUM(sd.daily_quantity) AS total_quantity,
        AVG(sd.daily_quantity) AS avg_daily_quantity           -- new metric
    FROM page_period pp
    JOIN sales_daily sd ON sd.cs_catalog_page_sk = pp.cp_catalog_page_sk
    WHERE sd.d_date BETWEEN pp.start_date AND pp.end_date
    GROUP BY pp.cp_catalog_page_sk, pp.cp_catalog_page_id, pp.cp_catalog_page_number, pp.cp_department, pp.start_date, pp.end_date, pp.active_days
),
page_returns_agg AS (
    SELECT
        pp.cp_catalog_page_sk,
        SUM(wr.wr_net_loss) AS total_return_loss,
        COUNT(*) AS return_events                           -- count of return rows
    FROM page_period pp
    JOIN web_returns wr ON TRUE
    JOIN date_dim rd ON wr.wr_returned_date_sk = rd.d_date_sk
    WHERE rd.d_date BETWEEN pp.start_date AND pp.end_date
    GROUP BY pp.cp_catalog_page_sk
),
final_metrics AS (
    SELECT
        sa.cp_catalog_page_id,
        sa.cp_catalog_page_number,
        sa.cp_department,
        sa.start_date,
        sa.end_date,
        sa.active_days,
        sa.total_net_paid_inc_tax,
        sa.total_quantity,
        sa.avg_daily_quantity,
        CASE
            WHEN sa.avg_daily_quantity > 100 THEN 'High Volume'
            ELSE 'Normal Volume'
        END AS volume_flag,
        COALESCE(pr.total_return_loss, 0) AS total_return_loss,
        COALESCE(pr.return_events, 0) AS return_events,
        ROW_NUMBER() OVER (PARTITION BY sa.cp_department ORDER BY sa.total_net_paid_inc_tax DESC) AS dept_rev_rank
    FROM sales_agg sa
    LEFT JOIN page_returns_agg pr ON sa.cp_catalog_page_sk = pr.cp_catalog_page_sk
)
SELECT
    cp_catalog_page_id,
    cp_catalog_page_number,
    cp_department,
    start_date,
    end_date,
    active_days,
    total_net_paid_inc_tax,
    total_quantity,
    avg_daily_quantity,
    volume_flag,
    total_return_loss,
    return_events,
    dept_rev_rank
FROM final_metrics
ORDER BY dept_rev_rank
LIMIT 15
