WITH unified_sales AS (
   SELECT ss.ss_sold_date_sk AS sold_date_sk,
          ss.ss_customer_sk AS customer_sk,
          ss.ss_store_sk AS store_sk,
          ss.ss_item_sk AS item_sk,
          ss.ss_quantity AS qty,
          ss.ss_net_paid AS net_paid,
          ss.ss_net_profit AS net_profit,
          'store' AS channel
   FROM store_sales ss
   UNION ALL
   SELECT ws.ws_sold_date_sk,
          ws.ws_bill_customer_sk,
          NULL AS store_sk,
          ws.ws_item_sk,
          ws.ws_quantity,
          ws.ws_net_paid,
          ws.ws_net_profit,
          'web' AS channel
   FROM web_sales ws
   UNION ALL
   SELECT cs.cs_sold_date_sk,
          cs.cs_bill_customer_sk,
          NULL AS store_sk,
          cs.cs_item_sk,
          cs.cs_quantity,
          cs.cs_net_paid,
          cs.cs_net_profit,
          'catalog' AS channel
   FROM catalog_sales cs
),
unified_returns AS (
   SELECT sr.sr_returned_date_sk AS ret_date_sk,
          sr.sr_customer_sk AS customer_sk,
          sr.sr_store_sk AS store_sk,
          sr.sr_item_sk AS item_sk,
          sr.sr_return_quantity AS qty,
          sr.sr_return_amt AS ret_amount,
          sr.sr_net_loss AS net_loss,
          'store' AS channel
   FROM store_returns sr
   UNION ALL
   SELECT wr.wr_returned_date_sk,
          wr.wr_refunded_customer_sk,
          NULL AS store_sk,
          wr.wr_item_sk,
          wr.wr_return_quantity,
          wr.wr_return_amt,
          wr.wr_net_loss,
          'web' AS channel
   FROM web_returns wr
   UNION ALL
   SELECT cr.cr_returned_date_sk,
          cr.cr_refunded_customer_sk,
          NULL AS store_sk,
          cr.cr_item_sk,
          cr.cr_return_quantity,
          cr.cr_return_amount,
          cr.cr_net_loss,
          'catalog' AS channel
   FROM catalog_returns cr
),
customer_base AS (
   SELECT c.c_customer_sk,
          COALESCE(c.c_first_name, 'UNKNOWN') AS first_name,
          COALESCE(c.c_last_name, 'UNKNOWN') AS last_name,
          COALESCE(ca.ca_state, 'UNKNOWN') AS state,
          c.c_current_addr_sk
   FROM customer c
   LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_agg AS (
   SELECT cb.c_customer_sk,
          cb.state,
          s.channel,
          SUM(COALESCE(s.net_profit, 0)) AS profit,
          SUM(COALESCE(s.net_paid, 0)) AS sales,
          COUNT(*) AS sales_txn
   FROM customer_base cb
   LEFT JOIN unified_sales s ON cb.c_customer_sk = s.customer_sk
   GROUP BY cb.c_customer_sk, cb.state, s.channel
),
returns_agg AS (
   SELECT cb.c_customer_sk,
          cb.state,
          r.channel,
          SUM(COALESCE(r.net_loss, 0)) AS loss,
          SUM(COALESCE(r.ret_amount, 0)) AS return_amount,
          COUNT(*) AS return_txn
   FROM customer_base cb
   LEFT JOIN unified_returns r ON cb.c_customer_sk = r.customer_sk
   GROUP BY cb.c_customer_sk, cb.state, r.channel
),
combined AS (
   SELECT
       COALESCE(sa.c_customer_sk, ra.c_customer_sk) AS customer_sk,
       COALESCE(sa.state, ra.state) AS state,
       COALESCE(sa.channel, ra.channel) AS channel,
       COALESCE(sa.profit, 0) AS profit,
       COALESCE(sa.sales, 0) AS sales,
       COALESCE(sa.sales_txn, 0) AS sales_txn,
       COALESCE(ra.loss, 0) AS loss,
       COALESCE(ra.return_amount, 0) AS return_amount,
       COALESCE(ra.return_txn, 0) AS return_txn
   FROM sales_agg sa
   FULL OUTER JOIN returns_agg ra
       ON sa.c_customer_sk = ra.c_customer_sk
       AND sa.channel = ra.channel
       AND sa.state = ra.state
),
ranked AS (
   SELECT
       c.customer_sk,
       c.state,
       c.channel,
       c.profit,
       c.sales,
       c.loss,
       (c.profit - c.loss) AS net_contribution,
       ROW_NUMBER() OVER (PARTITION BY c.state ORDER BY (c.profit - c.loss) DESC NULLS LAST) AS state_rank,
       RANK() OVER (ORDER BY (c.profit - c.loss) DESC) AS global_rank,
       SUM(c.profit) OVER (PARTITION BY c.state) AS state_total_profit,
       AVG(c.profit) OVER (PARTITION BY c.state) AS state_avg_profit,
       NTILE(4) OVER (PARTITION BY c.state ORDER BY (c.profit - c.loss) DESC) AS profit_quartile,
       CASE
           WHEN c.profit > 0 AND c.loss = 0 THEN 'WINNER'
           WHEN c.profit < 0 AND c.loss > 0 THEN 'LOSER'
           ELSE 'NEUTRAL'
       END AS profit_status,
       CONCAT(c.state, '|', COALESCE(c.channel, 'NONE')) AS state_channel_key,
       LENGTH(COALESCE(c.channel, '')) AS channel_len
   FROM combined c
   WHERE c.profit IS NOT NULL OR c.loss IS NOT NULL
),
state_medians AS (
   SELECT state,
          approx_percentile(net_contribution, 0.5) AS median_contribution
   FROM ranked
   GROUP BY state
),
final AS (
   SELECT
       r.*,
       sm.median_contribution,
       CASE
           WHEN r.net_contribution > sm.median_contribution THEN 'ABOVE_MEDIAN'
           WHEN r.net_contribution < sm.median_contribution THEN 'BELOW_MEDIAN'
           ELSE 'AT_MEDIAN'
       END AS median_compare,
       (SELECT COUNT(*) FROM ranked r2 WHERE r2.state = r.state AND r2.net_contribution > r.net_contribution) AS higher_in_state,
       (SELECT array_join(array_distinct(array_agg(us.channel)), ',') FROM unified_sales us WHERE us.customer_sk = r.customer_sk) AS channel_list,
       (SELECT MAX(us.sold_date_sk) FROM unified_sales us WHERE us.customer_sk = r.customer_sk) AS last_purchase_date_sk,
       COALESCE(r.sales, 1) AS sales_nonzero,
       (r.net_contribution * 100.0 / NULLIF(r.sales, 0)) AS profit_margin_pct,
       LENGTH(COALESCE(r.state, '') || COALESCE(r.channel, '')) AS state_channel_len
   FROM ranked r
   LEFT JOIN state_medians sm ON r.state = sm.state
   WHERE r.state <> 'UNKNOWN'
)
SELECT *
FROM final
WHERE (higher_in_state IS NULL OR higher_in_state < 5)
   AND profit_status = 'WINNER'
   AND profit_quartile = 1
   AND (state_rank <= 3 OR net_contribution > 5000)
   AND EXISTS (
       SELECT 1 FROM unified_returns ur
       WHERE ur.customer_sk = final.customer_sk
         AND ur.channel = final.channel
         AND ur.ret_amount > 0
   )
ORDER BY state, state_rank, net_contribution DESC
LIMIT 200
