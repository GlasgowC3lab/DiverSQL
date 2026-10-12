WITH returns_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        i.i_category,
        i.i_brand,
        d.d_year,
        d.d_month_seq,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(wr.wr_return_quantity) AS avg_qty,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(DISTINCT cd_refunded.cd_gender) AS refunded_gender_cnt,
        COUNT(DISTINCT cd_returning.cd_gender) AS returning_gender_cnt,
        SUM(CASE WHEN cd_refunded.cd_credit_rating = 'A' THEN wr.wr_net_loss ELSE 0 END) AS net_loss_credit_A,
        SUM(CASE WHEN cd_returning.cd_credit_rating = 'A' THEN wr.wr_net_loss ELSE 0 END) AS net_loss_return_credit_A
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_demographics cd_refunded
        ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN customer_demographics cd_returning
        ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        i.i_category,
        i.i_brand,
        d.d_year,
        d.d_month_seq
)
SELECT
    ra.s_store_id,
    ra.s_store_name,
    ra.s_city,
    ra.s_state,
    ra.i_category,
    ra.i_brand,
    ra.d_year,
    ra.d_month_seq,
    ra.total_net_loss,
    ra.return_cnt,
    ra.avg_qty,
    ra.total_return_amt,
    ra.refunded_gender_cnt,
    ra.returning_gender_cnt,
    ra.net_loss_credit_A,
    ra.net_loss_return_credit_A,
    ROW_NUMBER() OVER (PARTITION BY ra.s_store_id ORDER BY ra.total_net_loss DESC) AS category_loss_rank,
    SUM(ra.total_net_loss) OVER (
        PARTITION BY ra.s_store_id
        ORDER BY ra.d_year, ra.d_month_seq
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_store_loss
FROM returns_agg ra
ORDER BY ra.total_net_loss DESC
LIMIT 100
