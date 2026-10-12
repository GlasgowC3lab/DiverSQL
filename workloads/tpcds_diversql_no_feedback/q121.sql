WITH cp_sample AS (
    SELECT *
    FROM catalog_page TABLESAMPLE BERNOULLI (10)
),
max_qty AS (
    SELECT MAX(ss_quantity) AS max_qty FROM store_sales
)
SELECT *
FROM (
    SELECT
        d_date.d_year,
        cd_store.cd_gender,
        SUM(ss.ss_net_paid) AS store_sales_paid,
        SUM(ws.ws_net_paid) AS web_sales_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        RANK() OVER (PARTITION BY d_date.d_year ORDER BY SUM(ss.ss_net_paid) DESC) AS sales_rank
    FROM
        web_site we
        RIGHT OUTER JOIN web_sales ws ON ws.ws_web_site_sk = we.web_site_sk
        LEFT JOIN date_dim d_date ON ws.ws_sold_date_sk = d_date.d_date_sk
        LEFT JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
        LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
        LEFT JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
        LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = d_date.d_date_sk
        LEFT JOIN time_dim t_sales ON ss.ss_sold_time_sk = t_sales.t_time_sk
        LEFT JOIN customer c_store ON ss.ss_customer_sk = c_store.c_customer_sk
        LEFT JOIN customer_demographics cd_store ON ss.ss_cdemo_sk = cd_store.cd_demo_sk
        LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                                 AND wr.wr_item_sk = ws.ws_item_sk
        LEFT JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
        LEFT JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
        LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        LEFT JOIN cp_sample cp ON cp.cp_start_date_sk = d_date.d_date_sk
    WHERE
        ws.ws_quantity > (SELECT max_qty FROM max_qty)
    GROUP BY
        d_date.d_year,
        cd_store.cd_gender
) ranked
WHERE sales_rank <= 5
ORDER BY d_year DESC, store_sales_paid DESC
LIMIT 100
