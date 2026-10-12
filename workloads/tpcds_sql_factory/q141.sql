WITH store_agg AS (
       SELECT sr.sr_customer_sk AS customer_sk,
              SUM(sr.sr_net_loss) AS store_net_loss,
              COUNT(*) AS store_return_cnt,
              SUM(sr.sr_return_amt_inc_tax) AS store_return_inc_tax
       FROM store_returns sr
       GROUP BY sr.sr_customer_sk
   ),
   web_agg AS (
       SELECT wr.wr_refunded_customer_sk AS customer_sk,
              SUM(wr.wr_net_loss) AS web_net_loss,
              COUNT(*) AS web_return_cnt,
              SUM(wr.wr_return_amt_inc_tax) AS web_return_inc_tax
       FROM web_returns wr
       GROUP BY wr.wr_refunded_customer_sk
   ),
   page_agg AS (
       SELECT wp.wp_customer_sk AS customer_sk,
              COUNT(DISTINCT wp.wp_web_page_sk) AS page_cnt,
              SUM(wp.wp_image_count) AS total_image_count,
              MAX(wp.wp_char_count) AS max_char_count
       FROM web_page wp
       GROUP BY wp.wp_customer_sk
   )
SELECT c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       COALESCE(sa.store_net_loss, 0) AS store_net_loss,
       COALESCE(wa.web_net_loss, 0) AS web_net_loss,
       COALESCE(sa.store_return_inc_tax, 0) AS store_return_inc_tax,
       COALESCE(wa.web_return_inc_tax, 0) AS web_return_inc_tax,
       COALESCE(sa.store_net_loss, 0) + COALESCE(wa.web_net_loss, 0) AS total_net_loss,
       COALESCE(pa.page_cnt, 0) AS page_count,
       COALESCE(pa.total_image_count, 0) AS total_image_count,
       COALESCE(pa.max_char_count, 0) AS max_char_count,
       (COALESCE(sa.store_return_inc_tax, 0) + COALESCE(wa.web_return_inc_tax, 0)) / NULLIF(COALESCE(sa.store_return_cnt,0) + COALESCE(wa.web_return_cnt,0), 0) AS avg_return_inc_tax
FROM customer c
LEFT JOIN store_agg sa ON sa.customer_sk = c.c_customer_sk
LEFT JOIN web_agg wa ON wa.customer_sk = c.c_customer_sk
LEFT JOIN page_agg pa ON pa.customer_sk = c.c_customer_sk
WHERE COALESCE(sa.store_return_cnt,0) + COALESCE(wa.web_return_cnt,0) > 5
ORDER BY avg_return_inc_tax DESC NULLS LAST
LIMIT 100
