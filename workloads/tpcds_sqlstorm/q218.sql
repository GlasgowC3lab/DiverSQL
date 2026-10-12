WITH sales_aggregated AS (
 SELECT s.date_sk,
        d.d_year,
        d.d_month_seq,
        s.channel,
        i.i_category,
        i.i_class,
        p.p_promo_name,
        cc.cc_name AS call_center_name,
        sum(s.sales_amount) AS sales_amount,
        sum(s.net_profit) AS net_profit,
        sum(s.discount_amount) AS discount_amount,
        count(distinct s.customer_sk) AS distinct_customers
 FROM (
   SELECT cs.cs_sold_date_sk AS date_sk,
          'catalog' AS channel,
          cs.cs_item_sk AS item_sk,
          cs.cs_call_center_sk AS call_center_sk,
          cs.cs_promo_sk AS promo_sk,
          cs.cs_bill_customer_sk AS customer_sk,
          cs.cs_ext_sales_price AS sales_amount,
          cs.cs_net_profit AS net_profit,
          cs.cs_ext_discount_amt AS discount_amount
   FROM catalog_sales cs
   UNION ALL
   SELECT ss.ss_sold_date_sk,
          'store' AS channel,
          ss.ss_item_sk AS item_sk,
          NULL AS call_center_sk,
          ss.ss_promo_sk AS promo_sk,
          ss.ss_customer_sk AS customer_sk,
          ss.ss_ext_sales_price AS sales_amount,
          ss.ss_net_profit AS net_profit,
          ss.ss_ext_discount_amt AS discount_amount
   FROM store_sales ss
   UNION ALL
   SELECT ws.ws_sold_date_sk,
          'web' AS channel,
          ws.ws_item_sk AS item_sk,
          NULL AS call_center_sk,
          ws.ws_promo_sk AS promo_sk,
          ws.ws_bill_customer_sk AS customer_sk,
          ws.ws_ext_sales_price AS sales_amount,
          ws.ws_net_profit AS net_profit,
          ws.ws_ext_discount_amt AS discount_amount
   FROM web_sales ws
 ) s
 LEFT JOIN item i ON s.item_sk = i.i_item_sk
 LEFT JOIN date_dim d ON s.date_sk = d.d_date_sk
 LEFT JOIN promotion p ON s.promo_sk = p.p_promo_sk
 LEFT JOIN call_center cc ON s.call_center_sk = cc.cc_call_center_sk
 GROUP BY s.date_sk, d.d_year, d.d_month_seq, s.channel, i.i_category, i.i_class, p.p_promo_name, cc.cc_name
),
returns_aggregated AS (
 SELECT r.date_sk,
        d.d_year,
        d.d_month_seq,
        r.channel,
        i.i_category,
        i.i_class,
        sum(r.return_amount) AS return_amount,
        sum(r.net_loss) AS net_loss,
        count(distinct r.customer_sk) AS distinct_return_customers
 FROM (
   SELECT cr.cr_returned_date_sk AS date_sk,
          'catalog' AS channel,
          cr.cr_item_sk AS item_sk,
          cr.cr_call_center_sk AS call_center_sk,
          cr.cr_refunded_customer_sk AS customer_sk,
          cr.cr_return_amount AS return_amount,
          cr.cr_net_loss AS net_loss
   FROM catalog_returns cr
   UNION ALL
   SELECT sr.sr_returned_date_sk,
          'store' AS channel,
          sr.sr_item_sk AS item_sk,
          NULL AS call_center_sk,
          sr.sr_customer_sk AS customer_sk,
          sr.sr_return_amt AS return_amount,
          sr.sr_net_loss AS net_loss
   FROM store_returns sr
   UNION ALL
   SELECT wr.wr_returned_date_sk,
          'web' AS channel,
          wr.wr_item_sk AS item_sk,
          NULL AS call_center_sk,
          wr.wr_refunded_customer_sk AS customer_sk,
          wr.wr_return_amt AS return_amount,
          wr.wr_net_loss AS net_loss
   FROM web_returns wr
 ) r
 LEFT JOIN item i ON r.item_sk = i.i_item_sk
 LEFT JOIN date_dim d ON r.date_sk = d.d_date_sk
 GROUP BY r.date_sk, d.d_year, d.d_month_seq, r.channel, i.i_category, i.i_class
),
sales_returns_combined AS (
 SELECT s.d_year,
        s.d_month_seq,
        s.channel,
        s.i_category,
        s.i_class,
        s.p_promo_name,
        s.call_center_name,
        s.sales_amount,
        COALESCE(r.return_amount, 0) AS return_amount,
        s.net_profit - COALESCE(r.net_loss, 0) AS net_profit,
        s.discount_amount,
        s.distinct_customers,
        COALESCE(r.distinct_return_customers, 0) AS distinct_return_customers
 FROM sales_aggregated s
 LEFT JOIN returns_aggregated r
   ON s.date_sk = r.date_sk
   AND s.channel = r.channel
   AND s.i_category = r.i_category
   AND s.i_class = r.i_class
),
ranked AS (
 SELECT *,
        row_number() OVER (PARTITION BY d_year, d_month_seq, channel ORDER BY net_profit DESC) AS profit_rank,
        round(approx_percentile(net_profit, 0.5) OVER (PARTITION BY d_year, channel), 2) AS median_net_profit_channel_year
 FROM sales_returns_combined
),
final_result AS (
 SELECT d_year,
        d_month_seq,
        channel,
        i_category,
        i_class,
        sum(sales_amount) AS total_sales_amount,
        sum(return_amount) AS total_return_amount,
        sum(net_profit) AS total_net_profit,
        sum(discount_amount) AS total_discount_amount,
        sum(distinct_customers) AS total_distinct_customers,
        sum(distinct_return_customers) AS total_distinct_return_customers,
        max(profit_rank) FILTER (WHERE profit_rank <= 10) AS top10_rank,
        avg(median_net_profit_channel_year) AS avg_median_net_profit_channel_year
 FROM ranked
 GROUP BY d_year, d_month_seq, channel, i_category, i_class
 HAVING sum(sales_amount) > 50000
 ORDER BY d_year, d_month_seq, channel, total_net_profit DESC
 LIMIT 200
)
SELECT *
FROM final_result
