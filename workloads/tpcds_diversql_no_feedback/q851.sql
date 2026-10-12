SELECT
    s.ss_ticket_number,
    t.t_hour,
    a.ca_state,
    w.w_warehouse_name,
    c.cr_order_number,
    c.cr_net_loss,
    wr.wr_return_quantity,
    r.r_reason_desc,
    ROW_NUMBER() OVER (PARTITION BY a.ca_state ORDER BY c.cr_net_loss DESC) AS rn_state
FROM tpcds.store_sales AS s
JOIN tpcds.time_dim AS t
  ON s.ss_sold_time_sk = t.t_time_sk
JOIN tpcds.customer_address AS a
  ON s.ss_addr_sk = a.ca_address_sk
JOIN tpcds.catalog_returns AS c
  ON c.cr_returned_time_sk = t.t_time_sk
 AND c.cr_refunded_addr_sk = a.ca_address_sk
JOIN tpcds.warehouse AS w
  ON c.cr_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.web_returns AS wr
  ON wr.wr_returned_time_sk = t.t_time_sk
 AND wr.wr_refunded_addr_sk = a.ca_address_sk
JOIN tpcds.reason AS r
  ON c.cr_reason_sk = r.r_reason_sk
WHERE
    t.t_hour BETWEEN 9 AND 17
    AND a.ca_state = 'CA'
    AND w.w_gmt_offset = -5.00
    AND s.ss_sales_price > 20.00
    AND s.ss_coupon_amt < 150.00
    AND c.cr_net_loss > 0
    AND wr.wr_return_quantity >= 2
    AND r.r_reason_desc LIKE '%color%'
ORDER BY rn_state
LIMIT 100
