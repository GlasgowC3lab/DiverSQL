WITH brand_returns AS (
    SELECT
        i.i_brand,
        i.i_size,
        i.i_units,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_amt) AS avg_return_amt,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450000 AND 2450999
      AND i.i_brand_id IN (5003002, 1001001)
      AND i.i_units = 'Bunch'
    GROUP BY i.i_brand, i.i_size, i.i_units
    HAVING SUM(sr.sr_net_loss) > 1000
)
SELECT
    i_brand,
    i_size,
    i_units,
    total_net_loss,
    avg_return_amt,
    return_cnt,
    RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank
FROM brand_returns
ORDER BY loss_rank
LIMIT 10
