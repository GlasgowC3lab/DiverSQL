SELECT hd_buy_potential,
       SUM(ss_net_paid) AS total_net_paid
FROM store_sales
JOIN household_demographics
  ON store_sales.ss_hdemo_sk = household_demographics.hd_demo_sk
WHERE hd_income_band_sk = 4
GROUP BY hd_buy_potential
