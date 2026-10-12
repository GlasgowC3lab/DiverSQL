/*
  Goal: Identify store‑sales transactions (ticket numbers) that do not have a matching return order, while showing per‑store net paid totals, a lag of the previous total, and a running total of net paid. The query uses GROUPING SETS for flexible aggregation, analytic window functions, and an EXCEPT set operation to subtract the returned‑order key set from the sales key set.
*/
WITH sales_pre AS (
  SELECT
    ss.ss_ticket_number,
    s.s_store_id,
    ss.ss_sold_date_sk,
    ss.ss_net_paid
  FROM tpcds.store_sales ss
  JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
  JOIN tpcds.time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
  WHERE td.t_hour BETWEEN 9 AND 12
    AND s.s_state = 'CA'
),

sales_agg AS (
  SELECT
    ss_ticket_number,
    s_store_id,
    SUM(ss_net_paid) AS total_net_paid,
    COUNT(*) AS sales_cnt
  FROM sales_pre
  GROUP BY GROUPING SETS (
    (ss_ticket_number, s_store_id),
    (s_store_id)
  )
),

sales_window AS (
  SELECT
    ss_ticket_number,
    s_store_id,
    total_net_paid,
    sales_cnt,
    LAG(total_net_paid) OVER (PARTITION BY s_store_id ORDER BY ss_ticket_number) AS lag_total_net,
    SUM(total_net_paid) OVER (PARTITION BY s_store_id ORDER BY ss_ticket_number ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_net
  FROM sales_agg
),

returns_pre AS (
  SELECT
    cr.cr_order_number,
    w.w_warehouse_id,
    cr.cr_refunded_cash
  FROM tpcds.catalog_returns cr
  JOIN tpcds.warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN tpcds.time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
  WHERE td.t_hour BETWEEN 9 AND 12
    AND w.w_country = 'United States'
),

returns_agg AS (
  SELECT
    cr_order_number AS ss_ticket_number,
    w_warehouse_id AS s_store_id,
    SUM(cr_refunded_cash) AS total_refunded_cash,
    COUNT(*) AS return_cnt
  FROM returns_pre
  GROUP BY GROUPING SETS (
    (cr_order_number, w_warehouse_id),
    (w_warehouse_id)
  )
)
SELECT
  sw.ss_ticket_number,
  sw.s_store_id,
  sw.total_net_paid,
  sw.sales_cnt,
  sw.lag_total_net,
  sw.running_total_net
FROM sales_window sw
EXCEPT
SELECT
  ra.ss_ticket_number,
  ra.s_store_id,
  ra.total_refunded_cash AS total_net_paid,
  ra.return_cnt AS sales_cnt,
  NULL AS lag_total_net,
  NULL AS running_total_net
FROM returns_agg ra
ORDER BY s_store_id, ss_ticket_number
LIMIT 100
