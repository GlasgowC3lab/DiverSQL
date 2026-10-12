WITH base AS (
  SELECT
    s.s_store_id,
    s.s_state,
    i.i_category,
    d.d_month_seq,
    SUM(ss.ss_net_paid_inc_tax) AS total_sales,
    SUM(COALESCE(sr.sr_return_amt_inc_tax, 0)) AS total_returns,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(COALESCE(sr.sr_net_loss, 0)) * -1 AS total_return_loss,
    COUNT(DISTINCT ss.ss_ticket_number) AS txn_count
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
                       AND cs.cs_sold_date_sk = d.d_date_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                    AND inv.inv_warehouse_sk = w.w_warehouse_sk
                    AND inv.inv_date_sk = d.d_date_sk
  LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                            AND sr.sr_item_sk = i.i_item_sk
                            AND sr.sr_store_sk = s.s_store_sk
                            AND sr.sr_returned_date_sk = d.d_date_sk
                            AND sr.sr_return_time_sk = t.t_time_sk
                            AND sr.sr_customer_sk = c.c_customer_sk
                            AND sr.sr_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
                        AND wp.wp_creation_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND t.t_meal_time = 'dinner'
    AND s.s_state = 'CA'
    AND i.i_brand = 'Brand#12'
    AND p.p_discount_active = 'Y'
    AND cc.cc_name = 'Call Center 1'
    AND EXISTS (
        SELECT 1 FROM store_returns sr2
        WHERE sr2.sr_store_sk = s.s_store_sk
          AND sr2.sr_return_amt > 100
    )
  GROUP BY s.s_store_id, s.s_state, i.i_category, d.d_month_seq
),

cross_dim AS (
  SELECT DISTINCT s_state AS cd_state FROM store WHERE s_state IN ('CA', 'NY')
),

cross_set AS (
  SELECT 1 AS flag UNION ALL SELECT 2
),

ranked AS (
  SELECT
    b.s_store_id,
    b.s_state,
    b.i_category,
    b.d_month_seq,
    b.total_sales,
    b.total_returns,
    b.total_profit,
    b.total_return_loss,
    b.txn_count,
    cd.cd_state,
    cs.flag,
    ROW_NUMBER() OVER (PARTITION BY b.s_store_id ORDER BY b.total_sales DESC) AS rn
  FROM base b
  CROSS JOIN cross_dim cd
  CROSS JOIN cross_set cs
)
SELECT
  s_store_id,
  s_state,
  i_category,
  d_month_seq,
  total_sales,
  total_returns,
  total_profit,
  total_return_loss,
  txn_count,
  cd_state,
  flag,
  rn
FROM ranked
WHERE rn <= 3
ORDER BY s_store_id, rn
LIMIT 100
