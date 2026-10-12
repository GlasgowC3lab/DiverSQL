WITH store_data AS (
   SELECT
       c.c_customer_id,
       hd.hd_buy_potential,
       sr.sr_net_loss,
       CASE WHEN sr.sr_net_loss > 500 THEN 'High' ELSE 'Low' END AS loss_flag
   FROM store_returns sr
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
   WHERE sr.sr_net_loss > 0
),
web_data AS (
   SELECT
       c.c_customer_id,
       hd.hd_buy_potential,
       wr.wr_net_loss,
       CASE WHEN wr.wr_net_loss > 500 THEN 'High' ELSE 'Low' END AS loss_flag
   FROM web_returns wr
   JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
   JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
   WHERE wr.wr_net_loss > 0
),
union_data AS (
   SELECT c_customer_id, hd_buy_potential, sr_net_loss AS net_loss, loss_flag
   FROM store_data
   UNION
   SELECT c_customer_id, hd_buy_potential, wr_net_loss AS net_loss, loss_flag
   FROM web_data
),
agg_data AS (
   SELECT
       c_customer_id,
       hd_buy_potential,
       SUM(net_loss) AS total_net_loss,
       MAX(loss_flag) AS overall_flag
   FROM union_data
   GROUP BY c_customer_id, hd_buy_potential
),
ranked AS (
   SELECT
       c_customer_id,
       hd_buy_potential,
       total_net_loss,
       CASE
           WHEN total_net_loss > 1000 THEN 'High'
           WHEN total_net_loss > 100  THEN 'Medium'
           ELSE 'Low'
       END AS loss_category,
       ROW_NUMBER() OVER (PARTITION BY hd_buy_potential ORDER BY total_net_loss DESC) AS rn
   FROM agg_data
)
SELECT
   c_customer_id,
   hd_buy_potential,
   total_net_loss,
   loss_category
FROM ranked
WHERE rn <= 5
ORDER BY hd_buy_potential, total_net_loss DESC
LIMIT 100
