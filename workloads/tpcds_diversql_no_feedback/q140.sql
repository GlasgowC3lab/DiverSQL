WITH joined_data AS (
   SELECT
       sm.sm_ship_mode_id,
       ss.ss_net_profit,
       ws.ws_net_profit,
       cr.cr_net_loss,
       wr.wr_net_loss,
       ss.ss_ticket_number,
       ws.ws_order_number,
       ss.ss_sold_date_sk,
       sm.sm_contract,
       wsite.web_country
   FROM store_sales ss
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN catalog_returns cr ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
                         AND cr.cr_returning_hdemo_sk = hd.hd_demo_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN web_sales ws ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
                    AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   JOIN web_returns wr ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
                      AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
                      AND wr.wr_order_number = ws.ws_order_number
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
),
agg_a AS (
   SELECT
       sm_ship_mode_id,
       SUM(ss_net_profit) AS total_store_profit,
       SUM(ws_net_profit) AS total_web_profit,
       SUM(cr_net_loss) AS total_catalog_return_loss,
       SUM(wr_net_loss) AS total_web_return_loss,
       COUNT(DISTINCT ss_ticket_number) AS store_transactions,
       COUNT(DISTINCT ws_order_number) AS web_transactions
   FROM joined_data
   WHERE sm_contract = 'HVDFCcQ'
     AND ss_sold_date_sk BETWEEN 2452000 AND 2453000
     AND web_country = 'United States'
   GROUP BY sm_ship_mode_id
),
agg_b AS (
   SELECT
       sm_ship_mode_id,
       SUM(ss_net_profit) AS total_store_profit,
       SUM(ws_net_profit) AS total_web_profit,
       SUM(cr_net_loss) AS total_catalog_return_loss,
       SUM(wr_net_loss) AS total_web_return_loss,
       COUNT(DISTINCT ss_ticket_number) AS store_transactions,
       COUNT(DISTINCT ws_order_number) AS web_transactions
   FROM joined_data
   WHERE sm_contract = 'yVfotg7Tio3MVhBg6Bkn'
     AND ss_sold_date_sk BETWEEN 2451000 AND 2451500
     AND web_country = 'Canada'
   GROUP BY sm_ship_mode_id
),
union_agg AS (
   SELECT * FROM agg_a
   UNION
   SELECT * FROM agg_b
)
SELECT
   ship_mode_id,
   (total_store_profit + total_web_profit - total_catalog_return_loss - total_web_return_loss) AS net_profit,
   (total_store_profit + total_web_profit - total_catalog_return_loss - total_web_return_loss) / NULLIF((store_transactions + web_transactions), 0) AS profit_per_txn
FROM (
   SELECT
       sm_ship_mode_id AS ship_mode_id,
       SUM(total_store_profit) AS total_store_profit,
       SUM(total_web_profit) AS total_web_profit,
       SUM(total_catalog_return_loss) AS total_catalog_return_loss,
       SUM(total_web_return_loss) AS total_web_return_loss,
       SUM(store_transactions) AS store_transactions,
       SUM(web_transactions) AS web_transactions
   FROM union_agg
   GROUP BY sm_ship_mode_id
) final
ORDER BY net_profit DESC
LIMIT 100
