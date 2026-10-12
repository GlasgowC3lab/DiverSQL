SELECT
    hd.hd_demo_sk,
    hd.hd_income_band_sk,
    cd.cd_gender,
    COUNT(*) AS txn_count,
    AVG(ss.ss_net_profit) AS avg_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    SUM(CASE WHEN ss.ss_ext_discount_amt > 5 THEN 1 ELSE 0 END) AS high_discount_txns,
    (SUM(CASE WHEN ss.ss_ext_discount_amt > 5 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS pct_high_discount,
    RANK() OVER (ORDER BY AVG(ss.ss_net_profit) DESC) AS profit_rank
FROM store_sales ss
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
GROUP BY
    hd.hd_demo_sk,
    hd.hd_income_band_sk,
    cd.cd_gender
HAVING COUNT(*) >= 50
ORDER BY profit_rank
