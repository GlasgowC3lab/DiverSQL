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
    WHERE cp.cp_catalog_page_number % 2 = 0               -- even numbered pages only
),
sales_daily AS (
    SELECT
        cs.cs_catalog_page_sk,
        d.d_date,
        SUM(cs.cs_net_paid) AS daily_net_paid,
        SUM(cs.cs_ext_discount_amt) AS daily_discount
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
        COUNT(*) AS days_with_sales
    FROM page_period pp
    JOIN sales_daily sd ON sd.cs_catalog_page_sk = pp.cp_catalog_page_sk
    WHERE sd.d_date BETWEEN pp.start_date AND pp.end_date
    GROUP BY pp.cp_catalog_page_sk, pp.cp_catalog_page_id, pp.cp_catalog_page_number, pp.cp_department, pp.start_date, pp.end_date, pp.active_days
),
page_returns_agg AS (
    SELECT
        pp.cp_catalog_page_sk,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount_inc_tax,
        SUM(wr.wr_return_quantity) AS total_return_qty
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
        CASE WHEN sa.total_discount / NULLIF(sa.total_net_paid,0) > 0.25 THEN 'Very High Discount' ELSE 'Standard' END AS discount_category,
        COALESCE(pr.total_return_amount_inc_tax,0) AS total_return_amount_inc_tax,
        COALESCE(pr.total_return_qty,0) AS total_return_qty,
        sa.days_with_sales,
        PERCENT_RANK() OVER (PARTITION BY sa.cp_department ORDER BY sa.total_net_paid) AS dept_net_paid_percentile,
        ROW_NUMBER() OVER (ORDER BY (sa.total_net_paid - COALESCE(pr.total_return_amount_inc_tax,0)) DESC) AS net_profit_rank
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
    discount_category,
    total_return_amount_inc_tax,
    total_return_qty,
    days_with_sales,
    dept_net_paid_percentile,
    net_profit_rank
FROM final_metrics
WHERE net_profit_rank <= 30
ORDER BY net_profit_rank
