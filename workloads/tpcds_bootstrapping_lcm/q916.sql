WITH cat_agg AS (
    SELECT
        d.d_date_sk AS d_date_sk,
        s.s_market_id,
        cd_ref.cd_gender AS refunded_gender,
        cd_ret.cd_gender AS returning_gender,
        SUM(cr.cr_net_loss) AS cat_net_loss,
        COUNT(*) AS cat_return_cnt,
        AVG(cr.cr_return_amount) AS cat_avg_return_amount,
        SUM(cr.cr_fee) AS cat_total_fee
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    GROUP BY d.d_date_sk, s.s_market_id, cd_ref.cd_gender, cd_ret.cd_gender
),
web_agg AS (
    SELECT
        d.d_date_sk AS d_date_sk,
        s.s_market_id,
        cd_ref.cd_gender AS refunded_gender,
        cd_ret.cd_gender AS returning_gender,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(*) AS web_return_cnt,
        AVG(wr.wr_return_amt) AS web_avg_return_amount,
        SUM(wr.wr_fee) AS web_total_fee
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN customer_demographics cd_ref ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN customer_demographics cd_ret ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
    GROUP BY d.d_date_sk, s.s_market_id, cd_ref.cd_gender, cd_ret.cd_gender
)
SELECT
    d.d_year,
    d.d_month_seq,
    ca.s_market_id,
    ca.refunded_gender,
    ca.returning_gender,
    ca.cat_net_loss,
    wa.web_net_loss,
    ca.cat_return_cnt,
    wa.web_return_cnt,
    ca.cat_avg_return_amount,
    wa.web_avg_return_amount,
    ca.cat_total_fee,
    wa.web_total_fee,
    COALESCE(ca.cat_net_loss, 0) + COALESCE(wa.web_net_loss, 0) AS total_net_loss,
    CASE
        WHEN COALESCE(ca.cat_net_loss, 0) + COALESCE(wa.web_net_loss, 0) = 0 THEN NULL
        ELSE COALESCE(ca.cat_net_loss, 0) / (COALESCE(ca.cat_net_loss, 0) + COALESCE(wa.web_net_loss, 0))
    END AS cat_loss_ratio,
    CASE
        WHEN COALESCE(ca.cat_net_loss, 0) + COALESCE(wa.web_net_loss, 0) = 0 THEN NULL
        ELSE COALESCE(wa.web_net_loss, 0) / (COALESCE(ca.cat_net_loss, 0) + COALESCE(wa.web_net_loss, 0))
    END AS web_loss_ratio
FROM cat_agg ca
FULL OUTER JOIN web_agg wa
    ON ca.d_date_sk = wa.d_date_sk
    AND ca.s_market_id = wa.s_market_id
    AND ca.refunded_gender = wa.refunded_gender
    AND ca.returning_gender = wa.returning_gender
JOIN date_dim d ON COALESCE(ca.d_date_sk, wa.d_date_sk) = d.d_date_sk
WHERE d.d_year BETWEEN 2020 AND 2022
ORDER BY d.d_year, d.d_month_seq, ca.s_market_id, ca.refunded_gender, ca.returning_gender
LIMIT 200
