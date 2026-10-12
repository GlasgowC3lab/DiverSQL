-- goal: Summarize 2001 store sales by store and item category, including related catalog returns, store returns, web returns and inventory, rank stores by net paid and limit to top 100 rows.
WITH
  /* Base sales with date and time dimensions */
  base_sales AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_item_sk,
      ss.ss_store_sk,
      ss.ss_customer_sk,
      ss.ss_hdemo_sk,
      ss.ss_addr_sk,
      ss.ss_ticket_number,
      ss.ss_net_paid,
      d.d_year,
      t.t_hour
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  ),
  /* Join sales to all other reference tables, re‑using several dimension tables under different aliases */
  joined_data AS (
    SELECT
      bs.d_year                              AS sales_year,
      s.s_store_name,
      i.i_category,
      bs.ss_net_paid,
      bs.ss_ticket_number,
      cr.cr_net_loss                         AS cr_net_loss,
      sr.sr_net_loss                         AS sr_net_loss,
      wr.wr_net_loss                         AS wr_net_loss,
      inv.inv_quantity_on_hand               AS inv_quantity_on_hand
    FROM base_sales bs
    /* Core dimensions */
    JOIN store s                     ON bs.ss_store_sk = s.s_store_sk
    JOIN item i                      ON bs.ss_item_sk = i.i_item_sk
    JOIN customer c                  ON bs.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd   ON bs.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca         ON bs.ss_addr_sk = ca.ca_address_sk
    /* Optional return and inventory information */
    LEFT JOIN catalog_returns cr                     ON bs.ss_item_sk = cr.cr_item_sk
    LEFT JOIN date_dim d_cr                         ON cr.cr_returned_date_sk = d_cr.d_date_sk
    LEFT JOIN store_returns sr                     ON bs.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN date_dim d_sr                         ON sr.sr_returned_date_sk = d_sr.d_date_sk
    LEFT JOIN reason r_sr                           ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN web_returns wr                       ON bs.ss_item_sk = wr.wr_item_sk
    LEFT JOIN date_dim d_wr                         ON wr.wr_returned_date_sk = d_wr.d_date_sk
    LEFT JOIN reason r_wr                           ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN web_page wp                           ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN inventory inv                         ON bs.ss_item_sk = inv.inv_item_sk
                                                AND bs.ss_sold_date_sk = inv.inv_date_sk
    LEFT JOIN warehouse w                           ON inv.inv_warehouse_sk = w.w_warehouse_sk
  )
SELECT
  sales_year,
  s_store_name,
  i_category,
  SUM(ss_net_paid)                               AS total_net_paid,
  COUNT(DISTINCT ss_ticket_number)               AS distinct_tickets,
  ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY SUM(ss_net_paid) DESC) AS sales_rank,
  AVG(cr_net_loss)                               AS avg_catalog_net_loss,
  SUM(sr_net_loss)                               AS total_store_return_loss,
  SUM(wr_net_loss)                               AS total_web_return_loss,
  SUM(inv_quantity_on_hand)                      AS total_inventory_on_hand
FROM joined_data
WHERE sales_year = 2001
GROUP BY sales_year, s_store_name, i_category
ORDER BY total_net_paid DESC
LIMIT 100
