/* Goal: Identify the top 5 stores (by store key) for the most recent year, based on a combined profit/loss metric that pulls together sales, catalog sales and all return types. The query joins every selected TPC‑DS table, re‑uses the DATE_DIM and CUSTOMER dimensions under different aliases, compares a column to a scalar sub‑query, aggregates the data, ranks stores per year and returns the top‑k rows. */
WITH
  /* Base fact joins – left‑deep chain */
  base AS (
    SELECT
      d_sales.d_year,
      s.ss_store_sk,
      s.ss_net_profit,
      cs.cs_net_profit,
      sr.sr_net_loss,
      cr.cr_net_loss,
      wr.wr_net_loss
    FROM
      store_sales s
      /* 1 */ JOIN date_dim d_sales ON s.ss_sold_date_sk = d_sales.d_date_sk
      /* 2 */ JOIN customer c1 ON s.ss_customer_sk = c1.c_customer_sk
      /* 3 */ JOIN promotion p1 ON s.ss_promo_sk = p1.p_promo_sk
      /* 4 */ JOIN catalog_sales cs ON cs.cs_sold_date_sk = d_sales.d_date_sk
                                AND cs.cs_bill_customer_sk = c1.c_customer_sk
      /* 5 */ JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
      /* 6 */ JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
      /* 7 */ JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
      /* 8 */ JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
      /* 9 */ JOIN store_returns sr ON sr.sr_ticket_number = s.ss_ticket_number
      /* 10 */ JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
      /* 11 */ JOIN customer c2 ON sr.sr_customer_sk = c2.c_customer_sk
      /* 12 */ JOIN inventory i ON i.inv_date_sk = d_return.d_date_sk
      /* 13 */ JOIN date_dim d_inventory ON i.inv_date_sk = d_inventory.d_date_sk
      /* 14 */ JOIN web_returns wr ON wr.wr_returned_date_sk = d_return.d_date_sk
      /* 15 */ JOIN date_dim d_web ON wr.wr_returned_date_sk = d_web.d_date_sk
      /* 16 */ JOIN web_site ws ON ws.web_open_date_sk = d_web.d_date_sk
    WHERE
      d_sales.d_year = (SELECT MAX(d_year) FROM date_dim)
  ),

  /* Aggregate per store and year */
  agg AS (
    SELECT
      d_year,
      ss_store_sk,
      SUM(ss_net_profit)   AS sum_ss_net_profit,
      SUM(cs_net_profit)   AS sum_cs_net_profit,
      SUM(sr_net_loss)     AS sum_sr_net_loss,
      SUM(cr_net_loss)     AS sum_cr_net_loss,
      SUM(wr_net_loss)     AS sum_wr_net_loss
    FROM base
    GROUP BY d_year, ss_store_sk
  )

SELECT
  year,
  store_sk,
  total_contribution,
  rnk
FROM (
  SELECT
    d_year   AS year,
    ss_store_sk AS store_sk,
    (sum_ss_net_profit + sum_cs_net_profit - sum_sr_net_loss - sum_cr_net_loss - sum_wr_net_loss) AS total_contribution,
    RANK() OVER (PARTITION BY d_year ORDER BY (sum_ss_net_profit + sum_cs_net_profit - sum_sr_net_loss - sum_cr_net_loss - sum_wr_net_loss) DESC) AS rnk
  FROM agg
) t
WHERE rnk <= 5
ORDER BY year, rnk
LIMIT 100
