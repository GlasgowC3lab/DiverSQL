WITH sales_agg AS (
   SELECT 
      d_sold.d_year AS year,
      s.s_state,
      s.s_city,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      SUM(cs.cs_ext_discount_amt) AS total_discount,
      COUNT(DISTINCT cs.cs_order_number) AS num_orders
   FROM catalog_sales cs
   JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
   JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
   GROUP BY d_sold.d_year, s.s_state, s.s_city
),
returns_agg AS (
   SELECT 
      d_return.d_year AS year,
      r.r_reason_desc,
      SUM(wr.wr_return_amt) AS total_return_amt,
      SUM(wr.wr_net_loss) AS total_net_loss,
      COUNT(DISTINCT wr.wr_order_number) AS num_return_orders
   FROM web_returns wr
   JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   GROUP BY d_return.d_year, r.r_reason_desc
)
SELECT 
   s.year,
   s.s_state,
   s.s_city,
   s.total_sales,
   s.total_discount,
   s.num_orders,
   r.r_reason_desc,
   r.total_return_amt,
   r.total_net_loss,
   r.num_return_orders,
   (s.total_sales - r.total_return_amt) AS net_sales_after_returns,
   CASE 
      WHEN s.total_sales > 0 THEN (r.total_return_amt / s.total_sales) * 100
      ELSE NULL
   END AS return_rate_pct
FROM sales_agg s
JOIN returns_agg r ON s.year = r.year
WHERE s.total_sales > 10000
ORDER BY net_sales_after_returns DESC
LIMIT 100
