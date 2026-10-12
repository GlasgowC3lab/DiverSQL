WITH item_returns AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        i.i_category,
        i.i_color,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        AVG(wr.wr_return_amt_inc_tax) AS avg_return_amt_inc_tax,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
        MAX(wr.wr_returned_date_sk) AS last_return_date_sk
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE i.i_current_price > 50
      AND wr.wr_returned_date_sk BETWEEN 2450815 AND 2451088
    GROUP BY i.i_item_sk, i.i_brand, i.i_category, i.i_color
)
SELECT
    ir.i_brand,
    ir.i_category,
    ir.i_color,
    ir.total_return_qty,
    ir.total_net_loss,
    ir.total_return_amt_inc_tax,
    ir.avg_return_amt_inc_tax,
    ir.distinct_orders,
    RANK() OVER (PARTITION BY ir.i_brand ORDER BY ir.total_net_loss DESC) AS brand_net_loss_rank,
    ROW_NUMBER() OVER (ORDER BY ir.total_net_loss DESC) AS overall_net_loss_rank
FROM item_returns ir
WHERE ir.total_return_qty > 10
ORDER BY ir.total_net_loss DESC
LIMIT 100
