SELECT
    d.d_date AS sale_date,
    s.s_store_id,
    s.s_store_name,
    d_closed.d_date AS store_closed_date,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    COALESCE(SUM(sr.sr_return_quantity), 0) AS total_quantity_returned,
    COALESCE(SUM(sr.sr_return_amt), 0) AS total_return_amount,
    COALESCE(SUM(sr.sr_net_loss), 0) AS total_return_loss,
    COALESCE(cw.creation_image_cnt, 0) AS total_images_created,
    COALESCE(cw.creation_link_cnt, 0) AS total_links_created,
    COALESCE(aw.access_image_cnt, 0) AS total_images_accessed,
    COALESCE(aw.access_link_cnt, 0) AS total_links_accessed
FROM date_dim d
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = ss.ss_item_sk
    AND sr.sr_store_sk = s.s_store_sk
    AND sr.sr_returned_date_sk = d.d_date_sk
LEFT JOIN (
    SELECT
        wp_creation_date_sk AS date_sk,
        SUM(wp_image_count) AS creation_image_cnt,
        SUM(wp_link_count) AS creation_link_cnt
    FROM web_page
    GROUP BY wp_creation_date_sk
) cw
    ON cw.date_sk = d.d_date_sk
LEFT JOIN (
    SELECT
        wp_access_date_sk AS date_sk,
        SUM(wp_image_count) AS access_image_cnt,
        SUM(wp_link_count) AS access_link_cnt
    FROM web_page
    GROUP BY wp_access_date_sk
) aw
    ON aw.date_sk = d.d_date_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
GROUP BY
    d.d_date,
    s.s_store_id,
    s.s_store_name,
    d_closed.d_date,
    cw.creation_image_cnt,
    cw.creation_link_cnt,
    aw.access_image_cnt,
    aw.access_link_cnt
ORDER BY
    total_sales_amount DESC,
    d.d_date,
    s.s_store_id
