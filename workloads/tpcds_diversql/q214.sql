WITH base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_quantity,
        wsite.web_site_id,
        wsite.web_state,
        cc.cc_name,
        d.d_year,
        t.t_hour,
        cd.cd_gender,
        wp.wp_url,
        r.r_reason_desc,
        inv.inv_quantity_on_hand,
        s.s_store_name,
        cp.cp_department
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                             AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
    LEFT JOIN time_dim t_ret ON wr.wr_returned_time_sk = t_ret.t_time_sk
    LEFT JOIN inventory inv ON inv.inv_date_sk = d_ret.d_date_sk
    LEFT JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
    LEFT JOIN date_dim d_cc ON cc.cc_closed_date_sk = d_cc.d_date_sk
    LEFT JOIN date_dim d_cp ON cp.cp_end_date_sk = d_cp.d_date_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 17
      AND cd.cd_gender = 'M'
      AND wsite.web_state = 'CA'
      AND ws.ws_quantity > 5
      AND ws.ws_bill_customer_sk IN (SELECT c_customer_sk FROM customer WHERE c_birth_year = 1965)
)
SELECT
    b.web_site_id,
    b.cc_name,
    SUM(b.ws_net_profit) AS total_profit,
    AVG(b.ws_net_profit) AS avg_profit,
    COUNT(DISTINCT b.ws_order_number) AS order_cnt,
    MIN(b.ws_quantity) AS min_qty,
    MAX(b.ws_quantity) AS max_qty,
    CASE WHEN SUM(b.ws_net_profit) > 100000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
    RANK() OVER (PARTITION BY b.web_site_id ORDER BY SUM(b.ws_net_profit) DESC) AS profit_rank,
    url_part
FROM base b
CROSS JOIN UNNEST(split(b.wp_url, '/')) AS u(url_part)
GROUP BY b.web_site_id, b.cc_name, url_part
ORDER BY total_profit DESC
LIMIT 100
