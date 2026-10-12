WITH ret_agg AS (
    SELECT sr.sr_customer_sk,
           sr.sr_store_sk,
           sr.sr_item_sk,
           SUM(sr.sr_net_loss) AS total_net_loss,
           SUM(sr.sr_refunded_cash) AS total_refunded_cash,
           SUM(sr.sr_return_amt) AS total_return_amt,
           SUM(sr.sr_return_quantity) AS total_return_qty,
           COUNT(*) AS return_txns
    FROM store_returns sr
    GROUP BY sr.sr_customer_sk, sr.sr_store_sk, sr.sr_item_sk
),
inv_agg AS (
    SELECT i.inv_item_sk,
           SUM(i.inv_quantity_on_hand) AS total_inventory_qty
    FROM inventory i
    GROUP BY i.inv_item_sk
),
cust_store AS (
    SELECT r.sr_customer_sk AS customer_sk,
           r.sr_store_sk AS store_sk,
           SUM(r.total_net_loss) AS cust_total_net_loss,
           SUM(r.total_refunded_cash) AS cust_total_refunded_cash,
           SUM(r.total_return_amt) AS cust_total_return_amt,
           SUM(r.total_return_qty) AS cust_total_return_qty,
           SUM(r.return_txns) AS cust_return_txns,
           AVG(i.total_inventory_qty) AS avg_inventory_qty_of_returned_items
    FROM ret_agg r
    INNER JOIN inv_agg i ON r.sr_item_sk = i.inv_item_sk
    GROUP BY r.sr_customer_sk, r.sr_store_sk
)
SELECT s.s_store_id,
       s.s_store_name,
       cs.customer_sk,
       cs.cust_total_net_loss,
       cs.cust_total_refunded_cash,
       cs.cust_total_return_amt,
       cs.cust_total_return_qty,
       cs.cust_return_txns,
       cs.avg_inventory_qty_of_returned_items,
       CASE 
           WHEN cs.cust_total_return_amt = 0 THEN NULL
           ELSE (cs.cust_total_refunded_cash - cs.cust_total_net_loss) / cs.cust_total_return_amt
       END AS profit_margin,
       CASE 
           WHEN (cs.cust_total_refunded_cash - cs.cust_total_net_loss) / NULLIF(cs.cust_total_return_amt,0) > 0.2 THEN 'Profitable'
           WHEN (cs.cust_total_refunded_cash - cs.cust_total_net_loss) / NULLIF(cs.cust_total_return_amt,0) BETWEEN -0.05 AND 0.2 THEN 'Break-even'
           ELSE 'Loss'
       END AS profitability,
       ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY 
           CASE WHEN cs.cust_total_return_amt = 0 THEN 0
                ELSE (cs.cust_total_refunded_cash - cs.cust_total_net_loss) / cs.cust_total_return_amt
           END DESC) AS profit_rank
FROM cust_store cs
INNER JOIN store s ON cs.store_sk = s.s_store_sk
ORDER BY s.s_store_id, profit_rank
LIMIT 100
