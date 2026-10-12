WITH sales_with_dim AS (
    SELECT
        cs.cs_bill_customer_sk,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_ext_discount_amt,
        cs.cs_quantity,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        t.t_hour,
        t.t_meal_time,
        ws.web_site_sk,
        ws.web_name,
        d.d_week_seq
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN web_site ws ON d.d_date_sk BETWEEN ws.web_open_date_sk AND ws.web_close_date_sk
    WHERE ws.web_state = 'CA'
), weekly_sales AS (
    SELECT
        csd.cs_bill_customer_sk,
        csd.d_week_seq,
        SUM(csd.cs_net_paid) AS week_net_paid,
        SUM(csd.cs_net_profit) AS week_net_profit
    FROM sales_with_dim csd
    GROUP BY csd.cs_bill_customer_sk, csd.d_week_seq
), customer_aggregates AS (
    SELECT
        ws.cs_bill_customer_sk,
        COUNT(DISTINCT ws.d_week_seq) AS active_weeks,
        SUM(ws.week_net_paid) AS total_net_paid,
        SUM(ws.week_net_profit) AS total_net_profit,
        SUM(ws.week_net_profit) / NULLIF(SUM(ws.week_net_paid), 0) AS profit_margin
    FROM weekly_sales ws
    GROUP BY ws.cs_bill_customer_sk
), customer_ranked AS (
    SELECT
        ca.*, 
        DENSE_RANK() OVER (ORDER BY ca.total_net_profit DESC) AS profit_rank,
        CASE WHEN ca.profit_margin > 0.4 THEN 'Gold' WHEN ca.profit_margin > 0.2 THEN 'Silver' ELSE 'Bronze' END AS tier
    FROM customer_aggregates ca
), recent_purchases AS (
    SELECT
        csd.cs_bill_customer_sk,
        csd.cs_order_number,
        csd.cs_net_paid,
        csd.cs_net_profit,
        csd.d_date,
        csd.web_name,
        ROW_NUMBER() OVER (PARTITION BY csd.cs_bill_customer_sk ORDER BY csd.d_date DESC) AS recent_rank,
        SUM(csd.cs_net_profit) OVER (PARTITION BY csd.cs_bill_customer_sk ORDER BY csd.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit
    FROM sales_with_dim csd
    WHERE csd.d_date >= DATE '2022-01-01'
)
SELECT
    cr.cs_bill_customer_sk,
    cr.active_weeks,
    cr.total_net_paid,
    cr.total_net_profit,
    cr.profit_margin,
    cr.profit_rank,
    cr.tier,
    rp.cs_order_number,
    rp.d_date,
    rp.web_name,
    rp.recent_rank,
    rp.cumulative_profit
FROM customer_ranked cr
JOIN recent_purchases rp ON cr.cs_bill_customer_sk = rp.cs_bill_customer_sk
WHERE rp.recent_rank <= 3
ORDER BY cr.profit_rank, rp.recent_rank
