SELECT hd.hd_buy_potential AS buy_potential,
       sum(sr.sr_net_loss) AS total_store_loss,
       sum(wr.wr_net_loss) AS total_web_loss
FROM store_returns sr
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN web_returns wr ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
WHERE sr.sr_returned_date_sk = 2451376
  AND wr.wr_returned_date_sk = 2451577
GROUP BY hd.hd_buy_potential
