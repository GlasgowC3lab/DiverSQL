WITH store_agg AS (
       SELECT sr.sr_customer_sk AS customer_sk,
              SUM(sr.sr_net_loss) AS store_net_loss,
              COUNT(*) AS store_return_cnt
       FROM store_returns sr
       GROUP BY sr.sr_customer_sk
   ),
   web_agg AS (
       SELECT wr.wr_refunded_customer_sk AS customer_sk,
              SUM(wr.wr_net_loss) AS web_net_loss,
              COUNT(*) AS web_return_cnt
       FROM web_returns wr
       GROUP BY wr.wr_refunded_customer_sk
   ),
   page_agg AS (
       SELECT wp.wp_customer_sk AS customer_sk,
              COUNT(DISTINCT wp.wp_web_page_sk) AS page_cnt,
              SUM(wp.wp_image_count) AS total_image_count
       FROM web_page wp
       GROUP BY wp.wp_customer_sk
   )
SELECT c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       COALESCE(sa.store_net_loss, 0) AS store_net_loss,
       COALESCE(wa.web_net_loss, 0) AS web_net_loss,
       COALESCE(sa.store_net_loss, 0) + COALESCE(wa.web_net_loss, 0) AS total_net_loss,
       COALESCE(pa.page_cnt, 0) AS page_count,
       COALESCE(pa.total_image_count, 0) AS total_image_count,
       AVG(COALESCE(sa.store_net_loss, 0) + COALESCE(wa.web_net_loss, 0)) OVER (PARTITION BY c.c_birth_month) AS avg_loss_by_birth_month,
       ROW_NUMBER() OVER (PARTITION BY c.c_birth_country ORDER BY COALESCE(sa.store_net_loss, 0) + COALESCE(wa.web_net_loss, 0) DESC) AS country_loss_rank
FROM customer c
LEFT JOIN store_agg sa ON sa.customer_sk = c.c_customer_sk
LEFT JOIN web_agg wa ON wa.customer_sk = c.c_customer_sk
LEFT JOIN page_agg pa ON pa.customer_sk = c.c_customer_sk
WHERE COALESCE(sa.store_net_loss, 0) + COALESCE(wa.web_net_loss, 0) > 0
ORDER BY total_net_loss DESC
OFFSET 10 ROWS FETCH NEXT 90 ROWS ONLY
