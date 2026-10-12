WITH filtered_returns AS (
    SELECT sr.sr_item_sk,
           sr.sr_return_time_sk,
           sr.sr_return_quantity,
           sr.sr_return_amt,
           sr.sr_return_tax,
           sr.sr_net_loss,
           sr.sr_return_amt_inc_tax,
           sr.sr_return_ship_cost,
           sr.sr_fee,
           sr.sr_refunded_cash,
           sr.sr_store_credit
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 0
      AND sr.sr_return_amt > 0
),
joined AS (
    SELECT fr.sr_return_quantity,
           fr.sr_return_amt,
           fr.sr_net_loss,
           i.i_category,
           i.i_brand_id,
           t.t_hour
    FROM filtered_returns fr
    JOIN item i ON fr.sr_item_sk = i.i_item_sk
    JOIN time_dim t ON fr.sr_return_time_sk = t.t_time_sk
    WHERE i.i_category_id = 3
      AND t.t_hour BETWEEN 9 AND 17
)
SELECT
    agg.i_category,
    agg.i_brand_id,
    agg.t_hour,
    agg.return_cnt,
    agg.total_qty,
    agg.total_return_amt,
    agg.total_net_loss,
    agg.avg_return_amt,
    RANK() OVER (PARTITION BY agg.t_hour ORDER BY agg.total_net_loss DESC) AS loss_rank
FROM (
    SELECT
        j.i_category,
        j.i_brand_id,
        j.t_hour,
        COUNT(*) AS return_cnt,
        SUM(j.sr_return_quantity) AS total_qty,
        SUM(j.sr_return_amt) AS total_return_amt,
        SUM(j.sr_net_loss) AS total_net_loss,
        AVG(j.sr_return_amt) AS avg_return_amt
    FROM joined j
    GROUP BY j.i_category, j.i_brand_id, j.t_hour
    HAVING SUM(j.sr_return_quantity) > 10
) agg
ORDER BY agg.t_hour, loss_rank
LIMIT 50
