WITH inventory_daily AS (
    SELECT
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_inventory_on_hand
    FROM inventory
    GROUP BY inv_date_sk
)
SELECT
    r.s_store_id,
    r.s_store_name,
    r.d_year,
    r.d_month_seq,
    r.cd_gender,
    r.cd_marital_status,
    r.cd_credit_rating,
    r.num_returns,
    r.total_return_amount,
    r.total_net_loss,
    r.total_return_quantity,
    r.total_return_tax,
    r.avg_inventory_on_hand,
    ROW_NUMBER() OVER (PARTITION BY r.d_year, r.d_month_seq ORDER BY r.total_net_loss DESC) AS net_loss_rank
FROM (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d_ret.d_year,
        d_ret.d_month_seq,
        cd_ret.cd_gender,
        cd_ret.cd_marital_status,
        cd_ref.cd_credit_rating,
        COUNT(DISTINCT wr.wr_order_number) AS num_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_tax) AS total_return_tax,
        AVG(ia.total_inventory_on_hand) AS avg_inventory_on_hand
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN customer_demographics cd_ret
        ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN customer_demographics cd_ref
        ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN inventory_daily ia
        ON ia.inv_date_sk = d_ret.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d_ret.d_year,
        d_ret.d_month_seq,
        cd_ret.cd_gender,
        cd_ret.cd_marital_status,
        cd_ref.cd_credit_rating
) r
ORDER BY r.total_net_loss DESC
LIMIT 100
