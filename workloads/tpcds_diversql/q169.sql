WITH ss AS (
    SELECT
        ss_sold_time_sk,
        ss_item_sk,
        ss_customer_sk,
        ss_cdemo_sk,
        ss_hdemo_sk,
        ss_addr_sk,
        ss_store_sk,
        ss_ticket_number,
        ss_net_paid,
        ss_net_profit,
        ss_sold_date_sk
    FROM store_sales TABLESAMPLE BERNOULLI (10)
)
SELECT
    s.s_state,
    i.i_category,
    t.t_hour,
    COUNT(DISTINCT c.c_customer_sk)                     AS uniq_customers,
    SUM(ss.ss_net_paid)                                AS total_net_paid,
    AVG(ss.ss_net_profit)                              AS avg_net_profit,
    SUM(cr.cr_net_loss)                                AS total_catalog_return_loss,
    SUM(sr.sr_net_loss)                                AS total_store_return_loss,
    SUM(wr.wr_net_loss)                                AS total_web_return_loss,
    MIN(ss.ss_sold_date_sk)                           AS min_sold_date_sk,
    MAX(ss.ss_sold_date_sk)                           AS max_sold_date_sk
FROM ss
JOIN time_dim t          ON ss.ss_sold_time_sk = t.t_time_sk
JOIN item i               ON ss.ss_item_sk = i.i_item_sk
JOIN customer c           ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca  ON ss.ss_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib       ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store s              ON ss.ss_store_sk = s.s_store_sk
JOIN store_returns sr    ON sr.sr_ticket_number = ss.ss_ticket_number
                           AND sr.sr_item_sk = ss.ss_item_sk
JOIN reason r             ON sr.sr_reason_sk = r.r_reason_sk
JOIN catalog_sales cs    ON cs.cs_item_sk = i.i_item_sk
                           AND cs.cs_sold_time_sk = t.t_time_sk
                           AND cs.cs_bill_customer_sk = c.c_customer_sk
JOIN catalog_returns cr  ON cr.cr_order_number = cs.cs_order_number
                           AND cr.cr_item_sk = i.i_item_sk
JOIN web_sales ws        ON ws.ws_item_sk = i.i_item_sk
                           AND ws.ws_sold_time_sk = t.t_time_sk
                           AND ws.ws_bill_customer_sk = c.c_customer_sk
JOIN web_page wp          ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_returns wr      ON wr.wr_order_number = ws.ws_order_number
                           AND wr.wr_item_sk = i.i_item_sk
JOIN reason r2           ON wr.wr_reason_sk = r2.r_reason_sk
WHERE
    s.s_state = 'CA'
    AND i.i_brand_id = 12
    AND t.t_hour BETWEEN 9 AND 17
    AND hd.hd_vehicle_count >= 1
    AND ib.ib_upper_bound <= 80000
GROUP BY
    s.s_state,
    i.i_category,
    t.t_hour
ORDER BY
    total_net_paid DESC
LIMIT 100
