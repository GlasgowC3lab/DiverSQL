WITH store_returns_filtered AS (
   SELECT
     'store' AS return_source,
     d.d_year AS year,
     d.d_month_seq AS month_seq,
     r.r_reason_desc AS reason_desc,
     sr.sr_return_quantity AS return_quantity,
     sr.sr_return_amt AS return_amount,
     sr.sr_net_loss AS net_loss
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
   WHERE NOT EXISTS (
         SELECT 1
         FROM catalog_returns cr
         WHERE cr.cr_order_number = sr.sr_ticket_number
   )
   AND d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2002-01-01'
   AND hd.hd_buy_potential = '5001-10000'
),
web_returns_filtered AS (
   SELECT
     'web' AS return_source,
     d.d_year AS year,
     d.d_month_seq AS month_seq,
     r.r_reason_desc AS reason_desc,
     wr.wr_return_quantity AS return_quantity,
     wr.wr_return_amt AS return_amount,
     wr.wr_net_loss AS net_loss
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
   WHERE NOT EXISTS (
         SELECT 1
         FROM catalog_returns cr
         WHERE cr.cr_order_number = wr.wr_order_number
   )
   AND d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2002-01-01'
   AND hd.hd_buy_potential = '5001-10000'
),
combined AS (
   SELECT * FROM store_returns_filtered
   UNION ALL
   SELECT * FROM web_returns_filtered
)
SELECT
   ROW_NUMBER() OVER (ORDER BY return_source, year, month_seq, reason_desc) AS row_num,
   return_source,
   year,
   month_seq,
   reason_desc,
   SUM(return_quantity) AS total_quantity,
   SUM(return_amount) AS total_return_amount,
   SUM(net_loss) AS total_net_loss
FROM combined
GROUP BY ROLLUP (return_source, year, month_seq, reason_desc)
ORDER BY row_num
LIMIT 100
