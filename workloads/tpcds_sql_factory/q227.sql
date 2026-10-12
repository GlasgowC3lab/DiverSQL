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
        ws.web_name
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN web_site ws ON d.d_date_sk BETWEEN ws.web_open_date_sk AND ws.web_close_date_sk
), customer_aggregates AS (
    SELECT
        csd.cs_bill_customer_sk,
        COUNT(*) AS purchase_count,
        SUM(csd.cs_net_paid) AS total_net_paid,
        SUM(csd.cs_net_profit) AS total_net_profit,
        SUM(csd.cs_ext_discount_amt) AS total_discount,
        SUM(csd.cs_quantity) AS total_quantity,
        SUM(csd.cs_net_profit) / NULLIF(SUM(csd.cs_net_paid), 0) AS profit_margin
    FROM sales_with_dim csd
    GROUP BY csd.cs_bill_customer_sk
), customer_ranked AS (
    SELECT
        ca.*,
        RANK() OVER (ORDER BY ca.total_net_profit DESC) AS profit_rank,
        CASE 
            WHEN ca.profit_margin >= 0.5 THEN 'VIP'
            WHEN ca.profit_margin >= 0.2 THEN 'Preferred'
            ELSE 'Standard'
        END AS customer_segment
    FROM customer_aggregates ca
), customer_top_purchases AS (
    SELECT
        csd.cs_bill_customer_sk,
        csd.cs_order_number,
        csd.cs_net_paid,
        csd.cs_net_profit,
        csd.d_date,
        csd.web_name,
        ROW_NUMBER() OVER (PARTITION BY csd.cs_bill_customer_sk ORDER BY csd.cs_net_paid DESC) AS purchase_rank,
        AVG(csd.cs_net_profit) OVER (PARTITION BY csd.cs_bill_customer_sk ORDER BY csd.d_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS three_purchase_moving_avg_profit
    FROM sales_with_dim csd
)
SELECT
    cr.cs_bill_customer_sk,
    cr.purchase_count,
    cr.total_net_paid,
    cr.total_net_profit,
    cr.profit_margin,
    cr.profit_rank,
    cr.customer_segment,
    tp.cs_order_number,
    tp.d_date,
    tp.web_name,
    tp.purchase_rank,
    tp.three_purchase_moving_avg_profit
FROM customer_ranked cr
JOIN customer_top_purchases tp
  ON cr.cs_bill_customer_sk = tp.cs_bill_customer_sk
WHERE tp.purchase_rank <= 5
ORDER BY cr.profit_rank, tp.purchase_rank
