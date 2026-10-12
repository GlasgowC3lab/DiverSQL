WITH
  joined_data AS (
    SELECT
      cs.cs_order_number,
      cs.cs_net_profit,
      cs.cs_sold_time_sk,
      ss.ss_ticket_number,
      ss.ss_net_profit,
      ss.ss_customer_sk,
      ws.ws_order_number,
      ws.ws_net_profit,
      sr.sr_net_loss,
      wr.wr_net_loss,
      i.i_category,
      i.i_brand,
      i.i_current_price,
      c.c_customer_id,
      cd.cd_education_status,
      hd.hd_buy_potential,
      s.s_store_id,
      s.s_state,
      td.t_hour,
      inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN item i                         ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c                     ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd       ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim td                    ON cs.cs_sold_time_sk = td.t_time_sk
    LEFT JOIN inventory inv             ON i.i_item_sk = inv.inv_item_sk
    JOIN store_sales ss                 ON ss.ss_item_sk = i.i_item_sk
                                         AND ss.ss_customer_sk = c.c_customer_sk
    JOIN store s                        ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr               ON sr.sr_ticket_number = ss.ss_ticket_number
                                         AND sr.sr_item_sk = i.i_item_sk
    JOIN web_sales ws                   ON ws.ws_item_sk = i.i_item_sk
                                         AND ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_returns wr                ON wr.wr_order_number = ws.ws_order_number
                                         AND wr.wr_item_sk = i.i_item_sk
    WHERE cs.cs_net_profit > 500
      AND cd.cd_education_status = 'Advanced Degree'
      AND i.i_current_price BETWEEN 20 AND 100
      AND s.s_state = 'CA'
      AND td.t_hour BETWEEN 9 AND 18
      AND inv.inv_quantity_on_hand > 0
  ),
  customer_diff AS (
    SELECT cs.cs_bill_customer_sk AS customer_sk
    FROM catalog_sales cs
    EXCEPT
    SELECT ws.ws_bill_customer_sk
    FROM web_sales ws
  ),
  aggregated AS (
    SELECT
      jd.s_store_id,
      jd.i_category,
      jd.ss_customer_sk,
      SUM(jd.cs_net_profit)   AS sum_catalog_profit,
      SUM(jd.ss_net_profit)   AS sum_store_profit,
      SUM(jd.ws_net_profit)   AS sum_web_profit,
      SUM(jd.sr_net_loss)     AS sum_store_return_loss,
      SUM(jd.wr_net_loss)     AS sum_web_return_loss,
      COUNT(*)                AS txn_count
    FROM joined_data jd
    GROUP BY jd.s_store_id, jd.i_category, jd.ss_customer_sk
  )
SELECT
  a.s_store_id,
  a.i_category,
  AVG(a.sum_catalog_profit + a.sum_store_profit + a.sum_web_profit
      - a.sum_store_return_loss - a.sum_web_return_loss) AS avg_total_profit,
  a.txn_count
FROM aggregated a
WHERE a.ss_customer_sk IN (SELECT customer_sk FROM customer_diff)
GROUP BY a.s_store_id, a.i_category, a.txn_count
HAVING AVG(a.sum_catalog_profit + a.sum_store_profit + a.sum_web_profit
      - a.sum_store_return_loss - a.sum_web_return_loss) > 1000
ORDER BY avg_total_profit DESC
LIMIT 20
