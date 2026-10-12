/*
  Goal: Compute the average monthly net sales (ss_net_paid) for preferred customers who made purchases in 2002,
  have sufficient inventory on hand, and whose customer key appears in a list of customers with high catalog store credit.
  The query joins all seven selected tables using only the permitted join keys, aggregates per customer‑month in a CTE,
  then aggregates again to get the average per month, applying several filters and a subquery‑based IN predicate.
*/
WITH base AS (
    SELECT
        c.c_customer_sk,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_paid) AS sum_net_paid,
        SUM(ss.ss_net_profit) AS sum_net_profit,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS sum_store_return_loss,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS sum_catalog_return_loss,
        SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS sum_inventory_qty
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_customer_sk = ss.ss_customer_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND d.d_year = 2002
      AND inv.inv_quantity_on_hand > 100
      AND ss.ss_customer_sk IN (
            SELECT cr_refunded_customer_sk
            FROM catalog_returns
            WHERE cr_store_credit > 500
      )
    GROUP BY c.c_customer_sk, d.d_year, d.d_month_seq
)
SELECT
    b.d_year,
    b.d_month_seq,
    AVG(b.sum_net_paid) AS avg_monthly_net_paid,
    AVG(b.sum_net_profit) AS avg_monthly_net_profit,
    AVG(b.sum_store_return_loss) AS avg_monthly_store_return_loss,
    AVG(b.sum_catalog_return_loss) AS avg_monthly_catalog_return_loss,
    AVG(b.sum_inventory_qty) AS avg_monthly_inventory_qty
FROM base b
WHERE b.sum_net_paid > 1000
GROUP BY b.d_year, b.d_month_seq
HAVING AVG(b.sum_net_paid) > 2000
ORDER BY avg_monthly_net_paid DESC
LIMIT 100
