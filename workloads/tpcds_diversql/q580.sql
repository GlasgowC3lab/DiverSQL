WITH all_data AS (
   SELECT
       cs.cs_order_number,
       cs.cs_net_paid,
       cs.cs_net_profit,
       cs.cs_sold_date_sk            AS sold_date_sk,
       d_sold.d_year                 AS sold_year,
       cd_bill.cd_gender             AS bill_gender,
       sr.sr_return_quantity,
       sr.sr_net_loss,
       sr.sr_returned_date_sk,
       sr.sr_return_time_sk,
       st.s_store_sk                 AS store_sk,
       d_store_closed.d_year         AS store_closed_year,
       ss.ss_quantity,
       ss.ss_net_paid                AS ss_net_paid,
       ss.ss_net_profit              AS ss_net_profit,
       t_ss.t_hour                   AS ss_sold_hour,
       t_return.t_hour               AS return_hour,
       cd_store.cd_gender            AS store_cust_gender,
       cd_return.cd_gender           AS return_gender,
       cc.cc_name,
       d_ss_sold.d_year              AS ss_sold_year
   FROM catalog_sales cs
   JOIN date_dim d_sold
       ON cs.cs_sold_date_sk = d_sold.d_date_sk                                   -- join 1
   JOIN date_dim d_ship
       ON cs.cs_ship_date_sk = d_ship.d_date_sk                                   -- join 2
   JOIN time_dim t_sold
       ON cs.cs_sold_time_sk = t_sold.t_time_sk                                   -- join 3
   JOIN customer_demographics cd_bill
       ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk                               -- join 4
   JOIN customer_demographics cd_ship
       ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk                               -- join 5
   JOIN call_center cc
       ON cs.cs_call_center_sk = cc.cc_call_center_sk                             -- join 6
   JOIN store_returns sr
       ON sr.sr_returned_date_sk = d_sold.d_date_sk                               -- join 7 (second use of date_dim)
   JOIN store_sales ss
       ON ss.ss_item_sk = sr.sr_item_sk                                            -- join 8 (item key)
       AND ss.ss_ticket_number = sr.sr_ticket_number                               -- same join clause
   JOIN store st
       ON ss.ss_store_sk = st.s_store_sk                                           -- join 9
   JOIN date_dim d_store_closed
       ON st.s_closed_date_sk = d_store_closed.d_date_sk                           -- join 10
   JOIN date_dim d_return
       ON sr.sr_returned_date_sk = d_return.d_date_sk                              -- join 11 (different alias)
   JOIN time_dim t_return
       ON sr.sr_return_time_sk = t_return.t_time_sk                                -- join 12
   JOIN customer_demographics cd_return
       ON sr.sr_cdemo_sk = cd_return.cd_demo_sk                                   -- join 13
   JOIN customer_demographics cd_store
       ON ss.ss_cdemo_sk = cd_store.cd_demo_sk                                    -- join 14
   JOIN time_dim t_ss
       ON ss.ss_sold_time_sk = t_ss.t_time_sk                                    -- join 15
   JOIN date_dim d_ss_sold
       ON ss.ss_sold_date_sk = d_ss_sold.d_date_sk                               -- join 16
   WHERE d_sold.d_year = 2001                                                    -- filter on a DATE column
)
SELECT
    sold_year,
    bill_gender,
    SUM(cs_net_paid)   AS total_net_paid,
    SUM(cs_net_profit) AS total_net_profit,
    SUM(sr_net_loss)   AS total_net_loss,
    ROW_NUMBER() OVER (ORDER BY SUM(cs_net_paid) DESC)          AS global_rn,
    RANK()       OVER (PARTITION BY sold_year ORDER BY SUM(cs_net_profit) DESC) AS yearly_rank
FROM all_data ad
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr2
    WHERE sr2.sr_ticket_number = ad.cs_order_number
      AND sr2.sr_return_quantity > 0
      AND sr2.sr_returned_date_sk = ad.sold_date_sk
      AND sr2.sr_store_sk = ad.store_sk
)
GROUP BY GROUPING SETS (
    (sold_year, bill_gender),
    (sold_year)
)
ORDER BY total_net_paid DESC
LIMIT 100
