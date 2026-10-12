WITH
    /* Central fact table */
    ss AS (
        SELECT *
        FROM store_sales
    )
SELECT
    s.s_store_name,
    d_sales.d_year,
    SUM(ss.ss_net_paid) AS total_net_paid,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    SUM(wr.wr_net_loss) AS web_return_loss,
    SUM(inv.inv_quantity_on_hand) AS total_inventory,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_web_pages
FROM ss
JOIN date_dim d_sales
  ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t_sales
  ON ss.ss_sold_time_sk = t_sales.t_time_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
  ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
  ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN catalog_sales cs
  ON cs.cs_sold_date_sk = d_sales.d_date_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN catalog_returns cr
  ON cr.cr_returned_date_sk = d_sales.d_date_sk
JOIN reason r_cr
  ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN inventory inv
  ON inv.inv_date_sk = d_sales.d_date_sk
JOIN web_returns wr
  ON wr.wr_returned_date_sk = d_sales.d_date_sk
JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN reason r_wr
  ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN web_site ws
  ON ws.web_open_date_sk = d_sales.d_date_sk
WHERE s.s_store_sk NOT IN (
        SELECT s_closed.s_store_sk
        FROM store s_closed
        WHERE s_closed.s_closed_date_sk IS NOT NULL
    )
GROUP BY s.s_store_name, d_sales.d_year
HAVING SUM(ss.ss_net_paid) > 100000
ORDER BY total_net_paid DESC
LIMIT 100
