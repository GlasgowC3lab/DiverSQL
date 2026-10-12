WITH sales_all AS (
   SELECT 'store' AS channel,
          ss_sold_date_sk AS sold_date_sk,
          ss_item_sk AS item_sk,
          ss_quantity AS quantity,
          ss_net_paid AS net_paid,
          ss_net_profit AS net_profit,
          ss_ext_discount_amt AS discount_amt,
          ss_promo_sk AS promo_sk
   FROM store_sales
   UNION ALL
   SELECT 'catalog',
          cs_sold_date_sk,
          cs_item_sk,
          cs_quantity,
          cs_net_paid,
          cs_net_profit,
          cs_ext_discount_amt,
          cs_promo_sk
   FROM catalog_sales
   UNION ALL
   SELECT 'web',
          ws_sold_date_sk,
          ws_item_sk,
          ws_quantity,
          ws_net_paid,
          ws_net_profit,
          ws_ext_discount_amt,
          ws_promo_sk
   FROM web_sales
), 
returns_all AS (
   SELECT 'store' AS channel,
          sr_returned_date_sk AS returned_date_sk,
          sr_item_sk AS item_sk,
          sr_return_quantity AS quantity,
          sr_return_amt AS return_amt,
          sr_net_loss AS net_loss
   FROM store_returns
   UNION ALL
   SELECT 'catalog',
          cr_returned_date_sk,
          cr_item_sk,
          cr_return_quantity,
          cr_return_amount,
          cr_net_loss
   FROM catalog_returns
   UNION ALL
   SELECT 'web',
          wr_returned_date_sk,
          wr_item_sk,
          wr_return_quantity,
          wr_return_amt,
          wr_net_loss
   FROM web_returns
), 
sales_agg AS (
   SELECT d.d_year AS sales_year,
          d.d_month_seq AS month_seq,
          i.i_category AS category,
          s.channel AS channel,
          SUM(s.quantity) AS total_quantity,
          SUM(s.net_paid) AS total_net_paid,
          SUM(s.net_profit) AS total_net_profit,
          SUM(s.discount_amt) AS total_discount,
          SUM(COALESCE(p.p_cost, 0.0)) AS total_promo_cost
   FROM sales_all s
   JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
   JOIN item i ON s.item_sk = i.i_item_sk
   LEFT JOIN promotion p ON s.promo_sk = p.p_promo_sk
   GROUP BY d.d_year, d.d_month_seq, i.i_category, s.channel
), 
returns_agg AS (
   SELECT d.d_year AS sales_year,
          d.d_month_seq AS month_seq,
          i.i_category AS category,
          r.channel AS channel,
          SUM(r.quantity) AS total_return_quantity,
          SUM(r.return_amt) AS total_return_amt,
          SUM(r.net_loss) AS total_return_loss
   FROM returns_all r
   JOIN date_dim d ON r.returned_date_sk = d.d_date_sk
   JOIN item i ON r.item_sk = i.i_item_sk
   GROUP BY d.d_year, d.d_month_seq, i.i_category, r.channel
), 
combined AS (
   SELECT
       COALESCE(s.sales_year, r.sales_year) AS sales_year,
       COALESCE(s.month_seq, r.month_seq) AS month_seq,
       COALESCE(s.category, r.category) AS category,
       COALESCE(s.channel, r.channel) AS channel,
       COALESCE(s.total_quantity, 0) AS total_quantity,
       COALESCE(s.total_net_paid, 0) AS total_net_paid,
       COALESCE(s.total_net_profit, 0) AS total_net_profit,
       COALESCE(s.total_discount, 0) AS total_discount,
       COALESCE(s.total_promo_cost, 0) AS total_promo_cost,
       COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
       COALESCE(r.total_return_amt, 0) AS total_return_amt,
       COALESCE(r.total_return_loss, 0) AS total_return_loss
   FROM sales_agg s
   FULL OUTER JOIN returns_agg r
     ON s.sales_year = r.sales_year
    AND s.month_seq = r.month_seq
    AND s.category = r.category
    AND s.channel = r.channel
)
SELECT
    sales_year,
    month_seq,
    category,
    channel,
    total_quantity,
    total_net_paid,
    total_net_profit,
    total_discount,
    total_promo_cost,
    total_return_quantity,
    total_return_amt,
    total_return_loss,
    (total_net_paid - total_return_amt) AS net_sales_adjusted,
    (total_net_profit - total_return_loss) AS net_profit_adjusted,
    CASE WHEN total_quantity > 0 THEN total_discount / total_quantity ELSE 0 END AS avg_discount_per_unit,
    RANK() OVER (PARTITION BY sales_year, month_seq ORDER BY (total_net_paid - total_return_amt) DESC) AS sales_rank,
    AVG(total_net_paid - total_return_amt) OVER (PARTITION BY category ORDER BY month_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS three_month_moving_avg_net_sales
FROM combined
WHERE sales_year = 2001
ORDER BY sales_year, month_seq, category, channel
LIMIT 100
