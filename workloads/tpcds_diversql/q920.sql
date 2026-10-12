SELECT
  d_sold.d_year,
  i.i_category,
  p.p_promo_name,
  SUM(cs.cs_net_paid) AS total_net_paid,
  SUM(cs.cs_net_profit) AS total_net_profit,
  SUM(sr.sr_net_loss) AS total_store_return_loss,
  SUM(wr.wr_net_loss) AS total_web_return_loss,
  (SUM(cs.cs_net_profit) - SUM(sr.sr_net_loss) - SUM(wr.wr_net_loss)) AS net_total_profit,
  ROW_NUMBER() OVER (PARTITION BY d_sold.d_year ORDER BY (SUM(cs.cs_net_profit) - SUM(sr.sr_net_loss) - SUM(wr.wr_net_loss)) DESC) AS profit_rank
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number AND cr.cr_item_sk = cs.cs_item_sk
JOIN date_dim d_return ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
JOIN date_dim d_store_sold ON ss.ss_sold_date_sk = d_store_sold.d_date_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = ss.ss_item_sk
JOIN date_dim d_store_return ON sr.sr_returned_date_sk = d_store_return.d_date_sk
JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d_web_sold ON ws.ws_sold_date_sk = d_web_sold.d_date_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = ws.ws_item_sk
JOIN date_dim d_web_return ON wr.wr_returned_date_sk = d_web_return.d_date_sk
JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN date_dim d_web_site_open ON wsite.web_open_date_sk = d_web_site_open.d_date_sk
JOIN date_dim d_web_site_close ON wsite.web_close_date_sk = d_web_site_close.d_date_sk
WHERE
  cc.cc_tax_percentage > 0.02
  AND i.i_current_price BETWEEN 10 AND 100
  AND hd_bill.hd_vehicle_count >= 1
  AND ib.ib_upper_bound >= 50000
  AND d_sold.d_year = 2001
  AND cs.cs_item_sk IN (SELECT i2.i_item_sk FROM item i2 WHERE i2.i_brand = 'BrandX')
  AND cs.cs_ext_discount_amt > (SELECT AVG(p2.p_cost) FROM promotion p2)
GROUP BY CUBE (d_sold.d_year, i.i_category, p.p_promo_name)
HAVING SUM(cs.cs_net_profit) > 100000
ORDER BY net_total_profit DESC, profit_rank
LIMIT 100
