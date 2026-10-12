WITH unified_sales AS (
 SELECT cs.cs_sold_date_sk AS sale_date_sk,
        cs.cs_sold_time_sk AS sale_time_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_ext_discount_amt AS discount_amt,
        cs.cs_promo_sk AS promo_sk,
        'Catalog' AS channel
 FROM catalog_sales cs
 UNION ALL
 SELECT ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        ws.ws_promo_sk,
        'Web' AS channel
 FROM web_sales ws
 UNION ALL
 SELECT ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_ext_discount_amt,
        ss.ss_promo_sk,
        'Store' AS channel
 FROM store_sales ss
),
unified_returns AS (
 SELECT cr.cr_returned_date_sk AS return_date_sk,
        cr.cr_item_sk AS item_sk,
        cr.cr_return_quantity AS quantity,
        cr.cr_return_amount AS return_amount,
        cr.cr_net_loss AS net_loss,
        'Catalog' AS channel
 FROM catalog_returns cr
 UNION ALL
 SELECT sr.sr_returned_date_sk,
        sr.sr_item_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        'Store' AS channel
 FROM store_returns sr
 UNION ALL
 SELECT wr.wr_returned_date_sk,
        wr.wr_item_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss,
        'Web' AS channel
 FROM web_returns wr
),
aggregated_returns AS (
 SELECT channel,
        item_sk,
        return_date_sk,
        SUM(return_amount) AS total_return_amount
 FROM unified_returns
 GROUP BY channel, item_sk, return_date_sk
),
sales_with_returns AS (
 SELECT us.sale_date_sk,
        us.item_sk,
        us.customer_sk,
        us.channel,
        us.quantity,
        us.net_paid,
        us.net_profit,
        us.discount_amt,
        us.promo_sk,
        COALESCE(ar.total_return_amount, 0) AS total_return_amount,
        us.net_paid - COALESCE(ar.total_return_amount, 0) AS net_paid_adjusted
 FROM unified_sales us
 LEFT JOIN aggregated_returns ar
   ON us.channel = ar.channel
  AND us.item_sk = ar.item_sk
  AND us.sale_date_sk = ar.return_date_sk
),
sales_enriched AS (
 SELECT swr.*,
        p.p_discount_active,
        COALESCE(p.p_promo_name, 'No Promo') AS promo_name,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_brand,
        CONCAT(i.i_category, '-', i.i_brand) AS category_brand,
        CASE
          WHEN swr.discount_amt > 0 OR COALESCE(p.p_discount_active, 'N') = 'Y' THEN 'Discounted'
          ELSE 'FullPrice'
        END AS price_type,
        (swr.net_profit / NULLIF(swr.net_paid_adjusted, 0)) * 100 AS profit_margin_pct,
        RANK() OVER (PARTITION BY swr.channel, d.d_year, d.d_month_seq ORDER BY swr.net_paid_adjusted DESC) AS sales_rank,
        (SELECT AVG(s2.net_paid_adjusted) FROM sales_with_returns s2 WHERE s2.item_sk = swr.item_sk) AS avg_item_sales
 FROM sales_with_returns swr
 LEFT JOIN promotion p
   ON swr.promo_sk = p.p_promo_sk
  AND swr.item_sk = p.p_item_sk
  AND swr.sale_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
 JOIN date_dim d
   ON swr.sale_date_sk = d.d_date_sk
 JOIN item i
   ON swr.item_sk = i.i_item_sk
 WHERE d.d_year = 2001
),
final_aggregates AS (
 SELECT channel,
        d_year,
        d_month_seq,
        category_brand,
        SUM(net_paid_adjusted) AS total_net_paid,
        SUM(net_profit) AS total_net_profit,
        SUM(discount_amt) AS total_discount,
        COUNT(DISTINCT customer_sk) AS distinct_customers,
        AVG(profit_margin_pct) AS avg_profit_margin_pct,
        MAX(sales_rank) AS max_sales_rank,
        SUM(total_return_amount) AS total_return_amount
 FROM sales_enriched
 GROUP BY channel, d_year, d_month_seq, category_brand
)
SELECT *
FROM final_aggregates
WHERE total_net_paid > 10000
ORDER BY total_net_paid DESC
LIMIT 100
