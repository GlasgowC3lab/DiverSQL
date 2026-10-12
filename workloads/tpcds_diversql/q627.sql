WITH joined_data AS (
    SELECT
        cust.c_customer_sk,
        cust.c_first_name,
        cust.c_last_name,
        cust.c_birth_year,
        cust.c_last_review_date,
        i.i_item_sk,
        i.i_product_name,
        i.i_brand_id,
        i.i_color,
        s.s_store_sk,
        s.s_state,
        cs.cs_order_number        AS catalog_order_number,
        cs.cs_net_profit          AS catalog_net_profit,
        ss.ss_ticket_number       AS store_ticket_number,
        ss.ss_net_profit          AS store_net_profit,
        ws.ws_order_number        AS web_order_number,
        ws.ws_net_profit          AS web_net_profit,
        ws.ws_sold_date_sk        AS ws_sold_date_sk,
        cr.cr_net_loss            AS catalog_net_loss,
        sr.sr_net_loss            AS store_net_loss,
        wr.wr_net_loss            AS web_net_loss,
        r.r_reason_desc,
        td_cat.t_hour             AS catalog_hour,
        td_store.t_hour           AS store_hour,
        td_web.t_hour             AS web_hour,
        wp.wp_url,
        ws_site.web_name
    FROM
        customer cust
        JOIN catalog_sales cs
            ON cs.cs_bill_customer_sk = cust.c_customer_sk
        JOIN catalog_returns cr
            ON cr.cr_order_number = cs.cs_order_number
        JOIN store_sales ss
            ON ss.ss_customer_sk = cust.c_customer_sk
        JOIN store_returns sr
            ON sr.sr_ticket_number = ss.ss_ticket_number
        JOIN web_sales ws
            ON ws.ws_bill_customer_sk = cust.c_customer_sk
        JOIN web_returns wr
            ON wr.wr_order_number = ws.ws_order_number
        JOIN item i
            ON i.i_item_sk = cs.cs_item_sk
            AND i.i_item_sk = ss.ss_item_sk
            AND i.i_item_sk = ws.ws_item_sk
        JOIN store s
            ON s.s_store_sk = ss.ss_store_sk
            AND s.s_store_sk = sr.sr_store_sk
        JOIN reason r
            ON r.r_reason_sk = cr.cr_reason_sk
            AND r.r_reason_sk = sr.sr_reason_sk
            AND r.r_reason_sk = wr.wr_reason_sk
        JOIN web_page wp
            ON wp.wp_web_page_sk = ws.ws_web_page_sk
            AND wp.wp_web_page_sk = wr.wr_web_page_sk
        JOIN web_site ws_site
            ON ws_site.web_site_sk = ws.ws_web_site_sk
        JOIN time_dim td_cat
            ON td_cat.t_time_sk = cs.cs_sold_time_sk
        JOIN time_dim td_ret
            ON td_ret.t_time_sk = cr.cr_returned_time_sk
        JOIN time_dim td_store
            ON td_store.t_time_sk = ss.ss_sold_time_sk
        JOIN time_dim td_store_ret
            ON td_store_ret.t_time_sk = sr.sr_return_time_sk
        JOIN time_dim td_web
            ON td_web.t_time_sk = ws.ws_sold_time_sk
        JOIN time_dim td_web_ret
            ON td_web_ret.t_time_sk = wr.wr_returned_time_sk
    WHERE
        cust.c_birth_year BETWEEN 1950 AND 1975
        AND cust.c_last_review_date > 2452400
        AND i.i_brand_id IN (10, 12, 15)
        AND i.i_color = 'Red'
        AND r.r_reason_id = 'AAAAAAAAPAAAAAAA'
        AND s.s_state = 'CA'
        AND wp.wp_type = 'Content'
)
,
ranked AS (
    SELECT
        *,
        (COALESCE(catalog_net_profit, 0) + COALESCE(store_net_profit, 0) + COALESCE(web_net_profit, 0)) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY i_item_sk ORDER BY (COALESCE(catalog_net_profit, 0) + COALESCE(store_net_profit, 0) + COALESCE(web_net_profit, 0)) DESC) AS profit_rank
    FROM joined_data
)
SELECT
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.i_product_name,
    r.i_brand_id,
    r.i_color,
    r.s_state,
    r.catalog_net_profit,
    r.store_net_profit,
    r.web_net_profit,
    r.total_net_profit,
    r.profit_rank,
    r.catalog_hour,
    r.store_hour,
    r.web_hour,
    r.wp_url,
    r.web_name
FROM ranked r
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr2
    WHERE wr2.wr_refunded_customer_sk = r.c_customer_sk
      AND wr2.wr_order_number = r.web_order_number
      AND wr2.wr_return_quantity > 0
      AND wr2.wr_returned_date_sk <> r.ws_sold_date_sk
)
ORDER BY r.total_net_profit DESC, r.c_customer_sk
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
