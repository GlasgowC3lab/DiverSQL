WITH base AS (
   SELECT
       i.i_item_sk,
       i.i_brand,
       i.i_category,
       i.i_units,
       inv.inv_warehouse_sk,
       inv.inv_quantity_on_hand,
       wr.wr_return_quantity,
       wr.wr_return_amt,
       wr.wr_returned_date_sk
   FROM tpcds.inventory inv
   JOIN tpcds.item i ON inv.inv_item_sk = i.i_item_sk
   JOIN tpcds.web_returns wr ON wr.wr_item_sk = i.i_item_sk
   WHERE i.i_units IN ('Pound', 'Ton', 'Ounce', 'Dram', 'Carton')
     AND i.i_brand_id BETWEEN 10 AND 20
     AND inv.inv_quantity_on_hand > 0
     AND wr.wr_return_quantity > 0
     AND inv.inv_warehouse_sk IN (3, 6, 12, 13, 20)
     AND wr.wr_returned_date_sk BETWEEN 2451200 AND 2451300
),
agg1 AS (
   SELECT
       i_item_sk,
       i_brand,
       i_category,
       SUM(inv_quantity_on_hand) AS total_on_hand,
       SUM(wr_return_quantity)   AS total_return_qty,
       SUM(wr_return_amt)        AS total_return_amt
   FROM base
   GROUP BY i_item_sk, i_brand, i_category
   HAVING SUM(wr_return_amt) > 100
),
ranked AS (
   SELECT
       i_item_sk,
       i_brand,
       i_category,
       total_on_hand,
       total_return_qty,
       total_return_amt,
       ROW_NUMBER() OVER (PARTITION BY i_brand ORDER BY total_return_amt DESC) AS brand_rank
   FROM agg1
   WHERE total_on_hand > 10
),
final AS (
   SELECT DISTINCT
       r.i_item_sk,
       r.i_brand,
       r.i_category,
       r.total_on_hand,
       r.total_return_qty,
       r.total_return_amt,
       r.brand_rank
   FROM ranked r
   WHERE EXISTS (
       SELECT 1
       FROM tpcds.web_returns wr2
       WHERE wr2.wr_item_sk = r.i_item_sk
         AND wr2.wr_return_amt > 0
   )
     AND r.brand_rank <= 5
)
SELECT
    i_item_sk,
    i_brand,
    i_category,
    total_on_hand,
    total_return_qty,
    total_return_amt,
    brand_rank
FROM final
WHERE i_item_sk NOT IN (
    SELECT inv_item_sk
    FROM tpcds.inventory
    WHERE inv_quantity_on_hand = 0
    EXCEPT
    SELECT i_item_sk
    FROM tpcds.item
    WHERE i_current_price IS NULL
)
ORDER BY total_return_amt DESC, i_item_sk
LIMIT 100
