SELECT
    cs.cs_order_number,
    cs.cs_net_profit,
    s.s_store_id,
    s.s_store_name,
    td.t_hour,
    cd.cd_gender,
    hd.hd_vehicle_count,
    ib.ib_upper_bound,
    r.r_reason_desc,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY cs.cs_net_profit DESC) AS profit_rank
FROM catalog_sales cs
JOIN time_dim td
  ON cs.cs_sold_time_sk = td.t_time_sk
JOIN customer_demographics cd
  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca
  ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN store_sales ss
  ON ss.ss_sold_time_sk = td.t_time_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
WHERE td.t_shift = 'first'
  AND td.t_hour >= 10
  AND cd.cd_gender = 'M'
  AND hd.hd_vehicle_count >= 1
  AND ib.ib_upper_bound <= 130000
  AND s.s_state = 'CA'
  AND cs.cs_quantity > 5
  AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_ticket_number = cs.cs_order_number
          AND sr2.sr_return_quantity > 0
    )
