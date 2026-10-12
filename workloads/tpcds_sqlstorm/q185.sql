WITH sales AS (
 SELECT
   ss_customer_sk AS customer_sk,
   ss_sold_date_sk AS date_sk,
   ss_ext_sales_price AS sales_amount,
   ss_net_profit AS profit,
   ss_coupon_amt AS coupon,
   'store' AS channel,
   ss_promo_sk AS promo_sk
 FROM store_sales
 UNION ALL
 SELECT
   cs_bill_customer_sk,
   cs_sold_date_sk,
   cs_ext_sales_price,
   cs_net_profit,
   cs_coupon_amt,
   'catalog',
   cs_promo_sk
 FROM catalog_sales
 UNION ALL
 SELECT
   ws_bill_customer_sk,
   ws_sold_date_sk,
   ws_ext_sales_price,
   ws_net_profit,
   ws_coupon_amt,
   'web',
   ws_promo_sk
 FROM web_sales
),
returns AS (
 SELECT
   cr_refunded_customer_sk AS customer_sk,
   cr_returned_date_sk AS date_sk,
   cr_net_loss AS loss,
   cr_return_quantity AS return_qty,
   'catalog' AS channel
 FROM catalog_returns
 UNION ALL
 SELECT
   sr_customer_sk,
   sr_returned_date_sk,
   sr_net_loss,
   sr_return_quantity,
   'store'
 FROM store_returns
 UNION ALL
 SELECT
   wr_refunded_customer_sk,
   wr_returned_date_sk,
   wr_net_loss,
   wr_return_quantity,
   'web'
 FROM web_returns
),
sales_with_dim AS (
 SELECT
   c.c_customer_id,
   d.d_year,
   d.d_month_seq,
   s.channel,
   s.sales_amount,
   s.profit,
   s.coupon,
   s.promo_sk
 FROM sales s
 JOIN customer c ON c.c_customer_sk = s.customer_sk
 JOIN date_dim d ON d.d_date_sk = s.date_sk
),
returns_with_dim AS (
 SELECT
   c.c_customer_id,
   d.d_year,
   d.d_month_seq,
   r.channel,
   r.loss,
   r.return_qty
 FROM returns r
 JOIN customer c ON c.c_customer_sk = r.customer_sk
 JOIN date_dim d ON d.d_date_sk = r.date_sk
),
sales_agg AS (
 SELECT
   c_customer_id,
   d_year,
   d_month_seq,
   channel,
   SUM(sales_amount) AS total_sales,
   SUM(profit) AS total_profit,
   SUM(coupon) AS total_coupon,
   COUNT(*) AS sales_transactions,
   AVG(coupon) AS avg_coupon,
   SUM(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) AS discount_active_count
 FROM sales_with_dim s
 LEFT JOIN promotion p ON p.p_promo_sk = s.promo_sk
 GROUP BY c_customer_id, d_year, d_month_seq, channel
),
returns_agg AS (
 SELECT
   c_customer_id,
   d_year,
   d_month_seq,
   channel,
   SUM(loss) AS total_loss,
   SUM(return_qty) AS total_return_qty,
   COUNT(*) AS return_transactions
 FROM returns_with_dim r
 GROUP BY c_customer_id, d_year, d_month_seq, channel
),
combined AS (
 SELECT
   s.c_customer_id,
   s.d_year,
   s.d_month_seq,
   s.channel,
   s.total_sales,
   s.total_profit,
   s.total_coupon,
   s.sales_transactions,
   s.avg_coupon,
   s.discount_active_count,
   COALESCE(r.total_loss, 0) AS total_loss,
   COALESCE(r.total_return_qty, 0) AS total_return_qty,
   COALESCE(r.return_transactions, 0) AS return_transactions,
   s.total_profit - COALESCE(r.total_loss, 0) AS net_profit_after_returns,
   CASE WHEN s.total_sales > 0 THEN COALESCE(r.total_loss, 0) / s.total_sales ELSE 0 END AS loss_ratio
 FROM sales_agg s
 LEFT JOIN returns_agg r
   ON r.c_customer_id = s.c_customer_id
   AND r.d_year = s.d_year
   AND r.d_month_seq = s.d_month_seq
   AND r.channel = s.channel
),
ranked AS (
 SELECT
   c_customer_id,
   d_year,
   d_month_seq,
   channel,
   total_sales,
   net_profit_after_returns,
   loss_ratio,
   sales_transactions,
   return_transactions,
   ROW_NUMBER() OVER (PARTITION BY d_year, channel ORDER BY net_profit_after_returns DESC) AS profit_rank,
   SUM(net_profit_after_returns) OVER (PARTITION BY d_year, channel ORDER BY d_month_seq
                                      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit
 FROM combined
)
SELECT
  c_customer_id,
  d_year,
  d_month_seq,
  channel,
  total_sales,
  net_profit_after_returns,
  loss_ratio,
  sales_transactions,
  return_transactions,
  profit_rank,
  cumulative_profit
FROM ranked
WHERE profit_rank <= 3
ORDER BY d_year, channel, profit_rank
