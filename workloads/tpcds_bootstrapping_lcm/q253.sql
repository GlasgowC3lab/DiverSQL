WITH sr_agg AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_cdemo_sk,
        sr.sr_returned_date_sk,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_amt) AS total_return_amount,
        COUNT(*) AS total_returns,
        AVG(sr.sr_return_quantity) AS avg_return_quantity
    FROM store_returns sr
    GROUP BY sr.sr_store_sk, sr.sr_cdemo_sk, sr.sr_returned_date_sk
)
SELECT
    cc.cc_market_manager,
    cc.cc_name,
    cd.cd_gender,
    cd.cd_education_status,
    s.s_store_name,
    s.s_city,
    dr.d_year,
    dr.d_month_seq,
    sr_agg.total_net_loss,
    sr_agg.total_return_amount,
    sr_agg.total_returns,
    sr_agg.avg_return_quantity,
    ROW_NUMBER() OVER (PARTITION BY dr.d_year ORDER BY sr_agg.total_net_loss DESC) AS net_loss_rank
FROM sr_agg
JOIN date_dim dr ON sr_agg.sr_returned_date_sk = dr.d_date_sk
JOIN customer_demographics cd ON sr_agg.sr_cdemo_sk = cd.cd_demo_sk
JOIN store s ON sr_agg.sr_store_sk = s.s_store_sk
JOIN date_dim ds ON s.s_closed_date_sk = ds.d_date_sk
JOIN call_center cc ON cc.cc_closed_date_sk = ds.d_date_sk
JOIN date_dim dco ON cc.cc_open_date_sk = dco.d_date_sk
WHERE dr.d_year BETWEEN 2015 AND 2022
ORDER BY dr.d_year, net_loss_rank
LIMIT 100
