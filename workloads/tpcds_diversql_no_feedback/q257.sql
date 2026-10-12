WITH store_ret_agg AS (
   SELECT sr.sr_store_sk,
          sr.sr_reason_sk,
          SUM(sr.sr_net_loss) AS store_return_loss
   FROM store_returns sr
   WHERE sr.sr_return_quantity > 0
   GROUP BY sr.sr_store_sk, sr.sr_reason_sk
),
web_ret_agg AS (
   SELECT wr.wr_returning_cdemo_sk,
          wr.wr_reason_sk,
          SUM(wr.wr_net_loss) AS web_return_loss
   FROM web_returns wr
   WHERE wr.wr_return_quantity > 0
   GROUP BY wr.wr_returning_cdemo_sk, wr.wr_reason_sk
),
union_data AS (
   SELECT
       p.p_promo_id   AS promo_id,
       td.t_hour      AS hour,
       s.s_store_id   AS channel_id,
       cd.cd_gender   AS gender,
       r.r_reason_desc AS reason_desc,
       ss.ss_net_paid AS net_paid,
       sr_agg.store_return_loss AS net_loss
   FROM store_sales ss
   JOIN store s               ON ss.ss_store_sk = s.s_store_sk
   JOIN promotion p           ON ss.ss_promo_sk = p.p_promo_sk
   JOIN time_dim td          ON ss.ss_sold_time_sk = td.t_time_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN store_returns sr      ON ss.ss_ticket_number = sr.sr_ticket_number
   JOIN store_ret_agg sr_agg  ON sr.sr_store_sk = sr_agg.sr_store_sk
                              AND sr.sr_reason_sk = sr_agg.sr_reason_sk
   JOIN reason r              ON sr.sr_reason_sk = r.r_reason_sk
   WHERE td.t_hour IN (9, 14)
     AND p.p_response_target = 1
     AND r.r_reason_desc LIKE '%defect%'
   UNION DISTINCT
   SELECT
       p.p_promo_id   AS promo_id,
       td.t_hour      AS hour,
       sm.sm_ship_mode_id AS channel_id,
       cd.cd_gender   AS gender,
       r.r_reason_desc AS reason_desc,
       ws.ws_net_paid AS net_paid,
       wr_agg.web_return_loss AS net_loss
   FROM web_sales ws
   JOIN ship_mode sm          ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN promotion p           ON ws.ws_promo_sk = p.p_promo_sk
   JOIN time_dim td          ON ws.ws_sold_time_sk = td.t_time_sk
   JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   JOIN web_returns wr        ON ws.ws_order_number = wr.wr_order_number
   JOIN web_ret_agg wr_agg    ON wr.wr_returning_cdemo_sk = wr_agg.wr_returning_cdemo_sk
                              AND wr.wr_reason_sk = wr_agg.wr_reason_sk
   JOIN reason r              ON wr.wr_reason_sk = r.r_reason_sk
   WHERE td.t_hour IN (9, 14)
     AND p.p_response_target = 1
     AND r.r_reason_desc LIKE '%defect%'
)
SELECT
    promo_id,
    hour,
    gender,
    reason_desc,
    AVG(net_paid) AS avg_net_paid,
    AVG(net_loss) AS avg_net_loss,
    COUNT(*)      AS txn_count
FROM union_data
GROUP BY promo_id, hour, gender, reason_desc
ORDER BY avg_net_paid DESC
LIMIT 100
