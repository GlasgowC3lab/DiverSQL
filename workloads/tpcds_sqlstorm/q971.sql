WITH the_sales AS (
   SELECT
       'Store' AS channel,
       s.s_store_sk AS entity_sk,
       CONCAT(s.s_store_name, ' (', s.s_city, ')') AS entity_name,
       d.d_year,
       d.d_month_seq,
       SUM(ss.ss_net_profit) AS net_profit,
       SUM(ss.ss_net_paid) AS net_paid,
       COUNT(*) AS sales_cnt,
       SUM(ss.ss_ext_discount_amt) AS total_discount
   FROM store_sales ss
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   GROUP BY s.s_store_sk, s.s_store_name, s.s_city, d.d_year, d.d_month_seq
   UNION ALL
   SELECT
       'Web' AS channel,
       ws.ws_web_page_sk AS entity_sk,
       CONCAT(wp.wp_type, ' ', wp.wp_url) AS entity_name,
       d.d_year,
       d.d_month_seq,
       SUM(ws.ws_net_profit) AS net_profit,
       SUM(ws.ws_net_paid) AS net_paid,
       COUNT(*) AS sales_cnt,
       SUM(ws.ws_ext_discount_amt) AS total_discount
   FROM web_sales ws
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   GROUP BY ws.ws_web_page_sk, wp.wp_type, wp.wp_url, d.d_year, d.d_month_seq
),
the_returns AS (
   SELECT
       'Store' AS channel,
       sr.sr_store_sk AS entity_sk,
       d.d_year,
       d.d_month_seq,
       SUM(sr.sr_net_loss) AS net_loss,
       SUM(sr.sr_return_amt) AS return_amt,
       COUNT(*) AS return_cnt
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   GROUP BY sr.sr_store_sk, d.d_year, d.d_month_seq
   UNION ALL
   SELECT
       'Web' AS channel,
       wr.wr_web_page_sk AS entity_sk,
       d.d_year,
       d.d_month_seq,
       SUM(wr.wr_net_loss) AS net_loss,
       SUM(wr.wr_return_amt) AS return_amt,
       COUNT(*) AS return_cnt
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   GROUP BY wr.wr_web_page_sk, d.d_year, d.d_month_seq
),
joined AS (
   SELECT
       s.channel,
       s.entity_sk,
       s.entity_name,
       s.d_year,
       s.d_month_seq,
       s.net_profit,
       s.net_paid,
       s.sales_cnt,
       s.total_discount,
       COALESCE(r.net_loss, 0) AS net_loss,
       COALESCE(r.return_amt, 0) AS return_amt,
       COALESCE(r.return_cnt, 0) AS return_cnt,
       s.net_profit - COALESCE(r.net_loss, 0) AS net_total,
       CASE WHEN s.net_profit - COALESCE(r.net_loss, 0) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS status
   FROM the_sales s
   LEFT JOIN the_returns r
       ON s.channel = r.channel
       AND s.entity_sk = r.entity_sk
       AND s.d_year = r.d_year
       AND s.d_month_seq = r.d_month_seq
),
final AS (
   SELECT
       j.*,
       ROW_NUMBER() OVER (PARTITION BY j.d_year ORDER BY j.net_total DESC) AS rank_year,
       SUM(j.net_total) OVER (PARTITION BY j.channel, j.d_year ORDER BY j.d_month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_total,
       (SELECT AVG(j2.net_total) FROM joined j2 WHERE j2.d_year = j.d_year AND j2.channel = j.channel AND j2.entity_sk <> j.entity_sk) AS avg_peer_net_total,
       CONCAT(j.entity_name, ' [', j.channel, ']') AS full_label,
       COALESCE(j.total_discount / NULLIF(j.sales_cnt, 0), 0) AS avg_discount_per_sale
   FROM joined j
)
SELECT
    f.channel,
    f.entity_sk,
    f.full_label,
    f.d_year,
    f.d_month_seq,
    f.net_total,
    f.cumulative_net_total,
    f.avg_peer_net_total,
    f.rank_year,
    f.status,
    f.avg_discount_per_sale
FROM final f
WHERE f.d_year = 2002
ORDER BY f.net_total DESC
LIMIT 100
