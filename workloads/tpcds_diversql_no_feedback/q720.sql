/*
  Goal: Identify the most profitable catalog sales by product category and month, showing subtotals and a grand total, while excluding any orders that have a corresponding return record. The query joins all 15 selected TPC‑DS tables, re‑uses the household_demographics and customer_address tables under different aliases, computes aggregates, applies a HAVING filter, orders the results, limits to 100 rows, and forces an anti‑semi‑join via a NOT IN sub‑query.
*/
WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_catalog_page_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk,
        i.i_category,
        d_sold.d_year,
        d_sold.d_month_seq,
        p.p_promo_name,
        hd_bill.hd_income_band_sk AS bill_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        s.s_store_name,
        wp.wp_url,
        ws.web_name,
        inv.inv_quantity_on_hand,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        hd_refunded.hd_income_band_sk AS refunded_income_band_sk,
        ca_refunded.ca_state AS refunded_state,
        r.r_reason_desc
    FROM catalog_sales cs
    JOIN date_dim d_sold
      ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
      ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd_bill
      ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_bill
      ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN store s
      ON s.s_closed_date_sk = d_sold.d_date_sk
    JOIN web_page wp
      ON wp.wp_creation_date_sk = d_sold.d_date_sk
    JOIN web_site ws
      ON ws.web_open_date_sk = d_sold.d_date_sk
    JOIN income_band ib
      ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN inventory inv
           ON inv.inv_item_sk = i.i_item_sk
          AND inv.inv_date_sk = d_sold.d_date_sk
    LEFT JOIN catalog_returns cr
           ON cs.cs_order_number = cr.cr_order_number
    LEFT JOIN household_demographics hd_refunded
           ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    LEFT JOIN customer_address ca_refunded
           ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    LEFT JOIN reason r
           ON cr.cr_reason_sk = r.r_reason_sk
)
SELECT
    i_category,
    d_month_seq,
    SUM(cs_net_profit) AS total_net_profit,
    SUM(COALESCE(cr_return_amount, 0)) AS total_return_amount,
    (SELECT MAX(d_year) FROM date_dim) AS max_year
FROM base
WHERE cs_order_number NOT IN (
      SELECT cr_order_number FROM catalog_returns
    )
GROUP BY ROLLUP (i_category, d_month_seq)
HAVING SUM(cs_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 100
