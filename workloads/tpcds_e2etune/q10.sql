WITH aggregated AS (
    SELECT
        i.i_category AS category,
        cd_ref.cd_gender AS refunded_gender,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        AVG(wr.wr_return_amt_inc_tax) AS avg_return_amt_inc_tax,
        COUNT(*) AS num_returns
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_demographics cd_ref ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN household_demographics hd_ref ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN customer_demographics cd_ret ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN household_demographics hd_ret ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
    WHERE
        cd_ref.cd_credit_rating = 'Good'
        AND cd_ret.cd_credit_rating = 'Good'
        AND i.i_current_price > 20
        AND wr.wr_returned_date_sk BETWEEN 20210101 AND 20211231
        AND hd_ref.hd_buy_potential = 'High'
        AND hd_ret.hd_buy_potential = 'High'
    GROUP BY
        i.i_category,
        cd_ref.cd_gender
)
SELECT
    category,
    refunded_gender,
    total_net_loss,
    total_return_qty,
    avg_return_amt_inc_tax,
    num_returns,
    RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank
FROM aggregated
ORDER BY loss_rank
LIMIT 50
