WITH sales_agg AS (
   SELECT
      hd.hd_income_band_sk,
      hd.hd_vehicle_count,
      hd.hd_buy_potential,
      p.p_channel_tv,
      p.p_channel_email,
      date_trunc('month', from_unixtime(cs.cs_sold_date_sk * 86400)) AS month,
      SUM(cs.cs_net_paid) AS total_sales_amount,
      SUM(cs.cs_net_profit) AS total_sales_profit,
      COUNT(DISTINCT cs.cs_order_number) AS num_orders
   FROM catalog_sales cs
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2450825
     AND p.p_discount_active = 'Y'
   GROUP BY
      hd.hd_income_band_sk,
      hd.hd_vehicle_count,
      hd.hd_buy_potential,
      p.p_channel_tv,
      p.p_channel_email,
      date_trunc('month', from_unixtime(cs.cs_sold_date_sk * 86400))
),
store_sales_agg AS (
   SELECT
      hd.hd_income_band_sk,
      hd.hd_vehicle_count,
      hd.hd_buy_potential,
      p.p_channel_tv,
      p.p_channel_email,
      date_trunc('month', from_unixtime(ss.ss_sold_date_sk * 86400)) AS month,
      SUM(ss.ss_net_paid) AS total_sales_amount,
      SUM(ss.ss_net_profit) AS total_sales_profit,
      COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions
   FROM store_sales ss
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2450825
     AND p.p_discount_active = 'Y'
   GROUP BY
      hd.hd_income_band_sk,
      hd.hd_vehicle_count,
      hd.hd_buy_potential,
      p.p_channel_tv,
      p.p_channel_email,
      date_trunc('month', from_unixtime(ss.ss_sold_date_sk * 86400))
),
returns_agg AS (
   SELECT
      hd.hd_income_band_sk,
      hd.hd_vehicle_count,
      hd.hd_buy_potential,
      p.p_channel_tv,
      p.p_channel_email,
      date_trunc('month', from_unixtime(sr.sr_returned_date_sk * 86400)) AS month,
      SUM(sr.sr_net_loss) AS total_return_loss,
      COUNT(DISTINCT sr.sr_ticket_number) AS num_returns
   FROM store_returns sr
   JOIN store_sales ss
     ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = ss.ss_item_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   WHERE sr.sr_returned_date_sk BETWEEN 2450815 AND 2450825
   GROUP BY
      hd.hd_income_band_sk,
      hd.hd_vehicle_count,
      hd.hd_buy_potential,
      p.p_channel_tv,
      p.p_channel_email,
      date_trunc('month', from_unixtime(sr.sr_returned_date_sk * 86400))
)
SELECT
   COALESCE(sa.hd_income_band_sk, ssa.hd_income_band_sk, ra.hd_income_band_sk) AS income_band_sk,
   COALESCE(sa.hd_vehicle_count, ssa.hd_vehicle_count, ra.hd_vehicle_count) AS vehicle_count,
   COALESCE(sa.hd_buy_potential, ssa.hd_buy_potential, ra.hd_buy_potential) AS buy_potential,
   COALESCE(sa.p_channel_tv, ssa.p_channel_tv, ra.p_channel_tv) AS channel_tv,
   COALESCE(sa.p_channel_email, ssa.p_channel_email, ra.p_channel_email) AS channel_email,
   COALESCE(sa.month, ssa.month, ra.month) AS month,
   COALESCE(sa.total_sales_amount, 0) + COALESCE(ssa.total_sales_amount, 0) AS total_sales_amount,
   COALESCE(sa.total_sales_profit, 0) + COALESCE(ssa.total_sales_profit, 0) AS total_sales_profit,
   COALESCE(ra.total_return_loss, 0) AS total_return_loss,
   (COALESCE(sa.total_sales_profit, 0) + COALESCE(ssa.total_sales_profit, 0) - COALESCE(ra.total_return_loss, 0)) AS net_profit_adj,
   (COALESCE(sa.num_orders, 0) + COALESCE(ssa.num_transactions, 0)) AS total_transactions,
   COALESCE(ra.num_returns, 0) AS total_returns,
   RANK() OVER (PARTITION BY COALESCE(sa.month, ssa.month, ra.month)
                ORDER BY (COALESCE(sa.total_sales_profit, 0) + COALESCE(ssa.total_sales_profit, 0) - COALESCE(ra.total_return_loss, 0)) DESC) AS profit_rank
FROM sales_agg sa
FULL OUTER JOIN store_sales_agg ssa
   ON sa.hd_income_band_sk = ssa.hd_income_band_sk
  AND sa.hd_vehicle_count = ssa.hd_vehicle_count
  AND sa.hd_buy_potential = ssa.hd_buy_potential
  AND sa.p_channel_tv = ssa.p_channel_tv
  AND sa.p_channel_email = ssa.p_channel_email
  AND sa.month = ssa.month
FULL OUTER JOIN returns_agg ra
   ON COALESCE(sa.hd_income_band_sk, ssa.hd_income_band_sk) = ra.hd_income_band_sk
  AND COALESCE(sa.hd_vehicle_count, ssa.hd_vehicle_count) = ra.hd_vehicle_count
  AND COALESCE(sa.hd_buy_potential, ssa.hd_buy_potential) = ra.hd_buy_potential
  AND COALESCE(sa.p_channel_tv, ssa.p_channel_tv) = ra.p_channel_tv
  AND COALESCE(sa.p_channel_email, ssa.p_channel_email) = ra.p_channel_email
  AND COALESCE(sa.month, ssa.month) = ra.month
WHERE (COALESCE(sa.total_sales_amount, 0) + COALESCE(ssa.total_sales_amount, 0)) > 0
ORDER BY net_profit_adj DESC
LIMIT 200
