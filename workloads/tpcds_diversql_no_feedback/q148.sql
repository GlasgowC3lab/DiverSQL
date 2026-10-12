WITH ss_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_sold_time_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        SUM(ss.ss_ext_sales_price) AS sum_store_sales_price,
        COUNT(*) AS cnt_store_sales
    FROM store_sales ss
    GROUP BY
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_sold_time_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk
)
SELECT
    s.s_state,
    p.p_promo_name,
    t_hour.t_hour AS sale_hour,
    SUM(ss_agg.sum_store_sales_price) AS total_store_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders,
    MIN(ws.ws_net_profit) AS min_web_profit,
    MAX(ws.ws_net_profit) AS max_web_profit,
    cr.customer_total_sales
FROM ss_agg
JOIN store s ON ss_agg.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss_agg.ss_promo_sk = p.p_promo_sk
JOIN time_dim t_hour ON ss_agg.ss_sold_time_sk = t_hour.t_time_sk
JOIN customer c ON ss_agg.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss_agg.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss_agg.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON ss_agg.ss_addr_sk = ca.ca_address_sk
JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN time_dim t_ret ON wr.wr_returned_time_sk = t_ret.t_time_sk
CROSS JOIN LATERAL (
    SELECT SUM(ws2.ws_ext_sales_price) AS customer_total_sales
    FROM web_sales ws2
    WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
) cr
WHERE s.s_state = 'CA'
  AND we.web_city = 'Woodlawn'
  AND t_hour.t_hour BETWEEN 9 AND 17
  AND p.p_discount_active = 'Y'
  AND we.web_rec_end_date = DATE '2001-08-15'
  AND r.r_reason_desc = 'Damaged'
GROUP BY
    s.s_state,
    p.p_promo_name,
    t_hour.t_hour,
    c.c_customer_sk,
    cr.customer_total_sales
ORDER BY total_store_sales DESC
LIMIT 100
