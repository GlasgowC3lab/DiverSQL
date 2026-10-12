WITH inventory_agg AS (
    SELECT
        inv_item_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 500
      AND inv_warehouse_sk IN (4, 7, 9)
    GROUP BY inv_item_sk, inv_date_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    d.d_year,
    d.d_month_seq,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(sr.sr_return_amt) AS total_store_return_amt,
    SUM(wr.wr_return_amt) AS total_web_return_amt,
    SUM(ia.total_quantity_on_hand) AS total_inventory_qty,
    SUM(COALESCE(r.total_store_return_amt, 0) + COALESCE(r.total_web_return_amt, 0)) AS lateral_total_return_amt
FROM store_sales ss
JOIN date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
 AND sr.sr_returned_date_sk = d.d_date_sk
 AND sr.sr_customer_sk = c.c_customer_sk
 AND sr.sr_hdemo_sk = hd.hd_demo_sk
 AND sr.sr_addr_sk = ca.ca_address_sk
JOIN web_returns wr
  ON wr.wr_returning_customer_sk = c.c_customer_sk
 AND wr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN inventory_agg ia
  ON ia.inv_item_sk = ss.ss_item_sk
 AND ia.inv_date_sk = d.d_date_sk
LEFT JOIN LATERAL (
    SELECT
        SUM(sr2.sr_return_amt) AS total_store_return_amt,
        SUM(wr2.wr_return_amt) AS total_web_return_amt
    FROM store_returns sr2
    JOIN web_returns wr2
      ON wr2.wr_returned_date_sk = sr2.sr_returned_date_sk
    WHERE sr2.sr_item_sk = ss.ss_item_sk
      AND sr2.sr_returned_date_sk = d.d_date_sk
) r ON TRUE
WHERE d.d_year = 2002
  AND d.d_month_seq BETWEEN 1200 AND 1210
  AND c.c_preferred_cust_flag = 'Y'
  AND c.c_birth_year BETWEEN 1950 AND 1970
  AND hd.hd_buy_potential = 'HIGH'
  AND ib.ib_lower_bound >= 50000
  AND ca.ca_state = 'CA'
  AND sr.sr_return_amt > 0
  AND wr.wr_return_amt > 0
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    d.d_year,
    d.d_month_seq,
    ca.ca_state
ORDER BY total_sales DESC
