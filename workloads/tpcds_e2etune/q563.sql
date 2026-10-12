WITH sales_agg AS (
    SELECT i.i_category AS category,
           d.d_year AS year,
           d.d_month_seq AS month_seq,
           SUM(cs.cs_net_profit) AS total_net_profit,
           COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
           SUM(cs.cs_quantity) AS total_quantity_sold
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2020
    GROUP BY i.i_category, d.d_year, d.d_month_seq
),
returns_agg AS (
    SELECT i.i_category AS category,
           d.d_year AS year,
           d.d_month_seq AS month_seq,
           SUM(sr.sr_net_loss) AS total_net_loss,
           COUNT(DISTINCT sr.sr_customer_sk) AS distinct_return_customers,
           SUM(sr.sr_return_quantity) AS total_quantity_returned
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2020
    GROUP BY i.i_category, d.d_year, d.d_month_seq
)
SELECT s.category,
       s.year,
       s.month_seq,
       s.total_net_profit,
       COALESCE(r.total_net_loss, 0) AS total_net_loss,
       s.distinct_customers,
       COALESCE(r.distinct_return_customers, 0) AS distinct_return_customers,
       CASE WHEN s.total_net_profit = 0 THEN NULL
            ELSE (COALESCE(r.total_net_loss, 0) / s.total_net_profit)
       END AS loss_to_profit_ratio,
       s.total_quantity_sold,
       COALESCE(r.total_quantity_returned, 0) AS total_quantity_returned,
       RANK() OVER (PARTITION BY s.year ORDER BY s.total_net_profit DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r
       ON s.category = r.category
      AND s.year = r.year
      AND s.month_seq = r.month_seq
WHERE s.total_net_profit > 1000
ORDER BY s.total_net_profit DESC
LIMIT 10
