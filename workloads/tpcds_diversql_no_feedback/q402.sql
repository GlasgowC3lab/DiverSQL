SELECT
    ss.ss_ticket_number,
    cs.cs_order_number,
    d_sold.d_date AS sale_date,
    w.w_warehouse_name,
    cc.cc_manager,
    cp.cp_description,
    ss.ss_net_profit,
    ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_name ORDER BY ss.ss_net_profit DESC) AS profit_rank,
    SUM(ss.ss_net_profit) OVER (PARTITION BY w.w_warehouse_name ORDER BY d_sold.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_profit_by_warehouse
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p_cat ON cs.cs_promo_sk = p_cat.p_promo_sk
JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN store_sales ss ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
JOIN customer c_ss ON ss.ss_customer_sk = c_ss.c_customer_sk
JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d_sold.d_date_sk
JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN customer c_wr_refund ON wr.wr_refunded_customer_sk = c_wr_refund.c_customer_sk
JOIN customer_demographics cd_wr_refund ON wr.wr_refunded_cdemo_sk = cd_wr_refund.cd_demo_sk
JOIN customer_address ca_wr_refund ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
JOIN customer c_wr_return ON wr.wr_returning_customer_sk = c_wr_return.c_customer_sk
JOIN customer_demographics cd_wr_return ON wr.wr_returning_cdemo_sk = cd_wr_return.cd_demo_sk
JOIN customer_address ca_wr_return ON wr.wr_returning_addr_sk = ca_wr_return.ca_address_sk
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
WHERE d_sold.d_year = 2001
  AND w.w_state = 'CA'
  AND cc.cc_manager = 'Larry Mccray'
  AND cp.cp_catalog_page_number = 10
  AND ss.ss_net_profit > 0
  AND r.r_reason_desc LIKE '%Damage%'
  AND ss.ss_ticket_number NOT IN (
        SELECT ss2.ss_ticket_number
        FROM store_sales ss2
        WHERE ss2.ss_net_paid > 10000
    )
ORDER BY profit_rank ASC, cum_profit_by_warehouse DESC
LIMIT 100
