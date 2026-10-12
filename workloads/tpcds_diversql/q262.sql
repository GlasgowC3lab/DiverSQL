WITH promo_channels AS (
    SELECT
        p.p_promo_sk,
        ARRAY[
            p.p_channel_dmail,
            p.p_channel_email,
            p.p_channel_catalog,
            p.p_channel_tv,
            p.p_channel_radio,
            p.p_channel_press,
            p.p_channel_event,
            p.p_channel_demo
        ] AS channels
    FROM promotion p
),
joined AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        d_sold.d_year AS sold_year,
        d_return.d_year AS return_year,
        d_web.d_year AS web_year,
        cs.cs_order_number,
        cr.cr_order_number AS return_order_number,
        ws.ws_order_number AS web_order_number,
        cs.cs_quantity,
        ws.ws_quantity,
        cs.cs_net_paid,
        ws.ws_net_paid,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        p.p_promo_name,
        r.r_reason_desc,
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_state AS ship_state,
        hd_bill.hd_income_band_sk,
        ws_site.web_name,
        ch.channel
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    LEFT JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
           AND cs.cs_item_sk = cr.cr_item_sk
    LEFT JOIN date_dim d_return
        ON cr.cr_returned_date_sk = d_return.d_date_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN date_dim d_web
        ON ws.ws_sold_date_sk = d_web.d_date_sk
    LEFT JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    LEFT JOIN promotion p2
        ON ws.ws_promo_sk = p2.p_promo_sk
    LEFT JOIN household_demographics hd_ship
        ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    LEFT JOIN customer_address ca_ws_bill
        ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
    LEFT JOIN promo_channels pc
        ON p.p_promo_sk = pc.p_promo_sk
    CROSS JOIN UNNEST(pc.channels) AS ch(channel)
)
SELECT
    i_category,
    i_brand,
    sold_year,
    COUNT(DISTINCT cs_order_number) AS distinct_sales_orders,
    COUNT(DISTINCT web_order_number) AS distinct_web_orders,
    SUM(cs_net_paid) AS total_sales_net_paid,
    SUM(ws_net_paid) AS total_web_net_paid,
    SUM(cr_return_quantity) AS total_return_qty,
    SUM(CASE WHEN cr_net_loss > 0 THEN cr_net_loss ELSE 0 END) AS total_net_loss,
    COUNT(DISTINCT r_reason_desc) AS distinct_return_reasons,
    COUNT(DISTINCT channel) AS distinct_promo_channels
FROM joined
GROUP BY
    i_category,
    i_brand,
    sold_year
ORDER BY
    total_sales_net_paid DESC,
    i_category
LIMIT 100
