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
    WHERE cp.cp_department IN ('Books', 'Home')                     -- limited departments
),
sales_daily AS (
    SELECT
        cs.cs_catalog_page_sk,
        d.d_date,
        SUM(cs.cs_net_paid) AS daily_net_paid,
        SUM(cs.cs_ext_discount_amt) AS daily_discount,
        SUM(cs.cs_quantity) AS daily_qty
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
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
        SUM(sd.daily_net_paid) AS total_net_paid,
        SUM(sd.daily_discount) AS total_discount,
        SUM(sd.daily_qty) AS total_qty,
        COUNT(DISTINCT sd.d_date) AS selling_days                     -- new metric
    FROM page_period pp
    JOIN sales_daily sd ON sd.cs_catalog_page_sk = pp.cp_catalog_page_sk
    WHERE sd.d_date BETWEEN pp.start_date AND pp.end_date
    GROUP BY pp.cp_catalog_page_sk, pp.cp_catalog_page_id, pp.cp_catalog_page_number, pp.cp_department, pp.start_date, pp.end_date, pp.active_days
),
page_returns_agg AS (
    SELECT
        pp.cp_catalog_page_sk,
        SUM(wr.wr_net_loss) AS total_return_loss,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_return_amt) AS total_return_amount
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
        sa.total_net_paid,
        sa.total_discount,
        sa.total_qty,
        sa.selling_days,
        CASE WHEN sa.total_discount / NULLIF(sa.total_net_paid,0) > 0.25 THEN 'Very High Discount' ELSE 'Acceptable Discount' END AS discount_severity,
        COALESCE(pr.total_return_loss,0) AS total_return_loss,
        COALESCE(pr.total_return_qty,0) AS total_return_qty,
        COALESCE(pr.total_return_amount,0) AS total_return_amount,
        DENSE_RANK() OVER (PARTITION BY sa.cp_department ORDER BY sa.total_net_paid / NULLIF(sa.active_days,0) DESC) AS dept_rev_per_day_rank,
        SUM(sa.total_net_paid) OVER (PARTITION BY sa.cp_department) AS dept_total_net_paid   -- window total per department
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
    total_net_paid,
    total_discount,
    total_qty,
    selling_days,
    discount_severity,
    total_return_loss,
    total_return_qty,
    total_return_amount,
    dept_rev_per_day_rank,
    dept_total_net_paid
FROM final_metrics
WHERE dept_rev_per_day_rank <= 3
ORDER BY cp_department, dept_rev_per_day_rank
