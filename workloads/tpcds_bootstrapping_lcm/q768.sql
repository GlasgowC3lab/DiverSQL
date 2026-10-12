WITH catalog_agg AS (
    SELECT cr.cr_returned_date_sk AS date_sk,
           SUM(cr.cr_return_amount) AS catalog_return_amount,
           SUM(cr.cr_fee) AS catalog_fee,
           SUM(cr.cr_net_loss) AS catalog_net_loss,
           COUNT(*) AS catalog_return_cnt
    FROM catalog_returns cr
    GROUP BY cr.cr_returned_date_sk
),
web_agg AS (
    SELECT wr.wr_returned_date_sk AS date_sk,
           SUM(wr.wr_return_amt) AS web_return_amount,
           SUM(wr.wr_fee) AS web_fee,
           SUM(wr.wr_net_loss) AS web_net_loss,
           COUNT(*) AS web_return_cnt
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk
),
inventory_agg AS (
    SELECT inv.inv_date_sk AS date_sk,
           SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
    FROM inventory inv
    GROUP BY inv.inv_date_sk
),
store_agg AS (
    SELECT s.s_closed_date_sk AS date_sk,
           COUNT(*) AS closed_store_cnt
    FROM store s
    GROUP BY s.s_closed_date_sk
)
SELECT d.d_date,
       d.d_year,
       d.d_month_seq,
       COALESCE(ca.catalog_return_amount, 0) AS catalog_return_amount,
       COALESCE(wa.web_return_amount, 0) AS web_return_amount,
       COALESCE(ca.catalog_fee, 0) + COALESCE(wa.web_fee, 0) AS total_fees,
       COALESCE(ca.catalog_net_loss, 0) + COALESCE(wa.web_net_loss, 0) AS total_net_loss,
       COALESCE(ca.catalog_return_cnt, 0) + COALESCE(wa.web_return_cnt, 0) AS total_return_cnt,
       CASE 
           WHEN (COALESCE(ca.catalog_return_cnt, 0) + COALESCE(wa.web_return_cnt, 0)) = 0 THEN 0
           ELSE (COALESCE(ca.catalog_net_loss, 0) + COALESCE(wa.web_net_loss, 0)) /
                (COALESCE(ca.catalog_return_cnt, 0) + COALESCE(wa.web_return_cnt, 0))
       END AS avg_net_loss_per_return,
       COALESCE(ia.total_inventory_qty, 0) AS total_inventory_qty,
       COALESCE(sa.closed_store_cnt, 0) AS closed_store_cnt,
       ROW_NUMBER() OVER (ORDER BY COALESCE(ca.catalog_net_loss, 0) + COALESCE(wa.web_net_loss, 0) DESC) AS net_loss_rank
FROM date_dim d
LEFT JOIN catalog_agg ca ON ca.date_sk = d.d_date_sk
LEFT JOIN web_agg wa ON wa.date_sk = d.d_date_sk
LEFT JOIN inventory_agg ia ON ia.date_sk = d.d_date_sk
LEFT JOIN store_agg sa ON sa.date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2020 AND 2023
ORDER BY total_net_loss DESC
LIMIT 100
