WITH joined AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_net_paid,
        ss.ss_net_paid,
        ws.ws_net_paid,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        cd.cd_gender,
        sm.sm_type,
        r.r_reason_desc,
        tp.t_hour,
        wp.wp_max_ad_count,
        wsite.web_state,
        sr.sr_return_quantity,
        wr.wr_return_quantity
    FROM catalog_sales cs
    JOIN time_dim tp
        ON cs.cs_sold_time_sk = tp.t_time_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store_sales ss
        ON ss.ss_sold_time_sk = tp.t_time_sk
        AND ss.ss_item_sk = i.i_item_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = tp.t_time_sk
        AND ws.ws_item_sk = i.i_item_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
    WHERE
        i.i_current_price > 50
        AND cs.cs_net_paid > 1000
        AND ss.ss_wholesale_cost BETWEEN 30 AND 70
        AND sr.sr_return_quantity > 0
        AND wp.wp_max_ad_count = 2
        AND wsite.web_state = 'CA'
        AND r.r_reason_desc = 'Did not like the color'
)
SELECT
    j.i_category,
    j.i_brand,
    j.sm_type,
    j.r_reason_desc,
    j.t_hour,
    SUM(j.cs_net_paid)      AS sum_catalog_net,
    SUM(j.ss_net_paid)      AS sum_store_net,
    SUM(j.ws_net_paid)      AS sum_web_net,
    COUNT(DISTINCT j.cs_order_number) AS distinct_orders,
    AVG(j.i_current_price)  AS avg_item_price,
    MIN(j.cs_net_paid)      AS min_catalog_net,
    MAX(j.cs_net_paid)      AS max_catalog_net,
    ROW_NUMBER() OVER (ORDER BY SUM(j.cs_net_paid) DESC) AS rn
FROM joined j
GROUP BY
    j.i_category,
    j.i_brand,
    j.sm_type,
    j.r_reason_desc,
    j.t_hour,
    j.cs_item_sk
HAVING EXISTS (
    SELECT 1 FROM web_returns wr2
    WHERE wr2.wr_item_sk = j.cs_item_sk
      AND wr2.wr_return_quantity > 0
)
ORDER BY rn
LIMIT 100
