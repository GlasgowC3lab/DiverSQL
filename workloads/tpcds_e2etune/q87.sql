SELECT
    s.s_store_name,
    d.d_quarter_name,
    hd.hd_income_band_sk,
    SUM(sr.sr_net_loss) AS store_net_loss,
    AVG(sr.sr_return_amt) AS avg_store_return_amt,
    COALESCE(wr_agg.web_net_loss, 0) AS web_net_loss,
    CASE
        WHEN SUM(sr.sr_net_loss) = 0 THEN NULL
        ELSE COALESCE(wr_agg.web_net_loss, 0) / SUM(sr.sr_net_loss)
    END AS web_to_store_loss_ratio,
    RANK() OVER (PARTITION BY d.d_quarter_name ORDER BY SUM(sr.sr_net_loss) DESC) AS loss_rank
FROM store_returns sr
JOIN date_dim d
    ON sr.sr_returned_date_sk = d.d_date_sk
JOIN household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN (
    SELECT
        d2.d_quarter_name,
        hd2.hd_income_band_sk,
        SUM(wr.wr_net_loss) AS web_net_loss
    FROM web_returns wr
    JOIN date_dim d2
        ON wr.wr_returned_date_sk = d2.d_date_sk
    JOIN household_demographics hd2
        ON wr.wr_refunded_hdemo_sk = hd2.hd_demo_sk
    GROUP BY d2.d_quarter_name, hd2.hd_income_band_sk
) wr_agg
    ON wr_agg.d_quarter_name = d.d_quarter_name
   AND wr_agg.hd_income_band_sk = hd.hd_income_band_sk
WHERE d.d_year = 1900
  AND hd.hd_income_band_sk IN (1, 2, 3)
GROUP BY s.s_store_name, d.d_quarter_name, hd.hd_income_band_sk, wr_agg.web_net_loss
ORDER BY d.d_quarter_name, store_net_loss DESC
LIMIT 100
